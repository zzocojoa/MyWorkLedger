import '../../../core/models/work_record.dart';
import '../../../core/models/work_rule.dart';
import 'work_time_candidate.dart';

WorkTimeCandidateSummary calculateWorkTimeCandidates({
  required WorkRecord record,
  required WorkRule? workRule,
}) {
  if (workRule == null) {
    return const WorkTimeCandidateSummary(
      status: WorkTimeCandidateStatus.unavailable,
      nonWorkdayDuration: Duration.zero,
      earlyWorkDuration: Duration.zero,
      overtimeDuration: Duration.zero,
      nightWorkDuration: Duration.zero,
      reason: 'workRuleMissing',
    );
  }

  final DateTime? clockInAt = record.clockInAt;
  final DateTime? clockOutAt = record.clockOutAt;
  if (clockInAt == null || clockOutAt == null) {
    return const WorkTimeCandidateSummary(
      status: WorkTimeCandidateStatus.unavailable,
      nonWorkdayDuration: Duration.zero,
      earlyWorkDuration: Duration.zero,
      overtimeDuration: Duration.zero,
      nightWorkDuration: Duration.zero,
      reason: 'incompleteWorkRecord',
    );
  }
  if (clockOutAt.isBefore(clockInAt)) {
    throw ArgumentError.value(
      clockOutAt,
      'clockOutAt',
      'must be greater than or equal to clockInAt',
    );
  }

  final bool isWorkWeekday = workRule.workWeekdays.contains(
    record.workDate.weekday,
  );
  final bool hasDelayedCheckout = record.tags.contains(
    WorkRecordTag.delayedCheckout,
  );
  final Duration nonWorkdayDuration = !isWorkWeekday && !hasDelayedCheckout
      ? _calculateAdjustedWorkedDuration(
          clockInAt: clockInAt,
          clockOutAt: clockOutAt,
          breakMinutes: workRule.breakMinutes,
        )
      : Duration.zero;
  final Duration earlyWorkDuration = _calculateEarlyWorkDuration(
    record: record,
    workRule: workRule,
  );
  final Duration overtimeDuration = !hasDelayedCheckout
      ? _calculateOvertimeDuration(record: record, workRule: workRule)
      : Duration.zero;
  final Duration nightWorkDuration = hasDelayedCheckout
      ? Duration.zero
      : _calculateNightWorkDuration(
          clockInAt: clockInAt,
          clockOutAt: clockOutAt,
        );

  return WorkTimeCandidateSummary(
    status: WorkTimeCandidateStatus.available,
    nonWorkdayDuration: nonWorkdayDuration,
    earlyWorkDuration: earlyWorkDuration,
    overtimeDuration: overtimeDuration,
    nightWorkDuration: nightWorkDuration,
    reason: null,
  );
}

Duration _calculateAdjustedWorkedDuration({
  required DateTime clockInAt,
  required DateTime clockOutAt,
  required int breakMinutes,
}) {
  final Duration workedDuration = clockOutAt.difference(clockInAt);
  final Duration breakDuration = Duration(minutes: breakMinutes);
  if (workedDuration <= breakDuration) {
    return Duration.zero;
  }
  return workedDuration - breakDuration;
}

Duration _calculateEarlyWorkDuration({
  required WorkRecord record,
  required WorkRule workRule,
}) {
  final DateTime? clockInAt = record.clockInAt;
  if (clockInAt == null) {
    throw ArgumentError.value(
      record.id,
      'record',
      'clockInAt is required for early work calculation',
    );
  }
  final DateTime regularStartAt = _dateTimeAtMinuteOfDay(
    date: record.workDate,
    minuteOfDay: workRule.regularStartTimeMinutes,
  );
  if (!clockInAt.isBefore(regularStartAt)) {
    return Duration.zero;
  }
  return regularStartAt.difference(clockInAt);
}

Duration _calculateOvertimeDuration({
  required WorkRecord record,
  required WorkRule workRule,
}) {
  final DateTime? clockOutAt = record.clockOutAt;
  if (clockOutAt == null) {
    throw ArgumentError.value(
      record.id,
      'record',
      'clockOutAt is required for overtime calculation',
    );
  }
  final DateTime regularEndAt = _dateTimeAtMinuteOfDay(
    date: record.workDate,
    minuteOfDay: workRule.regularEndTimeMinutes,
  );
  if (!clockOutAt.isAfter(regularEndAt)) {
    return Duration.zero;
  }
  return clockOutAt.difference(regularEndAt);
}

Duration _calculateNightWorkDuration({
  required DateTime clockInAt,
  required DateTime clockOutAt,
}) {
  final DateTime startDate = DateTime(
    clockInAt.year,
    clockInAt.month,
    clockInAt.day,
  ).subtract(const Duration(days: 1));
  final DateTime endDate = DateTime(
    clockOutAt.year,
    clockOutAt.month,
    clockOutAt.day,
  ).add(const Duration(days: 1));
  Duration total = Duration.zero;
  DateTime cursor = startDate;
  while (!cursor.isAfter(endDate)) {
    final DateTime nightStart = DateTime(
      cursor.year,
      cursor.month,
      cursor.day,
      22,
    );
    final DateTime nightEnd = nightStart.add(const Duration(hours: 8));
    total += _overlapDuration(
      leftStart: clockInAt,
      leftEnd: clockOutAt,
      rightStart: nightStart,
      rightEnd: nightEnd,
    );
    cursor = cursor.add(const Duration(days: 1));
  }
  return total;
}

Duration _overlapDuration({
  required DateTime leftStart,
  required DateTime leftEnd,
  required DateTime rightStart,
  required DateTime rightEnd,
}) {
  final DateTime start = leftStart.isAfter(rightStart) ? leftStart : rightStart;
  final DateTime end = leftEnd.isBefore(rightEnd) ? leftEnd : rightEnd;
  if (!end.isAfter(start)) {
    return Duration.zero;
  }
  return end.difference(start);
}

DateTime _dateTimeAtMinuteOfDay({
  required DateTime date,
  required int minuteOfDay,
}) {
  return DateTime(
    date.year,
    date.month,
    date.day,
    minuteOfDay ~/ 60,
    minuteOfDay.remainder(60),
  );
}
