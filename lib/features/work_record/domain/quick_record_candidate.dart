import '../../../core/input/clock_time_input.dart';
import '../../../core/models/compensation_reference_setting.dart';
import '../../../core/models/work_rule.dart';
import 'quick_record_settings.dart';

enum QuickRecordActionType { clockIn, clockOut }

enum QuickRecordCandidateType { currentTime, regularTime, manualInput }

final class QuickRecordCandidate {
  const QuickRecordCandidate({
    required this.type,
    required this.label,
    required this.recordedAt,
  });

  final QuickRecordCandidateType type;
  final String label;
  final DateTime? recordedAt;
}

final class QuickRecordManualInputException implements Exception {
  const QuickRecordManualInputException(this.message);

  final String message;

  @override
  String toString() {
    return 'QuickRecordManualInputException: $message';
  }
}

List<QuickRecordCandidate> buildQuickRecordCandidates({
  required QuickRecordMode mode,
  required QuickRecordActionType actionType,
  required DateTime currentTime,
  required WorkRule? workRule,
  required CompensationReferenceSetting? compensationReferenceSetting,
}) {
  if (mode == QuickRecordMode.currentTimeOnly) {
    return <QuickRecordCandidate>[];
  }
  final DateTime workDate = _dateOnly(currentTime);
  final List<QuickRecordCandidate> candidates = <QuickRecordCandidate>[
    QuickRecordCandidate(
      type: QuickRecordCandidateType.currentTime,
      label: '현재 시각 ${formatQuickRecordClock(value: currentTime)}',
      recordedAt: currentTime,
    ),
  ];
  final WorkRule? rule = workRule;
  if (rule != null) {
    final int minuteOfDay = switch (actionType) {
      QuickRecordActionType.clockIn => rule.regularStartTimeMinutes,
      QuickRecordActionType.clockOut => _clockOutCandidateMinuteOfDay(
        workRule: rule,
        compensationReferenceSetting: compensationReferenceSetting,
      ),
    };
    final String label = switch (actionType) {
      QuickRecordActionType.clockIn =>
        '정시 출근 ${formatQuickRecordMinuteOfDay(minuteOfDay: minuteOfDay)}',
      QuickRecordActionType.clockOut =>
        '정시 퇴근 ${formatQuickRecordMinuteOfDay(minuteOfDay: minuteOfDay)}',
    };
    candidates.add(
      QuickRecordCandidate(
        type: QuickRecordCandidateType.regularTime,
        label: label,
        recordedAt: dateTimeFromMinuteOfDay(
          workDate: workDate,
          minuteOfDay: minuteOfDay,
        ),
      ),
    );
  }
  candidates.add(
    const QuickRecordCandidate(
      type: QuickRecordCandidateType.manualInput,
      label: '직접 입력',
      recordedAt: null,
    ),
  );
  return candidates;
}

int _clockOutCandidateMinuteOfDay({
  required WorkRule workRule,
  required CompensationReferenceSetting? compensationReferenceSetting,
}) {
  final CompensationReferenceSetting? setting = compensationReferenceSetting;
  if (setting == null ||
      setting.mode != CompensationReferenceMode.fixedIncluded) {
    return workRule.regularEndTimeMinutes;
  }
  final int minuteOfDay =
      workRule.regularEndTimeMinutes +
      setting.fixedIncludedAfterRegularEndMinutes;
  if (minuteOfDay > 1439) {
    throw ArgumentError.value(
      minuteOfDay,
      'minuteOfDay',
      'must be between 0 and 1439',
    );
  }
  return minuteOfDay;
}

DateTime parseQuickRecordManualTime({
  required String value,
  required DateTime workDate,
}) {
  final String normalizedValue = normalizeClockInput(value: value);
  final RegExp clockPattern = RegExp(r'^(\d{2}):(\d{2})$');
  final RegExpMatch? match = clockPattern.firstMatch(normalizedValue);
  if (match == null) {
    throw QuickRecordManualInputException(
      'value=$value normalizedValue=$normalizedValue rule=HH:mm',
    );
  }
  final int hour = int.parse(match.group(1)!);
  final int minute = int.parse(match.group(2)!);
  if (hour < 0 || hour > 23) {
    throw QuickRecordManualInputException(
      'value=$value normalizedValue=$normalizedValue hour=$hour rule=between 0 and 23',
    );
  }
  if (minute < 0 || minute > 59) {
    throw QuickRecordManualInputException(
      'value=$value normalizedValue=$normalizedValue minute=$minute rule=between 0 and 59',
    );
  }
  return DateTime(workDate.year, workDate.month, workDate.day, hour, minute);
}

DateTime dateTimeFromMinuteOfDay({
  required DateTime workDate,
  required int minuteOfDay,
}) {
  if (minuteOfDay < 0 || minuteOfDay > 1439) {
    throw ArgumentError.value(
      minuteOfDay,
      'minuteOfDay',
      'must be between 0 and 1439',
    );
  }
  return DateTime(
    workDate.year,
    workDate.month,
    workDate.day,
    minuteOfDay ~/ 60,
    minuteOfDay % 60,
  );
}

String formatQuickRecordClock({required DateTime value}) {
  return formatQuickRecordMinuteOfDay(
    minuteOfDay: value.hour * 60 + value.minute,
  );
}

String formatQuickRecordMinuteOfDay({required int minuteOfDay}) {
  if (minuteOfDay < 0 || minuteOfDay > 1439) {
    throw ArgumentError.value(
      minuteOfDay,
      'minuteOfDay',
      'must be between 0 and 1439',
    );
  }
  final String hour = (minuteOfDay ~/ 60).toString().padLeft(2, '0');
  final String minute = (minuteOfDay % 60).toString().padLeft(2, '0');
  return '$hour:$minute';
}

DateTime _dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}
