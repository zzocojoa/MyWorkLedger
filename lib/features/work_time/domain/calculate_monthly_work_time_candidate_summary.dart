import '../../../core/models/work_record.dart';
import '../../../core/models/work_rule.dart';
import 'calculate_work_time_candidates.dart';
import 'work_time_candidate.dart';

WorkRule buildDefaultWorkTimeCandidateRule({required DateTime timestamp}) {
  return WorkRule(
    id: 'default-work-time-candidate-rule',
    regularStartTimeMinutes: 9 * 60,
    regularEndTimeMinutes: 18 * 60,
    overtimeStartTimeMinutes: 18 * 60,
    nightWorkStartTimeMinutes: workRuleDefaultNightWorkStartTimeMinutes,
    breakMinutes: 60,
    workWeekdays: <int>[
      DateTime.monday,
      DateTime.tuesday,
      DateTime.wednesday,
      DateTime.thursday,
      DateTime.friday,
    ],
    createdAt: timestamp,
    updatedAt: timestamp,
  );
}

WorkTimeCandidateSummary calculateMonthlyWorkTimeCandidateSummary({
  required List<WorkRecord> records,
  required WorkRule workRule,
}) {
  return records.fold(
    const WorkTimeCandidateSummary(
      status: WorkTimeCandidateStatus.available,
      nonWorkdayDuration: Duration.zero,
      regularWorkDuration: Duration.zero,
      earlyWorkDuration: Duration.zero,
      overtimeDuration: Duration.zero,
      nightWorkDuration: Duration.zero,
      reason: null,
    ),
    (WorkTimeCandidateSummary total, WorkRecord record) {
      final WorkTimeCandidateSummary candidate = calculateWorkTimeCandidates(
        record: record,
        workRule: workRule,
      );
      if (!candidate.isAvailable) {
        return total;
      }
      return WorkTimeCandidateSummary(
        status: WorkTimeCandidateStatus.available,
        nonWorkdayDuration:
            total.nonWorkdayDuration + candidate.nonWorkdayDuration,
        regularWorkDuration:
            total.regularWorkDuration + candidate.regularWorkDuration,
        earlyWorkDuration:
            total.earlyWorkDuration + candidate.earlyWorkDuration,
        overtimeDuration: total.overtimeDuration + candidate.overtimeDuration,
        nightWorkDuration:
            total.nightWorkDuration + candidate.nightWorkDuration,
        reason: null,
      );
    },
  );
}
