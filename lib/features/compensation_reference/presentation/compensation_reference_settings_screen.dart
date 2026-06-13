import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/models/compensation_reference_setting.dart';
import '../domain/compensation_reference_repository.dart';

final class CompensationReferenceSettingsScreen extends StatefulWidget {
  const CompensationReferenceSettingsScreen({
    required this.repository,
    required this.targetMonth,
    super.key,
  });

  final CompensationReferenceRepository repository;
  final DateTime targetMonth;

  @override
  State<CompensationReferenceSettingsScreen> createState() =>
      _CompensationReferenceSettingsScreenState();
}

final class _CompensationReferenceSettingsScreenState
    extends State<CompensationReferenceSettingsScreen> {
  final TextEditingController _overtimeMinutesController =
      TextEditingController(text: '0');
  final TextEditingController _nightMinutesController = TextEditingController(
    text: '0',
  );
  final TextEditingController _holidayMinutesController = TextEditingController(
    text: '0',
  );
  final TextEditingController _effectiveMonthController =
      TextEditingController();
  final TextEditingController _memoController = TextEditingController();

  CompensationReferenceMode _mode = CompensationReferenceMode.unknown;
  String? _errorMessage;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _effectiveMonthController.text = formatCompensationReferenceMonth(
      month: normalizeCompensationReferenceMonth(
        effectiveFromMonth: widget.targetMonth,
      ),
    );
    _loadSetting();
  }

  @override
  void dispose() {
    _overtimeMinutesController.dispose();
    _nightMinutesController.dispose();
    _holidayMinutesController.dispose();
    _effectiveMonthController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _loadSetting() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final CompensationReferenceSetting? setting = await widget.repository
          .findApplicableForMonth(
            year: widget.targetMonth.year,
            month: widget.targetMonth.month,
          );
      if (!mounted) {
        return;
      }
      if (setting != null) {
        _mode = setting.mode;
        _overtimeMinutesController.text = setting.fixedIncludedOvertimeMinutes
            .toString();
        _nightMinutesController.text = setting.fixedIncludedNightMinutes
            .toString();
        _holidayMinutesController.text = setting.fixedIncludedHolidayMinutes
            .toString();
        _effectiveMonthController.text = formatCompensationReferenceMonth(
          month: setting.effectiveFromMonth,
        );
        _memoController.text = setting.memo ?? '';
      }
      setState(() {
        _isLoading = false;
      });
    } on CompensationReferenceRepositoryException catch (error) {
      _showError('비교 방식을 불러올 수 없습니다. ${error.toString()}');
    }
  }

  Future<void> _saveSetting() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      final DateTime effectiveMonth = parseCompensationReferenceMonth(
        value: _effectiveMonthController.text,
      );
      final int overtimeMinutes = _readMinutes(
        controller: _overtimeMinutesController,
        fieldLabel: '연장 근무 포함 시간',
      );
      final int nightMinutes = _readMinutes(
        controller: _nightMinutesController,
        fieldLabel: '야간 근무 포함 시간',
      );
      final int holidayMinutes = _readMinutes(
        controller: _holidayMinutesController,
        fieldLabel: '휴무일 근무 포함 시간',
      );
      await widget.repository.save(
        mode: _mode,
        fixedIncludedOvertimeMinutes:
            _mode == CompensationReferenceMode.fixedIncluded
            ? overtimeMinutes
            : 0,
        fixedIncludedNightMinutes:
            _mode == CompensationReferenceMode.fixedIncluded ? nightMinutes : 0,
        fixedIncludedHolidayMinutes:
            _mode == CompensationReferenceMode.fixedIncluded
            ? holidayMinutes
            : 0,
        effectiveFromMonth: effectiveMonth,
        memo: _memoController.text,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } on FormatException catch (error) {
      _showError(error.message);
    } on ArgumentError catch (error) {
      _showError('비교 방식을 저장할 수 없습니다. ${error.message}');
    } on CompensationReferenceRepositoryException catch (error) {
      _showError('비교 방식을 저장할 수 없습니다. ${error.toString()}');
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
      appBar: AppBar(title: const Text('비교 방식')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else ...<Widget>[
                Text(
                  '고정 포함 시간 비교',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: const Color(0xFF181D26),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '입력한 시간은 실제 기록과 비교하는 개인 참고용입니다. 회사 기준이나 전문가 확인을 대신하지 않습니다.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF41454D),
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 18),
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
                    overtimeMinutesController: _overtimeMinutesController,
                    nightMinutesController: _nightMinutesController,
                    holidayMinutesController: _holidayMinutesController,
                  ),
                const SizedBox(height: 14),
                TextField(
                  controller: _effectiveMonthController,
                  decoration: const InputDecoration(
                    labelText: '적용 시작 월',
                    helperText: '예: 2026-06',
                  ),
                  keyboardType: TextInputType.datetime,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _memoController,
                  decoration: const InputDecoration(
                    labelText: '메모',
                    helperText: '선택 입력',
                  ),
                  maxLines: 3,
                  maxLength: 500,
                ),
                if (_errorMessage != null) ...<Widget>[
                  const SizedBox(height: 10),
                  Text(
                    _errorMessage!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFFAA2D00),
                      letterSpacing: 0,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: _isSaving ? null : _saveSetting,
                  child: Text(_isSaving ? '저장 중' : '저장'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
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
    return RadioListTile<CompensationReferenceMode>(
      title: Text(title),
      value: value,
      selected: value == selectedMode,
      contentPadding: EdgeInsets.zero,
    );
  }
}

final class _FixedIncludedFields extends StatelessWidget {
  const _FixedIncludedFields({
    required this.overtimeMinutesController,
    required this.nightMinutesController,
    required this.holidayMinutesController,
  });

  final TextEditingController overtimeMinutesController;
  final TextEditingController nightMinutesController;
  final TextEditingController holidayMinutesController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const SizedBox(height: 12),
        _MinutesField(
          controller: overtimeMinutesController,
          label: '연장 근무 포함 시간',
        ),
        const SizedBox(height: 12),
        _MinutesField(controller: nightMinutesController, label: '야간 근무 포함 시간'),
        const SizedBox(height: 12),
        _MinutesField(
          controller: holidayMinutesController,
          label: '휴무일 근무 포함 시간',
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
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: '$label(분)',
        helperText: '0 이상 숫자',
      ),
      keyboardType: TextInputType.number,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
      ],
    );
  }
}

String formatCompensationReferenceMonth({required DateTime month}) {
  final String paddedMonth = month.month.toString().padLeft(2, '0');
  return '${month.year}-$paddedMonth';
}

DateTime parseCompensationReferenceMonth({required String value}) {
  final RegExpMatch? match = RegExp(
    r'^(\d{4})-(\d{2})$',
  ).firstMatch(value.trim());
  if (match == null) {
    throw const FormatException('적용 시작 월은 YYYY-MM 형식으로 입력해 주세요.');
  }
  final int year = int.parse(match.group(1)!);
  final int month = int.parse(match.group(2)!);
  if (year < 2000 || year > 2100 || month < 1 || month > 12) {
    throw FormatException('적용 시작 월 값이 올바르지 않습니다. value=$value');
  }
  return DateTime(year, month);
}
