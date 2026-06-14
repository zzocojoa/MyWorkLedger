import 'package:flutter_test/flutter_test.dart';
import 'package:workledger/core/models/compensation_reference_setting.dart';

void main() {
  group('CompensationReferenceSetting', () {
    test('serializes and parses setting map', () {
      final CompensationReferenceSetting setting = CompensationReferenceSetting(
        id: 'setting-1',
        mode: CompensationReferenceMode.fixedIncluded,
        fixedIncludedAfterRegularEndMinutes: 120,
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
          fixedIncludedAfterRegularEndMinutes: 0,
          effectiveFromMonth: DateTime(2026, 6, 2),
          memo: null,
          createdAt: DateTime(2026, 6, 1),
          updatedAt: DateTime(2026, 6, 1),
        ),
        throwsArgumentError,
      );
    });

    test('parses legacy overtime included minutes as after regular end', () {
      final CompensationReferenceSetting parsed =
          CompensationReferenceSetting.fromMap(<String, Object?>{
            'id': 'setting-1',
            'mode': CompensationReferenceMode.fixedIncluded.name,
            'fixed_included_overtime_minutes': 90,
            'fixed_included_night_minutes': 30,
            'fixed_included_holiday_minutes': 60,
            'effective_from_month': DateTime(2026, 6).toIso8601String(),
            'memo': null,
            'created_at': DateTime(2026, 6, 1).toIso8601String(),
            'updated_at': DateTime(2026, 6, 1).toIso8601String(),
          });

      expect(parsed.fixedIncludedAfterRegularEndMinutes, 90);
    });
  });
}
