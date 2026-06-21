import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'key_value_storage.dart';

typedef PersistentStorageTables =
    Map<String, Map<String, Map<String, Object?>>>;
typedef _PersistentStorageMutation<T> = Future<T> Function();

const Duration _persistentStorageLockRetryDelay = Duration(milliseconds: 5);
const Duration _persistentStorageLockTimeout = Duration(seconds: 10);
const Duration _persistentStorageStaleLockAge = Duration(minutes: 2);
const Duration _persistentStorageStaleLockCheckDelay = Duration(
  milliseconds: 20,
);

final Map<String, Future<void>> _persistentStorageMutationQueues =
    <String, Future<void>>{};

final class PersistentKeyValueStorageException implements Exception {
  const PersistentKeyValueStorageException(this.message);

  final String message;

  @override
  String toString() {
    return 'PersistentKeyValueStorageException: $message';
  }
}

final class PersistentKeyValueStorage implements KeyValueStorage {
  const PersistentKeyValueStorage({required this.file});

  final File file;

  static const String storageFileName = 'workledger_key_value_storage.json';

  static File fileInDirectory({required Directory directory}) {
    return File('${directory.path}${Platform.pathSeparator}$storageFileName');
  }

  @override
  Future<Map<String, Object?>?> read({
    required String table,
    required String key,
  }) async {
    final PersistentStorageTables tables = await _readTables(
      file: file,
      table: table,
      key: key,
      action: 'read',
    );
    final Map<String, Object?>? value = tables[table]?[key];
    if (value == null) {
      return null;
    }
    return _copyStorageMap(
      value: value,
      table: table,
      key: key,
      action: 'read',
    );
  }

  @override
  Future<Map<String, Map<String, Object?>>> readAll({
    required String table,
  }) async {
    final PersistentStorageTables tables = await _readTables(
      file: file,
      table: table,
      key: '*',
      action: 'readAll',
    );
    return _copyRows(
      rows: tables[table] ?? <String, Map<String, Object?>>{},
      table: table,
      action: 'readAll',
    );
  }

  @override
  Future<void> write({
    required String table,
    required String key,
    required Map<String, Object?> value,
  }) async {
    await _runPersistentStorageMutation<void>(
      file: file,
      table: table,
      key: key,
      action: 'write',
      mutation: () async {
        final PersistentStorageTables tables = await _readTables(
          file: file,
          table: table,
          key: key,
          action: 'write',
        );
        final Map<String, Object?> copiedValue = _copyStorageMap(
          value: value,
          table: table,
          key: key,
          action: 'write',
        );
        final Map<String, Map<String, Object?>> tableValues =
            tables[table] ?? <String, Map<String, Object?>>{};
        tableValues[key] = copiedValue;
        tables[table] = tableValues;
        await _writeTables(file: file, table: table, key: key, tables: tables);
      },
    );
  }

  @override
  Future<void> delete({required String table, required String key}) async {
    await _runPersistentStorageMutation<void>(
      file: file,
      table: table,
      key: key,
      action: 'delete',
      mutation: () async {
        final PersistentStorageTables tables = await _readTables(
          file: file,
          table: table,
          key: key,
          action: 'delete',
        );
        final Map<String, Map<String, Object?>>? tableValues = tables[table];
        if (tableValues == null) {
          return;
        }
        tableValues.remove(key);
        if (tableValues.isEmpty) {
          tables.remove(table);
        } else {
          tables[table] = tableValues;
        }
        await _writeTables(file: file, table: table, key: key, tables: tables);
      },
    );
  }
}

Future<T> _runPersistentStorageMutation<T>({
  required File file,
  required String table,
  required String key,
  required String action,
  required _PersistentStorageMutation<T> mutation,
}) async {
  final String path = file.absolute.path;
  final Future<void> previousMutation =
      _persistentStorageMutationQueues[path] ?? Future<void>.value();
  final Completer<void> currentMutation = Completer<void>();
  final Future<void> currentFuture = currentMutation.future;
  _persistentStorageMutationQueues[path] = currentFuture;

  try {
    await previousMutation;
    return await _runWithPersistentStorageLock<T>(
      file: file,
      table: table,
      key: key,
      action: action,
      mutation: mutation,
    );
  } finally {
    currentMutation.complete();
    if (identical(_persistentStorageMutationQueues[path], currentFuture)) {
      _persistentStorageMutationQueues.remove(path);
    }
  }
}

Future<T> _runWithPersistentStorageLock<T>({
  required File file,
  required String table,
  required String key,
  required String action,
  required _PersistentStorageMutation<T> mutation,
}) async {
  final File lockFile = _lockFileFor(file: file);
  bool lockAcquired = false;
  try {
    await file.parent.create(recursive: true);
    await _acquirePersistentStorageLock(
      lockFile: lockFile,
      file: file,
      table: table,
      key: key,
      action: action,
    );
    lockAcquired = true;
    return await mutation();
  } on FileSystemException catch (error) {
    throw PersistentKeyValueStorageException(
      'action=$action table=$table key=$key path=${file.path} lockPath=${lockFile.path} error=${error.message}',
    );
  } finally {
    if (lockAcquired) {
      await _releasePersistentStorageLock(
        lockFile: lockFile,
        file: file,
        table: table,
        key: key,
        action: action,
      );
    }
  }
}

