abstract interface class KeyValueStorage {
  Future<Map<String, Object?>?> read({
    required String table,
    required String key,
  });

  Future<Map<String, Map<String, Object?>>> readAll({required String table});

  Future<void> write({
    required String table,
    required String key,
    required Map<String, Object?> value,
  });
}
