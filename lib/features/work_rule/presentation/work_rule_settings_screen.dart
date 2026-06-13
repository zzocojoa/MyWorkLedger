import 'package:flutter/material.dart';

import '../domain/work_rule_repository.dart';

final class WorkRuleSettingsScreen extends StatefulWidget {
  const WorkRuleSettingsScreen({required this.repository, super.key});

  final WorkRuleRepository repository;

  @override
  State<WorkRuleSettingsScreen> createState() => _WorkRuleSettingsScreenState();
}

final class _WorkRuleSettingsScreenState extends State<WorkRuleSettingsScreen> {
  final TextEditingController _startController = TextEditingController(
    text: '09:00',
  );
  final TextEditingController _endController = TextEditingController(
    text: '18:00',
  );
  final TextEditingController _breakController = TextEditingController(
    text: '60',
  );
  final Set<int> _selectedWeekdays = <int>{
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
  };
  String? _errorMessage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadExistingRule();
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    _breakController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingRule() async {
    try {
      final rule = await widget.repository.findActive();
      if (rule == null || !mounted) {
        return;
      }
      setState(() {
        _startController.text = formatWorkRuleMinuteOfDay(
          minuteOfDay: rule.regularStartTimeMinutes,
        );
        _endController.text = formatWorkRuleMinuteOfDay(
          minuteOfDay: rule.regularEndTimeMinutes,
        );
        _breakController.text = rule.breakMinutes.toString();
        _selectedWeekdays
          ..clear()
          ..addAll(rule.workWeekdays);
      });
    } on WorkRuleRepositoryException catch (error) {
      _showError('근무 기준을 불러올 수 없습니다. ${error.toString()}');
    }
  }

  void _applyPreset() {
    setState(() {
      _startController.text = '09:00';
      _endController.text = '18:00';
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

    try {
      await widget.repository.save(
        regularStartTimeMinutes: parseWorkRuleTimeText(
          text: _startController.text,
          field: 'regularStartTimeMinutes',
        ),
        regularEndTimeMinutes: parseWorkRuleTimeText(
          text: _endController.text,
          field: 'regularEndTimeMinutes',
        ),
        breakMinutes: parseWorkRuleBreakMinutes(text: _breakController.text),
        workWeekdays: _selectedWeekdays.toList(growable: false)..sort(),
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } on WorkRuleRepositoryException catch (error) {
      _showError('근무 기준을 저장할 수 없습니다. ${error.toString()}');
    } on ArgumentError catch (error) {
      _showError('근무 기준을 저장할 수 없습니다. ${error.message}');
    } on FormatException catch (error) {
      _showError('근무 기준을 저장할 수 없습니다. ${error.message}');
    }
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }
    setState(() {
      _errorMessage = message;
      _isSaving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('근무 기준 설정')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              OutlinedButton(
                onPressed: _isSaving ? null : _applyPreset,
                child: const Text('09:00-18:00 빠른 설정'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _startController,
                decoration: const InputDecoration(labelText: '정시 출근'),
                keyboardType: TextInputType.datetime,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _endController,
                decoration: const InputDecoration(labelText: '정시 퇴근'),
                keyboardType: TextInputType.datetime,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _breakController,
                decoration: const InputDecoration(labelText: '휴게시간(분)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 18),
              Text(
                '평일 근무 요일',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                      selected: _selectedWeekdays.contains(weekday),
                      onSelected: _isSaving
                          ? null
                          : (bool selected) {
                              setState(() {
                                if (selected) {
                                  _selectedWeekdays.add(weekday);
                                } else {
                                  _selectedWeekdays.remove(weekday);
                                }
                              });
                            },
                    ),
                ],
              ),
              if (_errorMessage != null) ...<Widget>[
                const SizedBox(height: 16),
                _WorkRuleMessage(message: _errorMessage!),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isSaving ? null : _save,
                child: const Text('저장'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: _isSaving
                    ? null
                    : () => Navigator.of(context).pop(false),
                child: const Text('나중에'),
              ),
            ],
          ),
        ),
      ),
    );
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

int parseWorkRuleTimeText({required String text, required String field}) {
  final RegExp pattern = RegExp(r'^(\d{1,2}):(\d{2})$');
  final RegExpMatch? match = pattern.firstMatch(text.trim());
  if (match == null) {
    throw FormatException('field=$field value=$text rule=HH:mm');
  }
  final int hour = int.parse(match.group(1)!);
  final int minute = int.parse(match.group(2)!);
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
    throw FormatException('field=$field value=$text rule=valid time');
  }
  return hour * 60 + minute;
}

int parseWorkRuleBreakMinutes({required String text}) {
  final int? value = int.tryParse(text.trim());
  if (value == null) {
    throw FormatException('field=breakMinutes value=$text rule=int minutes');
  }
  return value;
}

String formatWorkRuleMinuteOfDay({required int minuteOfDay}) {
  if (minuteOfDay < 0 || minuteOfDay > 1439) {
    throw ArgumentError.value(
      minuteOfDay,
      'minuteOfDay',
      'must be between 0 and 1439',
    );
  }
  final String hour = (minuteOfDay ~/ 60).toString().padLeft(2, '0');
  final String minute = minuteOfDay.remainder(60).toString().padLeft(2, '0');
  return '$hour:$minute';
}

String formatWorkRuleWeekday({required int weekday}) {
  return switch (weekday) {
    DateTime.monday => '월',
    DateTime.tuesday => '화',
    DateTime.wednesday => '수',
    DateTime.thursday => '목',
    DateTime.friday => '금',
    DateTime.saturday => '토',
    DateTime.sunday => '일',
    _ => throw ArgumentError.value(weekday, 'weekday', 'must be 1-7'),
  };
}

final class _WorkRuleMessage extends StatelessWidget {
  const _WorkRuleMessage({required this.message});

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
