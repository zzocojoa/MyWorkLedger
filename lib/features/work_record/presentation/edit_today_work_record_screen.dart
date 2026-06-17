import 'package:flutter/material.dart';

import '../../../core/theme/workledger_design_tokens.dart';

import '../../../core/models/work_record.dart';
import '../domain/save_work_record.dart';
import '../domain/work_record_repository.dart';
import 'work_record_formatters.dart';

final class EditTodayWorkRecordScreen extends StatefulWidget {
  const EditTodayWorkRecordScreen({
    required this.repository,
    required this.now,
    required this.workDate,
    super.key,
  });

  final WorkRecordRepository repository;
  final DateTime Function() now;
  final DateTime workDate;

  @override
  State<EditTodayWorkRecordScreen> createState() =>
      _EditTodayWorkRecordScreenState();
}

final class _EditTodayWorkRecordScreenState
    extends State<EditTodayWorkRecordScreen> {
  final TextEditingController _clockInController = TextEditingController();
  final TextEditingController _clockOutController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();
  final Set<WorkRecordTag> _selectedTags = <WorkRecordTag>{};

  WorkRecord? _record;
  String? _errorMessage;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadRecord();
  }

  @override
  void dispose() {
    _clockInController.dispose();
    _clockOutController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _loadRecord() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final DateTime targetDate = _dateOnly(widget.workDate);
      final WorkRecord? record = await widget.repository.findByDate(
        workDate: targetDate,
      );
      if (!mounted) {
        return;
      }
      if (record == null) {
        _clockInController.clear();
        _clockOutController.clear();
        _memoController.clear();
        _selectedTags.clear();
        setState(() {
          _record = null;
          _isLoading = false;
        });
        return;
      }
      _clockInController.text = formatNullableClockTime(
        value: record.clockInAt,
      );
      _clockOutController.text = formatNullableClockTime(
        value: record.clockOutAt,
      );
      _memoController.text = record.memo ?? '';
      _selectedTags
        ..clear()
        ..addAll(record.tags);
      setState(() {
        _record = record;
        _isLoading = false;
      });
    } on WorkRecordRepositoryException catch (error) {
      _showError('기록을 불러올 수 없습니다. ${error.message}');
    }
  }

  Future<void> _saveRecord() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final DateTime targetDate = _dateOnly(widget.workDate);
      final DateTime? clockInAt = parseClockInput(
        value: _clockInController.text,
        workDate: targetDate,
        fieldLabel: '출근 시각',
      );
      final DateTime? clockOutAt = parseClockInput(
        value: _clockOutController.text,
        workDate: targetDate,
        fieldLabel: '퇴근 시각',
      );
      final String memoText = _memoController.text.trim();
      await saveWorkRecord(
        repository: widget.repository,
        input: SaveWorkRecordInput(
          workDate: targetDate,
          clockInAt: clockInAt,
          clockOutAt: clockOutAt,
          tags: _selectedTags.toList(),
          memo: memoText.isEmpty ? null : memoText,
        ),
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } on EditTodayWorkRecordFormException catch (error) {
      _showError(error.message);
    } on SaveWorkRecordException catch (error) {
      _showError(_saveWorkRecordErrorMessage(error: error));
    } on WorkRecordRepositoryException catch (error) {
      _showError('저장할 수 없습니다. ${error.message}');
    } on ArgumentError catch (error) {
      _showError('저장할 수 없습니다. ${error.message}');
    }
  }

  Future<void> _deleteRecord() async {
    final WorkRecord? record = _record;
    if (record == null) {
      _showError('삭제할 기록이 없습니다.');
      return;
    }

    final bool confirmed = await _confirmWorkRecordDeletion(context: context);
    if (!confirmed) {
      return;
    }

    setState(() {
      _isDeleting = true;
      _errorMessage = null;
    });

    try {
      await widget.repository.deleteByDate(workDate: record.workDate);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } on WorkRecordRepositoryException catch (error) {
      _showError('삭제할 수 없습니다. ${error.message}');
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
      _isDeleting = false;
    });
  }

  void _toggleTag(WorkRecordTag tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final WorkRecord? record = _record;
    final DateTime targetDate = _dateOnly(widget.workDate);
    final String title = record == null ? '기록 추가' : '근무 기록 수정';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: <Widget>[
          TextButton(
            onPressed: _isLoading || _isSaving || _isDeleting
                ? null
                : _saveRecord,
            child: const Text('저장'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            workLedgerSpacingLarge,
            workLedgerSpacingExtraSmall,
            workLedgerSpacingLarge,
            workLedgerSpacingLarge,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else ...<Widget>[
                _ReadOnlyValue(label: '근무일', value: formatDateOnly(targetDate)),
                const SizedBox(height: 16),
                _TimeField(
                  key: const Key('clockInTimeField'),
                  label: '출근 시각',
                  controller: _clockInController,
                ),
                const SizedBox(height: 16),
                _TimeField(
                  key: const Key('clockOutTimeField'),
                  label: '퇴근 시각',
                  controller: _clockOutController,
                ),
                const SizedBox(height: workLedgerSpacingMedium),
                Text(
                  '기록 사유',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: workLedgerColorInk,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: editableWorkRecordReasonTags
                      .map(
                        (WorkRecordTag tag) => FilterChip(
                          label: Text(formatEditableWorkRecordReason(tag: tag)),
                          selected: _selectedTags.contains(tag),
                          onSelected: (bool selected) => _toggleTag(tag),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: workLedgerSpacingMedium),
                _MemoField(controller: _memoController),
                const SizedBox(height: workLedgerSpacingLarge),
                FilledButton(
                  onPressed: _isSaving || _isDeleting ? null : _saveRecord,
                  child: const Text('저장'),
                ),
                if (record != null) ...<Widget>[
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: _isSaving || _isDeleting ? null : _deleteRecord,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: workLedgerColorSignatureCoral,
                    ),
                    child: const Text('기록 삭제'),
                  ),
                ],
              ],
              if (_errorMessage != null) ...<Widget>[
                const SizedBox(height: 16),
                _ErrorBox(message: _errorMessage!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String _saveWorkRecordErrorMessage({required SaveWorkRecordException error}) {
  final String message = error.message;
  if (message.contains('field=clockOutAt')) {
    return '저장할 수 없습니다. 퇴근 시각은 출근 시각보다 빠를 수 없습니다.';
  }
  if (message.contains('field=memo')) {
    return '저장할 수 없습니다. 메모는 500자 이하로 입력하세요.';
  }
  return '저장할 수 없습니다. $message';
}

Future<bool> _confirmWorkRecordDeletion({required BuildContext context}) async {
  final bool? result = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('기록을 삭제할까요?'),
        content: const Text('삭제하면 선택한 날짜의 출근/퇴근 기록과 메모가 없어집니다.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제'),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

DateTime _dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

final class _ReadOnlyValue extends StatelessWidget {
  const _ReadOnlyValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: workLedgerColorInk,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            color: workLedgerColorCanvas,
            border: Border.all(color: workLedgerColorHairline),
            borderRadius: BorderRadius.circular(workLedgerRadiusSmall),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            child: Text(value),
          ),
        ),
      ],
    );
  }
}

final class _TimeField extends StatelessWidget {
  const _TimeField({required this.label, required this.controller, super.key});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.datetime,
      decoration: InputDecoration(
        labelText: label,
        hintText: '09:03',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(workLedgerRadiusSmall),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
    );
  }
}

final class _MemoField extends StatelessWidget {
  const _MemoField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: 3,
      maxLines: 5,
      decoration: InputDecoration(
        labelText: '메모',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(workLedgerRadiusSmall),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
    );
  }
}

final class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: workLedgerColorSurfaceSoft,
        border: Border.all(color: workLedgerColorHairline),
        borderRadius: BorderRadius.circular(workLedgerRadiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(workLedgerSpacingMedium),
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: workLedgerColorInk,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

final class EditTodayWorkRecordFormException implements Exception {
  const EditTodayWorkRecordFormException(this.message);

  final String message;
}

DateTime? parseClockInput({
  required String value,
  required DateTime workDate,
  required String fieldLabel,
}) {
  final String trimmedValue = value.trim();
  if (trimmedValue.isEmpty) {
    return null;
  }
  final RegExpMatch? match = RegExp(
    r'^([01]\d|2[0-3]):([0-5]\d)$',
  ).firstMatch(trimmedValue);
  if (match == null) {
    throw EditTodayWorkRecordFormException('$fieldLabel은 HH:mm 형식으로 입력해주세요.');
  }
  return DateTime(
    workDate.year,
    workDate.month,
    workDate.day,
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
  );
}
