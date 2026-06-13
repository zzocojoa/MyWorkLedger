import 'package:flutter_test/flutter_test.dart';
import 'package:workledger/core/models/work_record.dart';
import 'package:workledger/features/monthly_summary/domain/calculate_monthly_summary.dart';
import 'package:workledger/features/monthly_summary/domain/monthly_summary.dart';

void main() {
  group('calculateMonthlySummary', () {
    test('filters selected month and calculates completed record totals', () {
      final MonthlySummary summary = calculateMonthlySummary(
        targetMonth: const MonthlySummaryMonth(year: 2026, month: 6),
        records: <WorkRecord>[
          _completedRecord(
            id: 'work-previous-month',
            clockInAt: DateTime(2026, 5, 31, 9, 0),
            clockOutAt: DateTime(2026, 5, 31, 18, 0),
            tags: <WorkRecordTag>[WorkRecordTag.overtime],
            memo: null,
          ),
          _completedRecord(
            id: 'work-2',
            clockInAt: DateTime(2026, 6, 3, 9, 10),
            clockOutAt: DateTime(2026, 6, 3, 18, 20),
            tags: <WorkRecordTag>[],
            memo: '일반 근무',
          ),
          _completedRecord(
            id: 'work-1',
            clockInAt: DateTime(2026, 6, 1, 9, 0),
            clockOutAt: DateTime(2026, 6, 1, 20, 30),
            tags: <WorkRecordTag>[WorkRecordTag.overtime],
            memo: '배포 대응',
          ),
        ],
      );

      expect(
        summary.targetMonth,
        const MonthlySummaryMonth(year: 2026, month: 6),
      );
      expect(summary.completedWorkDayCount, 2);
      expect(
        summary.totalWorkedDuration,
        const Duration(hours: 20, minutes: 40),
      );
      expect(
        summary.overtimeReferenceDuration,
        const Duration(hours: 11, minutes: 30),
      );
      expect(
        summary.entries.map((MonthlyWorkRecordEntry entry) => entry.recordId),
        <String>['work-1', 'work-2'],
      );
    });

    test('keeps incomplete records visible without adding them to totals', () {
      final MonthlySummary summary = calculateMonthlySummary(
        targetMonth: const MonthlySummaryMonth(year: 2026, month: 6),
        records: <WorkRecord>[
          _completedRecord(
            id: 'complete',
            clockInAt: DateTime(2026, 6, 1, 9, 0),
            clockOutAt: DateTime(2026, 6, 1, 18, 0),
            tags: <WorkRecordTag>[],
            memo: null,
          ),
          _incompleteRecord(
            id: 'missing-clock-out',
            workDate: DateTime(2026, 6, 2),
            clockInAt: DateTime(2026, 6, 2, 9, 0),
            clockOutAt: null,
            tags: <WorkRecordTag>[WorkRecordTag.overtime],
          ),
          _incompleteRecord(
            id: 'missing-clock-in',
            workDate: DateTime(2026, 6, 3),
            clockInAt: null,
            clockOutAt: DateTime(2026, 6, 3, 18, 0),
            tags: <WorkRecordTag>[WorkRecordTag.holidayWork],
          ),
        ],
      );

      expect(summary.entries.length, 3);
      expect(summary.completedEntries.length, 1);
      expect(summary.incompleteEntries.length, 2);
      expect(summary.completedWorkDayCount, 1);
      expect(summary.totalWorkedDuration, const Duration(hours: 9));
      expect(summary.overtimeReferenceDuration, Duration.zero);
      expect(
        summary.incompleteEntries.map(
          (MonthlyWorkRecordEntry entry) => entry.recordId,
        ),
        <String>['missing-clock-out', 'missing-clock-in'],
      );
    });

    test(
      'sums overtime reference duration from tagged completed records only',
      () {
        final MonthlySummary summary = calculateMonthlySummary(
          targetMonth: const MonthlySummaryMonth(year: 2026, month: 6),
          records: <WorkRecord>[
            _completedRecord(
              id: 'overtime',
              clockInAt: DateTime(2026, 6, 1, 9, 0),
              clockOutAt: DateTime(2026, 6, 1, 21, 0),
              tags: <WorkRecordTag>[WorkRecordTag.overtime],
              memo: null,
            ),
            _completedRecord(
              id: 'delayed',
              clockInAt: DateTime(2026, 6, 2, 9, 0),
              clockOutAt: DateTime(2026, 6, 2, 19, 30),
              tags: <WorkRecordTag>[WorkRecordTag.delayedCheckout],
              memo: null,
            ),
            _completedRecord(
              id: 'holiday',
              clockInAt: DateTime(2026, 6, 6, 10, 0),
              clockOutAt: DateTime(2026, 6, 6, 15, 0),
              tags: <WorkRecordTag>[WorkRecordTag.holidayWork],
              memo: null,
            ),
            _completedRecord(
              id: 'untagged',
              clockInAt: DateTime(2026, 6, 7, 9, 0),
              clockOutAt: DateTime(2026, 6, 7, 18, 0),
              tags: <WorkRecordTag>[],
              memo: null,
            ),
          ],
        );

        expect(
          summary.overtimeReferenceDuration,
          const Duration(hours: 27, minutes: 30),
        );
        expect(summary.overtimeDuration, const Duration(hours: 12));
        expect(
          summary.delayedCheckoutDuration,
          const Duration(hours: 10, minutes: 30),
        );
        expect(summary.holidayWorkDuration, const Duration(hours: 5));
      },
    );

    test('sorts display entries by work date and id', () {
      final MonthlySummary summary = calculateMonthlySummary(
        targetMonth: const MonthlySummaryMonth(year: 2026, month: 6),
        records: <WorkRecord>[
          _completedRecord(
            id: 'work-c',
            clockInAt: DateTime(2026, 6, 3, 9, 0),
            clockOutAt: DateTime(2026, 6, 3, 18, 0),
            tags: <WorkRecordTag>[],
            memo: null,
          ),
          _completedRecord(
            id: 'work-b',
            clockInAt: DateTime(2026, 6, 1, 10, 0),
            clockOutAt: DateTime(2026, 6, 1, 18, 0),
            tags: <WorkRecordTag>[],
            memo: null,
          ),
          _completedRecord(
            id: 'work-a',
            clockInAt: DateTime(2026, 6, 1, 9, 0),
            clockOutAt: DateTime(2026, 6, 1, 17, 0),
            tags: <WorkRecordTag>[],
            memo: null,
          ),
        ],
      );

      expect(
        summary.entries.map((MonthlyWorkRecordEntry entry) => entry.recordId),
        <String>['work-a', 'work-b', 'work-c'],
      );
    });

    test('throws explicit error when clock-out is before clock-in', () {
      expect(
        () => calculateCompletedMonthlyWorkDuration(
          recordId: 'invalid-time',
          clockInAt: DateTime(2026, 6, 1, 18, 0),
          clockOutAt: DateTime(2026, 6, 1, 9, 0),
        ),
        throwsA(
          isA<MonthlySummaryException>().having(
            (MonthlySummaryException error) => error.message,
            'message',
            contains('recordId=invalid-time'),
          ),
        ),
      );
    });

    test('throws explicit error for invalid target month', () {
      expect(
        () => calculateMonthlySummary(
          targetMonth: const MonthlySummaryMonth(year: 2026, month: 13),
          records: <WorkRecord>[],
        ),
        throwsA(isA<MonthlySummaryException>()),
      );
    });
  });
}

WorkRecord _completedRecord({
  required String id,
  required DateTime clockInAt,
  required DateTime clockOutAt,
  required List<WorkRecordTag> tags,
  required String? memo,
}) {
  return WorkRecord(
    id: id,
    workDate: DateTime(clockInAt.year, clockInAt.month, clockInAt.day),
    clockInAt: clockInAt,
    clockOutAt: clockOutAt,
    tags: tags,
    memo: memo,
    createdAt: clockInAt,
    updatedAt: clockOutAt,
  );
}

WorkRecord _incompleteRecord({
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
    createdAt: DateTime(workDate.year, workDate.month, workDate.day, 9),
    updatedAt: DateTime(workDate.year, workDate.month, workDate.day, 18),
  );
}
