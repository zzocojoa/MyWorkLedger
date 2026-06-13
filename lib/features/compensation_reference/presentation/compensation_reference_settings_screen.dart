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
  final TextEditingController _memoController = TextEditingController();

  CompensationReferenceMode _mode = CompensationReferenceMode.unknown;
  String? _errorMessage;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSetting();
  }

  @override
  void dispose() {
    _overtimeMinutesController.dispose();
    _nightMinutesController.dispose();
    _holidayMinutesController.dispose();
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
        effectiveFromMonth: _globalEffectiveFromMonth(),
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

DateTime _globalEffectiveFromMonth() {
  return DateTime(2000);
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
