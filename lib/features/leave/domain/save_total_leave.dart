import '../../../core/models/leave_balance.dart';
import 'leave_repository.dart';

Future<LeaveBalance> saveTotalLeave({
  required LeaveRepository repository,
  required int year,
  required int totalLeaveMinutes,
}) async {
  return repository.saveBalance(
    year: year,
    totalLeaveMinutes: totalLeaveMinutes,
  );
}
