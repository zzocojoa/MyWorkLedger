import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workledger/core/models/compensation_reference_setting.dart';
import 'package:workledger/core/models/work_rule.dart';
import 'package:workledger/features/compensation_reference/domain/compensation_reference_repository.dart';
import 'package:workledger/features/settings/presentation/work_settings_screen.dart';
import 'package:workledger/features/work_rule/domain/work_rule_repository.dart';

void main() {
  testWidgets('saves work rule and fixed included comparison together', (
    WidgetTester tester,
  ) async {
    final _FakeWorkRuleRepository workRuleRepository = _FakeWorkRuleRepository(
      initialRule: null,
      saveError: null,
    );
    final _FakeCompensationReferenceRepository compensationRepository =
        _FakeCompensationReferenceRepository(
          setting: null,
          findError: null,
          saveError: null,
        );

    await tester.pumpWidget(
      _buildScreen(
        workRuleRepository: workRuleRepository,
        compensationRepository: compensationRepository,
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.ensureVisible(
      _findModeTile(value: CompensationReferenceMode.fixedIncluded),
    );
    await tester.pump();
    await tester.tap(
      _findModeTile(value: CompensationReferenceMode.fixedIncluded),
    );
    await tester.pump();
    await tester.ensureVisible(_findTextFieldByLabel(label: '정시 출근'));
    await tester.pump();
    await tester.enterText(_findTextFieldByLabel(label: '정시 출근'), '08:30');
    await tester.enterText(_findTextFieldByLabel(label: '정시 퇴근'), '17:30');
    await tester.enterText(_findTextFieldByLabel(label: '휴게시간(분)'), '30');
    await tester.enterText(_findTextFieldByLabel(label: '연장 근무 시작'), '18:30');
    await tester.enterText(_findTextFieldByLabel(label: '야간 근무 시작'), '22:30');
    await tester.ensureVisible(
      _findTextFieldByLabel(label: '정시 이후 고정 포함 시간(분)'),
    );
    await tester.pump();
    await tester.enterText(
      _findTextFieldByLabel(label: '정시 이후 고정 포함 시간(분)'),
      '120',
    );
    await _tapSave(tester: tester);
    await tester.pumpAndSettle();

    expect(workRuleRepository.savedRule, isNotNull);
    expect(workRuleRepository.savedRule!.regularStartTimeMinutes, 510);
    expect(workRuleRepository.savedRule!.regularEndTimeMinutes, 1050);
    expect(workRuleRepository.savedRule!.breakMinutes, 30);
    expect(workRuleRepository.savedRule!.overtimeStartTimeMinutes, 1110);
    expect(workRuleRepository.savedRule!.nightWorkStartTimeMinutes, 1350);
    expect(
      compensationRepository.savedMode,
      CompensationReferenceMode.fixedIncluded,
    );
    expect(compensationRepository.savedAfterRegularEndMinutes, 120);
    expect(compensationRepository.savedEffectiveFromMonth, DateTime(2000));
  });

  testWidgets('shows fixed included fields only for fixed included mode', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _buildScreen(
        workRuleRepository: _FakeWorkRuleRepository(
          initialRule: null,
          saveError: null,
        ),
        compensationRepository: _FakeCompensationReferenceRepository(
          setting: null,
          findError: null,
          saveError: null,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('기본 근무 기준'), findsOneWidget);
    expect(find.text('추가 근무 기준'), findsOneWidget);
    expect(find.text('포함 시간 비교'), findsOneWidget);
    expect(find.text('정시 이후 고정 포함 시간(분)'), findsNothing);

    await tester.ensureVisible(
      _findModeTile(value: CompensationReferenceMode.fixedIncluded),
    );
    await tester.pump();
    await tester.tap(
      _findModeTile(value: CompensationReferenceMode.fixedIncluded),
    );
    await tester.pump();

    expect(find.text('정시 이후 고정 포함 시간(분)'), findsOneWidget);
    expect(find.text('야간 근무 포함 시간(분)'), findsNothing);
    expect(find.text('휴무일 근무 포함 시간(분)'), findsNothing);

    await tester.tap(_findModeTile(value: CompensationReferenceMode.none));
    await tester.pump();

    expect(find.text('정시 이후 고정 포함 시간(분)'), findsNothing);

    await tester.tap(_findModeTile(value: CompensationReferenceMode.unknown));
    await tester.pump();

    expect(find.text('정시 이후 고정 포함 시간(분)'), findsNothing);
  });

  testWidgets('shows work rule save failure with section context', (
    WidgetTester tester,
  ) async {
    final _FakeCompensationReferenceRepository compensationRepository =
        _FakeCompensationReferenceRepository(
          setting: null,
          findError: null,
          saveError: null,
        );

    await tester.pumpWidget(
      _buildScreen(
        workRuleRepository: _FakeWorkRuleRepository(
          initialRule: null,
          saveError: const WorkRuleRepositoryException(
            'action=save rule=test failure',
          ),
        ),
        compensationRepository: compensationRepository,
      ),
    );
    await tester.pump();
    await tester.pump();

    await _tapSave(tester: tester);
    await tester.pump();

    expect(find.textContaining('근무 기준을 저장할 수 없습니다.'), findsOneWidget);
    expect(find.textContaining('action=save'), findsOneWidget);
    expect(compensationRepository.savedMode, isNull);
  });

  testWidgets('does not save work rule when comparison input is invalid', (
    WidgetTester tester,
  ) async {
    final _FakeWorkRuleRepository workRuleRepository = _FakeWorkRuleRepository(
      initialRule: null,
      saveError: null,
    );

    await tester.pumpWidget(
      _buildScreen(
        workRuleRepository: workRuleRepository,
        compensationRepository: _FakeCompensationReferenceRepository(
          setting: null,
          findError: null,
          saveError: null,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.ensureVisible(
      _findModeTile(value: CompensationReferenceMode.fixedIncluded),
    );
    await tester.pump();
    await tester.tap(
      _findModeTile(value: CompensationReferenceMode.fixedIncluded),
    );
    await tester.pump();
    await tester.ensureVisible(
      _findTextFieldByLabel(label: '정시 이후 고정 포함 시간(분)'),
    );
    await tester.pump();
    await tester.enterText(
      _findTextFieldByLabel(label: '정시 이후 고정 포함 시간(분)'),
      '',
    );

    await _tapSave(tester: tester);
    await tester.pump();

    expect(find.text('정시 이후 고정 포함 시간은 분 단위 숫자로 입력해 주세요.'), findsOneWidget);
    expect(workRuleRepository.savedRule, isNull);
  });

  testWidgets('shows comparison save failure with section context', (
    WidgetTester tester,
  ) async {
    final _FakeWorkRuleRepository workRuleRepository = _FakeWorkRuleRepository(
      initialRule: null,
      saveError: null,
    );

    await tester.pumpWidget(
      _buildScreen(
        workRuleRepository: workRuleRepository,
        compensationRepository: _FakeCompensationReferenceRepository(
          setting: null,
          findError: null,
          saveError: const CompensationReferenceRepositoryException(
            'action=save rule=test failure',
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await _tapSave(tester: tester);
    await tester.pump();

    expect(find.textContaining('포함 시간 비교를 저장할 수 없습니다.'), findsOneWidget);
    expect(find.textContaining('action=save'), findsOneWidget);
    expect(workRuleRepository.savedRule, isNotNull);
  });
}

Widget _buildScreen({
  required _FakeWorkRuleRepository workRuleRepository,
  required _FakeCompensationReferenceRepository compensationRepository,
}) {
  return MaterialApp(
    home: WorkSettingsScreen(
      workRuleRepository: workRuleRepository,
      compensationReferenceRepository: compensationRepository,
      targetMonth: DateTime(2026, 6, 12),
    ),
  );
}

Finder _findTextFieldByLabel({required String label}) {
  return find.byWidgetPredicate((Widget widget) {
    return widget is TextField && widget.decoration?.labelText == label;
  });
}

Finder _findModeTile({required CompensationReferenceMode value}) {
  return find.byWidgetPredicate((Widget widget) {
    return widget is RadioListTile<CompensationReferenceMode> &&
        widget.value == value;
  });
}

Future<void> _tapSave({required WidgetTester tester}) async {
  final Finder saveButton = find.widgetWithText(FilledButton, '저장');
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.ensureVisible(saveButton);
  await tester.pump();
  final FilledButton button = tester.widget<FilledButton>(saveButton);
  button.onPressed!();
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
    required int overtimeStartTimeMinutes,
    required int nightWorkStartTimeMinutes,
    required int breakMinutes,
    required List<int> workWeekdays,
  }) async {
    final WorkRuleRepositoryException? error = saveError;
    if (error != null) {
      throw error;
    }
    savedRule = WorkRule(
      id: 'work-rule-1',
      regularStartTimeMinutes: regularStartTimeMinutes,
      regularEndTimeMinutes: regularEndTimeMinutes,
      overtimeStartTimeMinutes: overtimeStartTimeMinutes,
      nightWorkStartTimeMinutes: nightWorkStartTimeMinutes,
      breakMinutes: breakMinutes,
      workWeekdays: workWeekdays,
      createdAt: DateTime(2026, 6, 12, 9),
      updatedAt: DateTime(2026, 6, 12, 9),
    );
    return savedRule!;
  }
}

final class _FakeCompensationReferenceRepository
    implements CompensationReferenceRepository {
  _FakeCompensationReferenceRepository({
    required this.setting,
    required this.findError,
    required this.saveError,
  });

  final CompensationReferenceSetting? setting;
  final CompensationReferenceRepositoryException? findError;
  final CompensationReferenceRepositoryException? saveError;
  CompensationReferenceMode? savedMode;
  int? savedAfterRegularEndMinutes;
  DateTime? savedEffectiveFromMonth;

  @override
  Future<CompensationReferenceSetting?> findApplicableForMonth({
    required int year,
    required int month,
  }) async {
    final CompensationReferenceRepositoryException? error = findError;
    if (error != null) {
      throw error;
    }
    return setting;
  }

  @override
  Future<CompensationReferenceSetting> save({
    required CompensationReferenceMode mode,
    required int fixedIncludedAfterRegularEndMinutes,
    required DateTime effectiveFromMonth,
    required String? memo,
  }) async {
    final CompensationReferenceRepositoryException? error = saveError;
    if (error != null) {
      throw error;
    }
    savedMode = mode;
    savedAfterRegularEndMinutes = fixedIncludedAfterRegularEndMinutes;
    savedEffectiveFromMonth = effectiveFromMonth;
    return CompensationReferenceSetting(
      id: 'compensation-setting-1',
      mode: mode,
      fixedIncludedAfterRegularEndMinutes: fixedIncludedAfterRegularEndMinutes,
      effectiveFromMonth: effectiveFromMonth,
      memo: memo,
      createdAt: DateTime(2026, 6, 12, 9),
      updatedAt: DateTime(2026, 6, 12, 9),
    );
  }
}
