import '../../../core/models/compensation_reference_setting.dart';
import '../../../core/models/leave_usage.dart';
import '../../../core/models/work_record.dart';
import '../../../core/models/work_rule.dart';
import '../../compensation_reference/domain/compensation_reference_repository.dart';
import '../../compensation_reference/domain/compensation_reference_summary.dart';
import '../../leave/domain/leave_repository.dart';
import '../../leave/domain/leave_summary.dart';
import '../../leave/domain/load_leave_summary.dart';
import '../../work_rule/domain/work_rule_repository.dart';
import '../../work_time/domain/calculate_monthly_work_time_candidate_summary.dart';
import '../../work_time/domain/work_time_candidate.dart';
import '../../work_record/domain/work_record_repository.dart';
import 'calculate_monthly_summary.dart';
import 'monthly_summary.dart';

Future<MonthlySummaryViewData> loadMonthlySummary({
  required WorkRecordRepository workRecordRepository,
  required LeaveRepository leaveRepository,
  required WorkRuleRepository workRuleRepository,
  required CompensationReferenceRepository compensationReferenceRepository,
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
  final WorkRule candidateWorkRule =
      workRule ??
      buildDefaultWorkTimeCandidateRule(
        timestamp: DateTime(targetMonth.year, targetMonth.month),
      );
  final WorkTimeCandidateSummary workTimeCandidateSummary =
      calculateMonthlyWorkTimeCandidateSummary(
        records: records,
        workRule: candidateWorkRule,
      );
  final CompensationReferenceSetting? compensationReferenceSetting =
      await compensationReferenceRepository.findApplicableForMonth(
        year: targetMonth.year,
        month: targetMonth.month,
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
    compensationReferenceSummary: calculateCompensationReferenceSummary(
      setting: compensationReferenceSetting,
      records: records,
      workRule: workRule,
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
