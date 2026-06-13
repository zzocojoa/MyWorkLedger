import 'package:flutter_test/flutter_test.dart';
import 'package:workledger/core/models/work_rule.dart';
import 'package:workledger/features/work_rule/data/local_storage_work_rule_repository.dart';
import 'package:workledger/features/work_rule/domain/work_rule_repository.dart';

import '../../../core/storage/in_memory_key_value_storage.dart';

void main() {
  group('LocalStorageWorkRuleRepository', () {
    test('returns null when active work rule is missing', () async {
      final InMemoryKeyValueStorage storage = InMemoryKeyValueStorage.empty();
      final LocalStorageWorkRuleRepository repository = _createRepository(
        storage: storage,
        clock: () => DateTime.parse('2026-06-12T09:00:00'),
        idGenerator: () => 'work-rule-1',
      );

      final WorkRule? rule = await repository.findActive();

      expect(rule, isNull);
    });

    test('saves and reads active work rule', () async {
      final InMemoryKeyValueStorage storage = InMemoryKeyValueStorage.empty();
      final LocalStorageWorkRuleRepository repository = _createRepository(
        storage: storage,
        clock: () => DateTime.parse('2026-06-12T09:00:00'),
        idGenerator: () => 'work-rule-1',
      );

      final WorkRule rule = await repository.save(
        regularStartTimeMinutes: 540,
        regularEndTimeMinutes: 1080,
        breakMinutes: 60,
        workWeekdays: <int>[1, 2, 3, 4, 5],
      );
      final WorkRule? savedRule = await repository.findActive();

      expect(rule.id, 'work-rule-1');
      expect(rule.regularStartTimeMinutes, 540);
      expect(rule.regularEndTimeMinutes, 1080);
      expect(rule.breakMinutes, 60);
      expect(rule.workWeekdays, <int>[1, 2, 3, 4, 5]);
      expect(savedRule, rule);
    });

    test('updates active work rule without changing id or createdAt', () async {
      DateTime now = DateTime.parse('2026-06-12T09:00:00');
      final InMemoryKeyValueStorage storage = InMemoryKeyValueStorage.empty();
      final LocalStorageWorkRuleRepository repository = _createRepository(
        storage: storage,
        clock: () => now,
        idGenerator: () => 'work-rule-1',
      );

      final WorkRule firstRule = await repository.save(
        regularStartTimeMinutes: 540,
        regularEndTimeMinutes: 1080,
        breakMinutes: 60,
        workWeekdays: <int>[1, 2, 3, 4, 5],
      );
      now = DateTime.parse('2026-06-13T09:00:00');
      final WorkRule updatedRule = await repository.save(
        regularStartTimeMinutes: 600,
        regularEndTimeMinutes: 1140,
        breakMinutes: 30,
        workWeekdays: <int>[1, 2, 3, 4],
      );

      expect(updatedRule.id, firstRule.id);
      expect(updatedRule.createdAt, firstRule.createdAt);
      expect(updatedRule.updatedAt, DateTime.parse('2026-06-13T09:00:00'));
      expect(updatedRule.regularStartTimeMinutes, 600);
      expect(updatedRule.workWeekdays, <int>[1, 2, 3, 4]);
    });

    test('throws explicit error when stored rule cannot parse', () async {
      final InMemoryKeyValueStorage storage = InMemoryKeyValueStorage.empty();
      await storage.write(
        table: LocalStorageWorkRuleRepository.workRulesTable,
        key: LocalStorageWorkRuleRepository.activeWorkRuleKey,
        value: <String, Object?>{
          'id': 'work-rule-1',
          'regular_start_time_minutes': '09:00',
          'regular_end_time_minutes': 1080,
          'break_minutes': 60,
          'work_weekdays': <Object?>[1, 2, 3, 4, 5],
          'created_at': '2026-06-12T09:00:00',
          'updated_at': '2026-06-12T09:00:00',
        },
      );
      final LocalStorageWorkRuleRepository repository = _createRepository(
        storage: storage,
        clock: () => DateTime.parse('2026-06-12T09:00:00'),
        idGenerator: () => 'unused-id',
      );

      await expectLater(
        repository.findActive(),
        throwsA(
          isA<WorkRuleRepositoryException>().having(
            (WorkRuleRepositoryException error) => error.message,
            'message',
            allOf(
              contains('action=parse'),
              contains('table=work_rules'),
              contains('key=active'),
              contains('cause='),
            ),
          ),
        ),
      );
    });
  });
}

LocalStorageWorkRuleRepository _createRepository({
  required InMemoryKeyValueStorage storage,
  required DateTime Function() clock,
  required String Function() idGenerator,
}) {
  return LocalStorageWorkRuleRepository(
    storage: storage,
    clock: clock,
    idGenerator: idGenerator,
  );
}
