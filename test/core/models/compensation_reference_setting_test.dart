import 'package:flutter_test/flutter_test.dart';
import 'package:workledger/core/models/compensation_reference_setting.dart';

void main() {
  group('CompensationReferenceSetting', () {
    test('serializes and parses setting map', () {
      final CompensationReferenceSetting setting = CompensationReferenceSetting(
        id: 'setting-1',
        mode: CompensationReferenceMode.fixedIncluded,
        fixedIncludedOvertimeMinutes: 120,
        fixedIncludedNightMinutes: 30,
        fixedIncludedHolidayMinutes: 60,
        effectiveFromMonth: DateTime(2026, 6),
        memo: '계약서 기준 확인',
        createdAt: DateTime(2026, 6, 1, 9),
        updatedAt: DateTime(2026, 6, 2, 9),
      );

      final CompensationReferenceSetting parsed =
          CompensationReferenceSetting.fromMap(setting.toMap());

      expect(parsed, setting);
      expect(parsed.mode, CompensationReferenceMode.fixedIncluded);
    });

    test('rejects non-month effective date', () {
      expect(
        () => CompensationReferenceSetting(
          id: 'setting-1',
          mode: CompensationReferenceMode.none,
          fixedIncludedOvertimeMinutes: 0,
          fixedIncludedNightMinutes: 0,
          fixedIncludedHolidayMinutes: 0,
          effectiveFromMonth: DateTime(2026, 6, 2),
          memo: null,
          createdAt: DateTime(2026, 6, 1),
          updatedAt: DateTime(2026, 6, 1),
        ),
        throwsArgumentError,
      );
    });
  });
}
