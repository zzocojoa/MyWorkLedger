import 'dart:convert';
import 'dart:io';

import 'key_value_storage.dart';

typedef PersistentStorageTables =
    Map<String, Map<String, Map<String, Object?>>>;

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
  try {
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(tables), flush: true);
  } on FileSystemException catch (error) {
    throw PersistentKeyValueStorageException(
      'action=write table=$table key=$key path=${file.path} error=${error.message}',
    );
  } on JsonUnsupportedObjectError catch (error) {
    throw PersistentKeyValueStorageException(
      'action=write table=$table key=$key path=${file.path} unsupportedObject=${error.unsupportedObject} rule=JSON encodable value',
    );
  }
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