Future<void> _acquirePersistentStorageLock({
  required File lockFile,
  required File file,
  required String table,
  required String key,
  required String action,
}) async {
  final DateTime deadline = DateTime.now().add(_persistentStorageLockTimeout);
  FileSystemException? lastError;
  while (true) {
    try {
      await lockFile.create(exclusive: true);
      await _writePersistentStorageLockMetadata(
        lockFile: lockFile,
        file: file,
        table: table,
        key: key,
        action: action,
      );
      return;
    } on FileSystemException catch (error) {
      lastError = error;
      await _recoverStalePersistentStorageLock(
        lockFile: lockFile,
        file: file,
        table: table,
        key: key,
        action: action,
      );
      if (DateTime.now().isAfter(deadline)) {
        throw PersistentKeyValueStorageException(
          'action=$action table=$table key=$key path=${file.path} lockPath=${lockFile.path} timeoutMs=${_persistentStorageLockTimeout.inMilliseconds} error=${lastError.message}',
        );
      }
      await Future<void>.delayed(_persistentStorageLockRetryDelay);
    }
  }
}

Future<void> _writePersistentStorageLockMetadata({
  required File lockFile,
  required File file,
  required String table,
  required String key,
  required String action,
}) async {
  try {
    await lockFile.writeAsString(
      jsonEncode(<String, Object?>{
        'pid': pid,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'path': file.absolute.path,
      }),
      flush: true,
    );
  } on FileSystemException catch (error) {
    throw PersistentKeyValueStorageException(
      'action=$action table=$table key=$key path=${file.path} lockPath=${lockFile.path} lockMetadataError=${error.message}',
    );
  } on JsonUnsupportedObjectError catch (error) {
    throw PersistentKeyValueStorageException(
      'action=$action table=$table key=$key path=${file.path} lockPath=${lockFile.path} lockMetadataError=${error.unsupportedObject}',
    );
  }
}

Future<void> _recoverStalePersistentStorageLock({
  required File lockFile,
  required File file,
  required String table,
  required String key,
  required String action,
}) async {
  final FileStat firstStat = await _statPersistentStorageLock(
    lockFile: lockFile,
    file: file,
    table: table,
    key: key,
    action: action,
  );
  if (!_isPersistentStorageLockStale(modifiedAt: firstStat.modified)) {
    return;
  }

  await Future<void>.delayed(_persistentStorageStaleLockCheckDelay);

  final FileStat secondStat = await _statPersistentStorageLock(
    lockFile: lockFile,
    file: file,
    table: table,
    key: key,
    action: action,
  );
  if (!_isPersistentStorageLockStale(modifiedAt: secondStat.modified)) {
    return;
  }
  if (firstStat.modified != secondStat.modified ||
      firstStat.size != secondStat.size) {
    return;
  }

  await _deletePersistentStorageLock(
    lockFile: lockFile,
    file: file,
    table: table,
    key: key,
    action: action,
    errorField: 'staleLockRecoveryError',
  );
}

Future<FileStat> _statPersistentStorageLock({
  required File lockFile,
  required File file,
  required String table,
  required String key,
  required String action,
}) async {
  try {
    return await lockFile.stat();
  } on FileSystemException catch (error) {
    if (!await lockFile.exists()) {
      return FileStat.statSync(lockFile.path);
    }
    throw PersistentKeyValueStorageException(
      'action=$action table=$table key=$key path=${file.path} lockPath=${lockFile.path} statError=${error.message}',
    );
  }
}

bool _isPersistentStorageLockStale({required DateTime modifiedAt}) {
  final DateTime staleCutoff = DateTime.now().subtract(
    _persistentStorageStaleLockAge,
  );
  return modifiedAt.isBefore(staleCutoff);
}

Future<void> _releasePersistentStorageLock({
  required File lockFile,
  required File file,
  required String table,
  required String key,
  required String action,
}) async {
  await _deletePersistentStorageLock(
    lockFile: lockFile,
    file: file,
    table: table,
    key: key,
    action: action,
    errorField: 'releaseError',
  );
}

Future<void> _deletePersistentStorageLock({
  required File lockFile,
  required File file,
  required String table,
  required String key,
  required String action,
  required String errorField,
}) async {
  try {
    await lockFile.delete();
  } on FileSystemException catch (error) {
    if (!await lockFile.exists()) {
      return;
    }
    throw PersistentKeyValueStorageException(
      'action=$action table=$table key=$key path=${file.path} lockPath=${lockFile.path} $errorField=${error.message}',
    );
  }
}

