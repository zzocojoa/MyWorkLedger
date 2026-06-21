import 'package:flutter_test/flutter_test.dart';
import 'package:workledger/features/work_record/data/local_storage_quick_record_settings_repository.dart';
import 'package:workledger/features/work_record/domain/quick_record_settings.dart';
import 'package:workledger/features/work_record/domain/quick_record_settings_repository.dart';

import '../../../core/storage/in_memory_key_value_storage.dart';

void main() {
  group('LocalStorageQuickRecordSettingsRepository', () {
    test('returns null when active settings do not exist', () async {
      final LocalStorageQuickRecordSettingsRepository repository =
          LocalStorageQuickRecordSettingsRepository(
            storage: InMemoryKeyValueStorage.empty(),
            clock: () => DateTime(2026, 6, 12, 9),
          );

      expect(await repository.findActive(), isNull);
    });

    test('saves and updates active settings', () async {
      DateTime now = DateTime(2026, 6, 12, 9);
      final LocalStorageQuickRecordSettingsRepository repository =
          LocalStorageQuickRecordSettingsRepository(
            storage: InMemoryKeyValueStorage.empty(),
            clock: () => now,
          );

      final QuickRecordSettings first = await repository.save(
        mode: QuickRecordMode.chooseBeforeSave,
      );
      now = DateTime(2026, 6, 12, 10);
      final QuickRecordSettings second = await repository.save(
        mode: QuickRecordMode.currentTimeOnly,
      );

      expect(first.createdAt, DateTime(2026, 6, 12, 9));
      expect(second.createdAt, DateTime(2026, 6, 12, 9));
      expect(second.updatedAt, DateTime(2026, 6, 12, 10));
      expect(
        (await repository.findActive())?.mode,
        QuickRecordMode.currentTimeOnly,
      );
    });

    test('wraps parse failures with table and key context', () async {
      final InMemoryKeyValueStorage storage = InMemoryKeyValueStorage.empty();
      await storage.write(
        table:
            LocalStorageQuickRecordSettingsRepository.quickRecordSettingsTable,
        key: LocalStorageQuickRecordSettingsRepository
            .activeQuickRecordSettingsKey,
        value: <String, Object?>{
          'mode': 'invalid',
          'created_at': '2026-06-12T09:00:00',
          'updated_at': '2026-06-12T09:00:00',
        },
      );
      final LocalStorageQuickRecordSettingsRepository repository =
          LocalStorageQuickRecordSettingsRepository(
            storage: storage,
            clock: () => DateTime(2026, 6, 12, 9),
          );

      await expectLater(
        repository.findActive(),
        throwsA(
          isA<QuickRecordSettingsRepositoryException>().having(
            (QuickRecordSettingsRepositoryException error) => error.message,
            'message',
            allOf(
              contains('table=quick_record_settings'),
              contains('key=active'),
              contains('field=mode'),
            ),
          ),
        ),
      );
    });
  });
}
