import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workledger/core/models/work_rule.dart';
import 'package:workledger/features/work_rule/domain/work_rule_repository.dart';
import 'package:workledger/features/work_rule/presentation/work_rule_settings_screen.dart';

void main() {
  testWidgets('saves default weekday work rule quickly', (
    WidgetTester tester,
  ) async {
    final _FakeWorkRuleRepository repository = _FakeWorkRuleRepository(
      initialRule: null,
      saveError: null,
    );

    await tester.pumpWidget(_buildScreen(repository: repository));
    await tester.pump();

    expect(find.text('정시 근무 기준'), findsNothing);
    expect(find.textContaining('급여나 법정 수당 확정값이 아닙니다.'), findsNothing);
    expect(find.text('09:00-18:00 빠른 설정'), findsOneWidget);

    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(repository.savedRule, isNotNull);
    expect(repository.savedRule!.regularStartTimeMinutes, 540);
    expect(repository.savedRule!.regularEndTimeMinutes, 1080);
    expect(repository.savedRule!.breakMinutes, 60);
    expect(repository.savedRule!.workWeekdays, <int>[1, 2, 3, 4, 5]);
  });

  testWidgets('loads existing rule into fields', (WidgetTester tester) async {
    final _FakeWorkRuleRepository repository = _FakeWorkRuleRepository(
      initialRule: WorkRule(
        id: 'active-rule',
        regularStartTimeMinutes: 600,
        regularEndTimeMinutes: 1140,
        breakMinutes: 30,
        workWeekdays: <int>[1, 2, 3, 4],
        createdAt: DateTime(2026, 6, 1, 9),
        updatedAt: DateTime(2026, 6, 1, 9),
      ),
      saveError: null,
    );

    await tester.pumpWidget(_buildScreen(repository: repository));
    await tester.pump();
    await tester.pump();

    expect(find.widgetWithText(TextField, '10:00'), findsOneWidget);
    expect(find.widgetWithText(TextField, '19:00'), findsOneWidget);
    expect(find.widgetWithText(TextField, '30'), findsOneWidget);
  });

  testWidgets('keeps input visible when validation fails', (
    WidgetTester tester,
  ) async {
    final _FakeWorkRuleRepository repository = _FakeWorkRuleRepository(
      initialRule: null,
      saveError: null,
    );

    await tester.pumpWidget(_buildScreen(repository: repository));
    await tester.pump();
    await tester.enterText(find.widgetWithText(TextField, '09:00'), '25:00');
    await tester.tap(find.text('저장'));
    await tester.pump();

    expect(find.textContaining('근무 기준을 저장할 수 없습니다.'), findsOneWidget);
    expect(find.widgetWithText(TextField, '25:00'), findsOneWidget);
    expect(repository.savedRule, isNull);
  });

  testWidgets('keeps input visible when repository save fails', (
    WidgetTester tester,
  ) async {
    final _FakeWorkRuleRepository repository = _FakeWorkRuleRepository(
      initialRule: null,
      saveError: const WorkRuleRepositoryException(
        'action=save rule=test failure',
      ),
    );

    await tester.pumpWidget(_buildScreen(repository: repository));
    await tester.pump();
    await tester.enterText(find.widgetWithText(TextField, '60'), '30');
    await tester.tap(find.text('저장'));
    await tester.pump();

    expect(find.textContaining('근무 기준을 저장할 수 없습니다.'), findsOneWidget);
    expect(find.textContaining('action=save'), findsOneWidget);
    expect(find.widgetWithText(TextField, '30'), findsOneWidget);
  });
}

Widget _buildScreen({required _FakeWorkRuleRepository repository}) {
  return MaterialApp(home: WorkRuleSettingsScreen(repository: repository));
}

final class _FakeWorkRuleRepository implements WorkRuleRepository {
  _FakeWorkRuleRepository({required this.initialRule, required this.saveError});

  final WorkRule? initialRule;
  final WorkRuleRepositoryException? saveError;
  WorkRule? savedRule;

  @override
  Future<WorkRule?> findActive() async {
    return initialRule;
  }

  @override
  Future<WorkRule> save({
    required int regularStartTimeMinutes,
    required int regularEndTimeMinutes,
    required int breakMinutes,
    required List<int> workWeekdays,
  }) async {
    final WorkRuleRepositoryException? error = saveError;
    if (error != null) {
      throw error;
    }
    savedRule = WorkRule(
      id: 'active-rule',
      regularStartTimeMinutes: regularStartTimeMinutes,
      regularEndTimeMinutes: regularEndTimeMinutes,
      breakMinutes: breakMinutes,
      workWeekdays: workWeekdays,
      createdAt: DateTime(2026, 6, 12, 9),
      updatedAt: DateTime(2026, 6, 12, 9),
    );
    return savedRule!;
  }
}
