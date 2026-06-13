import '../../../core/models/leave_balance.dart';
import '../../../core/models/leave_usage.dart';

abstract interface class LeaveRepository {
  Future<LeaveBalance?> findBalanceByYear({required int year});

  Future<LeaveBalance> saveBalance({
    required int year,
    required int totalLeaveMinutes,
  });

  Future<List<LeaveUsage>> findUsagesByYear({required int year});

  Future<LeaveUsage> addUsage({
    required DateTime usedOn,
    required int usedLeaveMinutes,
    required String? memo,
  });

  Future<void> deleteUsage({required String id});
}

final class LeaveRepositoryException implements Exception {
  const LeaveRepositoryException(this.message);

  final String message;

  @override
  String toString() {
    return 'LeaveRepositoryException: $message';
  }
}
