import '../../../core/models/work_record.dart';
import '../../../core/models/leave_usage.dart';
import '../../../core/models/work_rule.dart';
import '../../leave/domain/leave_summary.dart';
import '../../work_time/domain/work_time_candidate.dart';

final class MonthlySummaryException implements Exception {
  const MonthlySummaryException(this.message);

  final String message;

  @override
  String toString() {
    return 'MonthlySummaryException: $message';
  }
}

final class MonthlySummaryMonth {
  const MonthlySummaryMonth({required this.year, required this.month});

  final int year;
  final int month;

  bool containsDate({required DateTime date}) {
    validate();
    return date.year == year && date.month == month;
  }

  void validate() {
    if (year < 2000 || year > 2100) {
      throw MonthlySummaryException(
        'model=MonthlySummaryMonth field=year value=$year rule=between 2000 and 2100',
      );
    }
    if (month < 1 || month > 12) {
      throw MonthlySummaryException(
        'model=MonthlySummaryMonth field=month value=$month rule=between 1 and 12',
      );
    }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is MonthlySummaryMonth &&
            year == other.year &&
            month == other.month;
  }

  @override
  int get hashCode {
    return Object.hash(year, month);
  }
}

enum MonthlyWorkRecordEntryStatus { completed, incomplete }

final class MonthlyWorkRecordEntry {
  MonthlyWorkRecordEntry({
    required this.recordId,
    required this.workDate,
    required this.clockInAt,
    required this.clockOutAt,
    required List<WorkRecordTag> tags,
    required this.memo,
    required this.workedDuration,
    required this.status,
  }) : tags = List<WorkRecordTag>.unmodifiable(tags) {
    _validateEntry(this);
  }

  final String recordId;
  final DateTime workDate;
  final DateTime? clockInAt;
  final DateTime? clockOutAt;
  final List<WorkRecordTag> tags;
  final String? memo;
  final Duration? workedDuration;
  final MonthlyWorkRecordEntryStatus status;

  bool get isCompleted {
    return status == MonthlyWorkRecordEntryStatus.completed;
  }

  bool get hasOvertimeReferenceTag {
    return tags.contains(WorkRecordTag.overtime) ||
        tags.contains(WorkRecordTag.delayedCheckout) ||
        tags.contains(WorkRecordTag.holidayWork);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is MonthlyWorkRecordEntry &&
            recordId == other.recordId &&
            workDate == other.workDate &&
            clockInAt == other.clockInAt &&
            clockOutAt == other.clockOutAt &&
            _listEquals(tags, other.tags) &&
            memo == other.memo &&
            workedDuration == other.workedDuration &&
            status == other.status;
  }

  @override
  int get hashCode {
    return Object.hash(
      recordId,
      workDate,
      clockInAt,
      clockOutAt,
      Object.hashAll(tags),
      memo,
      workedDuration,
      status,
    );
  }
}

final class MonthlySummary {
  MonthlySummary({
    required this.targetMonth,
    required this.totalWorkedDuration,
    required this.completedWorkDayCount,
    required this.overtimeReferenceDuration,
    required this.overtimeDuration,
    required this.delayedCheckoutDuration,
    required this.holidayWorkDuration,
    required List<MonthlyWorkRecordEntry> entries,
  }) : entries = List<MonthlyWorkRecordEntry>.unmodifiable(entries) {
    _validateSummary(this);
  }

  final MonthlySummaryMonth targetMonth;
  final Duration totalWorkedDuration;
  final int completedWorkDayCount;
  final Duration overtimeReferenceDuration;
  final Duration overtimeDuration;
  final Duration delayedCheckoutDuration;
  final Duration holidayWorkDuration;
  final List<MonthlyWorkRecordEntry> entries;

  List<MonthlyWorkRecordEntry> get completedEntries {
    return entries
        .where((MonthlyWorkRecordEntry entry) => entry.isCompleted)
        .toList(growable: false);
  }

