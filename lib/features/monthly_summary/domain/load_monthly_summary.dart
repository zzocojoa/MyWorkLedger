import '../../../core/models/leave_usage.dart';
import '../../leave/domain/leave_repository.dart';
import '../../leave/domain/leave_summary.dart';
import '../../leave/domain/load_leave_summary.dart';
import '../../work_record/domain/work_record_repository.dart';
import 'calculate_monthly_summary.dart';
import 'monthly_summary.dart';

Future<MonthlySummaryViewData> loadMonthlySummary({
  required WorkRecordRepository workRecordRepository,
  required LeaveRepository leaveRepository,
  required MonthlySummaryMonth targetMonth,
}) async {
  targetMonth.validate();
  final MonthlySummary workSummary = calculateMonthlySummary(
    targetMonth: targetMonth,
    records: await workRecordRepository.findByMonth(
      year: targetMonth.year,
      month: targetMonth.month,
    ),
  );
  final LeaveSummary leaveSummary = await loadLeaveSummary(
    repository: leaveRepository,
    year: targetMonth.year,
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
  );
}
