import 'package:flutter/material.dart';

import '../../../core/theme/workledger_design_tokens.dart';

import '../../../core/models/work_record.dart';
import '../../../core/models/work_rule.dart';
import '../../../core/notifications/workledger_notification_service.dart';
import '../../monthly_summary/domain/calculate_monthly_summary.dart';
import '../../monthly_summary/domain/monthly_summary.dart';
import '../../work_rule/domain/work_rule_repository.dart';
import '../../work_time/domain/calculate_monthly_work_time_candidate_summary.dart';
import '../../work_time/domain/work_time_candidate.dart';
import '../../work_time/presentation/work_time_candidate_summary_card.dart';
import '../domain/work_record_repository.dart';
import 'edit_today_work_record_screen.dart';
import 'work_record_formatters.dart';

final class WorkRecordCalendarScreen extends StatefulWidget {
  const WorkRecordCalendarScreen({
    required this.repository,
    required this.workRuleRepository,
    required this.now,
    required this.refreshPersistentNotification,
    super.key,
  });

  final WorkRecordRepository repository;
  final WorkRuleRepository workRuleRepository;
  final DateTime Function() now;
  final RefreshWorkLedgerPersistentNotification refreshPersistentNotification;

  @override
  State<WorkRecordCalendarScreen> createState() =>
      _WorkRecordCalendarScreenState();
}

