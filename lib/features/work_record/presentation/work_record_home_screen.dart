import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/input/clock_time_input.dart';
import '../../../core/theme/workledger_design_tokens.dart';

import '../../../core/models/work_record.dart';
import '../../../core/notifications/workledger_notification_action.dart';
import '../../../core/notifications/workledger_notification_service.dart';
import '../../../core/notifications/workledger_notification_refresh_signal.dart';
import '../../compensation_reference/domain/compensation_reference_repository.dart';
import '../../leave/domain/leave_repository.dart';
import '../../leave/domain/leave_summary.dart';
import '../../leave/presentation/leave_management_screen.dart';
import '../../monthly_summary/domain/load_monthly_summary.dart';
import '../../monthly_summary/domain/monthly_summary.dart';
import '../../monthly_summary/presentation/monthly_summary_screen.dart';
import '../../pricing/domain/pricing_intent_repository.dart';
import '../../settings/presentation/notification_settings_screen.dart';
import '../../settings/presentation/settings_home_screen.dart';
import '../../../l10n/app_localizations.dart';
import '../../work_rule/domain/work_rule_repository.dart';
import '../domain/load_today_work_summary.dart';
import '../domain/quick_record_candidate.dart';
import '../domain/quick_record_settings.dart';
import '../domain/quick_record_settings_repository.dart';
import '../domain/today_work_status.dart';
import '../domain/today_work_summary.dart';
import '../domain/work_record_repository.dart';
import 'edit_today_work_record_screen.dart';
import 'work_record_calendar_screen.dart';
import 'work_record_formatters.dart';

final class WorkRecordHomeScreen extends StatefulWidget {
  const WorkRecordHomeScreen({
    required this.repository,
    required this.quickRecordSettingsRepository,
    required this.leaveRepository,
    required this.workRuleRepository,
    required this.compensationReferenceRepository,
    required this.pricingIntentRepository,
    required this.configureNotifications,
    required this.notificationActionController,
    required this.now,
    super.key,
  });

  final WorkRecordRepository repository;
  final QuickRecordSettingsRepository quickRecordSettingsRepository;
  final LeaveRepository leaveRepository;
  final WorkRuleRepository workRuleRepository;
  final CompensationReferenceRepository compensationReferenceRepository;
  final PricingIntentRepository pricingIntentRepository;
  final ConfigureWorkLedgerNotifications configureNotifications;
  final WorkLedgerNotificationActionController notificationActionController;
  final DateTime Function() now;

  @override
  State<WorkRecordHomeScreen> createState() => _WorkRecordHomeScreenState();
}

