import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workledger/core/models/work_record.dart';
import 'package:workledger/features/work_record/domain/work_record_repository.dart';
import 'package:workledger/features/work_record/presentation/work_record_calendar_screen.dart';

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

    await tester.pumpWidget(
      _buildScreen(
        repository: repository,
        now: now,
        textScaler: TextScaler.noScaling,
      ),
    );
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
    expect(find.text('태그: 퇴근 지연'), findsOneWidget);
    expect(find.text('메모: 배포 대응 후 퇴근'), findsOneWidget);
    expect(find.text('오늘 기록 수정'), findsOneWidget);
    expect(repository.requestedMonths, <String>['2026-06']);
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

    await tester.pumpWidget(
      _buildScreen(
        repository: repository,
        now: now,
        textScaler: TextScaler.noScaling,
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byKey(const Key('calendar-day-2026-06-10')));
    await tester.pump();

    expect(find.text('6월 10일 수요일'), findsOneWidget);
    expect(find.text('출근만 기록됨'), findsOneWidget);
    expect(find.text('출근 09:00'), findsOneWidget);
    expect(find.text('오늘 기록 수정'), findsNothing);

    await tester.tap(find.byKey(const Key('calendar-day-2026-06-11')));
    await tester.pump();

    expect(find.text('6월 11일 목요일'), findsOneWidget);
    expect(find.text('기록 없음'), findsOneWidget);
    expect(find.text('오늘 기록 수정'), findsNothing);
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

    await tester.pumpWidget(
      _buildScreen(
        repository: repository,
        now: now,
        textScaler: TextScaler.noScaling,
      ),
    );
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

  testWidgets('shows Korean error when repository fails', (
    WidgetTester tester,
  ) async {
    final DateTime now = DateTime(2026, 6, 12, 20, 0);
    final _FakeWorkRecordRepository repository =
        _FakeWorkRecordRepository(records: <WorkRecord>[], now: () => now)
          ..findByMonthError = const WorkRecordRepositoryException(
            'action=findByMonth rule=test failure',
          );

    await tester.pumpWidget(
      _buildScreen(
        repository: repository,
        now: now,
        textScaler: TextScaler.noScaling,
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('달력 기록을 불러올 수 없습니다.'), findsOneWidget);
    expect(find.textContaining('action=findByMonth'), findsOneWidget);
  });

  testWidgets(
    'does not overflow selected today cell on Android-like viewport',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2280);
      tester.view.devicePixelRatio = 3;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final DateTime now = DateTime(2026, 6, 13, 20, 0);
      final _FakeWorkRecordRepository repository = _FakeWorkRecordRepository(
        records: <WorkRecord>[
          _workRecord(
            id: 'work-2026-06-13',
            workDate: DateTime(2026, 6, 13),
            clockInAt: DateTime(2026, 6, 13, 7, 26),
            clockOutAt: DateTime(2026, 6, 13, 13, 26),
            tags: <WorkRecordTag>[],
            memo: null,
          ),
        ],
        now: () => now,
      );

      await tester.pumpWidget(
        _buildScreen(
          repository: repository,
          now: now,
          textScaler: const TextScaler.linear(1.1),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('오늘'), findsOneWidget);
      expect(find.text('총 6시간'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

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

      await tester.ensureVisible(find.text('오늘 기록 수정'));
      await tester.pump();
      await tester.tap(find.text('오늘 기록 수정'));
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
  required TextScaler textScaler,
}) {
  return MaterialApp(
    builder: (BuildContext context, Widget? child) {
      final MediaQueryData mediaQuery = MediaQuery.of(context);
      return MediaQuery(
        data: mediaQuery.copyWith(textScaler: textScaler),
        child: child ?? const SizedBox.shrink(),
      );
    },
    home: WorkRecordCalendarScreen(repository: repository, now: () => now),
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
          now: () => widget.now,
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
    for (final WorkRecord record in _records) {
      if (record.workDate == today) {
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
  Future<void> deleteToday() async {
    throw const WorkRecordRepositoryException('unexpected deleteToday call');
  }

  @override
  Future<void> deleteByDate({required DateTime workDate}) async {
    throw const WorkRecordRepositoryException('unexpected deleteByDate call');
  }
}
