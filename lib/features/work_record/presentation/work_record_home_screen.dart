import 'package:flutter/material.dart';

import '../../../core/models/work_record.dart';
import '../../leave/domain/leave_repository.dart';
import '../../leave/domain/leave_summary.dart';
import '../../leave/presentation/leave_management_screen.dart';
import '../../monthly_summary/domain/load_monthly_summary.dart';
import '../../monthly_summary/domain/monthly_summary.dart';
import '../../monthly_summary/presentation/monthly_summary_screen.dart';
import '../../pricing/domain/pricing_intent_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/load_today_work_summary.dart';
import '../domain/today_work_status.dart';
import '../domain/today_work_summary.dart';
import '../domain/work_record_repository.dart';
import 'edit_today_work_record_screen.dart';

final class WorkRecordHomeScreen extends StatefulWidget {
  const WorkRecordHomeScreen({
    required this.repository,
    required this.leaveRepository,
    required this.pricingIntentRepository,
    required this.now,
    super.key,
  });

  final WorkRecordRepository repository;
  final LeaveRepository leaveRepository;
  final PricingIntentRepository pricingIntentRepository;
  final DateTime Function() now;

  @override
  State<WorkRecordHomeScreen> createState() => _WorkRecordHomeScreenState();
}

final class _WorkRecordHomeScreenState extends State<WorkRecordHomeScreen> {
  TodayWorkSummary? _summary;
  _HomeMonthlyPreviewData? _monthlyPreviewData;
  String? _errorMessage;
  bool _isLoading = true;
  bool _isPreviewLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() {
      _isLoading = true;
      _isPreviewLoading = true;
      _errorMessage = null;
    });

    try {
      final DateTime currentTime = widget.now();
      final TodayWorkSummary summary = await loadTodayWorkSummary(
        repository: widget.repository,
        now: currentTime,
      );
      final _HomeMonthlyPreviewData monthlyPreviewData =
          await _loadMonthlyPreviewData(currentTime: currentTime);
      if (!mounted) {
        return;
      }
      setState(() {
        _summary = summary;
        _monthlyPreviewData = monthlyPreviewData;
        _isLoading = false;
        _isPreviewLoading = false;
      });
    } on WorkRecordRepositoryException catch (error) {
      _showError(error.toString());
    } on TodayWorkSummaryException catch (error) {
      _showError(error.toString());
    } on MonthlySummaryException catch (error) {
      _showError(error.toString());
    } on LeaveRepositoryException catch (error) {
      _showError(error.toString());
    } on LeaveSummaryException catch (error) {
      _showError(error.toString());
    }
  }

  Future<_HomeMonthlyPreviewData> _loadMonthlyPreviewData({
    required DateTime currentTime,
  }) async {
    final MonthlySummaryViewData viewData = await loadMonthlySummary(
      workRecordRepository: widget.repository,
      leaveRepository: widget.leaveRepository,
      targetMonth: MonthlySummaryMonth(
        year: currentTime.year,
        month: currentTime.month,
      ),
    );
    return _HomeMonthlyPreviewData(
      totalWorkedText: formatMonthlySummaryDuration(
        duration: viewData.workSummary.totalWorkedDuration,
      ),
      remainingLeaveText: viewData.leaveSummary.balance == null
          ? '총 연차 미입력'
          : _formatHomeRemainingLeave(viewData: viewData),
    );
  }

  String _formatHomeRemainingLeave({required MonthlySummaryViewData viewData}) {
    final int remainingLeaveMinutes =
        viewData.leaveSummary.remainingLeaveMinutes;
    if (viewData.leaveSummary.isExceeded) {
      return '초과 ${formatMonthlySummaryLeaveMinutes(minutes: -remainingLeaveMinutes)}';
    }
    return formatMonthlySummaryLeaveMinutes(minutes: remainingLeaveMinutes);
  }

  Future<void> _handlePrimaryAction(TodayWorkSummary summary) async {
    if (summary.primaryAction == TodayWorkPrimaryAction.editTodayRecord) {
      await _openEditTodayRecord();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      switch (summary.primaryAction) {
        case TodayWorkPrimaryAction.clockIn:
          await widget.repository.clockIn();
        case TodayWorkPrimaryAction.clockOut:
          await widget.repository.clockOut();
        case TodayWorkPrimaryAction.editTodayRecord:
          throw const TodayWorkSummaryException(
            'widget=WorkRecordHomeScreen action=editTodayRecord rule=handled before repository action',
          );
      }
      await _loadSummary();
    } on WorkRecordRepositoryException catch (error) {
      _showError(error.toString());
    } on TodayWorkSummaryException catch (error) {
      _showError(error.toString());
    }
  }

  Future<void> _openEditTodayRecord() async {
    final Object? result = await Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) => EditTodayWorkRecordScreen(
          repository: widget.repository,
          now: widget.now,
        ),
      ),
    );
    if (result == true) {
      await _loadSummary();
    }
  }

  Future<void> _handleSecondaryAction(TodayWorkSummary summary) async {
    final TodayWorkSecondaryAction? action = summary.secondaryAction;
    if (action == null) {
      return;
    }

    switch (action) {
      case TodayWorkSecondaryAction.viewMonthlySummary:
        await _openMonthlySummary();
    }
  }

  Future<void> _openMonthlySummary() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => MonthlySummaryScreen(
          repository: widget.repository,
          leaveRepository: widget.leaveRepository,
          pricingIntentRepository: widget.pricingIntentRepository,
          now: widget.now,
        ),
      ),
    );
  }

  Future<void> _openLeaveManagement() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => LeaveManagementScreen(
          repository: widget.leaveRepository,
          now: widget.now,
        ),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }
    setState(() {
      _errorMessage = message;
      _isLoading = false;
      _isPreviewLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final TodayWorkSummary? summary = _summary;
    final AppLocalizations localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(localizations.appKoreanName)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                formatTodayLabel(now: widget.now()),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF41454D),
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 24),
              if (_isLoading && summary == null)
                const Center(child: CircularProgressIndicator())
              else if (summary != null) ...<Widget>[
                _TodayStatusCard(summary: summary),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _isLoading
                      ? null
                      : () => _handlePrimaryAction(summary),
                  child: Text(summary.primaryButtonLabel),
                ),
                if (summary.secondaryButtonLabel != null) ...<Widget>[
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: _isLoading
                        ? null
                        : () => _handleSecondaryAction(summary),
                    child: Text(summary.secondaryButtonLabel!),
                  ),
                ],
              ],
              if (_errorMessage != null) ...<Widget>[
                const SizedBox(height: 16),
                _StatusMessage(message: _errorMessage!),
              ],
              const SizedBox(height: 28),
              _MonthlyPreview(
                data: _monthlyPreviewData,
                isLoading: _isPreviewLoading,
              ),
              const SizedBox(height: 18),
              _HomeLinks(
                onOpenMonthlySummary: _openMonthlySummary,
                onOpenLeaveManagement: _openLeaveManagement,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _HomeMonthlyPreviewData {
  const _HomeMonthlyPreviewData({
    required this.totalWorkedText,
    required this.remainingLeaveText,
  });

  final String totalWorkedText;
  final String remainingLeaveText;
}

final class _TodayStatusCard extends StatelessWidget {
  const _TodayStatusCard({required this.summary});

  final TodayWorkSummary summary;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDDDDDD)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              summary.statusText,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: const Color(0xFF181D26),
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 12),
            for (final String line in buildStatusLines(summary: summary))
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  line,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF333840),
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

