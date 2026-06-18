import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workledger/core/models/work_record.dart';
import 'package:workledger/core/models/work_rule.dart';
import 'package:workledger/features/work_record/domain/work_record_repository.dart';
import 'package:workledger/features/work_record/presentation/work_record_calendar_screen.dart';
import 'package:workledger/features/work_rule/domain/work_rule_repository.dart';

void main() {
  testWidgets('shows completed record detail for selected today', (
    WidgetTester tester,
  ) async {
    final DateTime now = DateTime(2026, 6, 12, 20, 0);
    final _FakeWorkRecordRepository repository = _FakeWorkRecordRepository(
      records: <WorkRecord>[
        _workRecord(
          id: 'work-2026-06-12',
          workDate: DateTime(2026, 6, 12),
          clockInAt: DateTime(2026, 6, 12, 9, 3),
          clockOutAt: DateTime(2026, 6, 12, 18, 42),
          tags: <WorkRecordTag>[WorkRecordTag.delayedCheckout],
          memo: '배포 대응 후 퇴근',
        ),
        _workRecord(
          id: 'work-2026-06-10',
          workDate: DateTime(2026, 6, 10),
          clockInAt: DateTime(2026, 6, 10, 9, 0),
          clockOutAt: null,
          tags: <WorkRecordTag>[],
          memo: null,
        ),
      ],
      now: () => now,
    );

    await tester.pumpWidget(_buildScreen(repository: repository, now: now));
    await tester.pump();
    await tester.pump();

    expect(find.text('달력 보기'), findsOneWidget);
    expect(find.text('2026년 6월'), findsOneWidget);
    expect(find.text('● 완료'), findsOneWidget);
    expect(find.text('◐ 출근만 기록'), findsOneWidget);
    expect(find.text('○ 시간 누락'), findsOneWidget);
    expect(find.text('· 기록 없음'), findsOneWidget);
    expect(find.text('6월 12일 금요일'), findsOneWidget);
    expect(find.text('09:03 - 18:42'), findsOneWidget);
    expect(find.text('총 9시간 39분'), findsOneWidget);
    expect(find.text('기록 사유: 퇴근 기록 지연'), findsOneWidget);
    expect(find.text('메모: 배포 대응 후 퇴근'), findsOneWidget);
    expect(find.text('기록 수정'), findsOneWidget);
    expect(find.text('닫기'), findsNothing);
    expect(repository.requestedMonths, <String>['2026-06']);
  });

  testWidgets('renders compact calendar without bottom overflow', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final DateTime now = DateTime(2026, 8, 31, 20, 0);
    final _FakeWorkRecordRepository repository = _FakeWorkRecordRepository(
      records: <WorkRecord>[
        _workRecord(
          id: 'work-2026-08-31',
          workDate: DateTime(2026, 8, 31),
          clockInAt: DateTime(2026, 8, 31, 9, 0),
          clockOutAt: DateTime(2026, 8, 31, 18, 0),
          tags: <WorkRecordTag>[],
          memo: null,
        ),
      ],
      now: () => now,
    );

    await tester.pumpWidget(_buildScreen(repository: repository, now: now));
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('달력 보기'), findsOneWidget);
    expect(find.text('오늘'), findsOneWidget);
    expect(find.text('닫기'), findsNothing);
  });

  testWidgets('keeps scrolling after selecting a non-today date', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final DateTime now = DateTime(2026, 8, 31, 20, 0);
    final _FakeWorkRecordRepository repository = _FakeWorkRecordRepository(
      records: <WorkRecord>[
        _workRecord(
          id: 'work-2026-08-31',
          workDate: DateTime(2026, 8, 31),
          clockInAt: DateTime(2026, 8, 31, 9, 0),
          clockOutAt: DateTime(2026, 8, 31, 18, 0),
          tags: <WorkRecordTag>[],
          memo: null,
        ),
      ],
      now: () => now,
    );

    await tester.pumpWidget(_buildScreen(repository: repository, now: now));
    await tester.pump();
    await tester.pump();

    final ScrollPosition todayPosition = _scrollPositionWithExtent(tester);
    final double todayMaxScrollExtent = todayPosition.maxScrollExtent;
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -240),
    );
    await tester.pumpAndSettle();

    expect(todayMaxScrollExtent, greaterThan(0));
    expect(todayPosition.pixels, greaterThan(0));

    todayPosition.jumpTo(0);
    await tester.pump();
    await tester.tap(find.byKey(const Key('calendar-day-2026-08-01')));
    await tester.pump();

    final ScrollPosition nonTodayPosition = _scrollPositionWithExtent(tester);
    final double nonTodayMaxScrollExtent = nonTodayPosition.maxScrollExtent;
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -240),
    );
    await tester.pumpAndSettle();

    expect(find.text('8월 1일 토요일'), findsOneWidget);
    expect(find.text('기록 추가'), findsOneWidget);
    expect(nonTodayMaxScrollExtent, greaterThan(0));
    expect(nonTodayMaxScrollExtent, lessThan(todayMaxScrollExtent));
    expect(nonTodayPosition.pixels, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows incomplete and empty date details after date selection', (
    WidgetTester tester,
  ) async {
    final DateTime now = DateTime(2026, 6, 12, 20, 0);
    final _FakeWorkRecordRepository repository = _FakeWorkRecordRepository(
      records: <WorkRecord>[
        _workRecord(
          id: 'work-2026-06-10',
          workDate: DateTime(2026, 6, 10),
          clockInAt: DateTime(2026, 6, 10, 9, 0),
          clockOutAt: null,
          tags: <WorkRecordTag>[],
          memo: null,
        ),
      ],
      now: () => now,
    );

    await tester.pumpWidget(_buildScreen(repository: repository, now: now));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byKey(const Key('calendar-day-2026-06-10')));
    await tester.pump();

    expect(find.text('6월 10일 수요일'), findsOneWidget);
    expect(find.text('출근만 기록됨'), findsOneWidget);
    expect(find.text('출근 09:00'), findsOneWidget);
    expect(find.text('기록 수정'), findsOneWidget);

    await tester.tap(find.byKey(const Key('calendar-day-2026-06-11')));
    await tester.pump();

    expect(find.text('6월 11일 목요일'), findsOneWidget);
    expect(find.text('기록 없음'), findsOneWidget);
    expect(find.text('기록 추가'), findsOneWidget);
  });

  testWidgets('shows add action for an empty previous date', (
    WidgetTester tester,
  ) async {
    final DateTime now = DateTime(2026, 6, 12, 20, 0);
    final _FakeWorkRecordRepository repository = _FakeWorkRecordRepository(
      records: <WorkRecord>[],
      now: () => now,
    );

    await tester.pumpWidget(_buildScreen(repository: repository, now: now));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byKey(const Key('calendar-day-2026-06-11')));
    await tester.pump();

    expect(find.text('6월 11일 목요일'), findsOneWidget);
    expect(find.text('기록 없음'), findsOneWidget);
    expect(find.text('기록 추가'), findsOneWidget);
    expect(find.text('기록 수정'), findsNothing);
  });

  testWidgets('adds previous record and refreshes selected date detail', (
    WidgetTester tester,
  ) async {
    final DateTime now = DateTime(2026, 6, 12, 20, 0);
    final _FakeWorkRecordRepository repository = _FakeWorkRecordRepository(
      records: <WorkRecord>[],
      now: () => now,
    );

    await tester.pumpWidget(_buildScreen(repository: repository, now: now));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byKey(const Key('calendar-day-2026-06-11')));
    await tester.pump();
    await tester.ensureVisible(find.text('기록 추가'));
    await tester.pump();
    await tester.tap(find.text('기록 추가'));
    await tester.pumpAndSettle();

    expect(find.text('기록 추가'), findsOneWidget);
    expect(find.text('2026-06-11'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('clockInTimeField')), '09:00');
    await tester.enterText(find.byKey(const Key('clockOutTimeField')), '17:30');
    await tester.enterText(find.byType(TextField).last, '어제 누락 기록');
    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await tester.pumpAndSettle();

    expect(find.text('6월 11일 목요일'), findsOneWidget);
    expect(find.text('09:00 - 17:30'), findsOneWidget);
    expect(find.text('총 8시간 30분'), findsOneWidget);
    expect(find.text('메모: 어제 누락 기록'), findsOneWidget);
    expect(find.text('기록 수정'), findsOneWidget);
    expect(repository.requestedMonths, <String>['2026-06', '2026-06']);
  });

  testWidgets('adds previous record with numeric time shorthand', (
    WidgetTester tester,
  ) async {
    final DateTime now = DateTime(2026, 6, 12, 20, 0);
    final _FakeWorkRecordRepository repository = _FakeWorkRecordRepository(
      records: <WorkRecord>[],
      now: () => now,
    );

    await tester.pumpWidget(_buildScreen(repository: repository, now: now));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byKey(const Key('calendar-day-2026-06-11')));
    await tester.pump();
    await tester.ensureVisible(find.text('기록 추가'));
    await tester.pump();
    await tester.tap(find.text('기록 추가'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('clockInTimeField')), '930');
    await tester.enterText(find.byKey(const Key('clockOutTimeField')), '1730');
    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await tester.pumpAndSettle();

    expect(find.text('6월 11일 목요일'), findsOneWidget);
    expect(find.text('09:30 - 17:30'), findsOneWidget);
    expect(find.text('총 8시간'), findsOneWidget);
  });

  testWidgets('shows edit action for an existing previous record', (
    WidgetTester tester,
  ) async {
    final DateTime now = DateTime(2026, 6, 12, 20, 0);
    final _FakeWorkRecordRepository repository = _FakeWorkRecordRepository(
      records: <WorkRecord>[
        _workRecord(
          id: 'work-2026-06-11',
          workDate: DateTime(2026, 6, 11),
          clockInAt: DateTime(2026, 6, 11, 9, 0),
          clockOutAt: DateTime(2026, 6, 11, 18, 0),
          tags: <WorkRecordTag>[],
          memo: null,
        ),
      ],
      now: () => now,
    );

    await tester.pumpWidget(_buildScreen(repository: repository, now: now));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byKey(const Key('calendar-day-2026-06-11')));
    await tester.pump();

    expect(find.text('6월 11일 목요일'), findsOneWidget);
    expect(find.text('09:00 - 18:00'), findsOneWidget);
    expect(find.text('기록 수정'), findsOneWidget);
    expect(find.text('기록 추가'), findsNothing);
  });

  testWidgets('keeps previous record input when clock-out is before clock-in', (
    WidgetTester tester,
  ) async {
    final DateTime now = DateTime(2026, 6, 12, 20, 0);
    final _FakeWorkRecordRepository repository = _FakeWorkRecordRepository(
      records: <WorkRecord>[],
      now: () => now,
    );

    await tester.pumpWidget(_buildScreen(repository: repository, now: now));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byKey(const Key('calendar-day-2026-06-11')));
    await tester.pump();
    await tester.ensureVisible(find.text('기록 추가'));
    await tester.pump();
    await tester.tap(find.text('기록 추가'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('clockInTimeField')), '18:00');
    await tester.enterText(find.byKey(const Key('clockOutTimeField')), '09:00');
    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await tester.pump();

    expect(find.text('저장할 수 없습니다. 퇴근 시각은 출근 시각보다 빠를 수 없습니다.'), findsOneWidget);
    expect(find.text('18:00'), findsOneWidget);
    expect(find.text('09:00'), findsOneWidget);
  });

  testWidgets('moves between months and reloads repository query', (
    WidgetTester tester,
  ) async {
    final DateTime now = DateTime(2026, 6, 30, 20, 0);
    final _FakeWorkRecordRepository repository = _FakeWorkRecordRepository(
      records: <WorkRecord>[
        _workRecord(
          id: 'work-2026-07-01',
          workDate: DateTime(2026, 7, 1),
          clockInAt: DateTime(2026, 7, 1, 9, 0),
          clockOutAt: DateTime(2026, 7, 1, 18, 0),
          tags: <WorkRecordTag>[],
          memo: null,
        ),
      ],
      now: () => now,
    );

    await tester.pumpWidget(_buildScreen(repository: repository, now: now));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byTooltip('다음 달'));
    await tester.pump();
    await tester.pump();

    expect(find.text('2026년 7월'), findsOneWidget);
    expect(find.text('7월 30일 목요일'), findsOneWidget);
    expect(repository.requestedMonths, <String>['2026-06', '2026-07']);

    await tester.tap(find.byKey(const Key('calendar-day-2026-07-01')));
    await tester.pump();

    expect(find.text('7월 1일 수요일'), findsOneWidget);
    expect(find.text('09:00 - 18:00'), findsOneWidget);
    expect(find.text('총 9시간'), findsOneWidget);
  });

  testWidgets('shows monthly work tag summary after moving month', (
    WidgetTester tester,
  ) async {
    final DateTime now = DateTime(2026, 6, 30, 20, 0);
    final _FakeWorkRecordRepository repository = _FakeWorkRecordRepository(
      records: <WorkRecord>[
        _workRecord(
          id: 'work-2026-07-01',
          workDate: DateTime(2026, 7, 1),
          clockInAt: DateTime(2026, 7, 1, 8, 30),
          clockOutAt: DateTime(2026, 7, 1, 21, 0),
          tags: <WorkRecordTag>[],
          memo: null,
        ),
      ],
      now: () => now,
    );

    await tester.pumpWidget(_buildScreen(repository: repository, now: now));
    await tester.pump();
    await tester.pump();

    expect(find.text('근무 태그'), findsNothing);

    await tester.tap(find.byTooltip('다음 달'));
    await tester.pump();
    await tester.pump();

    expect(find.text('2026년 7월'), findsOneWidget);
    expect(find.text('근무 태그'), findsOneWidget);
    expect(find.text('정시 전 근무'), findsOneWidget);
    expect(find.text('30분'), findsOneWidget);
    expect(find.text('연장 근무'), findsOneWidget);
    expect(find.text('3시간'), findsOneWidget);
    expect(repository.requestedMonths, <String>['2026-06', '2026-07']);
  });

  testWidgets('shows Korean error when repository fails', (
    WidgetTester tester,
  ) async {
    final DateTime now = DateTime(2026, 6, 12, 20, 0);
    final _FakeWorkRecordRepository repository =
        _FakeWorkRecordRepository(records: <WorkRecord>[], now: () => now)
          ..findByMonthError = const WorkRecordRepositoryException(
            'action=findByMonth rule=test failure',
          );

    await tester.pumpWidget(_buildScreen(repository: repository, now: now));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('달력 기록을 불러올 수 없습니다.'), findsOneWidget);
    expect(find.textContaining('action=findByMonth'), findsOneWidget);
  });

  testWidgets(
    'returns modified result after editing today and using app bar back',
    (WidgetTester tester) async {
      final DateTime now = DateTime(2026, 6, 12, 20, 0);
      final _FakeWorkRecordRepository repository = _FakeWorkRecordRepository(
        records: <WorkRecord>[
          _workRecord(
            id: 'work-2026-06-12',
            workDate: DateTime(2026, 6, 12),
            clockInAt: DateTime(2026, 6, 12, 9, 0),
            clockOutAt: DateTime(2026, 6, 12, 18, 0),
            tags: <WorkRecordTag>[],
            memo: null,
          ),
        ],
        now: () => now,
      );

      await tester.pumpWidget(_buildHost(repository: repository, now: now));
      await tester.pump();

      await tester.tap(find.text('달력 열기'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('기록 수정'));
      await tester.pump();
      await tester.tap(find.text('기록 수정'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('clockOutTimeField')),
        '19:10',
      );
      await tester.tap(find.widgetWithText(FilledButton, '저장'));
      await tester.pumpAndSettle();

      expect(find.text('총 10시간 10분'), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('달력 수정됨'), findsOneWidget);
    },
  );
}

