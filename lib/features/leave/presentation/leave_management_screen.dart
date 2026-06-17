import 'package:flutter/material.dart';

import '../../../core/theme/workledger_design_tokens.dart';

import '../../../core/models/leave_usage.dart';
import '../domain/add_leave_usage.dart';
import '../domain/leave_repository.dart';
import '../domain/leave_summary.dart';
import '../domain/load_leave_summary.dart';

final class LeaveManagementScreen extends StatefulWidget {
  const LeaveManagementScreen({
    required this.repository,
    required this.now,
    super.key,
  });

  final LeaveRepository repository;
  final DateTime Function() now;

  @override
  State<LeaveManagementScreen> createState() => _LeaveManagementScreenState();
}

final class _LeaveManagementScreenState extends State<LeaveManagementScreen> {
  late final int _year;
  final TextEditingController _usageDateController = TextEditingController();
  final TextEditingController _usageDaysController = TextEditingController();
  final TextEditingController _usageHoursController = TextEditingController();
  final TextEditingController _usageMemoController = TextEditingController();
  LeaveSummary? _summary;
  String? _errorMessage;
  bool _isLoading = true;
  bool _isDeletingUsage = false;

  @override
  void initState() {
    super.initState();
    final DateTime value = widget.now();
    _year = value.year;
    _usageDateController.text = _formatDateInput(value: value);
    _loadSummary();
  }

  @override
  void dispose() {
    _usageDateController.dispose();
    _usageDaysController.dispose();
    _usageHoursController.dispose();
    _usageMemoController.dispose();
    super.dispose();
  }

