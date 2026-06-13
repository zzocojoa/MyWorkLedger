import '../../../core/models/work_rule.dart';
import '../../../core/storage/key_value_storage.dart';
import '../domain/work_rule_repository.dart';

typedef WorkRuleClock = DateTime Function();
typedef WorkRuleIdGenerator = String Function();

final class LocalStorageWorkRuleRepository implements WorkRuleRepository {
  const LocalStorageWorkRuleRepository({
    required this.storage,
    required this.clock,
    required this.idGenerator,
  });

  final KeyValueStorage storage;
  final WorkRuleClock clock;
  final WorkRuleIdGenerator idGenerator;

  static const String workRulesTable = 'work_rules';
  static const String activeWorkRuleKey = 'active';

  @override
  Future<WorkRule?> findActive() async {
    final Map<String, Object?>? map = await storage.read(
      table: workRulesTable,
      key: activeWorkRuleKey,
    );
    if (map == null) {
      return null;
    }
    return _parseWorkRuleMap(key: activeWorkRuleKey, map: map);
  }

  @override
  Future<WorkRule> save({
    required int regularStartTimeMinutes,
    required int regularEndTimeMinutes,
    required int breakMinutes,
    required List<int> workWeekdays,
  }) async {
    final DateTime now = clock();
    final WorkRule? existingRule = await findActive();
    final WorkRule rule = existingRule == null
        ? WorkRule(
            id: idGenerator(),
            regularStartTimeMinutes: regularStartTimeMinutes,
            regularEndTimeMinutes: regularEndTimeMinutes,
            breakMinutes: breakMinutes,
            workWeekdays: workWeekdays,
            createdAt: now,
            updatedAt: now,
          )
        : existingRule.copyWith(
            id: existingRule.id,
            regularStartTimeMinutes: regularStartTimeMinutes,
            regularEndTimeMinutes: regularEndTimeMinutes,
            breakMinutes: breakMinutes,
            workWeekdays: workWeekdays,
            createdAt: existingRule.createdAt,
            updatedAt: now,
          );

    await storage.write(
      table: workRulesTable,
      key: activeWorkRuleKey,
      value: rule.toMap(),
    );
    return rule;
  }
}

WorkRule _parseWorkRuleMap({
  required String key,
  required Map<String, Object?> map,
}) {
  try {
    return WorkRule.fromMap(map);
  } on WorkRuleParseException catch (error) {
    throw WorkRuleRepositoryException(
      'action=parse table=${LocalStorageWorkRuleRepository.workRulesTable} key=$key cause=${error.message}',
    );
  } on ArgumentError catch (error) {
    throw WorkRuleRepositoryException(
      'action=parse table=${LocalStorageWorkRuleRepository.workRulesTable} key=$key cause=${error.message}',
    );
  }
}