  List<MonthlyWorkRecordEntry> get incompleteEntries {
    return entries
        .where((MonthlyWorkRecordEntry entry) => !entry.isCompleted)
        .toList(growable: false);
  }
}

final class MonthlySummaryViewData {
  MonthlySummaryViewData({
    required this.workSummary,
    required this.leaveSummary,
    required this.monthlyUsedLeaveMinutes,
    required this.workRule,
    required this.displayTotalWorkedDuration,
    required this.workTimeCandidateSummary,
  }) {
    _validateViewData(this);
  }

  final MonthlySummary workSummary;
  final LeaveSummary leaveSummary;
  final int monthlyUsedLeaveMinutes;
  final WorkRule? workRule;
  final Duration displayTotalWorkedDuration;
  final WorkTimeCandidateSummary workTimeCandidateSummary;
}

void _validateEntry(MonthlyWorkRecordEntry entry) {
  if (entry.recordId.isEmpty) {
    throw MonthlySummaryException(
      'model=MonthlyWorkRecordEntry field=recordId rule=non-empty',
    );
  }
  if (!_isDateOnly(entry.workDate)) {
    throw MonthlySummaryException(
      'model=MonthlyWorkRecordEntry recordId=${entry.recordId} field=workDate rule=date-only',
    );
  }
  final DateTime? clockInAt = entry.clockInAt;
  final DateTime? clockOutAt = entry.clockOutAt;
  if (clockInAt != null &&
      clockOutAt != null &&
      clockOutAt.isBefore(clockInAt)) {
    throw MonthlySummaryException(
      'model=MonthlyWorkRecordEntry recordId=${entry.recordId} field=clockOutAt value=${clockOutAt.toIso8601String()} clockInAt=${clockInAt.toIso8601String()} rule=clock-out must be greater than or equal to clock-in',
    );
  }
  switch (entry.status) {
    case MonthlyWorkRecordEntryStatus.completed:
      if (clockInAt == null || clockOutAt == null) {
        throw MonthlySummaryException(
          'model=MonthlyWorkRecordEntry recordId=${entry.recordId} status=completed rule=clock-in and clock-out required',
        );
      }
      if (entry.workedDuration == null) {
        throw MonthlySummaryException(
          'model=MonthlyWorkRecordEntry recordId=${entry.recordId} status=completed rule=workedDuration required',
        );
      }
    case MonthlyWorkRecordEntryStatus.incomplete:
      if (entry.workedDuration != null) {
        throw MonthlySummaryException(
          'model=MonthlyWorkRecordEntry recordId=${entry.recordId} status=incomplete rule=workedDuration must be null',
        );
      }
  }
}

void _validateSummary(MonthlySummary summary) {
  summary.targetMonth.validate();
  if (summary.totalWorkedDuration.isNegative) {
    throw MonthlySummaryException(
      'model=MonthlySummary field=totalWorkedDuration rule=non-negative',
    );
  }
  if (summary.overtimeReferenceDuration.isNegative) {
    throw MonthlySummaryException(
      'model=MonthlySummary field=overtimeReferenceDuration rule=non-negative',
    );
  }
  if (summary.overtimeDuration.isNegative) {
    throw MonthlySummaryException(
      'model=MonthlySummary field=overtimeDuration rule=non-negative',
    );
  }
  if (summary.delayedCheckoutDuration.isNegative) {
    throw MonthlySummaryException(
      'model=MonthlySummary field=delayedCheckoutDuration rule=non-negative',
    );
  }
  if (summary.holidayWorkDuration.isNegative) {
    throw MonthlySummaryException(
      'model=MonthlySummary field=holidayWorkDuration rule=non-negative',
    );
  }
  if (summary.completedWorkDayCount < 0) {
    throw MonthlySummaryException(
      'model=MonthlySummary field=completedWorkDayCount rule=non-negative',
    );
  }
  final int actualCompletedCount = summary.completedEntries.length;
  if (summary.completedWorkDayCount != actualCompletedCount) {
    throw MonthlySummaryException(
      'model=MonthlySummary field=completedWorkDayCount value=${summary.completedWorkDayCount} actual=$actualCompletedCount rule=match completed entries',
    );
  }
}