  Future<void> _loadSummary() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final LeaveSummary summary = await loadLeaveSummary(
        repository: widget.repository,
        year: _year,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    } on LeaveRepositoryException catch (error) {
      _showError('연차 정보를 불러올 수 없습니다. ${error.toString()}');
    } on LeaveSummaryException catch (error) {
      _showError('연차 요약을 계산할 수 없습니다. ${error.toString()}');
    }
  }

  Future<void> _addUsage() async {
    try {
      final DateTime usedOn = parseDateInput(text: _usageDateController.text);
      final int usedLeaveMinutes = parseLeaveMinutesInput(
        daysText: _usageDaysController.text,
        hoursText: _usageHoursController.text,
        allowZero: false,
      );
      await addLeaveUsage(
        repository: widget.repository,
        usedOn: usedOn,
        usedLeaveMinutes: usedLeaveMinutes,
        memo: _normalizeMemo(value: _usageMemoController.text),
      );
      _usageDaysController.clear();
      _usageHoursController.clear();
      _usageMemoController.clear();
      await _loadSummary();
    } on FormatException catch (error) {
      _showError('연차 사용을 추가할 수 없습니다. ${error.message}');
    } on ArgumentError catch (error) {
      _showError('연차 사용을 추가할 수 없습니다. ${error.message}');
    } on LeaveRepositoryException catch (error) {
      _showError('연차 사용을 추가할 수 없습니다. ${error.toString()}');
    }
  }

  Future<void> _deleteUsage(LeaveUsage usage) async {
    final bool confirmed = await _confirmLeaveUsageDeletion(
      context: context,
      usage: usage,
    );
    if (!confirmed) {
      return;
    }

    setState(() {
      _isDeletingUsage = true;
      _errorMessage = null;
    });

    try {
      await widget.repository.deleteUsage(id: usage.id);
      await _loadSummary();
      if (!mounted) {
        return;
      }
      setState(() {
        _isDeletingUsage = false;
      });
    } on LeaveRepositoryException catch (error) {
      _showError('연차 사용을 삭제할 수 없습니다. ${error.toString()}');
    }
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }
    setState(() {
      _errorMessage = message;
      _isLoading = false;
      _isDeletingUsage = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final LeaveSummary? summary = _summary;

    return Scaffold(
      appBar: AppBar(title: const Text('연차 관리')),
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
              _YearBlock(year: _year),
              const SizedBox(height: workLedgerSpacingMedium),
              if (_isLoading && summary == null)
                const Center(child: CircularProgressIndicator())
              else if (summary != null) ...<Widget>[
                _LeaveSummaryCard(summary: summary),
                const SizedBox(height: workLedgerSpacingLarge),
                _LeaveUsageForm(
                  dateController: _usageDateController,
                  daysController: _usageDaysController,
                  hoursController: _usageHoursController,
                  memoController: _usageMemoController,
                  onAdd: _isLoading ? null : _addUsage,
                ),
                const SizedBox(height: workLedgerSpacingLarge),
                _LeaveUsageList(
                  usages: summary.usages,
                  onDelete: _isDeletingUsage ? null : _deleteUsage,
                ),
              ],
              if (_errorMessage != null) ...<Widget>[
                const SizedBox(height: workLedgerSpacingMedium),
                _LeaveMessage(message: _errorMessage!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

final class _YearBlock extends StatelessWidget {
  const _YearBlock({required this.year});

  final int year;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '기준 연도',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: workLedgerColorMuted,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: workLedgerSpacingDense),
        Text(
          year.toString(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: workLedgerColorInk,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

final class _LeaveSummaryCard extends StatelessWidget {
  const _LeaveSummaryCard({required this.summary});

  final LeaveSummary summary;

  @override
  Widget build(BuildContext context) {
    final int remainingMinutes = summary.remainingLeaveMinutes;
    final String value = remainingMinutes < 0
        ? '초과 ${formatLeaveMinutes(minutes: -remainingMinutes, includeZeroHours: false)}'
        : formatLeaveMinutes(
            minutes: remainingMinutes,
            includeZeroHours: false,
          );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: workLedgerColorSignatureForest,
        borderRadius: BorderRadius.circular(workLedgerRadiusLarge),
      ),
      child: Padding(
        padding: const EdgeInsets.all(workLedgerSpacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '남은 연차',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: workLedgerColorOnDarkMuted,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: workLedgerSpacingCompact),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: workLedgerColorCanvas,
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: workLedgerSpacingCompact),
            Text(
              '총 ${formatLeaveMinutes(minutes: summary.totalLeaveMinutes, includeZeroHours: true)} · 사용 ${formatLeaveMinutes(minutes: summary.usedLeaveMinutes, includeZeroHours: true)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: workLedgerColorOnDarkMuted,
                letterSpacing: 0,
              ),
            ),
            if (summary.isExceeded) ...<Widget>[
              const SizedBox(height: workLedgerSpacingExtraSmall),
              Text(
                '초과 사용 중',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: workLedgerColorCanvas,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

final class _LeaveUsageForm extends StatelessWidget {
  const _LeaveUsageForm({
    required this.dateController,
    required this.daysController,
    required this.hoursController,
    required this.memoController,
    required this.onAdd,
  });

  final TextEditingController dateController;
  final TextEditingController daysController;
  final TextEditingController hoursController;
  final TextEditingController memoController;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return _SectionBox(
      title: '연차 사용 추가',
      children: <Widget>[
        TextField(
          key: const Key('usageDateField'),
          controller: dateController,
          keyboardType: TextInputType.datetime,
          decoration: const InputDecoration(
            labelText: '사용 날짜',
            hintText: '2026-06-12',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: workLedgerSpacingSmall),
        Row(
          children: <Widget>[
            Expanded(
              child: _NumberField(
                keyValue: const Key('usageDaysField'),
                controller: daysController,
                label: '일',
              ),
            ),
            const SizedBox(width: workLedgerSpacingSmall),
            Expanded(
              child: _NumberField(
                keyValue: const Key('usageHoursField'),
                controller: hoursController,
                label: '시간',
              ),
            ),
          ],
        ),
        const SizedBox(height: workLedgerSpacingSmall),
        TextField(
          key: const Key('usageMemoField'),
          controller: memoController,
          decoration: const InputDecoration(
            labelText: '메모',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: workLedgerSpacingSmall),
        OutlinedButton(onPressed: onAdd, child: const Text('연차 사용 추가')),
      ],
    );
  }
}

final class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.keyValue,
    required this.controller,
    required this.label,
  });

  final Key keyValue;
  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: keyValue,
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
    );
  }
}

final class _LeaveUsageList extends StatelessWidget {
  const _LeaveUsageList({required this.usages, required this.onDelete});

  final List<LeaveUsage> usages;
  final void Function(LeaveUsage usage)? onDelete;

  @override
  Widget build(BuildContext context) {
    if (usages.isEmpty) {
      return _SectionBox(
        title: '사용 내역',
        children: <Widget>[
          Text(
            '사용 내역이 없습니다',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: workLedgerColorMuted,
              letterSpacing: 0,
            ),
          ),
        ],
      );
    }

    return _SectionBox(
      title: '사용 내역',
      children: <Widget>[
        for (int index = 0; index < usages.length; index += 1)
          _LeaveUsageRow(
            usage: usages[index],
            showDivider: index < usages.length - 1,
            onDelete: onDelete,
          ),
      ],
    );
  }
}

final class _LeaveUsageRow extends StatelessWidget {
  const _LeaveUsageRow({
    required this.usage,
    required this.showDivider,
    required this.onDelete,
  });

  final LeaveUsage usage;
  final bool showDivider;
  final void Function(LeaveUsage usage)? onDelete;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: showDivider
              ? const BorderSide(color: workLedgerColorHairline)
              : BorderSide.none,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: workLedgerSpacingCompact),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: 58,
              child: Text(
                formatLeaveUsageDate(value: usage.usedOn),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: workLedgerColorInk,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                ),
              ),
            ),
            const SizedBox(width: workLedgerSpacingSmall),
            SizedBox(
              width: 74,
              child: Text(
                formatLeaveMinutes(
                  minutes: usage.usedLeaveMinutes,
                  includeZeroHours: false,
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: workLedgerColorInk,
                  letterSpacing: 0,
                ),
              ),
            ),
            const SizedBox(width: workLedgerSpacingSmall),
            Expanded(
              child: Text(
                usage.memo ?? '',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: workLedgerColorMuted,
                  letterSpacing: 0,
                ),
              ),
            ),
            const SizedBox(width: workLedgerSpacingExtraSmall),
            IconButton(
              onPressed: onDelete == null ? null : () => onDelete!(usage),
              tooltip: '연차 사용 삭제',
              icon: const Icon(Icons.delete_outline),
              color: workLedgerColorSignatureCoral,
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> _confirmLeaveUsageDeletion({
  required BuildContext context,
  required LeaveUsage usage,
}) async {
  final String usageText =
      '${formatLeaveUsageDate(value: usage.usedOn)} ${formatLeaveMinutes(minutes: usage.usedLeaveMinutes, includeZeroHours: false)}';
  final bool? result = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('연차 사용을 삭제할까요?'),
        content: Text('$usageText 기록을 삭제합니다.'),
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

final class _SectionBox extends StatelessWidget {
  const _SectionBox({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: workLedgerColorCanvas,
        border: Border.all(color: workLedgerColorHairline),
        borderRadius: BorderRadius.circular(workLedgerRadiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: workLedgerColorInk,
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: workLedgerSpacingSmall),
            ...children,
          ],
        ),
      ),
    );
  }
}