Widget _buildScreen({
  required _FakeWorkRecordRepository repository,
  required DateTime now,
  _FakeWorkRuleRepository? workRuleRepository,
}) {
  return MaterialApp(
    home: WorkRecordCalendarScreen(
      repository: repository,
      workRuleRepository:
          workRuleRepository ?? _FakeWorkRuleRepository(rule: _workRule()),
      now: () => now,
      refreshPersistentNotification: () async {},
    ),
  );
}

Widget _buildHost({
  required _FakeWorkRecordRepository repository,
  required DateTime now,
}) {
  return MaterialApp(
    home: _CalendarResultHost(repository: repository, now: now),
  );
}

ScrollPosition _scrollPositionWithExtent(WidgetTester tester) {
  final List<ScrollableState> states = tester
      .stateList<ScrollableState>(find.byType(Scrollable))
      .toList(growable: false);
  return states
      .map((ScrollableState state) => state.position)
      .firstWhere((ScrollPosition position) => position.maxScrollExtent > 0);
}

final class _CalendarResultHost extends StatefulWidget {
  const _CalendarResultHost({required this.repository, required this.now});

  final _FakeWorkRecordRepository repository;
  final DateTime now;

  @override
  State<_CalendarResultHost> createState() => _CalendarResultHostState();
}

