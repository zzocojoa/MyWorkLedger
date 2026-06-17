import 'package:flutter_test/flutter_test.dart';
import 'package:workledger/core/models/work_record.dart';
import 'package:workledger/core/models/work_rule.dart';
import 'package:workledger/features/work_time/domain/calculate_work_time_candidates.dart';
import 'package:workledger/features/work_time/domain/work_time_candidate.dart';

void main() {
  group('calculateWorkTimeCandidates', () {
    test('returns unavailable when work rule is missing', () {
      final WorkTimeCandidateSummary summary = calculateWorkTimeCandidates(
        record: _record(
          id: 'work-1',
          workDate: DateTime(2026, 6, 12),
          clockInAt: DateTime(2026, 6, 12, 9),
          clockOutAt: DateTime(2026, 6, 12, 20),
        ),
        workRule: null,
      );

      expect(summary.status, WorkTimeCandidateStatus.unavailable);
      expect(summary.nonWorkdayDuration, Duration.zero);
      expect(summary.earlyWorkDuration, Duration.zero);
      expect(summary.overtimeDuration, Duration.zero);
      expect(summary.nightWorkDuration, Duration.zero);
      expect(summary.reason, 'workRuleMissing');
    });

    test('returns unavailable when work record is incomplete', () {
      final WorkTimeCandidateSummary summary = calculateWorkTimeCandidates(
        record: _record(
          id: 'work-1',
          workDate: DateTime(2026, 6, 12),
          clockInAt: DateTime(2026, 6, 12, 9),
          clockOutAt: null,
        ),
        workRule: _weekdayRule(),
      );

      expect(summary.status, WorkTimeCandidateStatus.unavailable);
      expect(summary.reason, 'incompleteWorkRecord');
    });

    test('calculates weekday overtime after regular end', () {
      final WorkTimeCandidateSummary summary = calculateWorkTimeCandidates(
        record: _record(
          id: 'work-1',
          workDate: DateTime(2026, 6, 12),
          clockInAt: DateTime(2026, 6, 12, 9),
          clockOutAt: DateTime(2026, 6, 12, 20, 30),
        ),
        workRule: _weekdayRule(),
      );

      expect(summary.status, WorkTimeCandidateStatus.available);
      expect(summary.nonWorkdayDuration, Duration.zero);
      expect(summary.earlyWorkDuration, Duration.zero);
      expect(summary.overtimeDuration, const Duration(hours: 2, minutes: 30));
      expect(summary.nightWorkDuration, Duration.zero);
      expect(summary.hasActiveTags, isTrue);
      expect(summary.activeTagCount, 1);
    });

    test('calculates overtime after configured overtime start', () {
      final WorkTimeCandidateSummary summary = calculateWorkTimeCandidates(
        record: _record(
          id: 'work-1',
          workDate: DateTime(2026, 6, 12),
          clockInAt: DateTime(2026, 6, 12, 9),
          clockOutAt: DateTime(2026, 6, 12, 21),
        ),
        workRule: _weekdayRule().copyWith(
          id: 'active-rule',
          regularStartTimeMinutes: 540,
          regularEndTimeMinutes: 1080,
          overtimeStartTimeMinutes: 1200,
          nightWorkStartTimeMinutes: 1320,
          breakMinutes: 60,
          workWeekdays: <int>[
            DateTime.monday,
            DateTime.tuesday,
            DateTime.wednesday,
            DateTime.thursday,
            DateTime.friday,
          ],
          createdAt: DateTime.parse('2026-06-01T09:00:00'),
          updatedAt: DateTime.parse('2026-06-12T09:00:00'),
        ),
      );

      expect(summary.overtimeDuration, const Duration(hours: 1));
    });

    test('reports no active tags for regular weekday work', () {
      final WorkTimeCandidateSummary summary = calculateWorkTimeCandidates(
        record: _record(
          id: 'work-1',
          workDate: DateTime(2026, 6, 12),
          clockInAt: DateTime(2026, 6, 12, 9),
          clockOutAt: DateTime(2026, 6, 12, 18),
        ),
        workRule: _weekdayRule(),
      );

      expect(summary.status, WorkTimeCandidateStatus.available);
      expect(summary.hasActiveTags, isFalse);
      expect(summary.activeTagCount, 0);
    });

    test('calculates weekday early work before regular start', () {
      final WorkTimeCandidateSummary summary = calculateWorkTimeCandidates(
        record: _record(
          id: 'work-1',
          workDate: DateTime(2026, 6, 12),
          clockInAt: DateTime(2026, 6, 12, 7, 26),
          clockOutAt: DateTime(2026, 6, 12, 21, 26),
        ),
        workRule: _weekdayRule(),
      );

      expect(summary.earlyWorkDuration, const Duration(hours: 1, minutes: 34));
      expect(summary.overtimeDuration, const Duration(hours: 3, minutes: 26));
      expect(summary.nightWorkDuration, Duration.zero);
    });

    test('keeps non-workday and time candidates separated', () {
      final WorkTimeCandidateSummary summary = calculateWorkTimeCandidates(
        record: _record(
          id: 'work-1',
          workDate: DateTime(2026, 6, 13),
          clockInAt: DateTime(2026, 6, 13, 7, 26),
          clockOutAt: DateTime(2026, 6, 13, 21, 26),
        ),
        workRule: _weekdayRule(),
      );

      expect(summary.nonWorkdayDuration, const Duration(hours: 13));
      expect(summary.earlyWorkDuration, const Duration(hours: 1, minutes: 34));
      expect(summary.overtimeDuration, const Duration(hours: 3, minutes: 26));
      expect(summary.nightWorkDuration, Duration.zero);
    });

    test('excludes unreliable clock-out candidates for delayed checkout', () {
      final WorkTimeCandidateSummary summary = calculateWorkTimeCandidates(
        record: _recordWithTags(
          id: 'work-1',
          workDate: DateTime(2026, 6, 12),
          clockInAt: DateTime(2026, 6, 12, 7, 26),
          clockOutAt: DateTime(2026, 6, 12, 23, 30),
          tags: <WorkRecordTag>[WorkRecordTag.delayedCheckout],
        ),
        workRule: _weekdayRule(),
      );

      expect(summary.nonWorkdayDuration, Duration.zero);
      expect(summary.earlyWorkDuration, const Duration(hours: 1, minutes: 34));
      expect(summary.overtimeDuration, Duration.zero);
      expect(summary.nightWorkDuration, Duration.zero);
    });

    test('calculates night work overlap between 22 and next day 06', () {
      final WorkTimeCandidateSummary summary = calculateWorkTimeCandidates(
        record: _record(
          id: 'work-1',
          workDate: DateTime(2026, 6, 12),
          clockInAt: DateTime(2026, 6, 12, 21, 30),
          clockOutAt: DateTime(2026, 6, 13, 6, 30),
        ),
        workRule: _weekdayRule(),
      );

      expect(summary.overtimeDuration, const Duration(hours: 12, minutes: 30));
      expect(summary.nightWorkDuration, const Duration(hours: 8));
    });

    test('calculates night work from configured start for 8 hours', () {
      final WorkTimeCandidateSummary summary = calculateWorkTimeCandidates(
        record: _record(
          id: 'work-1',
          workDate: DateTime(2026, 6, 12),
          clockInAt: DateTime(2026, 6, 12, 22),
          clockOutAt: DateTime(2026, 6, 13, 7, 30),
        ),
        workRule: _weekdayRule().copyWith(
          id: 'active-rule',
          regularStartTimeMinutes: 540,
          regularEndTimeMinutes: 1080,
          overtimeStartTimeMinutes: 1080,
          nightWorkStartTimeMinutes: 1380,
          breakMinutes: 60,
          workWeekdays: <int>[
            DateTime.monday,
            DateTime.tuesday,
            DateTime.wednesday,
            DateTime.thursday,
            DateTime.friday,
          ],
          createdAt: DateTime.parse('2026-06-01T09:00:00'),
          updatedAt: DateTime.parse('2026-06-12T09:00:00'),
        ),
      );

      expect(summary.nightWorkDuration, const Duration(hours: 8));
    });

    test(
      'keeps overtime and night work as separate overlapping candidates',
      () {
        final WorkTimeCandidateSummary summary = calculateWorkTimeCandidates(
          record: _record(
            id: 'work-1',
            workDate: DateTime(2026, 6, 12),
            clockInAt: DateTime(2026, 6, 12, 9),
            clockOutAt: DateTime(2026, 6, 12, 23, 30),
          ),
          workRule: _weekdayRule(),
        );

        expect(summary.overtimeDuration, const Duration(hours: 5, minutes: 30));
        expect(
          summary.nightWorkDuration,
          const Duration(hours: 1, minutes: 30),
        );
      },
    );

    test('throws when clock-out is before clock-in', () {
      expect(
        () => calculateWorkTimeCandidates(
          record: _record(
            id: 'work-1',
            workDate: DateTime(2026, 6, 12),
            clockInAt: DateTime(2026, 6, 12, 10),
            clockOutAt: DateTime(2026, 6, 12, 9),
          ),
          workRule: _weekdayRule(),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}

WorkRule _weekdayRule() {
  return WorkRule(
    id: 'active-rule',
    regularStartTimeMinutes: 540,
    regularEndTimeMinutes: 1080,
    overtimeStartTimeMinutes: 1080,
    nightWorkStartTimeMinutes: 1320,
    breakMinutes: 60,
    workWeekdays: <int>[
      DateTime.monday,
      DateTime.tuesday,
      DateTime.wednesday,
      DateTime.thursday,
      DateTime.friday,
    ],
    createdAt: DateTime.parse('2026-06-01T09:00:00'),
    updatedAt: DateTime.parse('2026-06-12T09:00:00'),
  );
}

WorkRecord _record({
  required String id,
  required DateTime workDate,
  required DateTime? clockInAt,
  required DateTime? clockOutAt,
}) {
  return _recordWithTags(
    id: id,
    workDate: workDate,
    clockInAt: clockInAt,
    clockOutAt: clockOutAt,
    tags: <WorkRecordTag>[],
  );
}

WorkRecord _recordWithTags({
  required String id,
  required DateTime workDate,
  required DateTime? clockInAt,
  required DateTime? clockOutAt,
  required List<WorkRecordTag> tags,
}) {
  return WorkRecord(
    id: id,
    workDate: workDate,
    clockInAt: clockInAt,
    clockOutAt: clockOutAt,
    tags: tags,
    memo: null,
    createdAt: DateTime(workDate.year, workDate.month, workDate.day, 8),
    updatedAt: DateTime(workDate.year, workDate.month, workDate.day, 19),
  );
}