final class _StatusMessage extends StatelessWidget {
  const _StatusMessage({required this.message});

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

final class _MonthlyPreview extends StatelessWidget {
  const _MonthlyPreview({required this.data, required this.isLoading});

  final _HomeMonthlyPreviewData? data;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          localizations.homeThisMonth,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: const Color(0xFF181D26),
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: _SummaryTile(
                label: localizations.homeTotalWork,
                value: _resolveTotalWorkedText(localizations: localizations),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryTile(
                label: localizations.homeRemainingLeave,
                value: _resolveRemainingLeaveText(localizations: localizations),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _resolveTotalWorkedText({required AppLocalizations localizations}) {
    if (isLoading) {
      return localizations.homePreparing;
    }
    return data?.totalWorkedText ?? localizations.homePreparing;
  }

  String _resolveRemainingLeaveText({required AppLocalizations localizations}) {
    if (isLoading) {
      return localizations.homePreparing;
    }
    return data?.remainingLeaveText ?? localizations.homePreparing;
  }
}

final class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDDDDDD)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF41454D),
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFF181D26),
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _HomeLinks extends StatelessWidget {
  const _HomeLinks({
    required this.onOpenMonthlySummary,
    required this.onOpenLeaveManagement,
  });

  final VoidCallback onOpenMonthlySummary;
  final VoidCallback onOpenLeaveManagement;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        TextButton(
          onPressed: onOpenMonthlySummary,
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF41454D),
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 44),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
          child: Text(localizations.homeMonthlySummary),
        ),
        TextButton(
          onPressed: onOpenLeaveManagement,
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF41454D),
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 44),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
          child: Text(localizations.homeLeaveManagement),
        ),
      ],
    );
  }
}