final class _WorkRecordCalendarScreenState
    extends State<WorkRecordCalendarScreen> {
  late MonthlySummaryMonth _targetMonth;
  late DateTime _selectedDate;
  MonthlySummary? _summary;
  WorkTimeCandidateSummary? _workTimeCandidateSummary;
  String? _errorMessage;
  bool _isLoading = true;
  bool _didModifyRecord = false;

  @override
  void initState() {
    super.initState();
    final DateTime currentDate = _dateOnly(widget.now());
    _targetMonth = MonthlySummaryMonth(
      year: currentDate.year,
      month: currentDate.month,
    );
    _selectedDate = currentDate;
    _loadMonth();
  }

  Future<void> _loadMonth() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final List<WorkRecord> records = await widget.repository.findByMonth(
        year: _targetMonth.year,
        month: _targetMonth.month,
      );
      final MonthlySummary summary = calculateMonthlySummary(
        targetMonth: _targetMonth,
        records: records,
      );
      final WorkRule? workRule = await widget.workRuleRepository.findActive();
      final WorkRule candidateWorkRule =
          workRule ??
          buildDefaultWorkTimeCandidateRule(
            timestamp: DateTime(_targetMonth.year, _targetMonth.month),
          );
      final WorkTimeCandidateSummary workTimeCandidateSummary =
          calculateMonthlyWorkTimeCandidateSummary(
            records: records,
            workRule: candidateWorkRule,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _summary = summary;
        _workTimeCandidateSummary = workTimeCandidateSummary;
        _isLoading = false;
      });
    } on WorkRecordRepositoryException catch (error) {
      _showError('달력 기록을 불러올 수 없습니다. ${error.toString()}');
    } on WorkRuleRepositoryException catch (error) {
      _showError('근무 기준을 불러올 수 없습니다. ${error.toString()}');
    } on MonthlySummaryException catch (error) {
      _showError('달력 기록을 계산할 수 없습니다. ${error.toString()}');
    }
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

  Future<void> _moveMonth(int offset) async {
    final DateTime nextMonth = DateTime(
      _targetMonth.year,
      _targetMonth.month + offset,
    );
    final MonthlySummaryMonth targetMonth = MonthlySummaryMonth(
      year: nextMonth.year,
      month: nextMonth.month,
    );
    targetMonth.validate();
    setState(() {
      _targetMonth = targetMonth;
      _selectedDate = _clampSelectedDateToMonth(
        selectedDate: _selectedDate,
        targetMonth: targetMonth,
      );
    });
    await _loadMonth();
  }

  Future<void> _openEditWorkRecord() async {
    final Object? result = await Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) => EditTodayWorkRecordScreen(
          repository: widget.repository,
          now: widget.now,
          workDate: _selectedDate,
          refreshPersistentNotification: widget.refreshPersistentNotification,
        ),
      ),
    );
    if (result == true) {
      _didModifyRecord = true;
      await _loadMonth();
    }
  }

  void _closeScreen() {
    Navigator.of(context).pop(_didModifyRecord);
  }

  @override
  Widget build(BuildContext context) {
    final MonthlySummary? summary = _summary;
    final WorkTimeCandidateSummary? workTimeCandidateSummary =
        _workTimeCandidateSummary;
    final Map<DateTime, MonthlyWorkRecordEntry> entriesByDate =
        _buildEntriesByDate(summary: summary);
    final MonthlyWorkRecordEntry? selectedEntry = entriesByDate[_selectedDate];
    final DateTime today = _dateOnly(widget.now());
    final String editButtonLabel = selectedEntry == null ? '기록 추가' : '기록 수정';

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
          title: const Text('달력 보기'),
          leading: BackButton(onPressed: _closeScreen),
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
                _CalendarMonthHeader(
                  targetMonth: _targetMonth,
                  onPrevious: _isLoading ? null : () => _moveMonth(-1),
                  onNext: _isLoading ? null : () => _moveMonth(1),
                ),
                const SizedBox(height: workLedgerSpacingMedium),
                if (_isLoading && summary == null)
                  const Center(child: CircularProgressIndicator())
                else if (_errorMessage != null)
                  _CalendarMessage(message: _errorMessage!)
                else ...<Widget>[
                  _CalendarGrid(
                    targetMonth: _targetMonth,
                    entriesByDate: entriesByDate,
                    selectedDate: _selectedDate,
                    today: today,
                    onSelectDate: (DateTime date) {
                      setState(() {
                        _selectedDate = date;
                      });
                    },
                  ),
                  const SizedBox(height: workLedgerSpacingMedium),
                  _CalendarLegend(),
                  if (workTimeCandidateSummary != null &&
                      workTimeCandidateSummary.hasActiveTags) ...<Widget>[
                    const SizedBox(height: workLedgerSpacingMedium),
                    WorkTimeCandidateSummaryCard(
                      summary: workTimeCandidateSummary,
                    ),
                  ],
                  const SizedBox(height: workLedgerSpacingMedium),
                  _SelectedDateDetail(
                    selectedDate: _selectedDate,
                    entry: selectedEntry,
                  ),
                  const SizedBox(height: workLedgerSpacingMedium),
                  FilledButton(
                    onPressed: _openEditWorkRecord,
                    child: Text(editButtonLabel),
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

final class _CalendarMonthHeader extends StatelessWidget {
  const _CalendarMonthHeader({
    required this.targetMonth,
    required this.onPrevious,
    required this.onNext,
  });

  final MonthlySummaryMonth targetMonth;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        IconButton(
          onPressed: onPrevious,
          tooltip: '이전 달',
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: Text(
            '${targetMonth.year}년 ${targetMonth.month}월',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: workLedgerColorInk,
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
            ),
          ),
        ),
        IconButton(
          onPressed: onNext,
          tooltip: '다음 달',
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

final class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.targetMonth,
    required this.entriesByDate,
    required this.selectedDate,
    required this.today,
    required this.onSelectDate,
  });

  final MonthlySummaryMonth targetMonth;
  final Map<DateTime, MonthlyWorkRecordEntry> entriesByDate;
  final DateTime selectedDate;
  final DateTime today;
  final void Function(DateTime date) onSelectDate;

  @override
  Widget build(BuildContext context) {
    final List<DateTime?> cells = _buildMonthCells(targetMonth: targetMonth);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: workLedgerColorCanvas,
        border: Border.all(color: workLedgerColorHairline),
        borderRadius: BorderRadius.circular(workLedgerRadiusLarge),
      ),
      child: Padding(
        padding: const EdgeInsets.all(workLedgerSpacingCompact),
        child: Column(
          children: <Widget>[
            const _CalendarWeekdayRow(),
            const SizedBox(height: workLedgerSpacingDense),
            GridView.builder(
              itemCount: cells.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: workLedgerSpacingDense,
                crossAxisSpacing: workLedgerSpacingExtraExtraSmall,
                childAspectRatio: 0.58,
              ),
              itemBuilder: (BuildContext context, int index) {
                final DateTime? date = cells[index];
                if (date == null) {
                  return const SizedBox.shrink();
                }
                return _CalendarDayCell(
                  date: date,
                  entry: entriesByDate[date],
                  isSelected: _isSameDate(left: selectedDate, right: date),
                  isToday: _isSameDate(left: today, right: date),
                  onTap: () => onSelectDate(date),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

final class _CalendarWeekdayRow extends StatelessWidget {
  const _CalendarWeekdayRow();

  @override
  Widget build(BuildContext context) {
    const List<String> weekdays = <String>['일', '월', '화', '수', '목', '금', '토'];
    return Row(
      children: <Widget>[
        for (final String weekday in weekdays)
          Expanded(
            child: Text(
              weekday,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: workLedgerColorMuted,
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
              ),
            ),
          ),
      ],
    );
  }
}

final class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.date,
    required this.entry,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
  });

  final DateTime date;
  final MonthlyWorkRecordEntry? entry;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color foregroundColor = isSelected
        ? workLedgerColorCanvas
        : workLedgerColorInk;
    final Color backgroundColor = isSelected
        ? workLedgerColorInk
        : workLedgerColorCanvas;
    final BorderSide borderSide = isToday
        ? const BorderSide(color: workLedgerColorInk, width: 1.2)
        : const BorderSide(color: workLedgerColorHairline);

    return Semantics(
      label: _buildCalendarDaySemanticLabel(date: date, entry: entry),
      button: true,
      selected: isSelected,
      child: InkWell(
        key: Key(_buildCalendarDayKey(date: date)),
        onTap: onTap,
        borderRadius: BorderRadius.circular(workLedgerRadiusSmall),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.fromBorderSide(borderSide),
            borderRadius: BorderRadius.circular(workLedgerRadiusSmall),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: workLedgerSpacingExtraExtraSmall,
                horizontal: workLedgerSpacingHairline,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      date.day.toString(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: foregroundColor,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: workLedgerSpacingCalendarMarker),
                    Text(
                      _calendarMarker(entry: entry),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: foregroundColor,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0,
                      ),
                    ),
                    if (isToday) ...<Widget>[
                      const SizedBox(height: workLedgerSpacingHairline),
                      Text(
                        '오늘',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: foregroundColor,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _CalendarLegend extends StatelessWidget {
  const _CalendarLegend();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: workLedgerSpacingSmall,
      runSpacing: workLedgerSpacingExtraSmall,
      children: const <Widget>[
        _LegendItem(marker: '●', label: '완료'),
        _LegendItem(marker: '◐', label: '출근만 기록'),
        _LegendItem(marker: '○', label: '시간 누락'),
        _LegendItem(marker: '·', label: '기록 없음'),
      ],
    );
  }
}

final class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.marker, required this.label});

  final String marker;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$marker $label',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: workLedgerColorMuted,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
    );
  }
}