final class _LeaveMessage extends StatelessWidget {
  const _LeaveMessage({required this.message});

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

int parseLeaveMinutesInput({
  required String daysText,
  required String hoursText,
  required bool allowZero,
}) {
  final int days = _parseNonNegativeInt(text: daysText, fieldName: '일');
  final int hourMinutes = _parseHoursAsMinutes(text: hoursText);
  final int totalMinutes = days * leaveMinutesPerDay + hourMinutes;
  if (!allowZero && totalMinutes < 30) {
    throw const FormatException('사용량은 30분 이상이어야 합니다.');
  }
  if (totalMinutes % 30 != 0) {
    throw const FormatException('입력값은 30분 단위여야 합니다.');
  }
  return totalMinutes;
}

DateTime parseDateInput({required String text}) {
  final String trimmedText = text.trim();
  final RegExp datePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  if (!datePattern.hasMatch(trimmedText)) {
    throw const FormatException('날짜는 YYYY-MM-DD 형식이어야 합니다.');
  }
  final DateTime parsed = DateTime.parse(trimmedText);
  if (_formatDateInput(value: parsed) != trimmedText) {
    throw const FormatException('존재하는 날짜를 입력해야 합니다.');
  }
  return DateTime(parsed.year, parsed.month, parsed.day);
}

String formatLeaveMinutes({
  required int minutes,
  required bool includeZeroHours,
}) {
  if (minutes < 0) {
    throw ArgumentError.value(minutes, 'minutes', 'must not be negative');
  }
  final int days = minutes ~/ leaveMinutesPerDay;
  final int remainingMinutes = minutes.remainder(leaveMinutesPerDay);
  final int hours = remainingMinutes ~/ 60;
  final int trailingMinutes = remainingMinutes.remainder(60);
  final List<String> parts = <String>[];
  if (days > 0) {
    parts.add('$days일');
  }
  if (hours > 0 || trailingMinutes > 0 || parts.isEmpty || includeZeroHours) {
    if (trailingMinutes == 0) {
      parts.add('$hours시간');
    } else if (hours == 0) {
      parts.add('$trailingMinutes분');
    } else {
      parts.add('$hours시간 $trailingMinutes분');
    }
  }
  return parts.join(' ');
}

String formatLeaveUsageDate({required DateTime value}) {
  final String month = value.month.toString().padLeft(2, '0');
  final String day = value.day.toString().padLeft(2, '0');
  return '$month-$day';
}

String _formatDateInput({required DateTime value}) {
  final String year = value.year.toString().padLeft(4, '0');
  final String month = value.month.toString().padLeft(2, '0');
  final String day = value.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

String? _normalizeMemo({required String value}) {
  final String trimmedValue = value.trim();
  if (trimmedValue.isEmpty) {
    return null;
  }
  return trimmedValue;
}

int _parseNonNegativeInt({required String text, required String fieldName}) {
  final String trimmedText = text.trim();
  if (trimmedText.isEmpty) {
    return 0;
  }
  final int? value = int.tryParse(trimmedText);
  if (value == null || value < 0) {
    throw FormatException('$fieldName 값은 0 이상의 정수여야 합니다.');
  }
  return value;
}

int _parseHoursAsMinutes({required String text}) {
  final String trimmedText = text.trim();
  if (trimmedText.isEmpty) {
    return 0;
  }
  final double? hours = double.tryParse(trimmedText);
  if (hours == null || hours < 0) {
    throw const FormatException('시간 값은 0 이상의 숫자여야 합니다.');
  }
  final int minutes = (hours * 60).round();
  if ((minutes / 60 - hours).abs() > 0.001) {
    throw const FormatException('시간 값은 분으로 바꿀 수 있어야 합니다.');
  }
  return minutes;
}