final class _WorkRecordHomeScreenState extends State<WorkRecordHomeScreen>
    with WidgetsBindingObserver {
  TodayWorkSummary? _summary;
  _HomeMonthlyPreviewData? _monthlyPreviewData;
  String? _errorMessage;
  bool _isLoading = true;
  bool _isPreviewLoading = true;
  bool _isHandlingNotificationQuickRecord = false;
  bool _isPendingNotificationQuickRecordDrainScheduled = false;
  late final WorkLedgerNotificationRefreshListener _notificationRefreshListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _notificationRefreshListener = WorkLedgerNotificationRefreshListener(
      onRefresh: _handleNotificationRefresh,
    );
    _notificationRefreshListener.start();
    widget.notificationActionController.addListener(
      _handleNotificationQuickRecordRequest,
    );
    _loadSummary();
    _schedulePendingNotificationQuickRecordDrain();
  }

  @override
  void dispose() {
    _notificationRefreshListener.stop();
    widget.notificationActionController.removeListener(
      _handleNotificationQuickRecordRequest,
    );
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _handleNotificationRefresh();
    }
  }

  void _handleNotificationRefresh() {
    if (!mounted) {
      return;
    }
    _loadSummary();
  }

  Future<void> _refreshSummaryAndNotification() async {
    await _loadSummary();
    await _refreshPersistentNotification();
  }

  Future<void> _refreshPersistentNotification() async {
    await widget.configureNotifications();
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
      _schedulePendingNotificationQuickRecordDrain();
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
    } on WorkRuleRepositoryException catch (error) {
      _showError(error.toString());
    } on CompensationReferenceRepositoryException catch (error) {
      _showError(error.toString());
    }
  }

  Future<_HomeMonthlyPreviewData> _loadMonthlyPreviewData({
    required DateTime currentTime,
  }) async {
    final MonthlySummaryViewData viewData = await loadMonthlySummary(
      workRecordRepository: widget.repository,
      leaveRepository: widget.leaveRepository,
      workRuleRepository: widget.workRuleRepository,
      compensationReferenceRepository: widget.compensationReferenceRepository,
      targetMonth: MonthlySummaryMonth(
        year: currentTime.year,
        month: currentTime.month,
      ),
    );
    return _HomeMonthlyPreviewData(
      totalWorkedText: formatMonthlySummaryDuration(
        duration: viewData.displayTotalWorkedDuration,
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
      final QuickRecordSettings? quickRecordSettings = await widget
          .quickRecordSettingsRepository
          .findActive();
      final QuickRecordMode mode =
          quickRecordSettings?.mode ?? QuickRecordMode.currentTimeOnly;
      if (mode == QuickRecordMode.currentTimeOnly) {
        await _savePrimaryActionNow(summary: summary);
      } else {
        final bool saved = await _chooseAndSaveQuickRecord(summary: summary);
        if (!saved) {
          if (!mounted) {
            return;
          }
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }
      await _refreshSummaryAndNotification();
    } on QuickRecordSettingsRepositoryException catch (error) {
      _showError(error.toString());
    } on WorkRecordRepositoryException catch (error) {
      _showError(error.toString());
    } on TodayWorkSummaryException catch (error) {
      _showError(error.toString());
    } on WorkRuleRepositoryException catch (error) {
      _showError(error.toString());
    } on CompensationReferenceRepositoryException catch (error) {
      _showError(error.toString());
    } on QuickRecordManualInputException catch (error) {
      _showError('시각을 저장할 수 없습니다. ${error.toString()}');
    } on WorkLedgerNotificationException catch (error) {
      _showError(error.toString());
    }
  }

  Future<void> _savePrimaryActionNow({
    required TodayWorkSummary summary,
  }) async {
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
  }

  Future<bool> _chooseAndSaveQuickRecord({
    required TodayWorkSummary summary,
  }) async {
    final QuickRecordActionType actionType = _quickRecordActionType(
      summary: summary,
    );
    return _chooseAndSaveQuickRecordAction(actionType: actionType);
  }

  Future<bool> _chooseAndSaveQuickRecordAction({
    required QuickRecordActionType actionType,
  }) async {
    final DateTime currentTime = widget.now();
    final List<QuickRecordCandidate> candidates = buildQuickRecordCandidates(
      mode: QuickRecordMode.chooseBeforeSave,
      actionType: actionType,
      currentTime: currentTime,
      workRule: await widget.workRuleRepository.findActive(),
      compensationReferenceSetting: await widget.compensationReferenceRepository
          .findApplicableForMonth(
            year: currentTime.year,
            month: currentTime.month,
          ),
    );
    final QuickRecordCandidate? candidate = await _showQuickRecordCandidates(
      actionType: actionType,
      candidates: candidates,
    );
    if (candidate == null) {
      return false;
    }
    final DateTime? recordedAt = candidate.recordedAt;
    if (recordedAt != null) {
      await _savePrimaryActionAt(
        actionType: actionType,
        recordedAt: recordedAt,
      );
      return true;
    }
    final DateTime? manualRecordedAt = await _showManualQuickRecordInput(
      actionType: actionType,
      workDate: currentTime,
    );
    if (manualRecordedAt == null) {
      return false;
    }
    await _savePrimaryActionAt(
      actionType: actionType,
      recordedAt: manualRecordedAt,
    );
    return true;
  }

  void _handleNotificationQuickRecordRequest() {
    _schedulePendingNotificationQuickRecordDrain();
  }

  void _schedulePendingNotificationQuickRecordDrain() {
    if (_isPendingNotificationQuickRecordDrainScheduled || !mounted) {
      return;
    }
    _isPendingNotificationQuickRecordDrainScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isPendingNotificationQuickRecordDrainScheduled = false;
      if (!mounted) {
        return;
      }
      unawaited(_handlePendingNotificationQuickRecord());
    });
  }

  Future<void> _handlePendingNotificationQuickRecord() async {
    if (_isHandlingNotificationQuickRecord || !mounted) {
      return;
    }
    if (_summary == null || _isLoading) {
      _schedulePendingNotificationQuickRecordDrain();
      return;
    }
    final WorkLedgerNotificationAction? action = widget
        .notificationActionController
        .takePendingAction();
    if (action == null || action == WorkLedgerNotificationAction.openHome) {
      return;
    }
    _isHandlingNotificationQuickRecord = true;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final QuickRecordActionType actionType =
          _quickRecordActionTypeFromNotification(action: action);
      final bool saved = await _chooseAndSaveQuickRecordAction(
        actionType: actionType,
      );
      if (saved) {
        await _refreshSummaryAndNotification();
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } on WorkRecordRepositoryException catch (error) {
      _showError(error.toString());
    } on WorkRuleRepositoryException catch (error) {
      _showError(error.toString());
    } on CompensationReferenceRepositoryException catch (error) {
      _showError(error.toString());
    } on QuickRecordManualInputException catch (error) {
      _showError('시각을 저장할 수 없습니다. ${error.toString()}');
    } on WorkLedgerNotificationException catch (error) {
      _showError(error.toString());
    } finally {
      _isHandlingNotificationQuickRecord = false;
    }
  }

  QuickRecordActionType _quickRecordActionTypeFromNotification({
    required WorkLedgerNotificationAction action,
  }) {
    return switch (action) {
      WorkLedgerNotificationAction.clockIn => QuickRecordActionType.clockIn,
      WorkLedgerNotificationAction.clockOut => QuickRecordActionType.clockOut,
      WorkLedgerNotificationAction.openHome =>
        throw const TodayWorkSummaryException(
          'widget=WorkRecordHomeScreen action=notificationQuickRecord rule=openHome has no quick record action type',
        ),
    };
  }

  Future<void> _savePrimaryActionAt({
    required QuickRecordActionType actionType,
    required DateTime recordedAt,
  }) async {
    switch (actionType) {
      case QuickRecordActionType.clockIn:
        await widget.repository.clockInAt(clockInAt: recordedAt);
      case QuickRecordActionType.clockOut:
        await widget.repository.clockOutAt(clockOutAt: recordedAt);
    }
  }

  QuickRecordActionType _quickRecordActionType({
    required TodayWorkSummary summary,
  }) {
    return switch (summary.primaryAction) {
      TodayWorkPrimaryAction.clockIn => QuickRecordActionType.clockIn,
      TodayWorkPrimaryAction.clockOut => QuickRecordActionType.clockOut,
      TodayWorkPrimaryAction.editTodayRecord =>
        throw const TodayWorkSummaryException(
          'widget=WorkRecordHomeScreen action=quickRecordActionType rule=edit action has no quick record action type',
        ),
    };
  }

  Future<QuickRecordCandidate?> _showQuickRecordCandidates({
    required QuickRecordActionType actionType,
    required List<QuickRecordCandidate> candidates,
  }) async {
    return showModalBottomSheet<QuickRecordCandidate>(
      context: context,
      builder: (BuildContext context) {
        final String title = switch (actionType) {
          QuickRecordActionType.clockIn => '출근 시각 선택',
          QuickRecordActionType.clockOut => '퇴근 시각 선택',
        };
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(
              workLedgerSpacingLarge,
              workLedgerSpacingMedium,
              workLedgerSpacingLarge,
              workLedgerSpacingLarge,
            ),
            children: <Widget>[
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: workLedgerColorInk,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: workLedgerSpacingSmall),
              for (final QuickRecordCandidate candidate in candidates)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(candidate.label),
                  subtitle: Text(_quickRecordCandidateSubtitle(candidate)),
                  onTap: () => Navigator.of(context).pop(candidate),
                ),
              const SizedBox(height: workLedgerSpacingSmall),
              Text(
                '앱이 시간을 자동 보정하지 않습니다. 선택한 시각만 저장합니다.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: workLedgerColorMuted,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _quickRecordCandidateSubtitle(QuickRecordCandidate candidate) {
    return switch (candidate.type) {
      QuickRecordCandidateType.currentTime => '지금 확인한 실제 시각으로 저장',
      QuickRecordCandidateType.regularTime => '근무 설정의 정시 기준을 선택해서 저장',
      QuickRecordCandidateType.manualInput => 'HH:mm 형식으로 1분 단위 직접 입력',
    };
  }

  Future<DateTime?> _showManualQuickRecordInput({
    required QuickRecordActionType actionType,
    required DateTime workDate,
  }) async {
    final String title = switch (actionType) {
      QuickRecordActionType.clockIn => '출근 시각 직접 입력',
      QuickRecordActionType.clockOut => '퇴근 시각 직접 입력',
    };
    return showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) =>
          _ManualQuickRecordInputDialog(title: title, workDate: workDate),
    );
  }

  Future<void> _openEditTodayRecord() async {
    final Object? result = await Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) => EditTodayWorkRecordScreen(
          repository: widget.repository,
          now: widget.now,
          workDate: DateTime(
            widget.now().year,
            widget.now().month,
            widget.now().day,
          ),
          refreshPersistentNotification: _refreshPersistentNotification,
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
      case TodayWorkSecondaryAction.viewCalendar:
        await _openCalendar();
    }
  }

  Future<void> _openCalendar() async {
    final Object? result = await Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) => WorkRecordCalendarScreen(
          repository: widget.repository,
          workRuleRepository: widget.workRuleRepository,
          now: widget.now,
          refreshPersistentNotification: _refreshPersistentNotification,
        ),
      ),
    );
    if (result == true) {
      await _loadSummary();
    }
  }

  Future<void> _openMonthlySummary() async {
    final Object? result = await Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) => MonthlySummaryScreen(
          repository: widget.repository,
          leaveRepository: widget.leaveRepository,
          workRuleRepository: widget.workRuleRepository,
          compensationReferenceRepository:
              widget.compensationReferenceRepository,
          pricingIntentRepository: widget.pricingIntentRepository,
          now: widget.now,
          refreshPersistentNotification: _refreshPersistentNotification,
        ),
      ),
    );
    if (result == true) {
      await _loadSummary();
    }
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
    await _loadSummary();
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => SettingsHomeScreen(
          workRuleRepository: widget.workRuleRepository,
          quickRecordSettingsRepository: widget.quickRecordSettingsRepository,
          compensationReferenceRepository:
              widget.compensationReferenceRepository,
          leaveRepository: widget.leaveRepository,
          configureNotifications: widget.configureNotifications,
          now: widget.now,
        ),
      ),
    );
    await _loadSummary();
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
      appBar: AppBar(
        title: Text(localizations.appKoreanName),
        actions: <Widget>[
          IconButton(
            tooltip: '설정',
            onPressed: _openSettings,
            icon: const Icon(Icons.settings_outlined),
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
                formatTodayLabel(now: widget.now()),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: workLedgerColorMuted,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: workLedgerSpacingLarge),
              if (_isLoading && summary == null)
                const Center(child: CircularProgressIndicator())
              else if (summary != null) ...<Widget>[
                _TodayStatusCard(summary: summary),
                const SizedBox(height: workLedgerSpacingLarge),
                FilledButton(
                  onPressed: _isLoading
                      ? null
                      : () => _handlePrimaryAction(summary),
                  child: Text(summary.primaryButtonLabel),
                ),
                if (summary.secondaryButtonLabel != null) ...<Widget>[
                  const SizedBox(height: workLedgerSpacingCompact),
                  OutlinedButton(
                    onPressed: _isLoading
                        ? null
                        : () => _handleSecondaryAction(summary),
                    child: Text(summary.secondaryButtonLabel!),
                  ),
                ],
              ],
              if (_errorMessage != null) ...<Widget>[
                const SizedBox(height: workLedgerSpacingMedium),
                _StatusMessage(message: _errorMessage!),
              ],
              const SizedBox(height: workLedgerSpacingExtraLarge),
              _MonthlyPreview(
                data: _monthlyPreviewData,
                isLoading: _isPreviewLoading,
              ),
              const SizedBox(height: workLedgerSpacingMedium),
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

final class _ManualQuickRecordInputDialog extends StatefulWidget {
  const _ManualQuickRecordInputDialog({
    required this.title,
    required this.workDate,
  });

  final String title;
  final DateTime workDate;

  @override
  State<_ManualQuickRecordInputDialog> createState() {
    return _ManualQuickRecordInputDialogState();
  }
}

final class _ManualQuickRecordInputDialogState
    extends State<_ManualQuickRecordInputDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    try {
      final DateTime recordedAt = parseQuickRecordManualTime(
        value: _controller.text,
        workDate: widget.workDate,
      );
      Navigator.of(context).pop(recordedAt);
    } on QuickRecordManualInputException catch (error) {
      setState(() {
        _errorText = error.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          labelText: '시각',
          helperText: 'HH:mm 형식으로 입력하세요.',
          errorText: _errorText,
        ),
        keyboardType: TextInputType.datetime,
        inputFormatters: const <TextInputFormatter>[ClockTimeInputFormatter()],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('취소'),
        ),
        FilledButton(onPressed: _save, child: const Text('저장')),
      ],
    );
  }
}

