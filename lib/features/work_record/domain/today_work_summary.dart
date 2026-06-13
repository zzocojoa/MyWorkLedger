import '../../../core/models/work_record.dart';
import 'today_work_status.dart';

final class TodayWorkSummaryException implements Exception {
  const TodayWorkSummaryException(this.message);

  final String message;

  @override
  String toString() {
    return 'TodayWorkSummaryException: $message';
  }
}

final class TodayWorkSummary {
  const TodayWorkSummary({
    required this.status,
    required this.statusText,
    required this.primaryAction,
    required this.primaryButtonLabel,
    required this.secondaryAction,
    required this.secondaryButtonLabel,
    required this.elapsedDuration,
    required this.workedDuration,
    required this.record,
  });

  final TodayWorkStatus status;
  final String statusText;
  final TodayWorkPrimaryAction primaryAction;
  final String primaryButtonLabel;
  final TodayWorkSecondaryAction? secondaryAction;
  final String? secondaryButtonLabel;
  final Duration? elapsedDuration;
  final Duration? workedDuration;
  final WorkRecord? record;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TodayWorkSummary &&
            status == other.status &&
            statusText == other.statusText &&
            primaryAction == other.primaryAction &&
            primaryButtonLabel == other.primaryButtonLabel &&
            secondaryAction == other.secondaryAction &&
            secondaryButtonLabel == other.secondaryButtonLabel &&
            elapsedDuration == other.elapsedDuration &&
            workedDuration == other.workedDuration &&
            record == other.record;
  }

  @override
  int get hashCode {
    return Object.hash(
      status,
      statusText,
      primaryAction,
      primaryButtonLabel,
      secondaryAction,
      secondaryButtonLabel,
      elapsedDuration,
      workedDuration,
      record,
    );
  }
}

TodayWorkSummary buildTodayWorkSummary({
  required WorkRecord? record,
  required DateTime now,
}) {
  if (record == null) {
    return TodayWorkSummary(
      status: TodayWorkStatus.beforeClockIn,
      statusText: '아직 출근 전',
      primaryAction: TodayWorkPrimaryAction.clockIn,
      primaryButtonLabel: '출근하기',
      secondaryAction: null,
      secondaryButtonLabel: null,
      elapsedDuration: null,
      workedDuration: null,
      record: null,
    );
  }

  final DateTime? clockInAt = record.clockInAt;
  final DateTime? clockOutAt = record.clockOutAt;
  if (clockInAt == null && clockOutAt == null) {
    return TodayWorkSummary(
      status: TodayWorkStatus.beforeClockIn,
      statusText: '아직 출근 전',
      primaryAction: TodayWorkPrimaryAction.clockIn,
      primaryButtonLabel: '출근하기',
      secondaryAction: null,
      secondaryButtonLabel: null,
      elapsedDuration: null,
      workedDuration: null,
      record: record,
    );
  }

  if (clockInAt == null && clockOutAt != null) {
    throw TodayWorkSummaryException(
      'model=TodayWorkSummary recordId=${record.id} field=clockInAt rule=required when clockOutAt exists',
    );
  }

  if (clockInAt != null && clockOutAt == null) {
    return TodayWorkSummary(
      status: TodayWorkStatus.working,
      statusText: '근무 중',
      primaryAction: TodayWorkPrimaryAction.clockOut,
      primaryButtonLabel: '퇴근하기',
      secondaryAction: null,
      secondaryButtonLabel: null,
      elapsedDuration: calculateElapsedDuration(clockInAt: clockInAt, now: now),
      workedDuration: null,
      record: record,
    );
  }

  final Duration workedDuration = calculateWorkedDuration(
    clockInAt: clockInAt,
    clockOutAt: clockOutAt,
  );
  return TodayWorkSummary(
    status: TodayWorkStatus.afterClockOut,
    statusText: '오늘 기록 완료',
    primaryAction: TodayWorkPrimaryAction.editTodayRecord,
    primaryButtonLabel: '오늘 기록 수정',
    secondaryAction: TodayWorkSecondaryAction.viewMonthlySummary,
    secondaryButtonLabel: '월간 요약 보기',
    elapsedDuration: null,
    workedDuration: workedDuration,
    record: record,
  );
}

Duration calculateElapsedDuration({
  required DateTime clockInAt,
  required DateTime now,
}) {
  if (now.isBefore(clockInAt)) {
    throw TodayWorkSummaryException(
      'model=TodayWorkSummary field=now value=${now.toIso8601String()} clockInAt=${clockInAt.toIso8601String()} rule=now must be greater than or equal to clockInAt',
    );
  }
  return now.difference(clockInAt);
}

Duration calculateWorkedDuration({
  required DateTime? clockInAt,
  required DateTime? clockOutAt,
}) {
  if (clockInAt == null) {
    throw const TodayWorkSummaryException(
      'model=TodayWorkSummary field=clockInAt rule=required',
    );
  }
  if (clockOutAt == null) {
    throw const TodayWorkSummaryException(
      'model=TodayWorkSummary field=clockOutAt rule=required',
    );
  }
  if (clockOutAt.isBefore(clockInAt)) {
    throw TodayWorkSummaryException(
      'model=TodayWorkSummary field=clockOutAt value=${clockOutAt.toIso8601String()} clockInAt=${clockInAt.toIso8601String()} rule=clockOutAt must be greater than or equal to clockInAt',
    );
  }
  return clockOutAt.difference(clockInAt);
}
