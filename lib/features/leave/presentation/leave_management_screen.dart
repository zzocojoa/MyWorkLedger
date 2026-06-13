import 'package:flutter/material.dart';

import '../../../core/models/leave_usage.dart';
import '../domain/add_leave_usage.dart';
import '../domain/leave_repository.dart';
import '../domain/leave_summary.dart';
import '../domain/load_leave_summary.dart';
import '../domain/save_total_leave.dart';

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
  final TextEditingController _totalDaysController = TextEditingController();
  final TextEditingController _totalHoursController = TextEditingController();
  final TextEditingController _usageDateController = TextEditingController();
  final TextEditingController _usageDaysController = TextEditingController();
  final TextEditingController _usageHoursController = TextEditingController();
  final TextEditingController _usageMemoController = TextEditingController();
  LeaveSummary? _summary;
  String? _errorMessage;
  bool _isLoading = true;

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
    _totalDaysController.dispose();
    _totalHoursController.dispose();
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
      _setTotalLeaveFields(totalLeaveMinutes: summary.totalLeaveMinutes);
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

  Future<void> _saveTotalLeave() async {
    try {
      final int totalLeaveMinutes = parseLeaveMinutesInput(
        daysText: _totalDaysController.text,
        hoursText: _totalHoursController.text,
        allowZero: true,
      );
      await saveTotalLeave(
        repository: widget.repository,
        year: _year,
        totalLeaveMinutes: totalLeaveMinutes,
      );
      await _loadSummary();
    } on FormatException catch (error) {
      _showError('총 연차를 저장할 수 없습니다. ${error.message}');
    } on ArgumentError catch (error) {
      _showError('총 연차를 저장할 수 없습니다. ${error.message}');
    } on LeaveRepositoryException catch (error) {
      _showError('총 연차를 저장할 수 없습니다. ${error.toString()}');
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

  void _setTotalLeaveFields({required int totalLeaveMinutes}) {
    final int days = totalLeaveMinutes ~/ leaveMinutesPerDay;
    final int remainingMinutes = totalLeaveMinutes.remainder(
      leaveMinutesPerDay,
    );
    final int hours = remainingMinutes ~/ 60;
    final int minutes = remainingMinutes.remainder(60);
    _totalDaysController.text = days.toString();
    _totalHoursController.text = minutes == 0
        ? hours.toString()
        : '$hours.${minutes == 30 ? '5' : minutes.toString().padLeft(2, '0')}';
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }
    setState(() {
      _errorMessage = message;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final LeaveSummary? summary = _summary;

    return Scaffold(
      appBar: AppBar(title: const Text('연차 관리')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _YearBlock(year: _year),
              const SizedBox(height: 18),
              if (_isLoading && summary == null)
                const Center(child: CircularProgressIndicator())
              else if (summary != null) ...<Widget>[
                _LeaveSummaryCard(summary: summary),
                const SizedBox(height: 22),
                _TotalLeaveForm(
                  daysController: _totalDaysController,
                  hoursController: _totalHoursController,
                  onSave: _isLoading ? null : _saveTotalLeave,
                ),
                const SizedBox(height: 22),
                _LeaveUsageForm(
                  dateController: _usageDateController,
                  daysController: _usageDaysController,
                  hoursController: _usageHoursController,
                  memoController: _usageMemoController,
                  onAdd: _isLoading ? null : _addUsage,
                ),
                const SizedBox(height: 22),
                _LeaveUsageList(usages: summary.usages),
              ],
              if (_errorMessage != null) ...<Widget>[
                const SizedBox(height: 16),
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
            color: const Color(0xFF41454D),
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          year.toString(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: const Color(0xFF181D26),
            fontWeight: FontWeight.w600,
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
        color: const Color(0xFF123D2C),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '남은 연차',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.82),
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '총 ${formatLeaveMinutes(minutes: summary.totalLeaveMinutes, includeZeroHours: true)} · 사용 ${formatLeaveMinutes(minutes: summary.usedLeaveMinutes, includeZeroHours: true)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.72),
                letterSpacing: 0,
              ),
            ),
            if (summary.isExceeded) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                '초과 사용 중',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
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

final class _TotalLeaveForm extends StatelessWidget {
  const _TotalLeaveForm({
    required this.daysController,
    required this.hoursController,
    required this.onSave,
  });

  final TextEditingController daysController;
  final TextEditingController hoursController;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return _SectionBox(
      title: '총 연차',
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _NumberField(
                keyValue: const Key('totalLeaveDaysField'),
                controller: daysController,
                label: '일',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _NumberField(
                keyValue: const Key('totalLeaveHoursField'),
                controller: hoursController,
                label: '시간',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FilledButton(onPressed: onSave, child: const Text('총 연차 저장')),
      ],
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
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: _NumberField(
                keyValue: const Key('usageDaysField'),
                controller: daysController,
                label: '일',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _NumberField(
                keyValue: const Key('usageHoursField'),
                controller: hoursController,
                label: '시간',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('usageMemoField'),
          controller: memoController,
          decoration: const InputDecoration(
            labelText: '메모',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
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
  const _LeaveUsageList({required this.usages});

  final List<LeaveUsage> usages;

  @override
  Widget build(BuildContext context) {
    if (usages.isEmpty) {
      return _SectionBox(
        title: '사용 내역',
        children: <Widget>[
          Text(
            '사용 내역이 없습니다',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF41454D),
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
          ),
      ],
    );
  }
}

final class _LeaveUsageRow extends StatelessWidget {
  const _LeaveUsageRow({required this.usage, required this.showDivider});

  final LeaveUsage usage;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: showDivider
              ? const BorderSide(color: Color(0xFFEAEAEA))
              : BorderSide.none,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: 58,
              child: Text(
                formatLeaveUsageDate(value: usage.usedOn),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF181D26),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 74,
              child: Text(
                formatLeaveMinutes(
                  minutes: usage.usedLeaveMinutes,
                  includeZeroHours: false,
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF181D26),
                  letterSpacing: 0,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                usage.memo ?? '',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF41454D),
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _SectionBox extends StatelessWidget {
  const _SectionBox({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDDDDDD)),
        borderRadius: BorderRadius.circular(10),
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
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 12),
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