final class _TodayStatusCard extends StatelessWidget {
  const _TodayStatusCard({required this.summary});

  final TodayWorkSummary summary;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: workLedgerColorCanvas,
        border: Border.all(color: workLedgerColorHairline),
        borderRadius: BorderRadius.circular(workLedgerRadiusLarge),
      ),
      child: Padding(
        padding: const EdgeInsets.all(workLedgerSpacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              summary.statusText,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: workLedgerColorInk,
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: workLedgerSpacingSmall),
            for (final String line in buildStatusLines(summary: summary))
              Padding(
                padding: const EdgeInsets.only(bottom: workLedgerSpacingDense),
                child: Text(
                  line,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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

final class _StatusMessage extends StatelessWidget {
  const _StatusMessage({required this.message});

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
            color: workLedgerColorInk,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: workLedgerSpacingSmall),
        Row(
          children: <Widget>[
            Expanded(
              child: _SummaryTile(
                label: localizations.homeTotalWork,
                value: _resolveTotalWorkedText(localizations: localizations),
              ),
            ),
            const SizedBox(width: workLedgerSpacingSmall),
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
            foregroundColor: workLedgerColorMuted,
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 44),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
            ),
          ),
          child: Text(localizations.homeMonthlySummary),
        ),
        TextButton(
          onPressed: onOpenLeaveManagement,
          style: TextButton.styleFrom(
            foregroundColor: workLedgerColorMuted,
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 44),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
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
      return <String>['기록된 근무 시간이 없습니다'];
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
