import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workledger/core/notifications/workledger_notification_service.dart';
import 'package:workledger/core/models/compensation_reference_setting.dart';
import 'package:workledger/core/models/leave_balance.dart';
import 'package:workledger/core/models/leave_usage.dart';
import 'package:workledger/core/models/pricing_intent_event.dart';
import 'package:workledger/core/models/work_record.dart';
import 'package:workledger/core/models/work_rule.dart';
import 'package:workledger/features/compensation_reference/domain/compensation_reference_repository.dart';
import 'package:workledger/features/leave/domain/leave_repository.dart';
import 'package:workledger/features/leave/presentation/leave_management_screen.dart';
import 'package:workledger/features/leave/presentation/leave_balance_settings_screen.dart';
import 'package:workledger/features/monthly_summary/presentation/monthly_summary_screen.dart';
import 'package:workledger/features/pricing/domain/pricing_intent_repository.dart';
import 'package:workledger/features/settings/presentation/settings_home_screen.dart';
import 'package:workledger/features/settings/presentation/work_settings_screen.dart';
import 'package:workledger/features/work_record/domain/work_record_repository.dart';
import 'package:workledger/features/work_record/presentation/work_record_calendar_screen.dart';
import 'package:workledger/features/work_record/presentation/work_record_home_screen.dart';
import 'package:workledger/features/work_rule/domain/work_rule_repository.dart';
import 'package:workledger/l10n/app_localizations.dart';

