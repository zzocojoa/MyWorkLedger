import 'quick_record_settings.dart';

abstract interface class QuickRecordSettingsRepository {
  Future<QuickRecordSettings?> findActive();

  Future<QuickRecordSettings> save({required QuickRecordMode mode});
}

final class QuickRecordSettingsRepositoryException implements Exception {
  const QuickRecordSettingsRepositoryException(this.message);

  final String message;

  @override
  String toString() {
    return 'QuickRecordSettingsRepositoryException: $message';
  }
}
