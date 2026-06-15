import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/models/compensation_reference_setting.dart';
import '../../../core/models/work_rule.dart';
import '../../compensation_reference/domain/compensation_reference_repository.dart';
import '../../work_rule/domain/work_rule_repository.dart';
import '../../work_rule/presentation/work_rule_settings_screen.dart';

const NeverScrollableScrollPhysics _textFieldScrollPhysics =
    NeverScrollableScrollPhysics();
const String _fixedIncludedOvertimeStartWarningMessage =
    '고정 포함 시간은 연장 근무 태그를 줄이는 설정이 아닙니다. 연장 근무 시작을 정시 퇴근보다 늦게 두면 일부 시간이 태그에서 빠질 수 있습니다.';

final class WorkSettingsScreen extends StatefulWidget {
  const WorkSettingsScreen({
    required this.workRuleRepository,
    required this.compensationReferenceRepository,
    required this.targetMonth,
    super.key,
  });

  final WorkRuleRepository workRuleRepository;
  final CompensationReferenceRepository compensationReferenceRepository;
  final DateTime targetMonth;

  @override
  State<WorkSettingsScreen> createState() => _WorkSettingsScreenState();
}

final class _WorkSettingsScreenState extends State<WorkSettingsScreen> {
  final ScrollController _scrollController = ScrollController(
    keepScrollOffset: false,
  );
  Timer? _scrollResetTimer;
  final TextEditingController _startController = TextEditingController(
    text: '09:00',
  );
  final TextEditingController _endController = TextEditingController(
    text: '18:00',
  );
  final TextEditingController _overtimeStartController = TextEditingController(
    text: '18:00',
  );
  final TextEditingController _nightWorkStartController = TextEditingController(
    text: '22:00',
  );
  final TextEditingController _breakController = TextEditingController(
    text: '60',
  );
  final TextEditingController _includedAfterRegularEndController =
      TextEditingController(text: '0');
  final TextEditingController _memoController = TextEditingController();
  final Set<int> _selectedWeekdays = <int>{
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
  };