void _validateViewData(MonthlySummaryViewData data) {
  final MonthlySummaryMonth targetMonth = data.workSummary.targetMonth;
  if (data.leaveSummary.year != targetMonth.year) {
    throw MonthlySummaryException(
      'model=MonthlySummaryViewData field=leaveSummary.year value=${data.leaveSummary.year} expected=${targetMonth.year}',
    );
  }
  if (data.monthlyUsedLeaveMinutes < 0) {
    throw MonthlySummaryException(
      'model=MonthlySummaryViewData field=monthlyUsedLeaveMinutes rule=non-negative',
    );
  }
  final int actualMonthlyUsedLeaveMinutes = data.leaveSummary.usages
      .where((LeaveUsage usage) => targetMonth.containsDate(date: usage.usedOn))
      .fold(0, (int total, LeaveUsage usage) {
        return total + usage.usedLeaveMinutes;
      });
  if (data.monthlyUsedLeaveMinutes != actualMonthlyUsedLeaveMinutes) {
    throw MonthlySummaryException(
      'model=MonthlySummaryViewData field=monthlyUsedLeaveMinutes value=${data.monthlyUsedLeaveMinutes} actual=$actualMonthlyUsedLeaveMinutes rule=match selected month leave usages',
    );
  }
  if (data.displayTotalWorkedDuration.isNegative) {
    throw MonthlySummaryException(
      'model=MonthlySummaryViewData field=displayTotalWorkedDuration rule=non-negative',
    );
  }
  if (data.displayTotalWorkedDuration > data.workSummary.totalWorkedDuration) {
    throw MonthlySummaryException(
      'model=MonthlySummaryViewData field=displayTotalWorkedDuration value=${data.displayTotalWorkedDuration.inMinutes} total=${data.workSummary.totalWorkedDuration.inMinutes} rule=must not exceed raw total worked duration',
    );
  }
  if (data.workTimeCandidateSummary.overtimeDuration.isNegative) {
    throw MonthlySummaryException(
      'model=MonthlySummaryViewData field=workTimeCandidateSummary.overtimeDuration rule=non-negative',
    );
  }
  if (data.workTimeCandidateSummary.nonWorkdayDuration.isNegative) {
    throw MonthlySummaryException(
      'model=MonthlySummaryViewData field=workTimeCandidateSummary.nonWorkdayDuration rule=non-negative',
    );
  }
  if (data.workTimeCandidateSummary.earlyWorkDuration.isNegative) {
    throw MonthlySummaryException(
      'model=MonthlySummaryViewData field=workTimeCandidateSummary.earlyWorkDuration rule=non-negative',
    );
  }
  if (data.workTimeCandidateSummary.nightWorkDuration.isNegative) {
    throw MonthlySummaryException(
      'model=MonthlySummaryViewData field=workTimeCandidateSummary.nightWorkDuration rule=non-negative',
    );
  }
  if (data.workRule == null &&
      data.workTimeCandidateSummary.status !=
          WorkTimeCandidateStatus.unavailable) {
    throw MonthlySummaryException(
      'model=MonthlySummaryViewData field=workTimeCandidateSummary.status rule=unavailable when workRule is missing',
    );
  }
}

bool _isDateOnly(DateTime value) {
  return value.hour == 0 &&
      value.minute == 0 &&
      value.second == 0 &&
      value.millisecond == 0 &&
      value.microsecond == 0;
}

bool _listEquals<T>(List<T> left, List<T> right) {
  if (left.length != right.length) {
    return false;
  }
  for (int index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}