final class _CalendarResultHostState extends State<_CalendarResultHost> {
  bool _didModify = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Text(_didModify ? '달력 수정됨' : '달력 변경 없음'),
          FilledButton(onPressed: _openCalendar, child: const Text('달력 열기')),
        ],
      ),
    );
  }

  Future<void> _openCalendar() async {
    final Object? result = await Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) => WorkRecordCalendarScreen(
          repository: widget.repository,
          workRuleRepository: _FakeWorkRuleRepository(rule: _workRule()),
          now: () => widget.now,
          refreshPersistentNotification: () async {},
        ),
      ),
    );
    if (result == true) {
      setState(() {
        _didModify = true;
      });
    }
  }
}

WorkRule _workRule() {
  return WorkRule(
    id: 'work-rule',
    regularStartTimeMinutes: 9 * 60,
    regularEndTimeMinutes: 18 * 60,
    overtimeStartTimeMinutes: 18 * 60,
    nightWorkStartTimeMinutes: 22 * 60,
    breakMinutes: 60,
    workWeekdays: <int>[
      DateTime.monday,
      DateTime.tuesday,
      DateTime.wednesday,
      DateTime.thursday,
      DateTime.friday,
    ],
    createdAt: DateTime(2026, 1, 1, 9),
    updatedAt: DateTime(2026, 1, 1, 9),
  );
}

