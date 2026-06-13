import 'leave_repository.dart';
import 'leave_summary.dart';

Future<LeaveSummary> loadLeaveSummary({
  required LeaveRepository repository,
  required int year,
}) async {
  return buildLeaveSummary(
    year: year,
    balance: await repository.findBalanceByYear(year: year),
    usages: await repository.findUsagesByYear(year: year),
  );
}
