import '../../../core/models/leave_usage.dart';
import 'leave_repository.dart';

Future<LeaveUsage> addLeaveUsage({
  required LeaveRepository repository,
  required DateTime usedOn,
  required int usedLeaveMinutes,
  required String? memo,
}) async {
  return repository.addUsage(
    usedOn: usedOn,
    usedLeaveMinutes: usedLeaveMinutes,
    memo: memo,
  );
}
