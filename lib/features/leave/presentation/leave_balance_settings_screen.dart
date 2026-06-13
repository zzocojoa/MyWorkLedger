import 'package:flutter/material.dart';

import '../domain/leave_repository.dart';
import '../domain/leave_summary.dart';
import '../domain/load_leave_summary.dart';
import '../domain/save_total_leave.dart';
import 'leave_management_screen.dart';

final class LeaveBalanceSettingsScreen extends StatefulWidget {
  const LeaveBalanceSettingsScreen({
    required this.repository,
    required this.now,
    super.key,
  });

  final LeaveRepository repository;
  final DateTime Function() now;

  @override
  State<LeaveBalanceSettingsScreen> createState() =>
      _LeaveBalanceSettingsScreenState();
}

final class _LeaveBalanceSettingsScreenState
    extends State<LeaveBalanceSettingsScreen> {
  final TextEditingController _totalDaysController = TextEditingController();
  final TextEditingController _totalHoursController = TextEditingController();
  late final int _year;
  String? _errorMessage;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final DateTime value = widget.now();
    _year = value.year;
    _loadSummary();
  }

  @override
  void dispose() {
    _totalDaysController.dispose();
    _totalHoursController.dispose();
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
        _isLoading = false;
      });
    } on LeaveRepositoryException catch (error) {
      _showError('총 연차를 불러올 수 없습니다. ${error.toString()}');
    } on LeaveSummaryException catch (error) {
      _showError('총 연차를 계산할 수 없습니다. ${error.toString()}');
    }
  }

  Future<void> _saveTotalLeave() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
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
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } on FormatException catch (error) {
      _showError('총 연차를 저장할 수 없습니다. ${error.message}');
    } on ArgumentError catch (error) {
      _showError('총 연차를 저장할 수 없습니다. ${error.message}');
    } on LeaveRepositoryException catch (error) {
      _showError('총 연차를 저장할 수 없습니다. ${error.toString()}');
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
      _isSaving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('총 연차')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                _year.toString(),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF181D26),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else ...<Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _LeaveBalanceNumberField(
                        keyValue: const Key('totalLeaveDaysField'),
                        controller: _totalDaysController,
                        label: '일',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _LeaveBalanceNumberField(
                        keyValue: const Key('totalLeaveHoursField'),
                        controller: _totalHoursController,
                        label: '시간',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _isSaving ? null : _saveTotalLeave,
                  child: Text(_isSaving ? '저장 중' : '저장'),
                ),
              ],
              if (_errorMessage != null) ...<Widget>[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFAA2D00),
                    letterSpacing: 0,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

final class _LeaveBalanceNumberField extends StatelessWidget {
  const _LeaveBalanceNumberField({
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
        border: const OutlineInputBorder(),
      ),
    );
  }
}
