import '../../../core/models/work_record.dart';
import 'monthly_summary.dart';

MonthlySummary calculateMonthlySummary({
  required MonthlySummaryMonth targetMonth,
  required List<WorkRecord> records,
}) {
  targetMonth.validate();
  final List<WorkRecord> monthlyRecords = records
      .where(
        (WorkRecord record) => targetMonth.containsDate(date: record.workDate),
      )
      .toList(growable: false);
  final List<WorkRecord> sortedRecords = _sortWorkRecords(
    records: monthlyRecords,
  );
  final List<MonthlyWorkRecordEntry> entries = sortedRecords
      .map(buildMonthlyWorkRecordEntry)
      .toList(growable: false);
  final List<MonthlyWorkRecordEntry> completedEntries = entries
      .where((MonthlyWorkRecordEntry entry) => entry.isCompleted)
      .toList(growable: false);

  return MonthlySummary(
    targetMonth: targetMonth,
    totalWorkedDuration: _sumCompletedWorkedDuration(entries: completedEntries),
    completedWorkDayCount: completedEntries.length,
    overtimeReferenceDuration: _sumOvertimeReferenceDuration(
      entries: completedEntries,
    ),
    overtimeDuration: _sumTaggedDuration(
      entries: completedEntries,
      tag: WorkRecordTag.overtime,
    ),
    delayedCheckoutDuration: _sumTaggedDuration(
      entries: completedEntries,
      tag: WorkRecordTag.delayedCheckout,
    ),
    holidayWorkDuration: _sumTaggedDuration(
      entries: completedEntries,
      tag: WorkRecordTag.holidayWork,
    ),
    entries: entries,
  );
}

MonthlyWorkRecordEntry buildMonthlyWorkRecordEntry(WorkRecord record) {
  final DateTime? clockInAt = record.clockInAt;
  final DateTime? clockOutAt = record.clockOutAt;
  if (clockInAt == null || clockOutAt == null) {
    return MonthlyWorkRecordEntry(
      recordId: record.id,
      workDate: record.workDate,
      clockInAt: clockInAt,
      clockOutAt: clockOutAt,
      tags: record.tags,
      memo: record.memo,
      workedDuration: null,
      status: MonthlyWorkRecordEntryStatus.incomplete,
    );
  }

  return MonthlyWorkRecordEntry(
    recordId: record.id,
    workDate: record.workDate,
    clockInAt: clockInAt,
    clockOutAt: clockOutAt,
    tags: record.tags,
    memo: record.memo,
    workedDuration: calculateCompletedMonthlyWorkDuration(
      recordId: record.id,
      clockInAt: clockInAt,
      clockOutAt: clockOutAt,
    ),
    status: MonthlyWorkRecordEntryStatus.completed,
  );
}

Duration calculateCompletedMonthlyWorkDuration({
  required String recordId,
  required DateTime clockInAt,
  required DateTime clockOutAt,
}) {
  if (clockOutAt.isBefore(clockInAt)) {
    throw MonthlySummaryException(
      'model=MonthlySummary recordId=$recordId field=clockOutAt value=${clockOutAt.toIso8601String()} clockInAt=${clockInAt.toIso8601String()} rule=clock-out must be greater than or equal to clock-in',
    );
  }
  return clockOutAt.difference(clockInAt);
}

List<WorkRecord> _sortWorkRecords({required List<WorkRecord> records}) {
  final List<WorkRecord> sortedRecords = List<WorkRecord>.of(records);
  sortedRecords.sort((WorkRecord left, WorkRecord right) {
    final int dateCompare = left.workDate.compareTo(right.workDate);
    if (dateCompare != 0) {
      return dateCompare;
    }
    return left.id.compareTo(right.id);
  });
  return sortedRecords;
}

Duration _sumCompletedWorkedDuration({
  required List<MonthlyWorkRecordEntry> entries,
}) {
  return entries.fold(Duration.zero, (
    Duration total,
    MonthlyWorkRecordEntry entry,
  ) {
    final Duration? workedDuration = entry.workedDuration;
    if (workedDuration == null) {
      throw MonthlySummaryException(
        'model=MonthlySummary recordId=${entry.recordId} field=workedDuration rule=required for completed entry',
      );
    }
    return total + workedDuration;
  });
}

Duration _sumOvertimeReferenceDuration({
  required List<MonthlyWorkRecordEntry> entries,
}) {
  return entries
      .where((MonthlyWorkRecordEntry entry) => entry.hasOvertimeReferenceTag)
      .fold(Duration.zero, (Duration total, MonthlyWorkRecordEntry entry) {
        final Duration? workedDuration = entry.workedDuration;
        if (workedDuration == null) {
          throw MonthlySummaryException(
            'model=MonthlySummary recordId=${entry.recordId} field=workedDuration rule=required for overtime reference',
          );
        }
        return total + workedDuration;
      });
}

Duration _sumTaggedDuration({
  required List<MonthlyWorkRecordEntry> entries,
  required WorkRecordTag tag,
}) {
  return entries
      .where((MonthlyWorkRecordEntry entry) => entry.tags.contains(tag))
      .fold(Duration.zero, (Duration total, MonthlyWorkRecordEntry entry) {
        final Duration? workedDuration = entry.workedDuration;
        if (workedDuration == null) {
          throw MonthlySummaryException(
            'model=MonthlySummary recordId=${entry.recordId} field=workedDuration tag=$tag rule=required for tag reference',
          );
        }
        return total + workedDuration;
      });
}
