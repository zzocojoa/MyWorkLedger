import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workledger/app/workledger_app.dart';
import 'package:workledger/core/notifications/workledger_notification_service.dart';
import 'package:workledger/core/models/compensation_reference_setting.dart';
import 'package:workledger/core/models/leave_balance.dart';
import 'package:workledger/core/models/leave_usage.dart';
import 'package:workledger/core/models/pricing_intent_event.dart';
import 'package:workledger/core/models/work_record.dart';
import 'package:workledger/core/models/work_rule.dart';
import 'package:workledger/features/compensation_reference/domain/compensation_reference_repository.dart';
import 'package:workledger/features/leave/domain/leave_repository.dart';
import 'package:workledger/features/pricing/domain/pricing_intent_repository.dart';
import 'package:workledger/features/work_record/presentation/work_record_home_screen.dart';
import 'package:workledger/features/work_record/domain/work_record_repository.dart';
import 'package:workledger/features/work_rule/domain/work_rule_repository.dart';
import 'package:workledger/l10n/app_localizations.dart';

void main() {
  testWidgets('shows app names', (WidgetTester tester) async {
    await tester.pumpWidget(
      WorkLedgerApp(
        workRecordRepository: _WidgetTestWorkRecordRepository(),
        leaveRepository: _WidgetTestLeaveRepository(),
        workRuleRepository: _WidgetTestWorkRuleRepository(),
        compensationReferenceRepository:
            _WidgetTestCompensationReferenceRepository(),
        pricingIntentRepository: _WidgetTestPricingIntentRepository(),
        configureNotifications: () async {
          return const WorkLedgerNotificationSetupResult(
            permissionGranted: true,
            notificationShown: true,
          );
        },
        now: () => DateTime(2026, 6, 12, 9, 0),
        navigatorKey: GlobalKey<NavigatorState>(),
      ),
    );
    await tester.pump();

    expect(find.text('내근무장부'), findsOneWidget);
    expect(find.text('아직 출근 전'), findsOneWidget);
    expect(find.text('출근하기'), findsOneWidget);

    final BuildContext context = tester.element(
      find.byType(WorkRecordHomeScreen),
    );
    expect(Localizations.localeOf(context), const Locale('ko'));
    expect(AppLocalizations.of(context).homeMonthlySummary, '월간 요약');
    expect(AppLocalizations.supportedLocales, contains(const Locale('en')));
  });
}

final class _WidgetTestLeaveRepository implements LeaveRepository {
  @override
  Future<LeaveBalance?> findBalanceByYear({required int year}) async {
    return null;
  }

  @override
  Future<LeaveBalance> saveBalance({
    required int year,
    required int totalLeaveMinutes,
  }) async {
    throw const LeaveRepositoryException('test=widget action=saveBalance');
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
    throw const LeaveRepositoryException('test=widget action=addUsage');
  }

  @override
  Future<void> deleteUsage({required String id}) async {
    throw const LeaveRepositoryException('test=widget action=deleteUsage');
  }
}

final class _WidgetTestPricingIntentRepository
    implements PricingIntentRepository {
  @override
  Future<PricingIntentEvent> save({
    required PricingIntentEventType eventType,
    required PricingPlan? selectedPlan,
    required String sourceScreen,
  }) async {
    throw const PricingIntentRepositoryException(
      'test=widget action=savePricingIntent',
    );
  }

  @override
  Future<List<PricingIntentEvent>> findAll() async {
    return <PricingIntentEvent>[];
  }
}

final class _WidgetTestWorkRuleRepository implements WorkRuleRepository {
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
    throw const WorkRuleRepositoryException('test=widget action=saveWorkRule');
  }
}

final class _WidgetTestCompensationReferenceRepository
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
    throw const CompensationReferenceRepositoryException(
      'test=widget action=saveCompensationReference',
    );
  }
}

final class _WidgetTestWorkRecordRepository implements WorkRecordRepository {
  @override
  Future<WorkRecord?> findToday() async {
    return null;
  }

  @override
  Future<WorkRecord?> findByDate({required DateTime workDate}) async {
    return null;
  }

  @override
  Future<List<WorkRecord>> findByMonth({
    required int year,
    required int month,
  }) async {
    return <WorkRecord>[];
  }

  @override
  Future<WorkRecord> clockIn() async {
    throw const WorkRecordRepositoryException('test=widget action=clockIn');
  }

  @override
  Future<WorkRecord> clockOut() async {
    throw const WorkRecordRepositoryException('test=widget action=clockOut');
  }

  @override
  Future<WorkRecord> updateToday({
    required DateTime? clockInAt,
    required DateTime? clockOutAt,
    required List<WorkRecordTag> tags,
    required String? memo,
  }) async {
    throw const WorkRecordRepositoryException('test=widget action=updateToday');
  }

  @override
  Future<WorkRecord> upsertByDate({
    required DateTime workDate,
    required DateTime? clockInAt,
    required DateTime? clockOutAt,
    required List<WorkRecordTag> tags,
    required String? memo,
  }) async {
    throw const WorkRecordRepositoryException(
      'test=widget action=upsertByDate',
    );
  }

  @override
  Future<void> deleteToday() async {
    throw const WorkRecordRepositoryException('test=widget action=deleteToday');
  }

  @override
  Future<void> deleteByDate({required DateTime workDate}) async {
    throw const WorkRecordRepositoryException(
      'test=widget action=deleteByDate',
    );
  }
}
