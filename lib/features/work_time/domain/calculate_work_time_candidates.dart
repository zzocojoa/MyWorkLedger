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
      regularWorkDuration: Duration.zero,
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
      regularWorkDuration: Duration.zero,
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
  final Duration regularWorkDuration = isWorkWeekday
      ? _calculateRegularWorkDuration(
          clockInAt: clockInAt,
          clockOutAt: clockOutAt,
          workDate: record.workDate,
          workRule: workRule,
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
          workRule: workRule,
        );

  return WorkTimeCandidateSummary(
    status: WorkTimeCandidateStatus.available,
    nonWorkdayDuration: nonWorkdayDuration,
    regularWorkDuration: regularWorkDuration,
    earlyWorkDuration: earlyWorkDuration,
    overtimeDuration: overtimeDuration,
    nightWorkDuration: nightWorkDuration,
    reason: null,
  );
}

Duration _calculateRegularWorkDuration({
  required DateTime clockInAt,
  required DateTime clockOutAt,
  required DateTime workDate,
  required WorkRule workRule,
}) {
  final DateTime regularStartAt = _dateTimeAtMinuteOfDay(
    date: workDate,
    minuteOfDay: workRule.regularStartTimeMinutes,
  );
  final DateTime regularEndAt = _dateTimeAtMinuteOfDay(
    date: workDate,
    minuteOfDay: workRule.regularEndTimeMinutes,
  );
  final Duration regularOverlapDuration = _overlapDuration(
    leftStart: clockInAt,
    leftEnd: clockOutAt,
    rightStart: regularStartAt,
    rightEnd: regularEndAt,
  );
  return _subtractBreakDuration(
    duration: regularOverlapDuration,
    breakMinutes: workRule.breakMinutes,
  );
}

Duration _calculateAdjustedWorkedDuration({
  required DateTime clockInAt,
  required DateTime clockOutAt,
  required int breakMinutes,
}) {
  final Duration workedDuration = clockOutAt.difference(clockInAt);
  return _subtractBreakDuration(
    duration: workedDuration,
    breakMinutes: breakMinutes,
  );
}

Duration _subtractBreakDuration({
  required Duration duration,
  required int breakMinutes,
}) {
  final Duration breakDuration = Duration(minutes: breakMinutes);
  if (duration <= breakDuration) {
    return Duration.zero;
  }
  return duration - breakDuration;
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
  final DateTime overtimeStartAt = _dateTimeAtMinuteOfDay(
    date: record.workDate,
    minuteOfDay: workRule.overtimeStartTimeMinutes,
  );
  if (!clockOutAt.isAfter(overtimeStartAt)) {
    return Duration.zero;
  }
  return clockOutAt.difference(overtimeStartAt);
}

Duration _calculateNightWorkDuration({
  required DateTime clockInAt,
  required DateTime clockOutAt,
  required WorkRule workRule,
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
    final DateTime nightStart = _dateTimeAtMinuteOfDay(
      date: cursor,
      minuteOfDay: workRule.nightWorkStartTimeMinutes,
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
