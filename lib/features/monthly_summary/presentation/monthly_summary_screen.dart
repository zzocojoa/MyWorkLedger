import 'package:flutter/material.dart';

import '../../../core/theme/workledger_design_tokens.dart';
import '../../../core/models/pricing_intent_event.dart';
import '../../../core/models/work_record.dart';
import '../../../core/notifications/workledger_notification_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../compensation_reference/domain/compensation_reference_repository.dart';
import '../../compensation_reference/domain/compensation_reference_summary.dart';
import '../../leave/domain/leave_repository.dart';
import '../../leave/domain/leave_summary.dart';
import '../../pricing/domain/pricing_intent_repository.dart';
import '../../pricing/domain/record_pricing_intent.dart';
import '../../pricing/presentation/pricing_fake_door_screen.dart';
import '../../work_record/domain/work_record_repository.dart';
import '../../work_rule/domain/work_rule_repository.dart';
import '../../work_time/presentation/work_time_candidate_summary_card.dart';
import '../domain/load_monthly_summary.dart';
import '../domain/monthly_summary.dart';

const int _minutesPerDay = 24 * 60;

final class MonthlySummaryScreen extends StatefulWidget {
  const MonthlySummaryScreen({
    required this.repository,
    required this.leaveRepository,
    required this.workRuleRepository,
    required this.compensationReferenceRepository,
    required this.pricingIntentRepository,
    required this.now,
    required this.refreshPersistentNotification,
    super.key,
  });

  final WorkRecordRepository repository;
  final LeaveRepository leaveRepository;
  final WorkRuleRepository workRuleRepository;
  final CompensationReferenceRepository compensationReferenceRepository;
  final PricingIntentRepository pricingIntentRepository;
  final DateTime Function() now;
  final RefreshWorkLedgerPersistentNotification refreshPersistentNotification;

  @override
  State<MonthlySummaryScreen> createState() => _MonthlySummaryScreenState();
}

final class _MonthlySummaryScreenState extends State<MonthlySummaryScreen> {
  late final MonthlySummaryMonth _targetMonth;
  MonthlySummaryViewData? _viewData;
  String? _errorMessage;
  bool _isLoading = true;
  bool _isRecordingPricingIntent = false;
  bool _isDeletingRecord = false;
  bool _didDeleteWorkRecord = false;

