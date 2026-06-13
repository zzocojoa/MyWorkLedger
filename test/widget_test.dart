import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workledger/app/workledger_app.dart';
import 'package:workledger/core/models/leave_balance.dart';
import 'package:workledger/core/models/leave_usage.dart';
import 'package:workledger/core/models/pricing_intent_event.dart';
import 'package:workledger/core/models/work_record.dart';
import 'package:workledger/features/leave/domain/leave_repository.dart';
import 'package:workledger/features/pricing/domain/pricing_intent_repository.dart';
import 'package:workledger/features/work_record/presentation/work_record_home_screen.dart';
import 'package:workledger/features/work_record/domain/work_record_repository.dart';
import 'package:workledger/l10n/app_localizations.dart';

void main() {
  testWidgets('shows app names', (WidgetTester tester) async {
    await tester.pumpWidget(
      WorkLedgerApp(
        workRecordRepository: _WidgetTestWorkRecordRepository(),
        leaveRepository: _WidgetTestLeaveRepository(),
        pricingIntentRepository: _WidgetTestPricingIntentRepository(),
        now: () => DateTime(2026, 6, 12, 9, 0),
        navigatorKey: GlobalKey<NavigatorState>(),
      ),
    );
    await tester.pump();

    expect(find.text('내근무장부'), findsOneWidget);
    expect(find.text('아직 출근 전'), findsOneWidget);
    expect(find.text('출근하기'), findsOneWidget);
    expect(find.text('개인 로컬 기록'), findsOneWidget);

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

final class _WidgetTestWorkRecordRepository implements WorkRecordRepository {
  @override
  Future<WorkRecord?> findToday() async {
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
}
