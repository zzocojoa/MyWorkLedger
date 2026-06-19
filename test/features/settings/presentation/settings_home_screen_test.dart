import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workledger/core/models/compensation_reference_setting.dart';
import 'package:workledger/core/models/leave_balance.dart';
import 'package:workledger/core/models/leave_usage.dart';
import 'package:workledger/core/models/work_rule.dart';
import 'package:workledger/core/notifications/workledger_notification_service.dart';
import 'package:workledger/features/compensation_reference/domain/compensation_reference_repository.dart';
import 'package:workledger/features/leave/domain/leave_repository.dart';
import 'package:workledger/features/leave/presentation/leave_balance_settings_screen.dart';
import 'package:workledger/features/settings/presentation/notification_settings_screen.dart';
import 'package:workledger/features/settings/presentation/settings_home_screen.dart';
import 'package:workledger/features/settings/presentation/work_settings_screen.dart';
import 'package:workledger/features/work_rule/domain/work_rule_repository.dart';

void main() {
  testWidgets('shows integrated settings entries', (WidgetTester tester) async {
    await tester.pumpWidget(_buildScreen());

    expect(find.text('설정'), findsOneWidget);
    expect(find.text('근무 설정'), findsOneWidget);
    expect(find.text('근무 기준'), findsNothing);
    expect(find.text('비교 방식'), findsNothing);
    expect(find.text('총 연차'), findsOneWidget);
    expect(find.text('알림'), findsOneWidget);
  });

  testWidgets('opens work settings', (WidgetTester tester) async {
    await tester.pumpWidget(_buildScreen());

    await tester.tap(find.text('근무 설정'));
    await tester.pumpAndSettle();

    expect(find.byType(WorkSettingsScreen), findsOneWidget);
    expect(find.text('정시 근무'), findsOneWidget);
    expect(find.text('포괄임금 시간'), findsOneWidget);
  });

  testWidgets('opens total leave settings', (WidgetTester tester) async {
    await tester.pumpWidget(_buildScreen());

    await tester.tap(find.text('총 연차'));
    await tester.pumpAndSettle();

    expect(find.byType(LeaveBalanceSettingsScreen), findsOneWidget);
    expect(find.text('2026'), findsOneWidget);
  });

  testWidgets('opens notification settings and configures notification', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildScreen());

    await tester.tap(find.text('알림'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('권한 요청 및 알림 다시 표시'));
    await tester.pump();
    await tester.pump();

    expect(find.byType(NotificationSettingsScreen), findsOneWidget);
    expect(find.text('상시 알림이 표시되었습니다.'), findsOneWidget);
  });
}

Widget _buildScreen() {
  return MaterialApp(
    home: SettingsHomeScreen(
      workRuleRepository: _FakeWorkRuleRepository(),
      compensationReferenceRepository: _FakeCompensationReferenceRepository(),
      leaveRepository: _FakeLeaveRepository(),
      configureNotifications: () async {
        return const WorkLedgerNotificationSetupResult(
          permissionGranted: true,
          notificationShown: true,
        );
      },
      now: () => DateTime(2026, 6, 12, 9),
    ),
  );
}

final class _FakeWorkRuleRepository implements WorkRuleRepository {
  @override
  Future<WorkRule?> findActive() async {
    return null;
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
    return WorkRule(
      id: 'work-rule-1',
      regularStartTimeMinutes: regularStartTimeMinutes,
      regularEndTimeMinutes: regularEndTimeMinutes,
      overtimeStartTimeMinutes: overtimeStartTimeMinutes,
      nightWorkStartTimeMinutes: nightWorkStartTimeMinutes,
      breakMinutes: breakMinutes,
      workWeekdays: workWeekdays,
      createdAt: DateTime(2026, 6, 12),
      updatedAt: DateTime(2026, 6, 12),
    );
  }
}

final class _FakeCompensationReferenceRepository
    implements CompensationReferenceRepository {
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
    return CompensationReferenceSetting(
      id: 'compensation-reference-1',
      mode: mode,
      fixedIncludedAfterRegularEndMinutes: fixedIncludedAfterRegularEndMinutes,
      effectiveFromMonth: effectiveFromMonth,
      memo: memo,
      createdAt: DateTime(2026, 6, 12),
      updatedAt: DateTime(2026, 6, 12),
    );
  }
}

final class _FakeLeaveRepository implements LeaveRepository {
  @override
  Future<LeaveBalance?> findBalanceByYear({required int year}) async {
    return null;
  }

  @override
  Future<LeaveBalance> saveBalance({
    required int year,
    required int totalLeaveMinutes,
  }) async {
    return LeaveBalance(
      id: 'leave-balance-1',
      year: year,
      totalLeaveMinutes: totalLeaveMinutes,
      createdAt: DateTime(2026, 6, 12),
      updatedAt: DateTime(2026, 6, 12),
    );
  }

  @override
  Future<List<LeaveUsage>> findUsagesByYear({required int year}) async {
    return <LeaveUsage>[];
  }

  @override
  Future<LeaveUsage> addUsage({
    required DateTime usedOn,
    required int usedLeaveMinutes,
    required String? memo,
  }) async {
    return LeaveUsage(
      id: 'leave-usage-1',
      usedOn: usedOn,
      usedLeaveMinutes: usedLeaveMinutes,
      memo: memo,
      createdAt: DateTime(2026, 6, 12),
      updatedAt: DateTime(2026, 6, 12),
    );
  }

  @override
  Future<void> deleteUsage({required String id}) async {}
}
