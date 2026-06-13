import 'package:flutter_test/flutter_test.dart';
import 'package:workledger/core/models/compensation_reference_setting.dart';
import 'package:workledger/features/compensation_reference/data/local_storage_compensation_reference_repository.dart';

import '../../../core/storage/in_memory_key_value_storage.dart';

void main() {
  group('LocalStorageCompensationReferenceRepository', () {
    test('saves and finds latest applicable setting for month', () async {
      final InMemoryKeyValueStorage storage = InMemoryKeyValueStorage.empty();
      final LocalStorageCompensationReferenceRepository repository =
          _repository(storage: storage);

      await repository.save(
        mode: CompensationReferenceMode.fixedIncluded,
        fixedIncludedOvertimeMinutes: 120,
        fixedIncludedNightMinutes: 30,
        fixedIncludedHolidayMinutes: 60,
        effectiveFromMonth: DateTime(2026, 5, 20),
        memo: '5월부터',
      );
      await repository.save(
        mode: CompensationReferenceMode.none,
        fixedIncludedOvertimeMinutes: 0,
        fixedIncludedNightMinutes: 0,
        fixedIncludedHolidayMinutes: 0,
        effectiveFromMonth: DateTime(2026, 7, 1),
        memo: null,
      );

      final CompensationReferenceSetting? juneSetting = await repository
          .findApplicableForMonth(year: 2026, month: 6);
      final CompensationReferenceSetting? julySetting = await repository
          .findApplicableForMonth(year: 2026, month: 7);

      expect(juneSetting?.mode, CompensationReferenceMode.fixedIncluded);
      expect(juneSetting?.effectiveFromMonth, DateTime(2026, 5));
      expect(julySetting?.mode, CompensationReferenceMode.none);
    });

    test('updates same effective month without changing createdAt', () async {
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