  @override
  void initState() {
    super.initState();
    final DateTime value = widget.now();
    _targetMonth = MonthlySummaryMonth(year: value.year, month: value.month);
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final MonthlySummaryViewData viewData = await loadMonthlySummary(
        workRecordRepository: widget.repository,
        leaveRepository: widget.leaveRepository,
        workRuleRepository: widget.workRuleRepository,
        compensationReferenceRepository: widget.compensationReferenceRepository,
        targetMonth: _targetMonth,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _viewData = viewData;
        _isLoading = false;
      });
    } on WorkRecordRepositoryException catch (error) {
      _showError('월간 요약을 불러올 수 없습니다. ${error.toString()}');
    } on LeaveRepositoryException catch (error) {
      _showError('연차 요약을 불러올 수 없습니다. ${error.toString()}');
    } on WorkRuleRepositoryException catch (error) {
      _showError('근무 기준을 불러올 수 없습니다. ${error.toString()}');
    } on CompensationReferenceRepositoryException catch (error) {
      _showError('포함 시간 비교를 불러올 수 없습니다. ${error.toString()}');
    } on MonthlySummaryException catch (error) {
      _showError('월간 요약을 계산할 수 없습니다. ${error.toString()}');
    } on LeaveSummaryException catch (error) {
      _showError('연차 요약을 계산할 수 없습니다. ${error.toString()}');
    }
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }
    setState(() {
      _errorMessage = message;
      _isLoading = false;
      _isRecordingPricingIntent = false;
      _isDeletingRecord = false;
    });
  }

  Future<void> _openPricingFakeDoor() async {
    setState(() {
      _isRecordingPricingIntent = true;
      _errorMessage = null;
    });

    try {
      await recordPricingIntent(
        repository: widget.pricingIntentRepository,
        eventType: PricingIntentEventType.reportButtonTapped,
        selectedPlan: null,
        sourceScreen: 'monthly_summary',
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _isRecordingPricingIntent = false;
      });
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) =>
              PricingFakeDoorScreen(repository: widget.pricingIntentRepository),
        ),
      );
    } on PricingIntentRepositoryException catch (error) {
      _showError('가격 관심 이벤트를 저장할 수 없습니다. ${error.toString()}');
    } on ArgumentError catch (error) {
      _showError('가격 관심 이벤트를 저장할 수 없습니다. ${error.message}');
    }
  }

  Future<void> _deleteRecord(MonthlyWorkRecordEntry entry) async {
    final bool confirmed = await _confirmMonthlyRecordDeletion(
      context: context,
      entry: entry,
      isToday: _isSameDate(
        left: entry.workDate,
        right: _dateOnly(widget.now()),
      ),
    );
    if (!confirmed) {
      return;
    }

    setState(() {
      _isDeletingRecord = true;
      _errorMessage = null;
    });

    try {
      await widget.repository.deleteByDate(workDate: entry.workDate);
      _didDeleteWorkRecord = true;
      await _loadSummary();
      await widget.refreshPersistentNotification();
      if (!mounted) {
        return;
      }
      setState(() {
        _isDeletingRecord = false;
      });
    } on WorkRecordRepositoryException catch (error) {
      _showError('근무 기록을 삭제할 수 없습니다. ${error.toString()}');
    } on WorkLedgerNotificationException catch (error) {
      _showError('상시 알림을 갱신할 수 없습니다. ${error.toString()}');
    }
  }

  void _closeScreen() {
    Navigator.of(context).pop(_didDeleteWorkRecord);
  }

  @override
  Widget build(BuildContext context) {
    final MonthlySummaryViewData? viewData = _viewData;

    return PopScope<bool>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, bool? result) {
        if (didPop) {
          return;
        }
        _closeScreen();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('월간 요약'),
          leading: BackButton(onPressed: _closeScreen),
          actions: <Widget>[
            TextButton(
              onPressed:
                  _isLoading ||
                      _errorMessage != null ||
                      _isRecordingPricingIntent
                  ? null
                  : _openPricingFakeDoor,
              child: const Text('Report'),
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
                Text(
                  formatMonthlySummaryMonth(month: _targetMonth),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: workLedgerColorMuted,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: workLedgerSpacingLarge),
                if (_isLoading && viewData == null)
                  const Center(child: CircularProgressIndicator())
                else if (_errorMessage != null)
                  _MonthlySummaryMessage(message: _errorMessage!)
                else if (viewData != null) ...<Widget>[
                  _TotalWorkCard(viewData: viewData),
                  const SizedBox(height: workLedgerSpacingMedium),
                  _MonthlyStats(viewData: viewData),
                  if (viewData
                      .workTimeCandidateSummary
                      .hasActiveTags) ...<Widget>[
                    const SizedBox(height: workLedgerSpacingMedium),
                    WorkTimeCandidateSummaryCard(
                      summary: viewData.workTimeCandidateSummary,
                    ),
                  ],
                  if (_hasRecordTagSummary(
                    summary: viewData.workSummary,
                  )) ...<Widget>[
                    const SizedBox(height: workLedgerSpacingMedium),
                    _RecordTagSummaryCard(summary: viewData.workSummary),
                  ],
                  if (viewData.compensationReferenceSummary.status ==
                      CompensationReferenceSummaryStatus.available) ...<Widget>[
                    const SizedBox(height: workLedgerSpacingMedium),
                    _CompensationReferenceSummaryCard(viewData: viewData),
                  ],
                  const SizedBox(height: workLedgerSpacingMedium),
                  _MonthlyLeaveSummaryCard(viewData: viewData),
                  const SizedBox(height: workLedgerSpacingLarge),
                  _MonthlyRecordList(
                    summary: viewData.workSummary,
                    onDelete: _isDeletingRecord ? null : _deleteRecord,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _TotalWorkCard extends StatelessWidget {
  const _TotalWorkCard({required this.viewData});

  final MonthlySummaryViewData viewData;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: workLedgerColorInk,
        borderRadius: BorderRadius.circular(workLedgerRadiusLarge),
      ),
      child: Padding(
        padding: const EdgeInsets.all(workLedgerSpacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '이번 달 총 근무',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: workLedgerColorOnDarkMuted,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: workLedgerSpacingCompact),
            Text(
              formatMonthlySummaryDuration(
                duration: viewData.displayTotalWorkedDuration,
              ),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: workLedgerColorCanvas,
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _MonthlyStats extends StatelessWidget {
  const _MonthlyStats({required this.viewData});

  final MonthlySummaryViewData viewData;

  @override
  Widget build(BuildContext context) {
    final MonthlySummary summary = viewData.workSummary;
    final int visibleTagCount = _visibleMonthlyTagCount(viewData: viewData);
    return Row(
      children: <Widget>[
        Expanded(
          child: _StatTile(
            label: '근무일',
            value: '${summary.completedWorkDayCount}일',
          ),
        ),
        const SizedBox(width: workLedgerSpacingSmall),
        Expanded(
          child: _StatTile(
            label: '근무 태그',
            value: visibleTagCount > 0
                ? '$visibleTagCount개'
                : viewData.workRule == null
                ? '기준 미설정'
                : '0개',
          ),
        ),
      ],
    );
  }
}

int _visibleMonthlyTagCount({required MonthlySummaryViewData viewData}) {
  final int recordTagCount = _recordTagSummaryCount(
    summary: viewData.workSummary,
  );
  final int candidateTagCount =
      viewData.workTimeCandidateSummary.activeTagCount;
  return candidateTagCount > recordTagCount
      ? candidateTagCount
      : recordTagCount;
}

final class _MonthlyLeaveSummaryCard extends StatelessWidget {
  const _MonthlyLeaveSummaryCard({required this.viewData});

  final MonthlySummaryViewData viewData;

  @override
  Widget build(BuildContext context) {
    final LeaveSummary leaveSummary = viewData.leaveSummary;
    final bool hasBalance = leaveSummary.balance != null;
    final String remainingText = !hasBalance
        ? '총 연차를 입력해 주세요'
        : leaveSummary.isExceeded
        ? '초과 ${formatMonthlySummaryLeaveMinutes(minutes: -leaveSummary.remainingLeaveMinutes)}'
        : formatMonthlySummaryLeaveMinutes(
            minutes: leaveSummary.remainingLeaveMinutes,
          );
    final String monthlyUsedText = formatMonthlySummaryLeaveMinutes(
      minutes: viewData.monthlyUsedLeaveMinutes,
    );
    final String totalLine = hasBalance
        ? '총 ${formatMonthlySummaryLeaveMinutes(minutes: leaveSummary.totalLeaveMinutes)} · 올해 사용 ${formatMonthlySummaryLeaveMinutes(minutes: leaveSummary.usedLeaveMinutes)}'
        : '연차 관리에서 올해 총 연차를 먼저 입력하세요';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: workLedgerColorCanvas,
        border: Border.all(color: workLedgerColorHairline),
        borderRadius: BorderRadius.circular(workLedgerRadiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(workLedgerSpacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              '연차 요약',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: workLedgerColorInk,
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: workLedgerSpacingMedium),
            Row(
              children: <Widget>[
                Expanded(
                  child: _LeaveStatBlock(label: '남은 연차', value: remainingText),
                ),
                const SizedBox(width: workLedgerSpacingSmall),
                Expanded(
                  child: _LeaveStatBlock(
                    label: '이번 달 사용 연차',
                    value: monthlyUsedText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: workLedgerSpacingSmall),
            Text(
              totalLine,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: workLedgerColorMuted,
                letterSpacing: 0,
              ),
            ),
            if (hasBalance && leaveSummary.isExceeded) ...<Widget>[
              const SizedBox(height: workLedgerSpacingExtraSmall),
              Text(
                '초과 사용 중',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: workLedgerColorInk,
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

final class _RecordTagSummaryCard extends StatelessWidget {
  const _RecordTagSummaryCard({required this.summary});

  final MonthlySummary summary;

  @override
  Widget build(BuildContext context) {
    final List<_RecordTagSummaryData> rows = _visibleRecordTagRows(
      summary: summary,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: workLedgerColorCanvas,
        border: Border.all(color: workLedgerColorHairline),
        borderRadius: BorderRadius.circular(workLedgerRadiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(workLedgerSpacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              '태그별 참고',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: workLedgerColorInk,
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: workLedgerSpacingSmall),
            for (int index = 0; index < rows.length; index += 1) ...<Widget>[
              if (index > 0) const SizedBox(height: workLedgerSpacingCompact),
              _RecordTagSummaryRow(
                label: rows[index].label,
                value: formatMonthlySummaryDuration(
                  duration: rows[index].duration,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

final class _RecordTagSummaryData {
  const _RecordTagSummaryData({required this.label, required this.duration});

  final String label;
  final Duration duration;
}

List<_RecordTagSummaryData> _visibleRecordTagRows({
  required MonthlySummary summary,
}) {
  final List<_RecordTagSummaryData> rows = <_RecordTagSummaryData>[
    _RecordTagSummaryData(label: '야근', duration: summary.overtimeDuration),
    _RecordTagSummaryData(
      label: '퇴근 지연',
      duration: summary.delayedCheckoutDuration,
    ),
    _RecordTagSummaryData(label: '휴일근무', duration: summary.holidayWorkDuration),
  ];
  return rows
      .where((_RecordTagSummaryData row) => row.duration > Duration.zero)
      .toList(growable: false);
}

bool _hasRecordTagSummary({required MonthlySummary summary}) {
  return _recordTagSummaryCount(summary: summary) > 0;
}

int _recordTagSummaryCount({required MonthlySummary summary}) {
  return _visibleRecordTagRows(summary: summary).length;
}

final class _RecordTagSummaryRow extends StatelessWidget {
  const _RecordTagSummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: workLedgerColorMuted,
            letterSpacing: 0,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: workLedgerColorInk,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

final class _CompensationReferenceSummaryCard extends StatelessWidget {
  const _CompensationReferenceSummaryCard({required this.viewData});

  final MonthlySummaryViewData viewData;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: workLedgerColorCanvas,
        border: Border.all(color: workLedgerColorHairline),
        borderRadius: BorderRadius.circular(workLedgerRadiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(workLedgerSpacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              localizations.monthlySummaryCompensationReferenceTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: workLedgerColorInk,
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: workLedgerSpacingSmall),
            for (
              int index = 0;
              index < viewData.compensationReferenceSummary.rows.length;
              index += 1
            ) ...<Widget>[
              if (index > 0) const SizedBox(height: workLedgerSpacingSmall),
              _CompensationReferenceRow(
                row: viewData.compensationReferenceSummary.rows[index],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

final class _CompensationReferenceRow extends StatelessWidget {
  const _CompensationReferenceRow({required this.row});

  final CompensationReferenceComparisonRow row;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: workLedgerColorSurfaceSoft,
        borderRadius: BorderRadius.circular(workLedgerRadiusSmall),
      ),
      child: Padding(
        padding: const EdgeInsets.all(workLedgerSpacingSmall),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              row.label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: workLedgerColorInk,
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: workLedgerSpacingCompact),
            _CompensationReferenceValueLine(
              label:
                  localizations.monthlySummaryCompensationReferenceStartLabel,
              value: _formatCompensationReferenceMinuteOfDay(
                minutes: row.excessStartTimeMinutes,
              ),
            ),
            const SizedBox(height: workLedgerSpacingDense),
            _CompensationReferenceValueLine(
              label: localizations.monthlySummaryCompensationActualLabel,
              value: formatMonthlySummaryDuration(duration: row.actualDuration),
            ),
            const SizedBox(height: workLedgerSpacingDense),
            _CompensationReferenceValueLine(
              label:
                  localizations.monthlySummaryCompensationIncludedDurationLabel,
              value: formatMonthlySummaryDuration(
                duration: row.fixedIncludedDuration,
              ),
            ),
            const SizedBox(height: workLedgerSpacingDense),
            _CompensationReferenceValueLine(
              label:
                  localizations.monthlySummaryCompensationExcessReferenceLabel,
              value: formatMonthlySummaryDuration(
                duration: row.excessReferenceDuration,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatCompensationReferenceMinuteOfDay({required int minutes}) {
  if (minutes < 0) {
    throw ArgumentError.value(minutes, 'minutes', 'must be non-negative');
  }
  final int dayOffset = minutes ~/ _minutesPerDay;
  final int minuteOfDay = minutes.remainder(_minutesPerDay);
  final String hour = (minuteOfDay ~/ 60).toString().padLeft(2, '0');
  final String minute = minuteOfDay.remainder(60).toString().padLeft(2, '0');
  if (dayOffset > 0) {
    return '다음 날 $hour:$minute';
  }
  return '$hour:$minute';
}

final class _CompensationReferenceValueLine extends StatelessWidget {
  const _CompensationReferenceValueLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: workLedgerColorMuted,
            letterSpacing: 0,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: workLedgerColorInk,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

final class _LeaveStatBlock extends StatelessWidget {
  const _LeaveStatBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: workLedgerColorMuted,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: workLedgerSpacingExtraSmall),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: workLedgerColorInk,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

final class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: workLedgerColorCanvas,
        border: Border.all(color: workLedgerColorHairline),
        borderRadius: BorderRadius.circular(workLedgerRadiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(workLedgerSpacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: workLedgerColorMuted,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: workLedgerSpacingExtraSmall),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: workLedgerColorInk,
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _MonthlyRecordList extends StatelessWidget {
  const _MonthlyRecordList({required this.summary, required this.onDelete});

  final MonthlySummary summary;
  final void Function(MonthlyWorkRecordEntry entry)? onDelete;

  @override
  Widget build(BuildContext context) {
    if (summary.entries.isEmpty) {
      return const _EmptyMonthlyRecords();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          '이번 달 기록',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: workLedgerColorInk,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: workLedgerSpacingSmall),
        DecoratedBox(
          decoration: BoxDecoration(
            color: workLedgerColorCanvas,
            border: Border.all(color: workLedgerColorHairline),
            borderRadius: BorderRadius.circular(workLedgerRadiusMedium),
          ),
          child: Column(
            children: <Widget>[
              for (int index = 0; index < summary.entries.length; index += 1)
                _MonthlyRecordRow(
                  entry: summary.entries[index],
                  showDivider: index < summary.entries.length - 1,
                  onDelete: onDelete,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

final class _EmptyMonthlyRecords extends StatelessWidget {
  const _EmptyMonthlyRecords();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: workLedgerColorCanvas,
        border: Border.all(color: workLedgerColorHairline),
        borderRadius: BorderRadius.circular(workLedgerRadiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(workLedgerSpacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '이번 달 기록',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: workLedgerColorInk,
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: workLedgerSpacingSmall),
            Text(
              '이 달 기록이 없습니다',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: workLedgerColorInk,
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: workLedgerSpacingDense),
            Text(
              '출근/퇴근 기록이 쌓이면 월간 요약이 표시됩니다.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: workLedgerColorMuted,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _MonthlyRecordRow extends StatelessWidget {
  const _MonthlyRecordRow({
    required this.entry,
    required this.showDivider,
    required this.onDelete,
  });

  final MonthlyWorkRecordEntry entry;
  final bool showDivider;
  final void Function(MonthlyWorkRecordEntry entry)? onDelete;

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
        padding: const EdgeInsets.symmetric(
          horizontal: workLedgerSpacingMedium,
          vertical: workLedgerSpacingSmall,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    formatMonthlySummaryEntryLine(entry: entry),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: workLedgerColorInk,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0,
                    ),
                  ),
                  if (entry.isCompleted &&
                      formatMonthlySummaryRecordReasons(
                        tags: entry.tags,
                      ).isNotEmpty) ...<Widget>[
                    const SizedBox(height: workLedgerSpacingDense),
                    Text(
                      '기록 사유: ${formatMonthlySummaryRecordReasons(tags: entry.tags)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: workLedgerColorMuted,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: workLedgerSpacingExtraSmall),
            IconButton(
              onPressed: onDelete == null ? null : () => onDelete!(entry),
              tooltip: '근무 기록 삭제',
              icon: const Icon(Icons.delete_outline),
              color: workLedgerColorSignatureCoral,
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> _confirmMonthlyRecordDeletion({
  required BuildContext context,
  required MonthlyWorkRecordEntry entry,
  required bool isToday,
}) async {
  final bool? result = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('근무 기록을 삭제할까요?'),
        content: Text(
          _formatMonthlyRecordDeletionMessage(entry: entry, isToday: isToday),
        ),
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

String _formatMonthlyRecordDeletionMessage({
  required MonthlyWorkRecordEntry entry,
  required bool isToday,
}) {
  final String date = formatMonthlySummaryDate(value: entry.workDate);
  if (isToday) {
    return '$date 오늘 기록을 삭제합니다. 홈 상태도 출근 전으로 바뀝니다.';
  }
  return '$date 기록을 삭제합니다.';
}

DateTime _dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

bool _isSameDate({required DateTime left, required DateTime right}) {
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}

final class _MonthlySummaryMessage extends StatelessWidget {
  const _MonthlySummaryMessage({required this.message});

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

String formatMonthlySummaryMonth({required MonthlySummaryMonth month}) {
  final String monthValue = month.month.toString().padLeft(2, '0');
  return '${month.year}-$monthValue';
}

String formatMonthlySummaryEntryLine({required MonthlyWorkRecordEntry entry}) {
  final String date = formatMonthlySummaryDate(value: entry.workDate);
  if (entry.isCompleted) {
    final DateTime? clockInAt = entry.clockInAt;
    final DateTime? clockOutAt = entry.clockOutAt;
    if (clockInAt == null || clockOutAt == null) {
      throw MonthlySummaryException(
        'widget=MonthlySummaryScreen recordId=${entry.recordId} status=completed rule=clock-in and clock-out required',
      );
    }
    return '$date ${formatMonthlySummaryClock(value: clockInAt)}-${formatMonthlySummaryClock(value: clockOutAt)}';
  }

  if (entry.clockInAt != null && entry.clockOutAt == null) {
    return '$date 출근만 기록됨';
  }
  if (entry.clockInAt == null && entry.clockOutAt != null) {
    return '$date 퇴근만 기록됨';
  }
  return '$date 시간이 비어 있음';
}

String formatMonthlySummaryDate({required DateTime value}) {
  final String month = value.month.toString().padLeft(2, '0');
  final String day = value.day.toString().padLeft(2, '0');
  return '$month-$day';
}

String formatMonthlySummaryClock({required DateTime value}) {
  final String hour = value.hour.toString().padLeft(2, '0');
  final String minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String formatMonthlySummaryDuration({required Duration duration}) {
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

String formatMonthlySummaryLeaveMinutes({required int minutes}) {
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
  if (hours > 0 || trailingMinutes > 0 || parts.isEmpty) {
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

String formatMonthlySummaryRecordReasons({required List<WorkRecordTag> tags}) {
  return tags
      .where((WorkRecordTag tag) => tag == WorkRecordTag.delayedCheckout)
      .map(formatMonthlySummaryRecordReason)
      .join(' · ');
}

String formatMonthlySummaryRecordReason(WorkRecordTag tag) {
  return switch (tag) {
    WorkRecordTag.delayedCheckout => '퇴근 기록 지연',
    WorkRecordTag.overtime ||
    WorkRecordTag.holidayWork => throw ArgumentError.value(
      tag,
      'tag',
      'must be a monthly summary record reason tag',
    ),
  };
}