List<String> buildStatusLines({required TodayWorkSummary summary}) {
  final WorkRecord? record = summary.record;
  switch (summary.status) {
    case TodayWorkStatus.beforeClockIn:
      return <String>['기록된 근무 시간이 없습니다', '회사명·위치 없이 시작합니다'];
    case TodayWorkStatus.working:
      final DateTime? clockInAt = record?.clockInAt;
      final Duration? elapsedDuration = summary.elapsedDuration;
      if (clockInAt == null || elapsedDuration == null) {
        throw const TodayWorkSummaryException(
          'widget=WorkRecordHomeScreen state=working rule=clockInAt and elapsedDuration required',
        );
      }
      return <String>[
        '출근 ${formatClockTime(value: clockInAt)}',
        '현재 ${formatDurationForKorean(duration: elapsedDuration)} 기록 중',
      ];
    case TodayWorkStatus.afterClockOut:
      final DateTime? clockInAt = record?.clockInAt;
      final DateTime? clockOutAt = record?.clockOutAt;
      final Duration? workedDuration = summary.workedDuration;
      if (clockInAt == null || clockOutAt == null || workedDuration == null) {
        throw const TodayWorkSummaryException(
          'widget=WorkRecordHomeScreen state=afterClockOut rule=clockInAt clockOutAt and workedDuration required',
        );
      }
      return <String>[
        '${formatClockTime(value: clockInAt)} - ${formatClockTime(value: clockOutAt)}',
        '총 ${formatDurationForKorean(duration: workedDuration)}',
      ];
  }
}

String formatTodayLabel({required DateTime now}) {
  return '오늘 · ${now.month}월 ${now.day}일 ${formatKoreanWeekday(value: now)}';
}

String formatKoreanWeekday({required DateTime value}) {
  return switch (value.weekday) {
    DateTime.monday => '월요일',
    DateTime.tuesday => '화요일',
    DateTime.wednesday => '수요일',
    DateTime.thursday => '목요일',
    DateTime.friday => '금요일',
    DateTime.saturday => '토요일',
    DateTime.sunday => '일요일',
    _ => throw ArgumentError.value(value.weekday, 'weekday', 'must be 1-7'),
  };
}

String formatClockTime({required DateTime value}) {
  final String hour = value.hour.toString().padLeft(2, '0');
  final String minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String formatDurationForKorean({required Duration duration}) {
  if (duration.isNegative) {
    throw ArgumentError.value(duration, 'duration', 'must not be negative');
  }

  final int hours = duration.inHours;
  final int minutes = duration.inMinutes.remainder(60);
  if (hours == 0) {
    return '$minutes분';
  }
  if (minutes == 0) {
    return '$hours시간';
  }
  return '$hours시간 $minutes분';
}