  CompensationReferenceMode _mode = CompensationReferenceMode.unknown;
  String? _errorMessage;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _showsWeekdaySelector = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _scrollResetTimer?.cancel();
    _scrollController.dispose();
    _startController.dispose();
    _endController.dispose();
    _overtimeStartController.dispose();
    _nightWorkStartController.dispose();
    _breakController.dispose();
    _includedAfterRegularEndController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final WorkRule? rule = await widget.workRuleRepository.findActive();
      final CompensationReferenceSetting? setting = await widget
          .compensationReferenceRepository
          .findApplicableForMonth(
            year: widget.targetMonth.year,
            month: widget.targetMonth.month,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _applyRule(rule: rule);
        _applyCompensationReferenceSetting(setting: setting);
        _isLoading = false;
      });
      _jumpToTopAfterLoad();
    } on WorkRuleRepositoryException catch (error) {
      _showError('근무 기준을 불러올 수 없습니다. ${error.toString()}');
    } on CompensationReferenceRepositoryException catch (error) {
      _showError('포함 시간 비교를 불러올 수 없습니다. ${error.toString()}');
    }
  }

  void _applyRule({required WorkRule? rule}) {
    if (rule == null) {
      return;
    }
    _startController.text = formatWorkRuleMinuteOfDay(
      minuteOfDay: rule.regularStartTimeMinutes,
    );
    _endController.text = formatWorkRuleMinuteOfDay(
      minuteOfDay: rule.regularEndTimeMinutes,
    );
    _overtimeStartController.text = formatWorkRuleMinuteOfDay(
      minuteOfDay: rule.overtimeStartTimeMinutes,
    );
    _nightWorkStartController.text = formatWorkRuleMinuteOfDay(
      minuteOfDay: rule.nightWorkStartTimeMinutes,
    );
    _breakController.text = rule.breakMinutes.toString();
    _selectedWeekdays
      ..clear()
      ..addAll(rule.workWeekdays);
  }

  void _applyCompensationReferenceSetting({
    required CompensationReferenceSetting? setting,
  }) {
    if (setting == null) {
      return;
    }
    _mode = setting.mode;
    _includedAfterRegularEndController.text = setting
        .fixedIncludedAfterRegularEndMinutes
        .toString();
    _memoController.text = setting.memo ?? '';
  }

  void _applyPreset() {
    setState(() {
      _startController.text = '09:00';
      _endController.text = '18:00';
      _overtimeStartController.text = '18:00';
      _nightWorkStartController.text = '22:00';
      _breakController.text = '60';
      _selectedWeekdays
        ..clear()
        ..addAll(<int>[
          DateTime.monday,
          DateTime.tuesday,
          DateTime.wednesday,
          DateTime.thursday,
          DateTime.friday,
        ]);
      _errorMessage = null;
    });
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    late final int regularStartTimeMinutes;
    late final int regularEndTimeMinutes;
    late final int overtimeStartTimeMinutes;
    late final int nightWorkStartTimeMinutes;
    late final int breakMinutes;
    late final List<int> workWeekdays;
    try {
      regularStartTimeMinutes = parseWorkRuleTimeText(
        text: _startController.text,
        field: 'regularStartTimeMinutes',
      );
      regularEndTimeMinutes = parseWorkRuleTimeText(
        text: _endController.text,
        field: 'regularEndTimeMinutes',
      );
      overtimeStartTimeMinutes = parseWorkRuleTimeText(
        text: _overtimeStartController.text,
        field: 'overtimeStartTimeMinutes',
      );
      nightWorkStartTimeMinutes = parseWorkRuleTimeText(
        text: _nightWorkStartController.text,
        field: 'nightWorkStartTimeMinutes',
      );
      breakMinutes = parseWorkRuleBreakMinutes(text: _breakController.text);
      workWeekdays = _selectedWeekdays.toList(growable: false)..sort();
    } on ArgumentError catch (error) {
      _showError('근무 기준을 저장할 수 없습니다. ${error.message}');
      return;
    } on FormatException catch (error) {
      _showError('근무 기준을 저장할 수 없습니다. ${error.message}');
      return;
    }

    late final int includedAfterRegularEndMinutes;
    try {
      includedAfterRegularEndMinutes = _readMinutes(
        controller: _includedAfterRegularEndController,
        fieldLabel: '정시 이후 고정 포함 시간',
      );
    } on FormatException catch (error) {
      _showError(error.message);
      return;
    }

    try {
      await widget.workRuleRepository.save(
        regularStartTimeMinutes: regularStartTimeMinutes,
        regularEndTimeMinutes: regularEndTimeMinutes,
        overtimeStartTimeMinutes: overtimeStartTimeMinutes,
        nightWorkStartTimeMinutes: nightWorkStartTimeMinutes,
        breakMinutes: breakMinutes,
        workWeekdays: workWeekdays,
      );
    } on WorkRuleRepositoryException catch (error) {
      _showError('근무 기준을 저장할 수 없습니다. ${error.toString()}');
      return;
    }

    try {
      await widget.compensationReferenceRepository.save(
        mode: _mode,
        fixedIncludedAfterRegularEndMinutes:
            _mode == CompensationReferenceMode.fixedIncluded
            ? includedAfterRegularEndMinutes
            : 0,
        effectiveFromMonth: _globalEffectiveFromMonth(),
        memo: _memoController.text,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } on ArgumentError catch (error) {
      _showError('포함 시간 비교를 저장할 수 없습니다. ${error.message}');
    } on CompensationReferenceRepositoryException catch (error) {
      _showError('포함 시간 비교를 저장할 수 없습니다. ${error.toString()}');
    }
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }
    setState(() {
      _errorMessage = message;
      _isLoading = false;
      _isSaving = false;
    });
  }

  int _readMinutes({
    required TextEditingController controller,
    required String fieldLabel,
  }) {
    final String value = controller.text.trim();
    final int? minutes = int.tryParse(value);
    if (minutes == null) {
      throw FormatException('$fieldLabel은 분 단위 숫자로 입력해 주세요.');
    }
    if (minutes < 0) {
      throw FormatException('$fieldLabel은 0 이상으로 입력해 주세요.');
    }
    return minutes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('근무 설정'),
        actions: <Widget>[
          TextButton(
            onPressed: _isLoading || _isSaving ? null : _save,
            child: Text(_isSaving ? '저장 중' : '저장'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: _buildSettingsContent(context: context),
        ),
      ),
    );
  }

  List<Widget> _buildSettingsContent({required BuildContext context}) {
    if (_isLoading) {
      return <Widget>[const Center(child: CircularProgressIndicator())];
    }
    final String? fixedIncludedOvertimeStartWarning =
        _fixedIncludedOvertimeStartWarning();
    return <Widget>[
      _SettingsSection(
        title: '정시 근무',
        children: <Widget>[
          OutlinedButton(
            onPressed: _isSaving ? null : _applyPreset,
            child: const Text('09:00-18:00 빠른 설정'),
          ),
          const SizedBox(height: 12),
          _ParentScrollDragRegion(
            child: TextField(
              controller: _startController,
              decoration: const InputDecoration(labelText: '정시 출근'),
              keyboardType: TextInputType.datetime,
              scrollPhysics: _textFieldScrollPhysics,
            ),
          ),
          const SizedBox(height: 12),
          _ParentScrollDragRegion(
            child: TextField(
              controller: _endController,
              decoration: const InputDecoration(labelText: '정시 퇴근'),
              keyboardType: TextInputType.datetime,
              scrollPhysics: _textFieldScrollPhysics,
              onChanged: _handleTimingInputChanged,
            ),
          ),
          const SizedBox(height: 12),
          _ParentScrollDragRegion(
            child: TextField(
              controller: _breakController,
              decoration: const InputDecoration(labelText: '휴게시간(분)'),
              keyboardType: TextInputType.number,
              scrollPhysics: _textFieldScrollPhysics,
            ),
          ),
        ],
      ),
      const SizedBox(height: 18),
      _SettingsSection(
        title: '포함 시간 비교',
        children: <Widget>[
          RadioGroup<CompensationReferenceMode>(
            groupValue: _mode,
            onChanged: _changeMode,
            child: Column(
              children: <Widget>[
                _ModeTile(
                  title: '고정 포함 시간 없음',
                  value: CompensationReferenceMode.none,
                  selectedMode: _mode,
                ),
                _ModeTile(
                  title: '고정 포함 시간 있음',
                  value: CompensationReferenceMode.fixedIncluded,
                  selectedMode: _mode,
                ),
                _ModeTile(
                  title: '잘 모르겠음',
                  value: CompensationReferenceMode.unknown,
                  selectedMode: _mode,
                ),
              ],
            ),
          ),
          if (_mode == CompensationReferenceMode.fixedIncluded)
            _FixedIncludedFields(
              afterRegularEndMinutesController:
                  _includedAfterRegularEndController,
            ),
          _ParentScrollDragRegion(
            child: TextField(
              controller: _memoController,
              decoration: const InputDecoration(
                labelText: '메모',
                helperText: '선택 입력',
              ),
              maxLines: 3,
              maxLength: 500,
              scrollPhysics: _textFieldScrollPhysics,
            ),
          ),
        ],
      ),
      const SizedBox(height: 18),
      _SettingsSection(
        title: '고급 설정',
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '근무 요일',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: const Color(0xFF181D26),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatWorkRuleWeekdays(weekdays: _selectedWeekdays),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF5F6673),
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 82,
                child: OutlinedButton(
                  onPressed: _isSaving ? null : _toggleWeekdaySelector,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    padding: EdgeInsets.zero,
                  ),
                  child: Text(_showsWeekdaySelector ? '닫기' : '변경'),
                ),
              ),
            ],
          ),
          if (_showsWeekdaySelector) ...<Widget>[
            const SizedBox(height: 14),
            _WeekdaySelector(
              selectedWeekdays: _selectedWeekdays,
              enabled: !_isSaving,
              onChanged: _changeWeekdaySelection,
            ),
          ],
        ],
      ),
      const SizedBox(height: 18),
      _SettingsSection(
        title: '근무 태그 기준',
        children: <Widget>[
          Text(
            '정시 전 근무는 정시 출근 전 구간입니다.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF5F6673),
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 12),
          _ParentScrollDragRegion(
            child: TextField(
              controller: _overtimeStartController,
              decoration: InputDecoration(
                labelText: '연장 근무 시작',
                helperText: _overtimeStartHelperText(),
              ),
              keyboardType: TextInputType.datetime,
              scrollPhysics: _textFieldScrollPhysics,
              onChanged: _handleTimingInputChanged,
            ),
          ),
          if (fixedIncludedOvertimeStartWarning != null) ...<Widget>[
            const SizedBox(height: 10),
            _SettingsNotice(message: fixedIncludedOvertimeStartWarning),
          ],
          const SizedBox(height: 12),
          _ParentScrollDragRegion(
            child: TextField(
              controller: _nightWorkStartController,
              decoration: const InputDecoration(
                labelText: '야간 근무 시작',
                helperText: '예: 22:00부터 8시간',
              ),
              keyboardType: TextInputType.datetime,
              scrollPhysics: _textFieldScrollPhysics,
            ),
          ),
        ],
      ),
      if (_errorMessage != null) ...<Widget>[
        const SizedBox(height: 16),
        _SettingsMessage(message: _errorMessage!),
      ],
    ];
  }

  void _jumpToTopAfterLoad() {
    _scrollResetTimer?.cancel();
    FocusManager.instance.primaryFocus?.unfocus();
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      _jumpToTop();
    });
    _scrollResetTimer = Timer(const Duration(milliseconds: 350), _jumpToTop);
  }

  void _jumpToTop() {
    if (mounted && _scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  void _changeWeekdaySelection({required int weekday, required bool selected}) {
    setState(() {
      if (selected) {
        _selectedWeekdays.add(weekday);
      } else {
        _selectedWeekdays.remove(weekday);
      }
    });
  }

  void _toggleWeekdaySelector() {
    setState(() {
      _showsWeekdaySelector = !_showsWeekdaySelector;
    });
  }

  void _changeMode(CompensationReferenceMode? mode) {
    if (mode == null) {
      return;
    }
    setState(() {
      _mode = mode;
      _errorMessage = null;
    });
  }

  void _handleTimingInputChanged(String value) {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  String _overtimeStartHelperText() {
    if (_mode == CompensationReferenceMode.fixedIncluded) {
      return '보통 정시 퇴근과 같습니다. 포함 시간은 위에서 입력';
    }
    return '정시 퇴근 이후만 입력';
  }

  String? _fixedIncludedOvertimeStartWarning() {
    if (_mode != CompensationReferenceMode.fixedIncluded) {
      return null;
    }
    final int? regularEndTimeMinutes = _tryParseTimeText(
      text: _endController.text,
      field: 'regularEndTimeMinutes',
    );
    final int? overtimeStartTimeMinutes = _tryParseTimeText(
      text: _overtimeStartController.text,
      field: 'overtimeStartTimeMinutes',
    );
    if (regularEndTimeMinutes == null || overtimeStartTimeMinutes == null) {
      return null;
    }
    if (overtimeStartTimeMinutes <= regularEndTimeMinutes) {
      return null;
    }
    return _fixedIncludedOvertimeStartWarningMessage;
  }
}

DateTime _globalEffectiveFromMonth() {
  return DateTime(2000);
}

int? _tryParseTimeText({required String text, required String field}) {
  try {
    return parseWorkRuleTimeText(text: text, field: field);
  } on ArgumentError {
    return null;
  } on FormatException {
    return null;
  }
}

final List<int> _allWeekdays = <int>[
  DateTime.monday,
  DateTime.tuesday,
  DateTime.wednesday,
  DateTime.thursday,
  DateTime.friday,
  DateTime.saturday,
  DateTime.sunday,
];

String formatWorkRuleWeekdays({required Set<int> weekdays}) {
  if (_hasSameWeekdays(
    weekdays: weekdays,
    expected: <int>[
      DateTime.monday,
      DateTime.tuesday,
      DateTime.wednesday,
      DateTime.thursday,
      DateTime.friday,
    ],
  )) {
    return '월-금';
  }
  final List<int> sortedWeekdays = weekdays.toList(growable: false)..sort();
  if (sortedWeekdays.isEmpty) {
    return '선택 없음';
  }
  return sortedWeekdays
      .map((int weekday) => formatWorkRuleWeekday(weekday: weekday))
      .join(', ');
}

bool _hasSameWeekdays({
  required Set<int> weekdays,
  required List<int> expected,
}) {
  if (weekdays.length != expected.length) {
    return false;
  }
  for (final int weekday in expected) {
    if (!weekdays.contains(weekday)) {
      return false;
    }
  }
  return true;
}

final class _ParentScrollDragRegion extends StatelessWidget {
  const _ParentScrollDragRegion({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerMove: (PointerMoveEvent event) {
        final ScrollableState? scrollable = Scrollable.maybeOf(context);
        if (scrollable == null) {
          return;
        }
        final ScrollPosition position = scrollable.position;
        final double nextPixels = (position.pixels - event.delta.dy)
            .clamp(position.minScrollExtent, position.maxScrollExtent)
            .toDouble();
        if (nextPixels == position.pixels) {
          return;
        }
        position.jumpTo(nextPixels);
      },
      child: child,
    );
  }
}

final class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFEAEAEA)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFF181D26),
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}