void main() {
  testWidgets('shows before clock-in state and clocks in', (
    WidgetTester tester,
  ) async {
    final DateTime now = DateTime(2026, 6, 12, 9, 0);
    final _FakeWorkRecordRepository repository = _FakeWorkRecordRepository(
      initialRecord: null,
      monthlyRecords: <WorkRecord>[],
      now: () => now,
    );

    await tester.pumpWidget(_buildScreen(repository: repository, now: now));
    await tester.pump();

    expect(find.text('아직 출근 전'), findsOneWidget);
    expect(find.text('기록된 근무 시간이 없습니다'), findsOneWidget);
    expect(find.text('출근하기'), findsOneWidget);

    await tester.tap(find.text('출근하기'));
    await tester.pump();
    await tester.pump();

    expect(repository.clockInCallCount, 1);
    expect(find.text('근무 중'), findsOneWidget);
    expect(find.text('출근 09:00'), findsOneWidget);
  });

  testWidgets('shows working state and clocks out', (
    WidgetTester tester,
  ) async {
    final DateTime clockInAt = DateTime(2026, 6, 12, 9, 3);
    final DateTime now = DateTime(2026, 6, 12, 12, 45);
    final _FakeWorkRecordRepository repository = _FakeWorkRecordRepository(
      initialRecord: _workRecord(
        clockInAt: clockInAt,
        clockOutAt: null,
        now: clockInAt,
      ),
      monthlyRecords: <WorkRecord>[],
      now: () => now,
    );

    await tester.pumpWidget(_buildScreen(repository: repository, now: now));
    await tester.pump();

    expect(find.text('근무 중'), findsOneWidget);
    expect(find.text('출근 09:03'), findsOneWidget);
    expect(find.text('현재 3시간 42분 기록 중'), findsOneWidget);
    expect(find.text('퇴근하기'), findsOneWidget);

    await tester.tap(find.text('퇴근하기'));
    await tester.pump();
    await tester.pump();

    expect(repository.clockOutCallCount, 1);
    expect(find.text('오늘 기록 완료'), findsOneWidget);
    expect(find.text('09:03 - 12:45'), findsOneWidget);
    expect(find.text('총 3시간 42분'), findsOneWidget);
  });

  testWidgets('shows after clock-out state', (WidgetTester tester) async {
    final DateTime now = DateTime(2026, 6, 12, 19, 0);
    final _FakeWorkRecordRepository repository = _FakeWorkRecordRepository(
      initialRecord: _workRecord(
        clockInAt: DateTime(2026, 6, 12, 9, 3),
        clockOutAt: DateTime(2026, 6, 12, 18, 42),
        now: DateTime(2026, 6, 12, 18, 42),
      ),
      monthlyRecords: <WorkRecord>[],
      now: () => now,
    );

    await tester.pumpWidget(_buildScreen(repository: repository, now: now));
    await tester.pump();

    expect(find.text('오늘 기록 완료'), findsOneWidget);
    expect(find.text('09:03 - 18:42'), findsOneWidget);
    expect(find.text('총 9시간 39분'), findsOneWidget);
    expect(find.text('오늘 기록 수정'), findsOneWidget);
    expect(find.text('달력 보기'), findsOneWidget);
    expect(find.text('근무 태그를 볼까요?'), findsNothing);
  });

  testWidgets('opens work settings from settings home', (
    WidgetTester tester,
  ) async {
    final DateTime now = DateTime(2026, 6, 12, 19, 0);
    final _FakeWorkRuleRepository workRuleRepository = _FakeWorkRuleRepository(
      rule: null,
    );
    final _FakeWorkRecordRepository repository = _FakeWorkRecordRepository(
      initialRecord: _workRecord(
        clockInAt: DateTime(2026, 6, 12, 9, 3),
        clockOutAt: DateTime(2026, 6, 12, 18, 42),
        now: DateTime(2026, 6, 12, 18, 42),
      ),
      monthlyRecords: <WorkRecord>[],
      now: () => now,
    );

    await tester.pumpWidget(
      _buildScreen(
        repository: repository,
        workRuleRepository: workRuleRepository,
        now: now,
      ),
    );
    await tester.pump();

    await tester.tap(find.byTooltip('설정'));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsHomeScreen), findsOneWidget);

    await tester.tap(find.text('근무 설정'));
    await tester.pumpAndSettle();

    expect(find.byType(WorkSettingsScreen), findsOneWidget);
    expect(find.text('09:00-18:00 빠른 설정'), findsOneWidget);
    expect(find.text('기본 근무 기준'), findsOneWidget);
  });

  testWidgets('opens settings home from app bar action', (
    WidgetTester tester,
  ) async {
    final DateTime now = DateTime(2026, 6, 12, 19, 0);
    final _FakeWorkRuleRepository workRuleRepository = _FakeWorkRuleRepository(
      rule: _workRule(),
    );
    final _FakeWorkRecordRepository repository = _FakeWorkRecordRepository(
      initialRecord: null,
      monthlyRecords: <WorkRecord>[],
      now: () => now,
    );

    await tester.pumpWidget(
      _buildScreen(
        repository: repository,
        workRuleRepository: workRuleRepository,
        now: now,
      ),
    );
    await tester.pump();

    await tester.tap(find.byTooltip('설정'));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsHomeScreen), findsOneWidget);
    expect(find.text('설정'), findsOneWidget);
    expect(find.text('근무 설정'), findsOneWidget);
    expect(find.text('근무 기준'), findsNothing);
    expect(find.text('비교 방식'), findsNothing);
    expect(find.text('총 연차'), findsOneWidget);
    expect(find.text('알림'), findsOneWidget);
  });

  testWidgets('opens total leave settings from settings home', (
    WidgetTester tester,
  ) async {
    final DateTime now = DateTime(2026, 6, 12, 9, 0);
    final _FakeWorkRecordRepository repository = _FakeWorkRecordRepository(
      initialRecord: null,
      monthlyRecords: <WorkRecord>[],
      now: () => now,
    );

    await tester.pumpWidget(_buildScreen(repository: repository, now: now));
    await tester.pump();

    await tester.tap(find.byTooltip('설정'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('총 연차'));
    await tester.pumpAndSettle();

    expect(find.byType(LeaveBalanceSettingsScreen), findsOneWidget);
    expect(find.text('2026'), findsOneWidget);
  });

  testWidgets('shows current month preview values', (
    WidgetTester tester,
  ) async {
    final DateTime now = DateTime(2026, 6, 12, 19, 0);
    final WorkRecord firstRecord = _workRecord(
      clockInAt: DateTime(2026, 6, 12, 9, 0),
      clockOutAt: DateTime(2026, 6, 12, 18, 0),
      now: DateTime(2026, 6, 12, 18, 0),
    );
    final WorkRecord secondRecord = _workRecordWithId(
      id: 'record-2',
      clockInAt: DateTime(2026, 6, 13, 10, 0),
      clockOutAt: DateTime(2026, 6, 13, 12, 30),
      now: DateTime(2026, 6, 13, 12, 30),
    );
    final _FakeWorkRecordRepository repository = _FakeWorkRecordRepository(
      initialRecord: firstRecord,
      monthlyRecords: <WorkRecord>[firstRecord, secondRecord],
      now: () => now,
    );
    final _FakeLeaveRepository leaveRepository = _FakeLeaveRepository(
      balance: _leaveBalance(year: 2026, totalLeaveMinutes: 15 * 480, now: now),
      usages: <LeaveUsage>[
        _leaveUsage(
          id: 'leave-usage-1',
          usedOn: DateTime(2026, 3, 4),
          usedLeaveMinutes: 480,
          now: now,
        ),
      ],
    );

    await tester.pumpWidget(
      _buildScreen(
        repository: repository,
        leaveRepository: leaveRepository,
        workRuleRepository: _FakeWorkRuleRepository(rule: _workRule()),
        now: now,
      ),
    );
    await tester.pump();

    expect(find.text('이번 달'), findsOneWidget);
    expect(find.text('총 근무'), findsOneWidget);
    expect(find.text('9시간 30분'), findsOneWidget);
    expect(find.text('남은 연차'), findsOneWidget);
    expect(find.text('14일'), findsOneWidget);
    expect(find.text('준비 중'), findsNothing);
  });

  testWidgets('shows missing leave balance in current month preview', (
    WidgetTester tester,
  ) async {
    final DateTime now = DateTime(2026, 6, 12, 9, 0);
    final _FakeWorkRecordRepository repository = _FakeWorkRecordRepository(
      initialRecord: null,
      monthlyRecords: <WorkRecord>[],
      now: () => now,
    );

    await tester.pumpWidget(_buildScreen(repository: repository, now: now));
    await tester.pump();

    expect(find.text('총 근무'), findsOneWidget);
    expect(find.text('0분'), findsOneWidget);
    expect(find.text('남은 연차'), findsOneWidget);
    expect(find.text('총 연차 미입력'), findsOneWidget);
  });

  testWidgets('opens edit screen and refreshes after save', (
    WidgetTester tester,
  ) async {
    final DateTime now = DateTime(2026, 6, 12, 20, 0);
    final _FakeWorkRecordRepository repository = _FakeWorkRecordRepository(
      initialRecord: _workRecord(
        clockInAt: DateTime(2026, 6, 12, 9, 3),
        clockOutAt: DateTime(2026, 6, 12, 18, 42),
        now: DateTime(2026, 6, 12, 18, 42),
      ),
      monthlyRecords: <WorkRecord>[],
      now: () => now,
    );

    await tester.pumpWidget(_buildScreen(repository: repository, now: now));
    await tester.pump();

    await tester.tap(find.text('오늘 기록 수정'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('clockOutTimeField')), '19:10');
    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await tester.pumpAndSettle();

    expect(repository.upsertByDateCallCount, 1);
    expect(find.text('09:03 - 19:10'), findsOneWidget);
    expect(find.text('총 10시간 7분'), findsOneWidget);
  });

  testWidgets('shows explicit repository error', (WidgetTester tester) async {
    final DateTime now = DateTime(2026, 6, 12, 9, 0);
    final _FakeWorkRecordRepository repository =
        _FakeWorkRecordRepository(
            initialRecord: null,
            monthlyRecords: <WorkRecord>[],
            now: () => now,
          )
          ..clockInError = const WorkRecordRepositoryException(
            'action=clockIn rule=test failure',
          );

    await tester.pumpWidget(_buildScreen(repository: repository, now: now));
    await tester.pump();

    await tester.tap(find.text('출근하기'));
    await tester.pump();

    expect(
      find.text(
        'WorkRecordRepositoryException: action=clockIn rule=test failure',
      ),
      findsOneWidget,
    );
  });

  testWidgets('opens calendar from after clock-out secondary action', (
    WidgetTester tester,
  ) async {
    final DateTime now = DateTime(2026, 6, 12, 19, 0);
    final WorkRecord record = _workRecord(
      clockInAt: DateTime(2026, 6, 12, 9, 3),
      clockOutAt: DateTime(2026, 6, 12, 18, 42),
      now: DateTime(2026, 6, 12, 18, 42),
    );
    final _FakeWorkRecordRepository repository = _FakeWorkRecordRepository(
      initialRecord: record,
      monthlyRecords: <WorkRecord>[record],
      now: () => now,
    );

    await tester.pumpWidget(_buildScreen(repository: repository, now: now));
    await tester.pump();

    await tester.tap(find.text('달력 보기'));
    await tester.pumpAndSettle();

    expect(find.byType(WorkRecordCalendarScreen), findsOneWidget);
    expect(find.text('달력 보기'), findsOneWidget);
    expect(find.text('2026년 6월'), findsOneWidget);
    expect(find.text('총 9시간 39분'), findsOneWidget);
  });

  testWidgets('opens monthly summary from home monthly link', (
    WidgetTester tester,
  ) async {
    final DateTime now = DateTime(2026, 6, 12, 9, 0);
    final _FakeWorkRecordRepository repository = _FakeWorkRecordRepository(
      initialRecord: null,
      monthlyRecords: <WorkRecord>[],
      now: () => now,
    );

    await tester.pumpWidget(_buildScreen(repository: repository, now: now));
    await tester.pump();

    await tester.tap(find.text('월간 요약'));
    await tester.pumpAndSettle();

    expect(find.byType(MonthlySummaryScreen), findsOneWidget);
    expect(find.text('월간 요약'), findsOneWidget);
    expect(find.text('이 달 기록이 없습니다'), findsOneWidget);
  });

  testWidgets(
    'refreshes home after deleting today record from monthly summary',
    (WidgetTester tester) async {
      final DateTime now = DateTime(2026, 6, 12, 19, 0);
      final WorkRecord record = _workRecord(
        clockInAt: DateTime(2026, 6, 12, 9, 0),
        clockOutAt: DateTime(2026, 6, 12, 18, 0),
        now: DateTime(2026, 6, 12, 18, 0),
      );
      final _FakeWorkRecordRepository repository = _FakeWorkRecordRepository(
        initialRecord: record,
        monthlyRecords: <WorkRecord>[record],
        now: () => now,
      );

      await tester.pumpWidget(_buildScreen(repository: repository, now: now));
      await tester.pump();

      expect(find.text('오늘 기록 완료'), findsOneWidget);
      expect(find.text('09:00 - 18:00'), findsOneWidget);

      await tester.ensureVisible(find.text('월간 요약'));
      await tester.pump();
      await tester.tap(find.text('월간 요약'));
      await tester.pumpAndSettle();

      expect(find.byType(MonthlySummaryScreen), findsOneWidget);
      expect(find.text('06-12 09:00-18:00'), findsOneWidget);

      await tester.ensureVisible(find.byTooltip('근무 기록 삭제'));
      await tester.pump();
      await tester.tap(find.byTooltip('근무 기록 삭제'));
      await tester.pump();

      expect(find.text('근무 기록을 삭제할까요?'), findsOneWidget);
      expect(
        find.text('06-12 오늘 기록을 삭제합니다. 홈 상태도 출근 전으로 바뀝니다.'),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(TextButton, '삭제'));
      await tester.pump();
      await tester.pump();

      expect(repository.deleteByDateCallCount, 1);
      expect(find.text('이 달 기록이 없습니다'), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.byType(WorkRecordHomeScreen), findsOneWidget);
      expect(find.text('아직 출근 전'), findsOneWidget);
      expect(find.text('출근하기'), findsOneWidget);
      expect(find.text('0분'), findsOneWidget);
      expect(find.text('오늘 기록 완료'), findsNothing);
    },
  );

  testWidgets('opens leave management from home leave link', (
    WidgetTester tester,
  ) async {
    final DateTime now = DateTime(2026, 6, 12, 9, 0);
    final _FakeWorkRecordRepository repository = _FakeWorkRecordRepository(
      initialRecord: null,
      monthlyRecords: <WorkRecord>[],
      now: () => now,
    );

    await tester.pumpWidget(_buildScreen(repository: repository, now: now));
    await tester.pump();

    await tester.tap(find.text('연차 관리'));
    await tester.pumpAndSettle();

    expect(find.byType(LeaveManagementScreen), findsOneWidget);
    expect(find.text('연차 관리'), findsOneWidget);
    expect(find.text('기준 연도'), findsOneWidget);
  });
}

