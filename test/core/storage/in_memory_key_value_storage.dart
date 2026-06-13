import 'package:workledger/core/storage/key_value_storage.dart';

final class InMemoryKeyValueStorage implements KeyValueStorage {
  InMemoryKeyValueStorage({
    required Map<String, Map<String, Map<String, Object?>>> tables,
  }) : _tables = _copyTables(tables);

  InMemoryKeyValueStorage.empty()
    : _tables = <String, Map<String, Map<String, Object?>>>{};

  final Map<String, Map<String, Map<String, Object?>>> _tables;

  @override
  Future<Map<String, Object?>?> read({
    required String table,
    required String key,
  }) async {
    final Map<String, Object?>? value = _tables[table]?[key];
    if (value == null) {
      return null;
    }
    return _copyStorageMap(value);
  }

  @override
  Future<Map<String, Map<String, Object?>>> readAll({
    required String table,
  }) async {
    final Map<String, Map<String, Object?>>? rows = _tables[table];
    if (rows == null) {
      return <String, Map<String, Object?>>{};
    }
    return _copyRows(rows);
  }

  @override
  Future<void> write({
    required String table,
    required String key,
    required Map<String, Object?> value,
  }) async {
    final Map<String, Map<String, Object?>> tableValues =
        _tables[table] ?? <String, Map<String, Object?>>{};
    tableValues[key] = _copyStorageMap(value);
    _tables[table] = tableValues;
  }
}

Map<String, Map<String, Map<String, Object?>>> _copyTables(
  Map<String, Map<String, Map<String, Object?>>> tables,
) {
  final Map<String, Map<String, Map<String, Object?>>> copiedTables =
      <String, Map<String, Map<String, Object?>>>{};
  for (final MapEntry<String, Map<String, Map<String, Object?>>> tableEntry
      in tables.entries) {
    final Map<String, Map<String, Object?>> copiedRows = _copyRows(
      tableEntry.value,
    );
    copiedTables[tableEntry.key] = copiedRows;
  }
  return copiedTables;
}

Map<String, Map<String, Object?>> _copyRows(
  Map<String, Map<String, Object?>> rows,
) {
  final Map<String, Map<String, Object?>> copiedRows =
      <String, Map<String, Object?>>{};
  for (final MapEntry<String, Map<String, Object?>> rowEntry in rows.entries) {
    copiedRows[rowEntry.key] = _copyStorageMap(rowEntry.value);
  }
  return copiedRows;
}

Map<String, Object?> _copyStorageMap(Map<String, Object?> value) {
  final Map<String, Object?> copiedValue = <String, Object?>{};
  for (final MapEntry<String, Object?> entry in value.entries) {
    copiedValue[entry.key] = _copyStorageValue(entry.value);
  }
  return copiedValue;
}

Object? _copyStorageValue(Object? value) {
  if (value == null || value is String || value is num || value is bool) {
    return value;
  }
  if (value is List<Object?>) {
    return value.map(_copyStorageValue).toList();
  }
  if (value is Map<String, Object?>) {
    return _copyStorageMap(value);
  }
  throw ArgumentError.value(
    value,
    'value',
    'must be JSON-compatible storage value',
  );
}
