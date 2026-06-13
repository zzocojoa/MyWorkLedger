import '../../../core/models/leave_usage.dart';
import '../../../core/models/work_record.dart';
import '../../../core/models/work_rule.dart';
import '../../compensation_reference/domain/compensation_reference_summary.dart';
import '../../leave/domain/leave_repository.dart';
import '../../leave/domain/leave_summary.dart';
import '../../leave/domain/load_leave_summary.dart';
import '../../work_rule/domain/work_rule_repository.dart';
import '../../work_time/domain/calculate_work_time_candidates.dart';
import '../../work_time/domain/work_time_candidate.dart';
import '../../work_record/domain/work_record_repository.dart';
import 'calculate_monthly_summary.dart';
import 'monthly_summary.dart';

Future<MonthlySummaryViewData> loadMonthlySummary({
  required WorkRecordRepository workRecordRepository,
  required LeaveRepository leaveRepository,
  required WorkRuleRepository workRuleRepository,
  required MonthlySummaryMonth targetMonth,
}) async {
  targetMonth.validate();
  final List<WorkRecord> records = await workRecordRepository.findByMonth(
    year: targetMonth.year,
    month: targetMonth.month,
  );
  final MonthlySummary workSummary = calculateMonthlySummary(
    targetMonth: targetMonth,
    records: records,
  );
  final LeaveSummary leaveSummary = await loadLeaveSummary(
    repository: leaveRepository,
    year: targetMonth.year,
  );
  final WorkRule? workRule = await workRuleRepository.findActive();
  final WorkTimeCandidateSummary workTimeCandidateSummary =
      _calculateMonthlyWorkTimeCandidateSummary(
        records: records,
        workRule: workRule,
      );
  final int monthlyUsedLeaveMinutes = leaveSummary.usages
      .where((LeaveUsage usage) => targetMonth.containsDate(date: usage.usedOn))
      .fold(0, (int total, LeaveUsage usage) {
        return total + usage.usedLeaveMinutes;
      });
  return MonthlySummaryViewData(
    workSummary: workSummary,
    leaveSummary: leaveSummary,
    monthlyUsedLeaveMinutes: monthlyUsedLeaveMinutes,
    workRule: workRule,
    displayTotalWorkedDuration: calculateDisplayTotalWorkedDuration(
      workSummary: workSummary,
      workRule: workRule,
    ),
    workTimeCandidateSummary: workTimeCandidateSummary,
    compensationReferenceSummary: CompensationReferenceSummary(
      status: CompensationReferenceSummaryStatus.hidden,
      rows: <CompensationReferenceComparisonRow>[],
      reason: null,
    ),
  );
}

Duration calculateDisplayTotalWorkedDuration({
  required MonthlySummary workSummary,
  required WorkRule? workRule,
}) {
  if (workRule == null) {
    return workSummary.totalWorkedDuration;
  }
  return workSummary.completedEntries.fold(Duration.zero, (
    Duration total,
    MonthlyWorkRecordEntry entry,
  ) {
    final Duration? workedDuration = entry.workedDuration;
    if (workedDuration == null) {
      throw MonthlySummaryException(
        'model=MonthlySummaryViewData recordId=${entry.recordId} field=workedDuration rule=required for display total',
      );
    }
    final Duration breakDuration = Duration(minutes: workRule.breakMinutes);
    final Duration adjustedDuration = workedDuration > breakDuration
        ? workedDuration - breakDuration
        : Duration.zero;
    return total + adjustedDuration;
  });
}

WorkTimeCandidateSummary _calculateMonthlyWorkTimeCandidateSummary({
  required List<WorkRecord> records,
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

  return records.fold(
    const WorkTimeCandidateSummary(
      status: WorkTimeCandidateStatus.available,
      nonWorkdayDuration: Duration.zero,
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