Widget _buildScreen({
  required _FakeWorkRecordRepository repository,
  required DateTime now,
  _FakeLeaveRepository? leaveRepository,
  _FakeWorkRuleRepository? workRuleRepository,
}) {
  final _FakeLeaveRepository resolvedLeaveRepository =
      leaveRepository ?? _FakeLeaveRepository.empty();
  final _FakeWorkRuleRepository resolvedWorkRuleRepository =
      workRuleRepository ?? _FakeWorkRuleRepository(rule: null);

  return MaterialApp(
    locale: const Locale('ko'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: WorkRecordHomeScreen(
      repository: repository,
      leaveRepository: resolvedLeaveRepository,
      workRuleRepository: resolvedWorkRuleRepository,
      compensationReferenceRepository:
          const _FakeCompensationReferenceRepository(),
      pricingIntentRepository: _FakePricingIntentRepository(),
      configureNotifications: () async {
        return const WorkLedgerNotificationSetupResult(
          permissionGranted: true,
          notificationShown: true,
        );
      },
      now: () => now,
    ),
  );
}

WorkRecord _workRecord({
  required DateTime clockInAt,
  required DateTime? clockOutAt,
  required DateTime now,
}) {
  return _workRecordWithId(
    id: 'record-1',
    clockInAt: clockInAt,
    clockOutAt: clockOutAt,
    now: now,
  );
}

WorkRecord _workRecordWithId({
  required String id,
  required DateTime clockInAt,
  required DateTime? clockOutAt,
  required DateTime now,
}) {
  return WorkRecord(
    id: id,
    workDate: DateTime(clockInAt.year, clockInAt.month, clockInAt.day),
    clockInAt: clockInAt,
    clockOutAt: clockOutAt,
    tags: <WorkRecordTag>[],
    memo: null,
    createdAt: now,
    updatedAt: now,
  );
}

LeaveBalance _leaveBalance({
  required int year,
  required int totalLeaveMinutes,
  required DateTime now,
}) {
  return LeaveBalance(
    id: 'leave-balance-$year',
    year: year,
    totalLeaveMinutes: totalLeaveMinutes,
    createdAt: now,
    updatedAt: now,
  );
}

LeaveUsage _leaveUsage({
  required String id,
  required DateTime usedOn,
  required int usedLeaveMinutes,
  required DateTime now,
}) {
  return LeaveUsage(
    id: id,
    usedOn: DateTime(usedOn.year, usedOn.month, usedOn.day),
    usedLeaveMinutes: usedLeaveMinutes,
    memo: null,
    createdAt: now,
    updatedAt: now,
  );
}

WorkRule _workRule() {
  return WorkRule(
    id: 'active-rule',
    regularStartTimeMinutes: 540,
    regularEndTimeMinutes: 1080,
    overtimeStartTimeMinutes: 1080,
    nightWorkStartTimeMinutes: 1320,
    breakMinutes: 60,
    workWeekdays: <int>[1, 2, 3, 4, 5],
    createdAt: DateTime(2026, 6, 12, 19),
    updatedAt: DateTime(2026, 6, 12, 19),
  );
}

final class _FakeWorkRecordRepository implements WorkRecordRepository {
  _FakeWorkRecordRepository({
    required WorkRecord? initialRecord,
    required this.monthlyRecords,
    required this.now,
  }) : _record = initialRecord;

  WorkRecord? _record;
  final List<WorkRecord> monthlyRecords;
  final DateTime Function() now;
  int clockInCallCount = 0;
  int clockOutCallCount = 0;
  int updateTodayCallCount = 0;
  int upsertByDateCallCount = 0;
  int deleteTodayCallCount = 0;
  int deleteByDateCallCount = 0;
  WorkRecordRepositoryException? clockInError;

  @override
  Future<WorkRecord?> findToday() async {
    return _record;
  }

  @override
  Future<WorkRecord?> findByDate({required DateTime workDate}) async {
    final DateTime targetDate = DateTime(
      workDate.year,
      workDate.month,
      workDate.day,
    );
    final WorkRecord? todayRecord = _record;
    if (todayRecord != null && todayRecord.workDate == targetDate) {
      return todayRecord;
    }
    for (final WorkRecord record in monthlyRecords) {
      if (record.workDate == targetDate) {
        return record;
      }
    }
    return null;
  }

  @override
  Future<List<WorkRecord>> findByMonth({
    required int year,
    required int month,
  }) async {
    return monthlyRecords
        .where((WorkRecord record) {
          return record.workDate.year == year && record.workDate.month == month;
        })
        .toList(growable: false);
  }

  @override
  Future<WorkRecord> clockIn() async {
    clockInCallCount += 1;
    final WorkRecordRepositoryException? error = clockInError;
    if (error != null) {
      throw error;
    }
    final DateTime value = now();
    _record = WorkRecord(
      id: 'record-1',
      workDate: DateTime(value.year, value.month, value.day),
      clockInAt: value,
      clockOutAt: null,
      tags: <WorkRecordTag>[],
      memo: null,
      createdAt: value,
      updatedAt: value,
    );
    return _record!;
  }

  @override
  Future<WorkRecord> clockOut() async {
    clockOutCallCount += 1;
    final WorkRecord? record = _record;
    if (record == null) {
      throw const WorkRecordRepositoryException(
        'action=clockOut rule=missing record',
      );
    }
    final DateTime value = now();
    _record = record.copyWith(
      id: record.id,
      workDate: record.workDate,
      clockInAt: record.clockInAt,
      clockOutAt: value,
      tags: record.tags,
      memo: record.memo,
      createdAt: record.createdAt,
      updatedAt: value,
    );
    return _record!;
  }

  @override
  Future<WorkRecord> updateToday({
    required DateTime? clockInAt,
    required DateTime? clockOutAt,
    required List<WorkRecordTag> tags,
    required String? memo,
  }) async {
    updateTodayCallCount += 1;
    final WorkRecord? record = _record;
    if (record == null) {
      throw const WorkRecordRepositoryException(
        'action=updateToday rule=missing record',
      );
    }
    final DateTime value = now();
    _record = record.copyWith(
      id: record.id,
      workDate: record.workDate,
      clockInAt: clockInAt,
      clockOutAt: clockOutAt,
      tags: tags,
      memo: memo,
      createdAt: record.createdAt,
      updatedAt: value,
    );
    return _record!;
  }

  @override
  Future<WorkRecord> upsertByDate({
    required DateTime workDate,
    required DateTime? clockInAt,
    required DateTime? clockOutAt,
    required List<WorkRecordTag> tags,
    required String? memo,
  }) async {
    upsertByDateCallCount += 1;
    final DateTime targetDate = DateTime(
      workDate.year,
      workDate.month,
      workDate.day,
    );
    final WorkRecord? existingRecord = await findByDate(workDate: targetDate);
    final DateTime value = now();
    final WorkRecord savedRecord = existingRecord == null
        ? WorkRecord(
            id: 'record-${targetDate.toIso8601String()}',
            workDate: targetDate,
            clockInAt: clockInAt,
            clockOutAt: clockOutAt,
            tags: tags,
            memo: memo,
            createdAt: value,
            updatedAt: value,
          )
        : existingRecord.copyWith(
            id: existingRecord.id,
            workDate: existingRecord.workDate,
            clockInAt: clockInAt,
            clockOutAt: clockOutAt,
            tags: tags,
            memo: memo,
            createdAt: existingRecord.createdAt,
            updatedAt: value,
          );
    monthlyRecords.removeWhere((WorkRecord record) {
      return record.workDate == targetDate;
    });
    monthlyRecords.add(savedRecord);
    if (_record?.workDate == targetDate ||
        targetDate == DateTime(now().year, now().month, now().day)) {
      _record = savedRecord;
    }
    return savedRecord;
  }

  @override
  Future<void> deleteToday() async {
    deleteTodayCallCount += 1;
    if (_record == null) {
      throw const WorkRecordRepositoryException(
        'action=deleteToday rule=missing record',
      );
    }
    _record = null;
  }

  @override
  Future<void> deleteByDate({required DateTime workDate}) async {
    deleteByDateCallCount += 1;
    final DateTime targetDate = DateTime(
      workDate.year,
      workDate.month,
      workDate.day,
    );
    final int beforeCount = monthlyRecords.length;
    monthlyRecords.removeWhere((WorkRecord record) {
      return record.workDate == targetDate;
    });
    final WorkRecord? todayRecord = _record;
    if (todayRecord != null && todayRecord.workDate == targetDate) {
      _record = null;
    }
    if (beforeCount == monthlyRecords.length && todayRecord == _record) {
      throw WorkRecordRepositoryException(
        'action=deleteByDate workDate=${targetDate.toIso8601String()} rule=missing record',
      );
    }
  }
}

final class _FakePricingIntentRepository implements PricingIntentRepository {
  @override
  Future<PricingIntentEvent> save({
    required PricingIntentEventType eventType,
    required PricingPlan? selectedPlan,
    required String sourceScreen,
  }) async {
    return PricingIntentEvent(
      id: 'pricing-event-1',
      eventType: eventType,
      selectedPlan: selectedPlan,
      sourceScreen: sourceScreen,
      occurredAt: DateTime(2026, 6, 12, 18, 42),
      createdAt: DateTime(2026, 6, 12, 18, 42),
    );
  }

  @override
  Future<List<PricingIntentEvent>> findAll() async {
    return <PricingIntentEvent>[];
  }
}

final class _FakeLeaveRepository implements LeaveRepository {
  _FakeLeaveRepository({
    required this.balance,
    required List<LeaveUsage> usages,
  }) : usages = List<LeaveUsage>.unmodifiable(usages);

  factory _FakeLeaveRepository.empty() {
    return _FakeLeaveRepository(balance: null, usages: <LeaveUsage>[]);
  }

  final LeaveBalance? balance;
  final List<LeaveUsage> usages;

  @override
  Future<LeaveBalance?> findBalanceByYear({required int year}) async {
    final LeaveBalance? value = balance;
    if (value == null || value.year != year) {
      return null;
    }
    return value;
  }

  @override
  Future<LeaveBalance> saveBalance({
    required int year,
    required int totalLeaveMinutes,
  }) async {
    throw const LeaveRepositoryException('unexpected saveBalance call');
  }

  @override
  Future<List<LeaveUsage>> findUsagesByYear({required int year}) async {
    return usages
        .where((LeaveUsage usage) => usage.usedOn.year == year)
        .toList(growable: false);
  }

  @override
  Future<LeaveUsage> addUsage({
    required DateTime usedOn,
    required int usedLeaveMinutes,
    required String? memo,
  }) async {
    throw const LeaveRepositoryException('unexpected addUsage call');
  }

  @override
  Future<void> deleteUsage({required String id}) async {
    throw const LeaveRepositoryException('unexpected deleteUsage call');
  }
}

final class _FakeWorkRuleRepository implements WorkRuleRepository {
  _FakeWorkRuleRepository({required this.rule});

  WorkRule? rule;

  @override
  Future<WorkRule?> findActive() async {
    return rule;
  }

  @override
  Future<WorkRule> save({
    required int regularStartTimeMinutes,
    required int regularEndTimeMinutes,
    required int overtimeStartTimeMinutes,
    required int nightWorkStartTimeMinutes,
    required int breakMinutes,
    required List<int> workWeekdays,
  }) async {
    final WorkRule savedRule = WorkRule(
      id: 'active-rule',
      regularStartTimeMinutes: regularStartTimeMinutes,
      regularEndTimeMinutes: regularEndTimeMinutes,
      overtimeStartTimeMinutes: overtimeStartTimeMinutes,
      nightWorkStartTimeMinutes: nightWorkStartTimeMinutes,
      breakMinutes: breakMinutes,
      workWeekdays: workWeekdays,
      createdAt: DateTime(2026, 6, 12, 19),
      updatedAt: DateTime(2026, 6, 12, 19),
    );
    rule = savedRule;
    return savedRule;
  }
}

final class _FakeCompensationReferenceRepository
    implements CompensationReferenceRepository {
  const _FakeCompensationReferenceRepository();

  @override
  Future<CompensationReferenceSetting?> findApplicableForMonth({
    required int year,
    required int month,
  }) async {
    return null;
  }

  @override
  Future<CompensationReferenceSetting> save({
    required CompensationReferenceMode mode,
    required int fixedIncludedAfterRegularEndMinutes,
    required DateTime effectiveFromMonth,
    required String? memo,
  }) async {
    throw const CompensationReferenceRepositoryException(
      'unexpected save call',
    );
  }
}
