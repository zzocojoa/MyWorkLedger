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
    _useTallViewport(tester: tester);
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
    await tester.ensureVisible(_findTextFieldByLabel(label: '연장 근무 태그 시작'));
    await tester.pump();
    await tester.enterText(
      _findTextFieldByLabel(label: '연장 근무 태그 시작'),
      '19:00',
    );
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
    expect(workRuleRepository.savedRule!.overtimeStartTimeMinutes, 1140);
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
    _useTallViewport(tester: tester);
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

    expect(find.text('정시 근무'), findsOneWidget);
    expect(find.text('포함 시간 비교'), findsOneWidget);
    expect(find.text('근무 태그 기준'), findsOneWidget);
    expect(find.text('고급 설정'), findsOneWidget);
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

    await tester.ensureVisible(find.text('고정 포함 시간 없음'));
    await tester.pump();
    await tester.tap(find.text('고정 포함 시간 없음'));
    await tester.pump();

    expect(find.text('정시 이후 고정 포함 시간(분)'), findsNothing);

    await tester.ensureVisible(find.text('잘 모르겠음'));
    await tester.pump();
    await tester.tap(find.text('잘 모르겠음'));
    await tester.pump();

    expect(find.text('정시 이후 고정 포함 시간(분)'), findsNothing);
  });

  testWidgets(
    'shows excess start from regular end plus fixed included minutes',
    (WidgetTester tester) async {
      _useTallViewport(tester: tester);
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

      expect(_textFieldText(label: '연장 근무 태그 시작', tester: tester), '18:00');

      await tester.tap(
        _findModeTile(value: CompensationReferenceMode.fixedIncluded),
      );
      await tester.pump();
      await tester.enterText(_findTextFieldByLabel(label: '정시 퇴근'), '17:00');
      await tester.ensureVisible(
        _findTextFieldByLabel(label: '정시 이후 고정 포함 시간(분)'),
      );
      await tester.pump();
      await tester.enterText(
        _findTextFieldByLabel(label: '정시 이후 고정 포함 시간(분)'),
        '120',
      );
      await tester.pump();

      expect(find.text('초과 참고 시작 19:00'), findsOneWidget);
      expect(
        find.text('고정 포함 시간을 넘긴 부분만 초과 참고로 봅니다. 연장 근무 태그와 별도입니다.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('keeps overtime start editable in fixed included mode', (
    WidgetTester tester,
  ) async {
    _useTallViewport(tester: tester);
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

    await tester.tap(
      _findModeTile(value: CompensationReferenceMode.fixedIncluded),
    );
    await tester.pump();
    await tester.enterText(_findTextFieldByLabel(label: '정시 퇴근'), '17:00');
    await tester.enterText(
      _findTextFieldByLabel(label: '연장 근무 태그 시작'),
      '19:00',
    );
    await tester.pump();

    final TextField overtimeStartField = tester.widget<TextField>(
      _findTextFieldByLabel(label: '연장 근무 태그 시작'),
    );

    expect(overtimeStartField.readOnly, isFalse);
    expect(overtimeStartField.enableInteractiveSelection, isTrue);
    expect(_textFieldText(label: '연장 근무 태그 시작', tester: tester), '19:00');
  });

  testWidgets('preserves custom overtime start in fixed included mode', (
    WidgetTester tester,
  ) async {
    _useTallViewport(tester: tester);
    final _FakeWorkRuleRepository workRuleRepository = _FakeWorkRuleRepository(
      initialRule: WorkRule(
        id: 'work-rule-fixed',
        regularStartTimeMinutes: 540,
        regularEndTimeMinutes: 1080,
        overtimeStartTimeMinutes: 1140,
        nightWorkStartTimeMinutes: 1320,
        breakMinutes: 60,
        workWeekdays: <int>[
          DateTime.monday,
          DateTime.tuesday,
          DateTime.wednesday,
          DateTime.thursday,
          DateTime.friday,
        ],
        createdAt: DateTime(2026, 6, 12, 9),
        updatedAt: DateTime(2026, 6, 12, 9),
      ),
      saveError: null,
    );
    await tester.pumpWidget(
      _buildScreen(
        workRuleRepository: workRuleRepository,
        compensationRepository: _FakeCompensationReferenceRepository(
          setting: CompensationReferenceSetting(
            id: 'compensation-setting-fixed',
            mode: CompensationReferenceMode.fixedIncluded,
            fixedIncludedAfterRegularEndMinutes: 120,
            effectiveFromMonth: DateTime(2000),
            memo: null,
            createdAt: DateTime(2026, 6, 12, 9),
            updatedAt: DateTime(2026, 6, 12, 9),
          ),
          findError: null,
          saveError: null,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.enterText(_findTextFieldByLabel(label: '정시 퇴근'), '17:00');
    await tester.enterText(
      _findTextFieldByLabel(label: '연장 근무 태그 시작'),
      '19:00',
    );
    await tester.pump();

    await _tapSave(tester: tester);
    await tester.pumpAndSettle();

    expect(workRuleRepository.savedRule, isNotNull);
    expect(workRuleRepository.savedRule!.regularEndTimeMinutes, 1020);
    expect(workRuleRepository.savedRule!.overtimeStartTimeMinutes, 1140);
  });

  testWidgets('allows custom overtime start in none or unknown mode', (
    WidgetTester tester,
  ) async {
    _useTallViewport(tester: tester);
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

    await tester.enterText(_findTextFieldByLabel(label: '정시 퇴근'), '17:00');
    await tester.enterText(
      _findTextFieldByLabel(label: '연장 근무 태그 시작'),
      '19:00',
    );
    final TextField overtimeStartField = tester.widget<TextField>(
      _findTextFieldByLabel(label: '연장 근무 태그 시작'),
    );
    expect(overtimeStartField.readOnly, isFalse);

    await _tapSave(tester: tester);
    await tester.pumpAndSettle();

    expect(workRuleRepository.savedRule, isNotNull);
    expect(workRuleRepository.savedRule!.regularEndTimeMinutes, 1020);
    expect(workRuleRepository.savedRule!.overtimeStartTimeMinutes, 1140);
  });

  testWidgets('starts from regular work section on compact screen', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _buildScreen(
        workRuleRepository: _FakeWorkRuleRepository(
          initialRule: null,
          saveError: null,
        ),
        compensationRepository: _FakeCompensationReferenceRepository(
          setting: CompensationReferenceSetting(
            id: 'compensation-setting-start',
            mode: CompensationReferenceMode.fixedIncluded,
            fixedIncludedAfterRegularEndMinutes: 120,
            effectiveFromMonth: DateTime(2000),
            memo: null,
            createdAt: DateTime(2026, 6, 12, 9),
            updatedAt: DateTime(2026, 6, 12, 9),
          ),
          findError: null,
          saveError: null,
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    final double regularSectionTop = tester.getTopLeft(find.text('정시 근무')).dy;

    expect(regularSectionTop, greaterThan(0));
    expect(regularSectionTop, lessThan(260));
    await tester.scrollUntilVisible(
      find.text('근무 태그 기준'),
      320,
      scrollable: find
          .descendant(
            of: find.byType(WorkSettingsScreen),
            matching: find.byType(Scrollable),
          )
          .first,
      maxScrolls: 20,
    );
    await tester.pump();

    expect(find.text('근무 태그 기준'), findsOneWidget);
  });

  testWidgets('allows drag scrolling on compact screen', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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

    final ScrollableState scrollableState = tester.state<ScrollableState>(
      _workSettingsScrollable(),
    );

    expect(scrollableState.position.pixels, 0);
    expect(scrollableState.position.maxScrollExtent, greaterThan(0));

    await tester.drag(_workSettingsScrollable(), const Offset(0, -420));
    await tester.pump();

    expect(scrollableState.position.pixels, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps scrolling when drag starts on a text field', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _buildScreen(
        workRuleRepository: _FakeWorkRuleRepository(
          initialRule: null,
          saveError: null,
        ),
        compensationRepository: _FakeCompensationReferenceRepository(
          setting: CompensationReferenceSetting(
            id: 'compensation-setting-scroll',
            mode: CompensationReferenceMode.fixedIncluded,
            fixedIncludedAfterRegularEndMinutes: 120,
            effectiveFromMonth: DateTime(2000),
            memo: null,
            createdAt: DateTime(2026, 6, 12, 9),
            updatedAt: DateTime(2026, 6, 12, 9),
          ),
          findError: null,
          saveError: null,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final ScrollableState scrollableState = tester.state<ScrollableState>(
      _workSettingsScrollable(),
    );

    await tester.drag(_workSettingsScrollable(), const Offset(0, -360));
    await tester.pump();

    final double positionBeforeTextFieldDrag = scrollableState.position.pixels;
    expect(
      positionBeforeTextFieldDrag,
      lessThan(scrollableState.position.maxScrollExtent),
    );
    await tester.drag(
      _findTextFieldByLabel(label: '정시 이후 고정 포함 시간(분)'),
      const Offset(0, -360),
    );
    await tester.pump();

    expect(
      scrollableState.position.pixels,
      greaterThan(positionBeforeTextFieldDrag),
    );
    expect(find.text('고급 설정'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('scrolls to the last section and back on compact screen', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _buildScreen(
        workRuleRepository: _FakeWorkRuleRepository(
          initialRule: null,
          saveError: null,
        ),
        compensationRepository: _FakeCompensationReferenceRepository(
          setting: CompensationReferenceSetting(
            id: 'compensation-setting-bottom',
            mode: CompensationReferenceMode.fixedIncluded,
            fixedIncludedAfterRegularEndMinutes: 120,
            effectiveFromMonth: DateTime(2000),
            memo: null,
            createdAt: DateTime(2026, 6, 12, 9),
            updatedAt: DateTime(2026, 6, 12, 9),
          ),
          findError: null,
          saveError: null,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final ScrollableState scrollableState = tester.state<ScrollableState>(
      _workSettingsScrollable(),
    );

    await tester.scrollUntilVisible(
      _findTextFieldByLabel(label: '야간 근무 시작'),
      420,
      scrollable: _workSettingsScrollable(),
      maxScrolls: 20,
    );
    await tester.pump();

    expect(find.text('근무 태그 기준'), findsOneWidget);
    expect(_findTextFieldByLabel(label: '야간 근무 시작'), findsOneWidget);
    expect(scrollableState.position.pixels, greaterThan(0));

    scrollableState.position.jumpTo(scrollableState.position.maxScrollExtent);
    await tester.pump();

    final double bottomPosition = scrollableState.position.pixels;
    expect(bottomPosition, scrollableState.position.maxScrollExtent);

    await tester.drag(
      _findTextFieldByLabel(label: '야간 근무 시작'),
      const Offset(0, 520),
    );
    await tester.pump();

    expect(scrollableState.position.pixels, lessThan(bottomPosition));
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses short helper text for work tag fields', (
    WidgetTester tester,
  ) async {
    _useTallViewport(tester: tester);
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

    expect(find.text('근무 태그 기준입니다. 초과 참고 시작과 별도입니다.'), findsOneWidget);
    expect(find.text('예: 22:00부터 8시간'), findsOneWidget);
    expect(find.text('정시 퇴근 이후 시각만 입력할 수 있습니다.'), findsNothing);
    expect(find.text('입력한 시각부터 8시간을 야간 근무 기준으로 봅니다.'), findsNothing);
  });

  testWidgets('keeps weekday selection collapsed until user changes it', (
    WidgetTester tester,
  ) async {
    _useTallViewport(tester: tester);
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

    await tester.ensureVisible(find.text('고급 설정'));
    await tester.pump();

    expect(find.text('근무 요일'), findsOneWidget);
    expect(find.text('월-금'), findsOneWidget);
    expect(find.text('평일 근무 요일'), findsNothing);
    expect(_findWeekdayChip(label: '월'), findsNothing);

    await tester.tap(find.widgetWithText(OutlinedButton, '변경'));
    await tester.pump();

    expect(find.text('근무 요일'), findsNWidgets(2));
    expect(_findWeekdayChip(label: '월'), findsOneWidget);
    expect(_findWeekdayChip(label: '토'), findsOneWidget);
  });

  testWidgets('shows work rule save failure with section context', (
    WidgetTester tester,
  ) async {
    _useTallViewport(tester: tester);
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
    _useTallViewport(tester: tester);
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
    _useTallViewport(tester: tester);
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
    theme: ThemeData(
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
      ),
    ),
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

String _textFieldText({required String label, required WidgetTester tester}) {
  final TextField field = tester.widget<TextField>(
    _findTextFieldByLabel(label: label),
  );
  final TextEditingController? controller = field.controller;
  if (controller == null) {
    throw StateError('label=$label text field controller is missing');
  }
  return controller.text;
}

Finder _findModeTile({required CompensationReferenceMode value}) {
  return find.byWidgetPredicate((Widget widget) {
    return widget is RadioListTile<CompensationReferenceMode> &&
        widget.value == value;
  });
}

Finder _workSettingsScrollable() {
  return find
      .descendant(
        of: find.byType(WorkSettingsScreen),
        matching: find.byType(Scrollable),
      )
      .first;
}

Future<void> _tapSave({required WidgetTester tester}) async {
  final Finder saveButton = find.widgetWithText(TextButton, '저장');
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pump();
  final TextButton button = tester.widget<TextButton>(saveButton);
  button.onPressed!();
}

Finder _findWeekdayChip({required String label}) {
  return find.byWidgetPredicate((Widget widget) {
    return widget is FilterChip &&
        widget.label is Text &&
        (widget.label as Text).data == label;
  });
}

void _useTallViewport({required WidgetTester tester}) {
  tester.view.physicalSize = const Size(390, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
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