final class _SelectedDateDetail extends StatelessWidget {
  const _SelectedDateDetail({required this.selectedDate, required this.entry});

  final DateTime selectedDate;
  final MonthlyWorkRecordEntry? entry;

  @override
  Widget build(BuildContext context) {
    final List<String> lines = _buildSelectedDateDetailLines(
      selectedDate: selectedDate,
      entry: entry,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: workLedgerColorCanvas,
        border: Border.all(color: workLedgerColorHairline),
        borderRadius: BorderRadius.circular(workLedgerRadiusLarge),
      ),
      child: Padding(
        padding: const EdgeInsets.all(workLedgerSpacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              _formatCalendarDateTitle(value: selectedDate),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: workLedgerColorInk,
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: workLedgerSpacingSmall),
            for (final String line in lines)
              Padding(
                padding: const EdgeInsets.only(bottom: workLedgerSpacingDense),
                child: Text(
                  line,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: workLedgerColorBody,
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

final class _CalendarMessage extends StatelessWidget {
  const _CalendarMessage({required this.message});

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

Map<DateTime, MonthlyWorkRecordEntry> _buildEntriesByDate({
  required MonthlySummary? summary,
}) {
  final MonthlySummary? value = summary;
  if (value == null) {
    return <DateTime, MonthlyWorkRecordEntry>{};
  }
  return <DateTime, MonthlyWorkRecordEntry>{
    for (final MonthlyWorkRecordEntry entry in value.entries)
      entry.workDate: entry,
  };
}

List<DateTime?> _buildMonthCells({required MonthlySummaryMonth targetMonth}) {
  targetMonth.validate();
  final DateTime firstDay = DateTime(targetMonth.year, targetMonth.month);
  final int leadingEmptyCount = firstDay.weekday % 7;
  final int dayCount = DateTime(targetMonth.year, targetMonth.month + 1, 0).day;
  final List<DateTime?> cells = <DateTime?>[
    for (int index = 0; index < leadingEmptyCount; index += 1) null,
    for (int day = 1; day <= dayCount; day += 1)
      DateTime(targetMonth.year, targetMonth.month, day),
  ];
  while (cells.length % 7 != 0) {
    cells.add(null);
  }
  return List<DateTime?>.unmodifiable(cells);
}

DateTime _clampSelectedDateToMonth({
  required DateTime selectedDate,
  required MonthlySummaryMonth targetMonth,
}) {
  final int lastDay = DateTime(targetMonth.year, targetMonth.month + 1, 0).day;
  final int day = selectedDate.day > lastDay ? lastDay : selectedDate.day;
  return DateTime(targetMonth.year, targetMonth.month, day);
}

DateTime _dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

bool _isSameDate({required DateTime left, required DateTime right}) {
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}

String _calendarMarker({required MonthlyWorkRecordEntry? entry}) {
  final MonthlyWorkRecordEntry? value = entry;
  if (value == null) {
    return '·';
  }
  if (value.isCompleted) {
    return '●';
  }
  if (value.clockInAt != null && value.clockOutAt == null) {
    return '◐';
  }
  return '○';
}

String _buildCalendarDayKey({required DateTime date}) {
  final String month = date.month.toString().padLeft(2, '0');
  final String day = date.day.toString().padLeft(2, '0');
  return 'calendar-day-${date.year}-$month-$day';
}

String _buildCalendarDaySemanticLabel({
  required DateTime date,
  required MonthlyWorkRecordEntry? entry,
}) {
  return '${date.month}월 ${date.day}일 ${_calendarStatusLabel(entry: entry)}';
}

String _calendarStatusLabel({required MonthlyWorkRecordEntry? entry}) {
  final MonthlyWorkRecordEntry? value = entry;
  if (value == null) {
    return '기록 없음';
  }
  if (value.isCompleted) {
    return '완료';
  }
  if (value.clockInAt != null && value.clockOutAt == null) {
    return '출근만 기록됨';
  }
  if (value.clockInAt == null && value.clockOutAt != null) {
    return '퇴근만 기록됨';
  }
  return '시간이 비어 있음';
}

String _formatCalendarDateTitle({required DateTime value}) {
  return '${value.month}월 ${value.day}일 ${formatKoreanWeekday(value: value)}';
}

List<String> _buildSelectedDateDetailLines({
  required DateTime selectedDate,
  required MonthlyWorkRecordEntry? entry,
}) {
  final MonthlyWorkRecordEntry? value = entry;
  if (value == null) {
    return <String>['기록 없음'];
  }
  if (value.isCompleted) {
    final DateTime? clockInAt = value.clockInAt;
    final DateTime? clockOutAt = value.clockOutAt;
    final Duration? workedDuration = value.workedDuration;
    if (clockInAt == null || clockOutAt == null || workedDuration == null) {
      throw MonthlySummaryException(
        'widget=WorkRecordCalendarScreen recordId=${value.recordId} status=completed rule=clock-in clock-out workedDuration required',
      );
    }
    final List<String> lines = <String>[
      '${formatClockTime(value: clockInAt)} - ${formatClockTime(value: clockOutAt)}',
      '총 ${formatDurationForKorean(duration: workedDuration)}',
    ];
    final String recordReasons = formatEditableWorkRecordReasons(
      tags: value.tags,
    );
    if (recordReasons.isNotEmpty) {
      lines.add('기록 사유: $recordReasons');
    }
    final String? memo = value.memo;
    if (memo != null && memo.isNotEmpty) {
      lines.add('메모: $memo');
    }
    return List<String>.unmodifiable(lines);
  }
  if (value.clockInAt != null && value.clockOutAt == null) {
    return <String>[
      '출근만 기록됨',
      '출근 ${formatClockTime(value: value.clockInAt!)}',
    ];
  }
  if (value.clockInAt == null && value.clockOutAt != null) {
    return <String>[
      '퇴근만 기록됨',
      '퇴근 ${formatClockTime(value: value.clockOutAt!)}',
    ];
  }
  return <String>['시간이 비어 있음'];
}