final class _WeekdaySelector extends StatelessWidget {
  const _WeekdaySelector({
    required this.selectedWeekdays,
    required this.enabled,
    required this.onChanged,
  });

  final Set<int> selectedWeekdays;
  final bool enabled;
  final void Function({required int weekday, required bool selected}) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '근무 요일',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: const Color(0xFF181D26),
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final int weekday in _allWeekdays)
              FilterChip(
                label: Text(formatWorkRuleWeekday(weekday: weekday)),
                selected: selectedWeekdays.contains(weekday),
                onSelected: enabled
                    ? (bool selected) =>
                          onChanged(weekday: weekday, selected: selected)
                    : null,
              ),
          ],
        ),
      ],
    );
  }
}

final class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.title,
    required this.value,
    required this.selectedMode,
  });

  final String title;
  final CompensationReferenceMode value;
  final CompensationReferenceMode selectedMode;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: RadioListTile<CompensationReferenceMode>(
        title: Text(title),
        value: value,
        selected: value == selectedMode,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}

final class _FixedIncludedFields extends StatelessWidget {
  const _FixedIncludedFields({required this.afterRegularEndMinutesController});

  final TextEditingController afterRegularEndMinutesController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const SizedBox(height: 12),
        _MinutesField(
          controller: afterRegularEndMinutesController,
          label: '정시 이후 고정 포함 시간',
        ),
      ],
    );
  }
}

final class _MinutesField extends StatelessWidget {
  const _MinutesField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return _ParentScrollDragRegion(
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: '$label(분)',
          helperText: '예: 120분 = 정시 후 2시간',
        ),
        keyboardType: TextInputType.number,
        scrollPhysics: _textFieldScrollPhysics,
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.digitsOnly,
        ],
      ),
    );
  }
}

final class _SettingsMessage extends StatelessWidget {
  const _SettingsMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFDDDDDD)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF181D26),
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

final class _SettingsNotice extends StatelessWidget {
  const _SettingsNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        border: Border.all(color: const Color(0xFFF5D48A)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: const Color(0xFF6B4E16),
            letterSpacing: 0,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}
