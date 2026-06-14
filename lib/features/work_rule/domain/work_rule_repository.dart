import '../../../core/models/work_rule.dart';

final class WorkRuleRepositoryException implements Exception {
  const WorkRuleRepositoryException(this.message);

  final String message;

  @override
  String toString() {
    return 'WorkRuleRepositoryException: $message';
  }
}

abstract interface class WorkRuleRepository {
  Future<WorkRule?> findActive();

  Future<WorkRule> save({
    required int regularStartTimeMinutes,
    required int regularEndTimeMinutes,
    required int overtimeStartTimeMinutes,
    required int nightWorkStartTimeMinutes,
    required int breakMinutes,
    required List<int> workWeekdays,
  });
}
