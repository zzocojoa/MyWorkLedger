import 'package:flutter_test/flutter_test.dart';
import 'package:workledger/core/models/compensation_reference_setting.dart';
import 'package:workledger/features/compensation_reference/data/local_storage_compensation_reference_repository.dart';

import '../../../core/storage/in_memory_key_value_storage.dart';

void main() {
  group('LocalStorageCompensationReferenceRepository', () {
    test('saves setting and applies it to every month lookup', () async {
      final InMemoryKeyValueStorage storage = InMemoryKeyValueStorage.empty();
      final LocalStorageCompensationReferenceRepository repository =
          _repository(storage: storage);

      await repository.save(
        mode: CompensationReferenceMode.fixedIncluded,
        fixedIncludedOvertimeMinutes: 120,
        fixedIncludedNightMinutes: 30,
        fixedIncludedHolidayMinutes: 60,
        effectiveFromMonth: DateTime(2026, 5, 20),
        memo: null,
      );

      final CompensationReferenceSetting? pastSetting = await repository
          .findApplicableForMonth(year: 2026, month: 6);
      final CompensationReferenceSetting? futureSetting = await repository
          .findApplicableForMonth(year: 2027, month: 1);

      expect(pastSetting?.mode, CompensationReferenceMode.fixedIncluded);
      expect(futureSetting?.mode, CompensationReferenceMode.fixedIncluded);
      expect(futureSetting?.fixedIncludedOvertimeMinutes, 120);
    });

    test('updates current setting without changing createdAt', () async {
      final InMemoryKeyValueStorage storage = InMemoryKeyValueStorage.empty();
      DateTime clock = DateTime(2026, 6, 1, 9);
      final LocalStorageCompensationReferenceRepository repository =
          LocalStorageCompensationReferenceRepository(
            storage: storage,
            clock: () => clock,
            idGenerator: () => 'setting-1',
          );
      final CompensationReferenceSetting first = await repository.save(
        mode: CompensationReferenceMode.unknown,
        fixedIncludedOvertimeMinutes: 0,
        fixedIncludedNightMinutes: 0,
        fixedIncludedHolidayMinutes: 0,
        effectiveFromMonth: DateTime(2026, 6),
        memo: null,
      );
      clock = DateTime(2026, 6, 2, 9);
      final CompensationReferenceSetting second = await repository.save(
        mode: CompensationReferenceMode.fixedIncluded,
        fixedIncludedOvertimeMinutes: 60,
        fixedIncludedNightMinutes: 0,
        fixedIncludedHolidayMinutes: 0,
        effectiveFromMonth: DateTime(2026, 6),
        memo: '변경',
      );

      expect(second.id, first.id);
      expect(second.createdAt, first.createdAt);
      expect(second.updatedAt, clock);
      expect(second.mode, CompensationReferenceMode.fixedIncluded);
    });
  });
}

LocalStorageCompensationReferenceRepository _repository({
  required InMemoryKeyValueStorage storage,
}) {
  return LocalStorageCompensationReferenceRepository(
    storage: storage,
    clock: () => DateTime(2026, 6, 1, 9),
    idGenerator: () => 'setting-${DateTime.now().microsecondsSinceEpoch}',
  );
}
