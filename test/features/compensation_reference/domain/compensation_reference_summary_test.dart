import 'package:flutter_test/flutter_test.dart';
import 'package:workledger/core/models/compensation_reference_setting.dart';
import 'package:workledger/core/models/work_record.dart';
import 'package:workledger/core/models/work_rule.dart';
import 'package:workledger/features/compensation_reference/domain/compensation_reference_summary.dart';

void main() {
  group('calculateCompensationReferenceSummary', () {
    test('hides summary when setting is none', () {
      final CompensationReferenceSummary summary =
          calculateCompensationReferenceSummary(
            setting: null,
            records: _records(),
            workRule: _workRule(),
          );

      expect(summary.status, CompensationReferenceSummaryStatus.hidden);
      expect(summary.isVisible, isFalse);
    });

    test('shows not configured when mode is unknown', () {
      final CompensationReferenceSummary summary =
          calculateCompensationReferenceSummary(
            setting: _setting(mode: CompensationReferenceMode.unknown),
            records: _records(),
            workRule: _workRule(),
          );

      expect(summary.status, CompensationReferenceSummaryStatus.notConfigured);
      expect(summary.isVisible, isTrue);
      expect(summary.rows, isEmpty);
    });

    test('calculates excess reference per completed workday record', () {
      final CompensationReferenceSummary summary =
          calculateCompensationReferenceSummary(
            setting: _setting(mode: CompensationReferenceMode.fixedIncluded),
            records: _records(),
            workRule: _workRule(),
          );

      expect(summary.status, CompensationReferenceSummaryStatus.available);
      expect(summary.rows, hasLength(1));
      expect(summary.rows[0].label, '정시 이후 근무');
      expect(summary.rows[0].excessStartTimeMinutes, 19 * 60);
      expect(summary.rows[0].actualDuration, const Duration(hours: 4));
      expect(summary.rows[0].fixedIncludedDuration, const Duration(hours: 3));
      expect(summary.rows[0].excessReferenceDuration, const Duration(hours: 1));
    });
  });
}

CompensationReferenceSetting _setting({
  required CompensationReferenceMode mode,
}) {
  return CompensationReferenceSetting(
    id: 'setting-1',
    mode: mode,
    fixedIncludedAfterRegularEndMinutes: 120,
    effectiveFromMonth: DateTime(2026, 6),
    memo: null,
    createdAt: DateTime(2026, 6, 1),
    updatedAt: DateTime(2026, 6, 1),
  );
}

List<WorkRecord> _records() {
  return <WorkRecord>[
    _record(
      id: 'record-1',
      workDate: DateTime(2026, 6, 1),
      clockOutAt: DateTime(2026, 6, 1, 18),
    ),
    _record(
      id: 'record-2',
      workDate: DateTime(2026, 6, 2),
      clockOutAt: DateTime(2026, 6, 2, 20),
    ),
    _record(
      id: 'record-3',
      workDate: DateTime(2026, 6, 7),
      clockOutAt: DateTime(2026, 6, 7, 20),
    ),
  ];
}

WorkRecord _record({
  required String id,
  required DateTime workDate,
  required DateTime clockOutAt,
}) {
  return WorkRecord(
    id: id,
    workDate: workDate,
    clockInAt: DateTime(workDate.year, workDate.month, workDate.day, 9),
    clockOutAt: clockOutAt,
    tags: <WorkRecordTag>[],
    memo: null,
    createdAt: DateTime(2026, 6, 1),
    updatedAt: DateTime(2026, 6, 1),
  );
}

WorkRule _workRule() {
  return WorkRule(
    id: 'work-rule-1',
    regularStartTimeMinutes: 9 * 60,
    regularEndTimeMinutes: 17 * 60,
    overtimeStartTimeMinutes: 17 * 60,
    nightWorkStartTimeMinutes: 22 * 60,
    breakMinutes: 60,
    workWeekdays: <int>[
      DateTime.monday,
      DateTime.tuesday,
      DateTime.wednesday,
      DateTime.thursday,
      DateTime.friday,
    ],
    createdAt: DateTime(2026, 6, 1),
    updatedAt: DateTime(2026, 6, 1),
  );
}
