import '../../../core/storage/key_value_storage.dart';
import '../domain/quick_record_settings.dart';
import '../domain/quick_record_settings_repository.dart';

typedef QuickRecordSettingsClock = DateTime Function();

final class LocalStorageQuickRecordSettingsRepository
    implements QuickRecordSettingsRepository {
  const LocalStorageQuickRecordSettingsRepository({
    required this.storage,
    required this.clock,
  });

  final KeyValueStorage storage;
  final QuickRecordSettingsClock clock;

  static const String quickRecordSettingsTable = 'quick_record_settings';
  static const String activeQuickRecordSettingsKey = 'active';

  @override
  Future<QuickRecordSettings?> findActive() async {
    final Map<String, Object?>? map = await storage.read(
      table: quickRecordSettingsTable,
      key: activeQuickRecordSettingsKey,
    );
    if (map == null) {
      return null;
    }
    return _parseSettingsMap(map: map);
  }

  @override
  Future<QuickRecordSettings> save({required QuickRecordMode mode}) async {
    final DateTime now = clock();
    final QuickRecordSettings? existingSettings = await findActive();
    final QuickRecordSettings settings = QuickRecordSettings(
      mode: mode,
      createdAt: existingSettings?.createdAt ?? now,
      updatedAt: now,
    );
    await storage.write(
      table: quickRecordSettingsTable,
      key: activeQuickRecordSettingsKey,
      value: settings.toMap(),
    );
    return settings;
  }
}

QuickRecordSettings _parseSettingsMap({required Map<String, Object?> map}) {
  try {
    return QuickRecordSettings.fromMap(map);
  } on QuickRecordSettingsParseException catch (error) {
    throw QuickRecordSettingsRepositoryException(
      'action=parse table=${LocalStorageQuickRecordSettingsRepository.quickRecordSettingsTable} key=${LocalStorageQuickRecordSettingsRepository.activeQuickRecordSettingsKey} cause=${error.message}',
    );
  }
}