Future<PersistentStorageTables> _readTables({
  required File file,
  required String table,
  required String key,
  required String action,
}) async {
  try {
    if (!await file.exists()) {
      return <String, Map<String, Map<String, Object?>>>{};
    }
    final String content = await file.readAsString();
    final Object? decoded = jsonDecode(content);
    return _parseTables(
      decoded: decoded,
      file: file,
      table: table,
      key: key,
      action: action,
    );
  } on FileSystemException catch (error) {
    throw PersistentKeyValueStorageException(
      'action=$action table=$table key=$key path=${file.path} error=${error.message}',
    );
  } on FormatException catch (error) {
    throw PersistentKeyValueStorageException(
      'action=$action table=$table key=$key path=${file.path} offset=${error.offset} rule=valid JSON',
    );
  }
}

PersistentStorageTables _parseTables({
  required Object? decoded,
  required File file,
  required String table,
  required String key,
  required String action,
}) {
  if (decoded is! Map<String, Object?>) {
    throw PersistentKeyValueStorageException(
      'action=$action table=$table key=$key path=${file.path} rule=root JSON object',
    );
  }

  final PersistentStorageTables tables =
      <String, Map<String, Map<String, Object?>>>{};
  for (final MapEntry<String, Object?> tableEntry in decoded.entries) {
    final Object? tableValue = tableEntry.value;
    if (tableValue is! Map<String, Object?>) {
      throw PersistentKeyValueStorageException(
        'action=$action table=$table key=$key path=${file.path} storedTable=${tableEntry.key} rule=table JSON object',
      );
    }

    final Map<String, Map<String, Object?>> rows =
        <String, Map<String, Object?>>{};
    for (final MapEntry<String, Object?> rowEntry in tableValue.entries) {
      final Object? rowValue = rowEntry.value;
      if (rowValue is! Map<String, Object?>) {
        throw PersistentKeyValueStorageException(
          'action=$action table=$table key=$key path=${file.path} storedTable=${tableEntry.key} storedKey=${rowEntry.key} rule=row JSON object',
        );
      }
      rows[rowEntry.key] = _copyStorageMap(
        value: rowValue,
        table: tableEntry.key,
        key: rowEntry.key,
        action: action,
      );
    }
    tables[tableEntry.key] = rows;
  }
  return tables;
}

Future<void> _writeTables({
  required File file,
  required String table,
  required String key,
  required PersistentStorageTables tables,
}) async {
  final File temporaryFile = _temporaryFileFor(file: file);
  try {
    final String encodedTables = jsonEncode(tables);
    await file.parent.create(recursive: true);
    if (await temporaryFile.exists()) {
      await temporaryFile.delete();
    }
    await temporaryFile.writeAsString(encodedTables, flush: true);
    await temporaryFile.rename(file.path);
  } on FileSystemException catch (error) {
    throw PersistentKeyValueStorageException(
      'action=write table=$table key=$key path=${file.path} temporaryPath=${temporaryFile.path} error=${error.message}',
    );
  } on JsonUnsupportedObjectError catch (error) {
    throw PersistentKeyValueStorageException(
      'action=write table=$table key=$key path=${file.path} unsupportedObject=${error.unsupportedObject} rule=JSON encodable value',
    );
  }
}

File _temporaryFileFor({required File file}) {
  return File('${file.path}.tmp');
}

File _lockFileFor({required File file}) {
  return File('${file.path}.lock');
}

Map<String, Map<String, Object?>> _copyRows({
  required Map<String, Map<String, Object?>> rows,
  required String table,
  required String action,
}) {
  final Map<String, Map<String, Object?>> copiedRows =
      <String, Map<String, Object?>>{};
  for (final MapEntry<String, Map<String, Object?>> rowEntry in rows.entries) {
    copiedRows[rowEntry.key] = _copyStorageMap(
      value: rowEntry.value,
      table: table,
      key: rowEntry.key,
      action: action,
    );
  }
  return copiedRows;
}

Map<String, Object?> _copyStorageMap({
  required Map<String, Object?> value,
  required String table,
  required String key,
  required String action,
}) {
  final Map<String, Object?> copiedValue = <String, Object?>{};
  for (final MapEntry<String, Object?> entry in value.entries) {
    copiedValue[entry.key] = _copyStorageValue(
      value: entry.value,
      table: table,
      key: key,
      action: action,
      field: entry.key,
    );
  }
  return copiedValue;
}

Object? _copyStorageValue({
  required Object? value,
  required String table,
  required String key,
  required String action,
  required String field,
}) {
  if (value == null || value is String || value is num || value is bool) {
    return value;
  }
  if (value is List<Object?>) {
    return value
        .map(
          (Object? item) => _copyStorageValue(
            value: item,
            table: table,
            key: key,
            action: action,
            field: '$field[]',
          ),
        )
        .toList();
  }
  if (value is Map<String, Object?>) {
    final Map<String, Object?> copiedMap = <String, Object?>{};
    for (final MapEntry<String, Object?> entry in value.entries) {
      copiedMap[entry.key] = _copyStorageValue(
        value: entry.value,
        table: table,
        key: key,
        action: action,
        field: '$field.${entry.key}',
      );
    }
    return copiedMap;
  }
  throw PersistentKeyValueStorageException(
    'action=$action table=$table key=$key field=$field valueType=${value.runtimeType} rule=JSON-compatible value',
  );
}