WorkRecord _workRecord({
  required String id,
  required DateTime workDate,
  required DateTime? clockInAt,
  required DateTime? clockOutAt,
  required List<WorkRecordTag> tags,
  required String? memo,
}) {
  final DateTime createdAt = DateTime(2026, 6, 1, 8, 0);
  return WorkRecord(
    id: id,
    workDate: DateTime(workDate.year, workDate.month, workDate.day),
    clockInAt: clockInAt,
    clockOutAt: clockOutAt,
    tags: tags,
    memo: memo,
    createdAt: createdAt,
    updatedAt: createdAt,
  );
}

final class _FakeWorkRecordRepository implements WorkRecordRepository {
  _FakeWorkRecordRepository({
    required List<WorkRecord> records,
    required this.now,
  }) : _records = List<WorkRecord>.of(records);

  final List<WorkRecord> _records;
  final DateTime Function() now;
  final List<String> requestedMonths = <String>[];
  WorkRecordRepositoryException? findByMonthError;

  @override
  Future<WorkRecord?> findToday() async {
    final DateTime today = DateTime(now().year, now().month, now().day);
    return findByDate(workDate: today);
  }

  @override
  Future<WorkRecord?> findByDate({required DateTime workDate}) async {
    final DateTime targetDate = DateTime(
      workDate.year,
      workDate.month,
      workDate.day,
    );
    for (final WorkRecord record in _records) {
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
    final String formattedMonth = month.toString().padLeft(2, '0');
    requestedMonths.add('$year-$formattedMonth');
    final WorkRecordRepositoryException? error = findByMonthError;
    if (error != null) {
      throw error;
    }
    return _records
        .where((WorkRecord record) {
          return record.workDate.year == year && record.workDate.month == month;
        })
        .toList(growable: false);
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
    final WorkRecord? record = await findToday();
    if (record == null) {
      throw const WorkRecordRepositoryException(
        'action=updateToday rule=missing today record',
      );
    }
    final WorkRecord updatedRecord = record.copyWith(
      id: record.id,
      workDate: record.workDate,
      clockInAt: clockInAt,
      clockOutAt: clockOutAt,
      tags: tags,
      memo: memo,
      createdAt: record.createdAt,
      updatedAt: now(),
    );
    _records.removeWhere((WorkRecord item) => item.workDate == record.workDate);
    _records.add(updatedRecord);
    return updatedRecord;
  }

  @override
  Future<WorkRecord> upsertByDate({
    required DateTime workDate,
    required DateTime? clockInAt,
    required DateTime? clockOutAt,
    required List<WorkRecordTag> tags,
    required String? memo,
  }) async {
    final DateTime targetDate = DateTime(
      workDate.year,
      workDate.month,
      workDate.day,
    );
    final WorkRecord? existingRecord = await findByDate(workDate: targetDate);
    final WorkRecord savedRecord = existingRecord == null
        ? WorkRecord(
            id: 'work-${targetDate.toIso8601String()}',
            workDate: targetDate,
            clockInAt: clockInAt,
            clockOutAt: clockOutAt,
            tags: tags,
            memo: memo,
            createdAt: now(),
            updatedAt: now(),
          )
        : existingRecord.copyWith(
            id: existingRecord.id,
            workDate: existingRecord.workDate,
            clockInAt: clockInAt,
            clockOutAt: clockOutAt,
            tags: tags,
            memo: memo,
            createdAt: existingRecord.createdAt,
            updatedAt: now(),
          );
    _records.removeWhere((WorkRecord item) => item.workDate == targetDate);
    _records.add(savedRecord);
    return savedRecord;
  }

  @override
  Future<void> deleteToday() async {
    throw const WorkRecordRepositoryException('unexpected deleteToday call');
  }

  @override
  Future<void> deleteByDate({required DateTime workDate}) async {
    throw const WorkRecordRepositoryException('unexpected deleteByDate call');
  }
}

final class _FakeWorkRuleRepository implements WorkRuleRepository {
  const _FakeWorkRuleRepository({required this.rule});

  final WorkRule? rule;

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
    throw const WorkRuleRepositoryException('unexpected save call');
  }
}
