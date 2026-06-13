import 'package:flutter/material.dart';

import '../../../core/models/work_record.dart';
import '../domain/update_today_work_record.dart';
import '../domain/work_record_repository.dart';
import 'work_record_home_screen.dart';

final class EditTodayWorkRecordScreen extends StatefulWidget {
  const EditTodayWorkRecordScreen({
    required this.repository,
    required this.now,
    super.key,
  });

  final WorkRecordRepository repository;
  final DateTime Function() now;

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
      final WorkRecord? record = await widget.repository.findToday();
      if (!mounted) {
        return;
      }
      if (record == null) {
        setState(() {
          _record = null;
          _isLoading = false;
          _errorMessage = '수정할 오늘 기록이 없습니다.';
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
    final WorkRecord? record = _record;
    if (record == null) {
      _showError('수정할 오늘 기록이 없습니다.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final DateTime? clockInAt = parseClockInput(
        value: _clockInController.text,
        workDate: record.workDate,
        fieldLabel: '출근 시각',
      );
      final DateTime? clockOutAt = parseClockInput(
        value: _clockOutController.text,
        workDate: record.workDate,
        fieldLabel: '퇴근 시각',
      );
      final String memoText = _memoController.text.trim();
      await updateTodayWorkRecord(
        repository: widget.repository,
        input: UpdateTodayWorkRecordInput(
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
    } on UpdateTodayWorkRecordException {
      _showError('저장할 수 없습니다. 퇴근 시각은 출근 시각보다 빠를 수 없습니다.');
    } on WorkRecordRepositoryException catch (error) {
      _showError('저장할 수 없습니다. ${error.message}');
    } on ArgumentError catch (error) {
      _showError('저장할 수 없습니다. ${error.message}');
    }
  }

  Future<void> _deleteRecord() async {
    final WorkRecord? record = _record;
    if (record == null) {
      _showError('삭제할 오늘 기록이 없습니다.');
      return;
    }

    final bool confirmed = await _confirmTodayRecordDeletion(context: context);
    if (!confirmed) {
      return;
    }

    setState(() {
      _isDeleting = true;
      _errorMessage = null;
    });

    try {
      await widget.repository.deleteToday();
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('오늘 기록 수정'),
        actions: <Widget>[
          TextButton(
            onPressed: _isLoading || _isSaving || _isDeleting || record == null
                ? null
                : _saveRecord,
            child: const Text('저장'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (record != null) ...<Widget>[
                _ReadOnlyValue(
                  label: '근무일',
                  value: formatDateOnly(record.workDate),
                ),
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
                const SizedBox(height: 18),
                Text(
                  '기록 사유',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF181D26),
                    fontWeight: FontWeight.w600,
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
                          label: Text(recordReasonLabel(tag: tag)),
                          selected: _selectedTags.contains(tag),
                          onSelected: (bool selected) => _toggleTag(tag),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 18),
                _MemoField(controller: _memoController),
                const SizedBox(height: 22),
                FilledButton(
                  onPressed: _isSaving || _isDeleting ? null : _saveRecord,
                  child: const Text('저장'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: _isSaving || _isDeleting ? null : _deleteRecord,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFAA2D00),
                  ),
                  child: const Text('오늘 기록 삭제'),
                ),
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

Future<bool> _confirmTodayRecordDeletion({
  required BuildContext context,
}) async {
  final bool? result = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('오늘 기록을 삭제할까요?'),
        content: const Text('삭제하면 오늘 출근/퇴근 기록과 메모가 없어집니다.'),
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
            color: const Color(0xFF181D26),
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFDDDDDD)),
            borderRadius: BorderRadius.circular(6),
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
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

String formatNullableClockTime({required DateTime? value}) {
  if (value == null) {
    return '';
  }
  return formatClockTime(value: value);
}

String formatDateOnly(DateTime value) {
  final String year = value.year.toString().padLeft(4, '0');
  final String month = value.month.toString().padLeft(2, '0');
  final String day = value.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

const List<WorkRecordTag> editableWorkRecordReasonTags = <WorkRecordTag>[
  WorkRecordTag.delayedCheckout,
];

String recordReasonLabel({required WorkRecordTag tag}) {
  return switch (tag) {
    WorkRecordTag.delayedCheckout => '퇴근 기록 지연',
    WorkRecordTag.overtime ||
    WorkRecordTag.holidayWork => throw ArgumentError.value(
      tag,
      'tag',
      'must be an editable work record reason tag',
    ),
  };
}
