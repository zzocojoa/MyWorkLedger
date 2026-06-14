import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workledger/core/models/compensation_reference_setting.dart';
import 'package:workledger/core/models/leave_balance.dart';
import 'package:workledger/core/models/leave_usage.dart';
import 'package:workledger/core/models/pricing_intent_event.dart';
import 'package:workledger/core/models/work_record.dart';
import 'package:workledger/core/models/work_rule.dart';
import 'package:workledger/features/compensation_reference/domain/compensation_reference_repository.dart';
import 'package:workledger/features/leave/domain/leave_repository.dart';
import 'package:workledger/features/monthly_summary/presentation/monthly_summary_screen.dart';
import 'package:workledger/features/pricing/domain/pricing_intent_repository.dart';
import 'package:workledger/features/pricing/presentation/pricing_fake_door_screen.dart';
import 'package:workledger/features/work_record/domain/work_record_repository.dart';
import 'package:workledger/features/work_rule/domain/work_rule_repository.dart';

void main() {
  testWidgets('shows empty monthly summary state', (WidgetTester tester) async {
    final _FakeWorkRecordRepository repository = _FakeWorkRecordRepository(
      monthlyRecords: <WorkRecord>[],
      findByMonthError: null,
    );

    await tester.pumpWidget(
      _buildScreen(
        repository: repository,
        leaveRepository: _emptyLeaveRepository(),
        now: DateTime(2026, 6, 12, 9, 0),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('월간 요약'), findsOneWidget);
    expect(find.text('2026-06'), findsOneWidget);
    expect(find.text('이번 달 총 근무'), findsOneWidget);
    expect(find.text('0분'), findsOneWidget);
    expect(find.text('0일'), findsOneWidget);
    expect(find.text('근무 태그'), findsOneWidget);
    expect(find.text('기준 미설정'), findsOneWidget);
    expect(find.text('근무 기준 설정'), findsNothing);
    expect(find.text('연차 요약'), findsOneWidget);
    expect(find.text('남은 연차'), findsOneWidget);
    expect(find.text('총 연차를 입력해 주세요'), findsOneWidget);
    expect(find.text('이번 달 사용 연차'), findsOneWidget);
    expect(find.text('연차 관리에서 올해 총 연차를 먼저 입력하세요'), findsOneWidget);
    expect(find.text('이 달 기록이 없습니다'), findsOneWidget);
    expect(find.text('월간 리포트 만들기'), findsOneWidget);
    expect(find.text('홈으로'), findsNothing);
    expect(repository.requestedYear, 2026);
    expect(repository.requestedMonth, 6);
  });

  testWidgets('shows completed monthly records and tag labels', (
    WidgetTester tester,
  ) async {
    final _FakeWorkRecordRepository repository = _FakeWorkRecordRepository(
      monthlyRecords: <WorkRecord>[
        _completedRecord(
          id: 'work-1',
          clockInAt: DateTime(2026, 6, 1, 9, 0),
          clockOutAt: DateTime(2026, 6, 1, 20, 30),
          tags: <WorkRecordTag>[WorkRecordTag.overtime],
        ),
        _completedRecord(
          id: 'work-2',
          clockInAt: DateTime(2026, 6, 3, 9, 10),
          clockOutAt: DateTime(2026, 6, 3, 18, 20),
          tags: <WorkRecordTag>[],
        ),
      ],
      findByMonthError: null,
    );

    await tester.pumpWidget(
      _buildScreen(
        repository: repository,
        leaveRepository: _FakeLeaveRepository(
          balance: _leaveBalance(totalLeaveMinutes: 7200),
          usages: <LeaveUsage>[
            _leaveUsage(
              id: 'leave-1',
              usedOn: DateTime(2026, 6, 10),
              usedLeaveMinutes: 240,
            ),
            _leaveUsage(
              id: 'leave-2',
              usedOn: DateTime(2026, 5, 31),
              usedLeaveMinutes: 480,
            ),
          ],
          findBalanceError: null,
          findUsagesError: null,
        ),
        workRuleRepository: _FakeWorkRuleRepository(
          rule: _workRule(),
          findActiveError: null,
        ),
        now: DateTime(2026, 6, 12, 9, 0),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('18시간 40분'), findsOneWidget);
    expect(find.text('휴게시간을 제외한 개인 참고용 기록입니다'), findsNothing);
    expect(find.text('2일'), findsOneWidget);
    expect(find.text('근무 태그'), findsWidgets);
    expect(find.text('1개'), findsOneWidget);
    expect(find.text('2시간 50분'), findsOneWidget);
    expect(find.text('13일 4시간'), findsOneWidget);
    expect(find.text('이번 달 사용 연차'), findsOneWidget);
    expect(find.text('4시간'), findsOneWidget);
    expect(find.text('총 15일 · 올해 사용 1일 4시간'), findsOneWidget);
    expect(find.text('연차 관리에서 올해 총 연차를 먼저 입력하세요'), findsNothing);
    expect(find.text('이번 달 기록'), findsOneWidget);
    expect(find.text('06-01 09:00-20:30'), findsOneWidget);
    expect(find.text('야근'), findsNothing);
    expect(find.textContaining('기록 사유:'), findsNothing);
    expect(find.text('06-03 09:10-18:20'), findsOneWidget);
  });

  testWidgets('shows included time comparison when fixed included is set', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _buildScreen(
        repository: _FakeWorkRecordRepository(
          monthlyRecords: <WorkRecord>[
            _completedRecord(
              id: 'work-1',
              clockInAt: DateTime(2026, 6, 1, 9, 0),
              clockOutAt: DateTime(2026, 6, 1, 21, 30),
              tags: <WorkRecordTag>[],
            ),
          ],
          findByMonthError: null,
        ),
        leaveRepository: _emptyLeaveRepository(),
        workRuleRepository: _FakeWorkRuleRepository(
          rule: _workRule(),
          findActiveError: null,
        ),
        compensationReferenceRepository: _FakeCompensationReferenceRepository(
          setting: _compensationReferenceSetting(
            mode: CompensationReferenceMode.fixedIncluded,
            fixedIncludedOvertimeMinutes: 120,
            fixedIncludedNightMinutes: 0,
            fixedIncludedHolidayMinutes: 0,
          ),
          findApplicableError: null,
        ),
        now: DateTime(2026, 6, 12, 9),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('포함 시간 대비'), findsOneWidget);
    expect(find.text('실제 기록'), findsWidgets);
    expect(find.text('포함 시간'), findsWidgets);
    expect(find.text('초과 참고'), findsWidgets);
    expect(find.text('연장 근무'), findsWidgets);
    expect(find.text('3시간 30분'), findsWidgets);
    expect(find.text('2시간'), findsOneWidget);
    expect(find.text('1시간 30분'), findsOneWidget);
    expect(find.text('고정 포함 시간 비교 설정'), findsNothing);
  });

  testWidgets('hides included time comparison when setting is not fixed', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _buildScreen(
        repository: _FakeWorkRecordRepository(
          monthlyRecords: <WorkRecord>[
            _completedRecord(
              id: 'work-1',
              clockInAt: DateTime(2026, 6, 1, 9, 0),
              clockOutAt: DateTime(2026, 6, 1, 21, 30),
              tags: <WorkRecordTag>[],
            ),
          ],
          findByMonthError: null,
        ),
        leaveRepository: _emptyLeaveRepository(),
        workRuleRepository: _FakeWorkRuleRepository(
          rule: _workRule(),
          findActiveError: null,
        ),
        compensationReferenceRepository: _FakeCompensationReferenceRepository(
          setting: _compensationReferenceSetting(
            mode: CompensationReferenceMode.unknown,
            fixedIncludedOvertimeMinutes: 0,
            fixedIncludedNightMinutes: 0,
            fixedIncludedHolidayMinutes: 0,
          ),
          findApplicableError: null,
        ),
        now: DateTime(2026, 6, 12, 9),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('포함 시간 대비'), findsNothing);
    expect(find.text('초과 참고'), findsNothing);
  });

  testWidgets(
    'shows candidate duration by work rule instead of whole-day tags',
    (WidgetTester tester) async {
      final _FakeWorkRecordRepository repository = _FakeWorkRecordRepository(
        monthlyRecords: <WorkRecord>[
          _completedRecord(
            id: 'early-and-overtime',
            clockInAt: DateTime(2026, 6, 1, 7, 26),
            clockOutAt: DateTime(2026, 6, 1, 21, 26),
            tags: <WorkRecordTag>[],
          ),
          _completedRecord(
            id: 'tag-delayed',
            clockInAt: DateTime(2026, 6, 2, 18, 0),
            clockOutAt: DateTime(2026, 6, 2, 21, 30),
            tags: <WorkRecordTag>[WorkRecordTag.delayedCheckout],
          ),
          _completedRecord(
            id: 'tag-holiday',
            clockInAt: DateTime(2026, 6, 6, 10, 0),
            clockOutAt: DateTime(2026, 6, 6, 14, 15),
            tags: <WorkRecordTag>[WorkRecordTag.holidayWork],
          ),
        ],
        findByMonthError: null,
      );

      await tester.pumpWidget(
        _buildScreen(
          repository: repository,
          leaveRepository: _emptyLeaveRepository(),
          workRuleRepository: _FakeWorkRuleRepository(
            rule: _workRule(),
            findActiveError: null,
          ),
          now: DateTime(2026, 6, 12, 9, 0),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('근무 태그'), findsWidgets);
      expect(find.text('3개'), findsOneWidget);
      expect(find.text('휴무일 근무'), findsOneWidget);
      expect(find.text('3시간 15분'), findsOneWidget);
      expect(find.text('정시 전 근무'), findsOneWidget);
      expect(find.text('1시간 34분'), findsOneWidget);
      expect(find.text('연장 근무'), findsOneWidget);
      expect(find.text('3시간 26분'), findsOneWidget);
      expect(find.text('야간 근무'), findsNothing);
      expect(find.text('개인 참고용 후보입니다. 급여나 법정 수당 확정값이 아닙니다.'), findsNothing);
      expect(find.text('기록 사유: 퇴근 기록 지연'), findsOneWidget);
    },
  );

  testWidgets('hides work tag result card when work rule has no active tags', (
    WidgetTester tester,
  ) async {
    final _FakeWorkRecordRepository repository = _FakeWorkRecordRepository(
      monthlyRecords: <WorkRecord>[
        _completedRecord(
          id: 'regular-work',
          clockInAt: DateTime(2026, 6, 1, 9, 0),
          clockOutAt: DateTime(2026, 6, 1, 18, 0),
          tags: <WorkRecordTag>[],
        ),
      ],
      findByMonthError: null,
    );

    await tester.pumpWidget(
      _buildScreen(
        repository: repository,
        leaveRepository: _emptyLeaveRepository(),
        workRuleRepository: _FakeWorkRuleRepository(
          rule: _workRule(),
          findActiveError: null,
        ),
        now: DateTime(2026, 6, 12, 9, 0),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('8시간'), findsOneWidget);
    expect(find.text('1일'), findsOneWidget);
    expect(find.text('0개'), findsOneWidget);
    expect(find.text('정시 기준 외 근무 없음'), findsNothing);
    expect(find.text('이번 달 기록은 설정한 근무 기준 안에 있습니다.'), findsNothing);
    expect(find.text('휴무일 근무'), findsNothing);
    expect(find.text('정시 전 근무'), findsNothing);
    expect(find.text('연장 근무'), findsNothing);
    expect(find.text('야간 근무'), findsNothing);
  });

  testWidgets('shows exceeded leave state clearly', (
    WidgetTester tester,
  ) async {
    final _FakeWorkRecordRepository repository = _FakeWorkRecordRepository(
      monthlyRecords: <WorkRecord>[],
      findByMonthError: null,
    );

    await tester.pumpWidget(
      _buildScreen(
        repository: repository,
        leaveRepository: _FakeLeaveRepository(
          balance: _leaveBalance(totalLeaveMinutes: 480),
          usages: <LeaveUsage>[
            _leaveUsage(
              id: 'leave-overuse',
              usedOn: DateTime(2026, 6, 10),
              usedLeaveMinutes: 960,
            ),
          ],
          findBalanceError: null,
          findUsagesError: null,
        ),
        now: DateTime(2026, 6, 12, 9, 0),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('초과 1일'), findsOneWidget);
    expect(find.text('이번 달 사용 연차'), findsOneWidget);
    expect(find.text('2일'), findsOneWidget);
    expect(find.text('총 1일 · 올해 사용 2일'), findsOneWidget);
    expect(find.text('초과 사용 중'), findsOneWidget);
  });

  testWidgets('shows incomplete monthly record status clearly', (
    WidgetTester tester,
  ) async {
    final _FakeWorkRecordRepository repository = _FakeWorkRecordRepository(
      monthlyRecords: <WorkRecord>[
        _incompleteRecord(
          id: 'missing-clock-out',
          workDate: DateTime(2026, 6, 2),
          clockInAt: DateTime(2026, 6, 2, 9, 0),
          clockOutAt: null,
        ),
        _incompleteRecord(
          id: 'missing-clock-in',
          workDate: DateTime(2026, 6, 3),
          clockInAt: null,
          clockOutAt: DateTime(2026, 6, 3, 18, 0),
        ),
        _incompleteRecord(
          id: 'missing-both',
          workDate: DateTime(2026, 6, 4),
          clockInAt: null,
          clockOutAt: null,
        ),
      ],
      findByMonthError: null,
    );

    await tester.pumpWidget(
      _buildScreen(
        repository: repository,
        leaveRepository: _emptyLeaveRepository(),
        now: DateTime(2026, 6, 12, 9, 0),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('06-02 출근만 기록됨'), findsOneWidget);
    expect(find.text('06-03 퇴근만 기록됨'), findsOneWidget);
    expect(find.text('06-04 시간이 비어 있음'), findsOneWidget);
    expect(find.text('0일'), findsOneWidget);
  });

  testWidgets('deletes monthly work record after confirmation and refreshes', (
    WidgetTester tester,
  ) async {
    final _FakeWorkRecordRepository repository = _FakeWorkRecordRepository(
      monthlyRecords: <WorkRecord>[
        _completedRecord(
          id: 'delete-target',
          clockInAt: DateTime(2026, 6, 1, 9, 0),
          clockOutAt: DateTime(2026, 6, 1, 17, 0),
          tags: <WorkRecordTag>[],
        ),
        _completedRecord(
          id: 'remaining-record',
          clockInAt: DateTime(2026, 6, 2, 10, 0),
          clockOutAt: DateTime(2026, 6, 2, 14, 0),
          tags: <WorkRecordTag>[],
        ),
      ],
      findByMonthError: null,
    );

    await tester.pumpWidget(
      _buildScreen(
        repository: repository,
        leaveRepository: _emptyLeaveRepository(),
        now: DateTime(2026, 6, 12, 9, 0),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('12시간'), findsOneWidget);
    expect(find.text('06-01 09:00-17:00'), findsOneWidget);
    expect(find.text('06-02 10:00-14:00'), findsOneWidget);

    await tester.ensureVisible(find.byTooltip('근무 기록 삭제').first);
    await tester.pump();
    await tester.tap(find.byTooltip('근무 기록 삭제').first);
    await tester.pump();

    expect(find.text('근무 기록을 삭제할까요?'), findsOneWidget);
    expect(find.text('06-01 기록을 삭제합니다.'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, '삭제'));
    await tester.pump();
    await tester.pump();

    expect(repository.deleteByDateCallCount, 1);
    expect(repository.deletedWorkDate, DateTime(2026, 6, 1));
    expect(find.text('06-01 09:00-17:00'), findsNothing);
    expect(find.text('06-02 10:00-14:00'), findsOneWidget);
    expect(find.text('4시간'), findsOneWidget);
  });

  testWidgets(
    'does not delete monthly work record when confirmation is cancelled',
    (WidgetTester tester) async {
      final _FakeWorkRecordRepository repository = _FakeWorkRecordRepository(
        monthlyRecords: <WorkRecord>[
          _completedRecord(
            id: 'delete-cancelled',
            clockInAt: DateTime(2026, 6, 1, 9, 0),
            clockOutAt: DateTime(2026, 6, 1, 17, 0),
            tags: <WorkRecordTag>[],
          ),
        ],
        findByMonthError: null,
      );

      await tester.pumpWidget(
        _buildScreen(
          repository: repository,
          leaveRepository: _emptyLeaveRepository(),
          now: DateTime(2026, 6, 12, 9, 0),
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.ensureVisible(find.byTooltip('근무 기록 삭제').first);
      await tester.pump();
      await tester.tap(find.byTooltip('근무 기록 삭제').first);
      await tester.pump();
      await tester.tap(find.widgetWithText(TextButton, '취소'));
      await tester.pump();

      expect(repository.deleteByDateCallCount, 0);
      expect(find.text('06-01 09:00-17:00'), findsOneWidget);
    },
  );

  testWidgets('shows Korean error when repository fails', (
    WidgetTester tester,
  ) async {
    final _FakeWorkRecordRepository repository = _FakeWorkRecordRepository(
      monthlyRecords: <WorkRecord>[],
      findByMonthError: const WorkRecordRepositoryException(
        'action=findByMonth rule=test failure',
      ),
    );

    await tester.pumpWidget(
      _buildScreen(
        repository: repository,
        leaveRepository: _emptyLeaveRepository(),
        now: DateTime(2026, 6, 12, 9, 0),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('월간 요약을 불러올 수 없습니다.'), findsOneWidget);
    expect(find.textContaining('action=findByMonth'), findsOneWidget);
  });

  testWidgets('opens fake-door screen and saves report button intent', (
    WidgetTester tester,
  ) async {
    final _FakeWorkRecordRepository repository = _FakeWorkRecordRepository(
      monthlyRecords: <WorkRecord>[],
      findByMonthError: null,
    );
    final _FakePricingIntentRepository pricingIntentRepository =
        _FakePricingIntentRepository(
          failingEventTypes: <PricingIntentEventType>{},
        );

    await tester.pumpWidget(
      _buildScreenWithPricingRepository(
        repository: repository,
        leaveRepository: _emptyLeaveRepository(),
        workRuleRepository: const _FakeWorkRuleRepository(
          rule: null,
          findActiveError: null,
        ),
        compensationReferenceRepository:
            const _FakeCompensationReferenceRepository(
              setting: null,
              findApplicableError: null,
            ),
        pricingIntentRepository: pricingIntentRepository,
        now: DateTime(2026, 6, 12, 9, 0),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.ensureVisible(find.text('월간 리포트 만들기'));
    await tester.pump();
    await tester.tap(find.text('월간 리포트 만들기'));
    await tester.pumpAndSettle();

    expect(find.byType(PricingFakeDoorScreen), findsOneWidget);
    expect(find.text('월간 리포트'), findsOneWidget);
    expect(
      pricingIntentRepository.savedEvents.map(
        (PricingIntentEvent event) => event.eventType,
      ),
      <PricingIntentEventType>[
        PricingIntentEventType.reportButtonTapped,
        PricingIntentEventType.pricingScreenViewed,
      ],
    );
    expect(
      pricingIntentRepository.savedEvents.first.sourceScreen,
      'monthly_summary',
    );
  });

  testWidgets('shows Korean error when report button intent save fails', (
    WidgetTester tester,
  ) async {
    final _FakeWorkRecordRepository repository = _FakeWorkRecordRepository(
      monthlyRecords: <WorkRecord>[],
      findByMonthError: null,
    );
    final _FakePricingIntentRepository pricingIntentRepository =
        _FakePricingIntentRepository(
          failingEventTypes: <PricingIntentEventType>{
            PricingIntentEventType.reportButtonTapped,
          },
        );

    await tester.pumpWidget(
      _buildScreenWithPricingRepository(
        repository: repository,
        leaveRepository: _emptyLeaveRepository(),
        workRuleRepository: const _FakeWorkRuleRepository(
          rule: null,
          findActiveError: null,
        ),
        compensationReferenceRepository:
            const _FakeCompensationReferenceRepository(
              setting: null,
              findApplicableError: null,
            ),
        pricingIntentRepository: pricingIntentRepository,
        now: DateTime(2026, 6, 12, 9, 0),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.ensureVisible(find.text('월간 리포트 만들기'));
    await tester.pump();
    await tester.tap(find.text('월간 리포트 만들기'));
    await tester.pump();
    await tester.pump();

    expect(find.byType(PricingFakeDoorScreen), findsNothing);
    expect(find.textContaining('가격 관심 이벤트를 저장할 수 없습니다.'), findsOneWidget);
    expect(find.textContaining('eventType=reportButtonTapped'), findsOneWidget);
  });
}

Widget _buildScreen({
  required _FakeWorkRecordRepository repository,
  required _FakeLeaveRepository leaveRepository,
  required DateTime now,
  _FakeWorkRuleRepository? workRuleRepository,
  _FakeCompensationReferenceRepository? compensationReferenceRepository,
}) {
  return _buildScreenWithPricingRepository(
    repository: repository,
    leaveRepository: leaveRepository,
    workRuleRepository:
        workRuleRepository ??
        const _FakeWorkRuleRepository(rule: null, findActiveError: null),
    compensationReferenceRepository:
        compensationReferenceRepository ??
        const _FakeCompensationReferenceRepository(
          setting: null,
          findApplicableError: null,
        ),
    pricingIntentRepository: _FakePricingIntentRepository(
      failingEventTypes: <PricingIntentEventType>{},
    ),
    now: now,
  );
}

Widget _buildScreenWithPricingRepository({
  required _FakeWorkRecordRepository repository,
  required _FakeLeaveRepository leaveRepository,
  required _FakeWorkRuleRepository workRuleRepository,
  required _FakeCompensationReferenceRepository compensationReferenceRepository,
  required _FakePricingIntentRepository pricingIntentRepository,
  required DateTime now,
}) {
  return MaterialApp(
    home: MonthlySummaryScreen(
      repository: repository,
      leaveRepository: leaveRepository,
      workRuleRepository: workRuleRepository,
      compensationReferenceRepository: compensationReferenceRepository,
      pricingIntentRepository: pricingIntentRepository,
      now: () => now,
    ),
  );
}

_FakeLeaveRepository _emptyLeaveRepository() {
  return _FakeLeaveRepository(
    balance: null,
    usages: <LeaveUsage>[],
    findBalanceError: null,
    findUsagesError: null,
  );
}

WorkRecord _completedRecord({
  required String id,
  required DateTime clockInAt,
  required DateTime clockOutAt,
  required List<WorkRecordTag> tags,
}) {
  return WorkRecord(
    id: id,
    workDate: DateTime(clockInAt.year, clockInAt.month, clockInAt.day),
    clockInAt: clockInAt,
    clockOutAt: clockOutAt,
    tags: tags,
    memo: null,
    createdAt: clockInAt,
    updatedAt: clockOutAt,
  );
}

LeaveBalance _leaveBalance({required int totalLeaveMinutes}) {
  return LeaveBalance(
    id: 'leave-balance-2026',
    year: 2026,
    totalLeaveMinutes: totalLeaveMinutes,
    createdAt: DateTime(2026, 1, 1, 9),
    updatedAt: DateTime(2026, 1, 1, 9),
  );
}

LeaveUsage _leaveUsage({
  required String id,
  required DateTime usedOn,
  required int usedLeaveMinutes,
}) {
  return LeaveUsage(
    id: id,
    usedOn: usedOn,
    usedLeaveMinutes: usedLeaveMinutes,
    memo: null,
    createdAt: DateTime(2026, 1, 1, 9),
    updatedAt: DateTime(2026, 1, 1, 9),
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
    createdAt: DateTime(2026, 6, 1, 9),
    updatedAt: DateTime(2026, 6, 1, 9),
  );
}

CompensationReferenceSetting _compensationReferenceSetting({
  required CompensationReferenceMode mode,
  required int fixedIncludedOvertimeMinutes,
  required int fixedIncludedNightMinutes,
  required int fixedIncludedHolidayMinutes,
}) {
  return CompensationReferenceSetting(
    id: 'compensation-reference',
    mode: mode,
    fixedIncludedOvertimeMinutes: fixedIncludedOvertimeMinutes,
    fixedIncludedNightMinutes: fixedIncludedNightMinutes,
    fixedIncludedHolidayMinutes: fixedIncludedHolidayMinutes,
    effectiveFromMonth: DateTime(2000),
    memo: null,
    createdAt: DateTime(2026, 6, 1, 9),
    updatedAt: DateTime(2026, 6, 1, 9),
  );
}

WorkRecord _incompleteRecord({
  required String id,
  required DateTime workDate,
  required DateTime? clockInAt,
  required DateTime? clockOutAt,
}) {
  return WorkRecord(
    id: id,
    workDate: workDate,
    clockInAt: clockInAt,
    clockOutAt: clockOutAt,
    tags: <WorkRecordTag>[],
    memo: null,
    createdAt: DateTime(workDate.year, workDate.month, workDate.day, 9),
    updatedAt: DateTime(workDate.year, workDate.month, workDate.day, 18),
  );
}

final class _FakeCompensationReferenceRepository
    implements CompensationReferenceRepository {
  const _FakeCompensationReferenceRepository({
    required this.setting,
    required this.findApplicableError,
  });

  final CompensationReferenceSetting? setting;
  final CompensationReferenceRepositoryException? findApplicableError;

  @override
  Future<CompensationReferenceSetting?> findApplicableForMonth({
    required int year,
    required int month,
  }) async {
    final CompensationReferenceRepositoryException? error = findApplicableError;
    if (error != null) {
      throw error;
    }
    return setting;
  }

  @override
  Future<CompensationReferenceSetting> save({
    required CompensationReferenceMode mode,
    required int fixedIncludedOvertimeMinutes,
    required int fixedIncludedNightMinutes,
    required int fixedIncludedHolidayMinutes,
    required DateTime effectiveFromMonth,
    required String? memo,
  }) async {
    throw const CompensationReferenceRepositoryException(
      'unexpected save call',
    );
  }
}

final class _FakeLeaveRepository implements LeaveRepository {
  _FakeLeaveRepository({
    required this.balance,
    required this.usages,
    required this.findBalanceError,
    required this.findUsagesError,
  });

  final LeaveBalance? balance;
  final List<LeaveUsage> usages;
  final LeaveRepositoryException? findBalanceError;
  final LeaveRepositoryException? findUsagesError;

  @override
  Future<LeaveBalance?> findBalanceByYear({required int year}) async {
    final LeaveRepositoryException? error = findBalanceError;
    if (error != null) {
      throw error;
    }
    return balance;
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
    final LeaveRepositoryException? error = findUsagesError;
    if (error != null) {
      throw error;
    }
    return usages;
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

final class _FakePricingIntentRepository implements PricingIntentRepository {
  _FakePricingIntentRepository({required this.failingEventTypes});

  final Set<PricingIntentEventType> failingEventTypes;
  final List<PricingIntentEvent> savedEvents = <PricingIntentEvent>[];

  @override
  Future<PricingIntentEvent> save({
    required PricingIntentEventType eventType,
    required PricingPlan? selectedPlan,
    required String sourceScreen,
  }) async {
    if (failingEventTypes.contains(eventType)) {
      throw PricingIntentRepositoryException(
        'action=save eventType=${eventType.name} sourceScreen=$sourceScreen rule=test failure',
      );
    }
    final PricingIntentEvent event = PricingIntentEvent(
      id: 'pricing-event-${savedEvents.length + 1}',
      eventType: eventType,
      selectedPlan: selectedPlan,
      sourceScreen: sourceScreen,
      occurredAt: DateTime(2026, 6, 12, 18, 42, savedEvents.length),
      createdAt: DateTime(2026, 6, 12, 18, 42, savedEvents.length),
    );
    savedEvents.add(event);
    return event;
  }

  @override
  Future<List<PricingIntentEvent>> findAll() async {
    return List<PricingIntentEvent>.of(savedEvents);
  }
}

final class _FakeWorkRuleRepository implements WorkRuleRepository {
  const _FakeWorkRuleRepository({
    required this.rule,
    required this.findActiveError,
  });

  final WorkRule? rule;
  final WorkRuleRepositoryException? findActiveError;

  @override
  Future<WorkRule?> findActive() async {
    final WorkRuleRepositoryException? error = findActiveError;
    if (error != null) {
      throw error;
    }
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
    throw const WorkRuleRepositoryException('unexpected save call');
  }
}

final class _FakeWorkRecordRepository implements WorkRecordRepository {
  _FakeWorkRecordRepository({
    required this.monthlyRecords,
    required this.findByMonthError,
  });

  final List<WorkRecord> monthlyRecords;
  final WorkRecordRepositoryException? findByMonthError;
  int? requestedYear;
  int? requestedMonth;
  int deleteByDateCallCount = 0;
  DateTime? deletedWorkDate;

  @override
  Future<WorkRecord?> findToday() async {
    throw const WorkRecordRepositoryException('unexpected findToday call');
  }

  @override
  Future<WorkRecord?> findByDate({required DateTime workDate}) async {
    throw const WorkRecordRepositoryException('unexpected findByDate call');
  }

  @override
  Future<List<WorkRecord>> findByMonth({
    required int year,
    required int month,
  }) async {
    requestedYear = year;
    requestedMonth = month;
    final WorkRecordRepositoryException? error = findByMonthError;
    if (error != null) {
      throw error;
    }
    return monthlyRecords;
  }

  @override
  Future<WorkRecord> clockIn() async {
    throw const WorkRecordRepositoryException('unexpected clockIn call');
  }

  @override
  Future<WorkRecord> clockOut() async {
    throw const WorkRecordRepositoryException('unexpected clockOut call');
  }

  @override
  Future<WorkRecord> updateToday({
    required DateTime? clockInAt,
    required DateTime? clockOutAt,
    required List<WorkRecordTag> tags,
    required String? memo,
  }) async {
    throw const WorkRecordRepositoryException('unexpected updateToday call');
  }

  @override
  Future<WorkRecord> upsertByDate({
    required DateTime workDate,
    required DateTime? clockInAt,
    required DateTime? clockOutAt,
    required List<WorkRecordTag> tags,
    required String? memo,
  }) async {
    throw const WorkRecordRepositoryException('unexpected upsertByDate call');
  }

  @override
  Future<void> deleteToday() async {
    throw const WorkRecordRepositoryException('unexpected deleteToday call');
  }

  @override
  Future<void> deleteByDate({required DateTime workDate}) async {
    deleteByDateCallCount += 1;
    final DateTime targetDate = DateTime(
      workDate.year,
      workDate.month,
      workDate.day,
    );
    deletedWorkDate = targetDate;
    final int removedCount = monthlyRecords.length;
    monthlyRecords.removeWhere((WorkRecord record) {
      return record.workDate == targetDate;
    });
    if (monthlyRecords.length == removedCount) {
      throw WorkRecordRepositoryException(
        'action=deleteByDate workDate=${targetDate.toIso8601String()} rule=missing work record',
      );
    }
  }
}
