import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workledger/core/input/clock_time_input.dart';
import 'package:workledger/core/models/work_record.dart';
import 'package:workledger/core/notifications/workledger_notification_service.dart';
import 'package:workledger/features/work_record/domain/work_record_repository.dart';
import 'package:workledger/features/work_record/presentation/edit_today_work_record_screen.dart';

void main() {
  testWidgets('saves edited today work record', (WidgetTester tester) async {
    final DateTime now = DateTime(2026, 6, 12, 20, 0);
    final _FakeWorkRecordRepository repository = _FakeWorkRecordRepository(
      initialRecord: _workRecord(
        clockInAt: DateTime(2026, 6, 12, 9, 3),
        clockOutAt: DateTime(2026, 6, 12, 18, 42),
        tags: <WorkRecordTag>[WorkRecordTag.overtime],
        memo: '기존 메모',
      ),
      now: () => now,
    );

    await tester.pumpWidget(
      _buildScreen(repository: repository, now: now, workDate: now),
    );
    await tester.pump();

    await tester.enterText(find.byKey(const Key('clockInTimeField')), '09:30');
    await tester.enterText(find.byKey(const Key('clockOutTimeField')), '18:40');
    expect(find.text('기록 사유'), findsOneWidget);
    expect(find.text('퇴근 기록 지연'), findsOneWidget);
    expect(find.text('야근'), findsNothing);
    expect(find.text('휴일근무'), findsNothing);

    await tester.tap(find.text('퇴근 기록 지연'));
    await tester.enterText(find.byType(TextField).last, '배포 대응 후 퇴근');
    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await tester.pump();

    expect(repository.upsertByDateCallCount, 1);
    expect(repository.record!.clockInAt, DateTime(2026, 6, 12, 9, 30));
    expect(repository.record!.clockOutAt, DateTime(2026, 6, 12, 18, 40));
    expect(repository.record!.tags, <WorkRecordTag>[
      WorkRecordTag.overtime,
      WorkRecordTag.delayedCheckout,
    ]);
    expect(repository.record!.memo, '배포 대응 후 퇴근');
  });

  testWidgets('saves edited today work record with numeric time shorthand', (
    WidgetTester tester,
  ) async {
    final DateTime now = DateTime(2026, 6, 12, 20, 0);
    final _FakeWorkRecordRepository repository = _FakeWorkRecordRepository(
      initialRecord: _workRecord(
        clockInAt: DateTime(2026, 6, 12, 9, 3),
        clockOutAt: DateTime(2026, 6, 12, 18, 42),
        tags: <WorkRecordTag>[],
        memo: null,
      ),
      now: () => now,
    );

    await tester.pumpWidget(
      _buildScreen(repository: repository, now: now, workDate: now),
    );
    await tester.pump();

    await tester.enterText(find.byKey(const Key('clockInTimeField')), '930');
    await tester.enterText(find.byKey(const Key('clockOutTimeField')), '1840');
    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await tester.pump();

    expect(repository.upsertByDateCallCount, 1);
    expect(repository.record!.clockInAt, DateTime(2026, 6, 12, 9, 30));
    expect(repository.record!.clockOutAt, DateTime(2026, 6, 12, 18, 40));
  });

  testWidgets('shows notification refresh failure after save', (
    WidgetTester tester,
  ) async {
    final DateTime now = DateTime(2026, 6, 12, 20, 0);
    final _FakeWorkRecordRepository repository = _FakeWorkRecordRepository(
      initialRecord: _workRecord(
        clockInAt: DateTime(2026, 6, 12, 9, 3),
        clockOutAt: DateTime(2026, 6, 12, 18, 42),
        tags: <WorkRecordTag>[],
        memo: null,
      ),
      now: () => now,
    );

    await tester.pumpWidget(
      _buildScreen(
        repository: repository,
        now: now,
        workDate: now,
        refreshPersistentNotification: () async {
          throw const WorkLedgerNotificationException(
            'action=refresh rule=test failure',
          );
        },
      ),
    );
    await tester.pump();

    await tester.enterText(find.byKey(const Key('clockInTimeField')), '09:30');
    await tester.enterText(find.byKey(const Key('clockOutTimeField')), '18:40');
    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await tester.pump();

    expect(repository.upsertByDateCallCount, 1);
    expect(find.text('근무 기록 수정'), findsOneWidget);
    expect(find.textContaining('상시 알림을 갱신할 수 없습니다.'), findsOneWidget);
    expect(find.textContaining('action=refresh'), findsOneWidget);
  });

  test('normalizes clock input from HH:mm and numeric shorthand', () {
    final DateTime workDate = DateTime(2026, 6, 12);

    expect(
      parseClockInput(value: '9:30', workDate: workDate, fieldLabel: '출근 시각'),
      DateTime(2026, 6, 12, 9, 30),
    );
    expect(
      parseClockInput(value: '930', workDate: workDate, fieldLabel: '출근 시각'),
      DateTime(2026, 6, 12, 9, 30),
    );
    expect(
      parseClockInput(value: '0930', workDate: workDate, fieldLabel: '출근 시각'),
      DateTime(2026, 6, 12, 9, 30),
    );
  });

  test(
    'formats four digit clock input while keeping three digits editable',
    () {
      const ClockTimeInputFormatter formatter = ClockTimeInputFormatter();

      expect(
        formatter
            .formatEditUpdate(
              const TextEditingValue(text: ''),
              const TextEditingValue(text: '930'),
            )
            .text,
        '930',
      );
      expect(
        formatter
            .formatEditUpdate(
              const TextEditingValue(text: '930'),
              const TextEditingValue(text: '0930'),
            )
            .text,
        '09:30',
      );
    },
  );

  testWidgets('keeps input and shows error when clock-out is before clock-in', (
    WidgetTester tester,
  ) async {
    final DateTime now = DateTime(2026, 6, 12, 20, 0);
    final _FakeWorkRecordRepository repository = _FakeWorkRecordRepository(
      initialRecord: _workRecord(
        clockInAt: DateTime(2026, 6, 12, 9, 3),
        clockOutAt: DateTime(2026, 6, 12, 18, 42),
        tags: <WorkRecordTag>[],
        memo: null,
      ),
      now: () => now,
    );

    await tester.pumpWidget(
      _buildScreen(repository: repository, now: now, workDate: now),
    );
    await tester.pump();

    await tester.enterText(find.byKey(const Key('clockInTimeField')), '18:42');
    await tester.enterText(find.byKey(const Key('clockOutTimeField')), '09:03');
    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await tester.pump();

    expect(repository.upsertByDateCallCount, 0);
    expect(find.text('저장할 수 없습니다. 퇴근 시각은 출근 시각보다 빠를 수 없습니다.'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(
            find.descendant(
              of: find.byKey(const Key('clockInTimeField')),
              matching: find.byType(TextField),
            ),
          )
          .controller!
          .text,
      '18:42',
    );
    expect(
      tester
          .widget<TextField>(
            find.descendant(
              of: find.byKey(const Key('clockOutTimeField')),
              matching: find.byType(TextField),
            ),
          )
          .controller!
          .text,
      '09:03',
    );
  });

  testWidgets('shows memo length error with actionable copy', (
    WidgetTester tester,
  ) async {
    final DateTime now = DateTime(2026, 6, 12, 20, 0);
    final _FakeWorkRecordRepository repository = _FakeWorkRecordRepository(
      initialRecord: _workRecord(
        clockInAt: DateTime(2026, 6, 12, 9, 3),
        clockOutAt: DateTime(2026, 6, 12, 18, 42),
        tags: <WorkRecordTag>[],
        memo: null,
      ),
      now: () => now,
    );

    await tester.pumpWidget(
      _buildScreen(repository: repository, now: now, workDate: now),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField).last, '메' * 501);
    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await tester.pump();

    expect(repository.upsertByDateCallCount, 0);
    expect(find.text('저장할 수 없습니다. 메모는 500자 이하로 입력하세요.'), findsOneWidget);
  });

  testWidgets('keeps input and shows error when repository save fails', (
    WidgetTester tester,
  ) async {
    final DateTime now = DateTime(2026, 6, 12, 20, 0);
    final _FakeWorkRecordRepository repository =
        _FakeWorkRecordRepository(
            initialRecord: _workRecord(
              clockInAt: DateTime(2026, 6, 12, 9, 3),
              clockOutAt: DateTime(2026, 6, 12, 18, 42),
              tags: <WorkRecordTag>[],
              memo: null,
            ),
            now: () => now,
          )
          ..updateError = const WorkRecordRepositoryException(
            'action=upsertByDate rule=test failure',
          );

    await tester.pumpWidget(
      _buildScreen(repository: repository, now: now, workDate: now),
    );
    await tester.pump();

    await tester.enterText(find.byKey(const Key('clockInTimeField')), '09:30');
    await tester.enterText(find.byType(TextField).last, '저장 실패 후 유지');
    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await tester.pump();

    expect(repository.upsertByDateCallCount, 1);
    expect(
      find.text('저장할 수 없습니다. action=upsertByDate rule=test failure'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<TextField>(
            find.descendant(
              of: find.byKey(const Key('clockInTimeField')),
              matching: find.byType(TextField),
            ),
          )
          .controller!
          .text,
      '09:30',
    );
    expect(find.text('저장 실패 후 유지'), findsOneWidget);
  });

  testWidgets('deletes today record after confirmation', (
    WidgetTester tester,
  ) async {
    final DateTime now = DateTime(2026, 6, 12, 20, 0);
    final _FakeWorkRecordRepository repository = _FakeWorkRecordRepository(
      initialRecord: _workRecord(
        clockInAt: DateTime(2026, 6, 12, 9, 3),
        clockOutAt: DateTime(2026, 6, 12, 18, 42),
        tags: <WorkRecordTag>[],
        memo: null,
      ),
      now: () => now,
    );

    await tester.pumpWidget(
      _buildScreen(repository: repository, now: now, workDate: now),
    );
    await tester.pump();

    await tester.tap(find.widgetWithText(OutlinedButton, '기록 삭제'));
    await tester.pumpAndSettle();
    expect(find.text('기록을 삭제할까요?'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, '삭제'));
    await tester.pumpAndSettle();

    expect(repository.deleteByDateCallCount, 1);
    expect(repository.record, isNull);
  });

  testWidgets('shows notification refresh failure after deletion', (
    WidgetTester tester,
  ) async {
    final DateTime now = DateTime(2026, 6, 12, 20, 0);
    final _FakeWorkRecordRepository repository = _FakeWorkRecordRepository(
      initialRecord: _workRecord(
        clockInAt: DateTime(2026, 6, 12, 9, 3),
        clockOutAt: DateTime(2026, 6, 12, 18, 42),
        tags: <WorkRecordTag>[],
        memo: null,
      ),
      now: () => now,
    );

    await tester.pumpWidget(
      _buildScreen(
        repository: repository,
        now: now,
        workDate: now,
        refreshPersistentNotification: () async {
          throw const WorkLedgerNotificationException(
            'action=refresh rule=test failure',
          );
        },
      ),
    );
    await tester.pump();

    await tester.tap(find.widgetWithText(OutlinedButton, '기록 삭제'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '삭제'));
    await tester.pump();

    expect(repository.deleteByDateCallCount, 1);
    expect(find.text('근무 기록 수정'), findsOneWidget);
    expect(find.textContaining('상시 알림을 갱신할 수 없습니다.'), findsOneWidget);
    expect(find.textContaining('action=refresh'), findsOneWidget);
  });

  testWidgets('does not delete today record when confirmation is cancelled', (
    WidgetTester tester,
  ) async {
    final DateTime now = DateTime(2026, 6, 12, 20, 0);
    final WorkRecord record = _workRecord(
      clockInAt: DateTime(2026, 6, 12, 9, 3),
      clockOutAt: DateTime(2026, 6, 12, 18, 42),
      tags: <WorkRecordTag>[],
      memo: null,
    );
    final _FakeWorkRecordRepository repository = _FakeWorkRecordRepository(
      initialRecord: record,
      now: () => now,
    );

    await tester.pumpWidget(
      _buildScreen(repository: repository, now: now, workDate: now),
    );
    await tester.pump();

    await tester.tap(find.widgetWithText(OutlinedButton, '기록 삭제'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '취소'));
    await tester.pumpAndSettle();

    expect(repository.deleteByDateCallCount, 0);
    expect(repository.record, record);
  });

  testWidgets('creates selected date record when record is missing', (
    WidgetTester tester,
  ) async {
    final DateTime now = DateTime(2026, 6, 12, 20, 0);
    final DateTime workDate = DateTime(2026, 6, 11);
    final _FakeWorkRecordRepository repository = _FakeWorkRecordRepository(
      initialRecord: null,
      now: () => now,
    );

    await tester.pumpWidget(
      _buildScreen(repository: repository, now: now, workDate: workDate),
    );
    await tester.pump();

    expect(find.text('기록 추가'), findsOneWidget);
    expect(find.text('2026-06-11'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '기록 삭제'), findsNothing);

    await tester.enterText(find.byKey(const Key('clockInTimeField')), '09:00');
    await tester.enterText(find.byKey(const Key('clockOutTimeField')), '18:00');
    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await tester.pump();

    expect(repository.upsertByDateCallCount, 1);
    expect(repository.record!.workDate, workDate);
    expect(repository.record!.clockInAt, DateTime(2026, 6, 11, 9));
    expect(repository.record!.clockOutAt, DateTime(2026, 6, 11, 18));
  });

  testWidgets('loads a previous date record by selected work date', (
    WidgetTester tester,
  ) async {
    final DateTime now = DateTime(2026, 6, 12, 20, 0);
    final DateTime workDate = DateTime(2026, 6, 10);
    final _FakeWorkRecordRepository repository = _FakeWorkRecordRepository(
      initialRecord: _workRecord(
        clockInAt: DateTime(2026, 6, 10, 9, 3),
        clockOutAt: DateTime(2026, 6, 10, 18, 42),
        tags: <WorkRecordTag>[],
        memo: '이전 기록',
      ),
      now: () => now,
    );

    await tester.pumpWidget(
      _buildScreen(repository: repository, now: now, workDate: workDate),
    );
    await tester.pump();

    expect(find.text('근무 기록 수정'), findsOneWidget);
    expect(find.text('2026-06-10'), findsOneWidget);
    expect(find.text('이전 기록'), findsOneWidget);
  });
}

Widget _buildScreen({
  required _FakeWorkRecordRepository repository,
  required DateTime now,
  required DateTime workDate,
  RefreshWorkLedgerPersistentNotification? refreshPersistentNotification,
}) {
  return MaterialApp(
    home: EditTodayWorkRecordScreen(
      repository: repository,
      now: () => now,
      workDate: workDate,
      refreshPersistentNotification:
          refreshPersistentNotification ?? () async {},
    ),
  );
}

WorkRecord _workRecord({
  required DateTime clockInAt,
  required DateTime clockOutAt,
  required List<WorkRecordTag> tags,
  required String? memo,
}) {
  return WorkRecord(
    id: 'record-1',
    workDate: DateTime(clockInAt.year, clockInAt.month, clockInAt.day),
    clockInAt: clockInAt,
    clockOutAt: clockOutAt,
    tags: tags,
    memo: memo,
    createdAt: DateTime(2026, 6, 12, 9, 0),
    updatedAt: DateTime(2026, 6, 12, 18, 42),
  );
}

final class _FakeWorkRecordRepository implements WorkRecordRepository {
  _FakeWorkRecordRepository({
    required WorkRecord? initialRecord,
    required this.now,
  }) : record = initialRecord;

  WorkRecord? record;
  final DateTime Function() now;
  int upsertByDateCallCount = 0;
  int deleteByDateCallCount = 0;
  WorkRecordRepositoryException? updateError;
  WorkRecordRepositoryException? deleteError;

  @override
  Future<WorkRecord?> findToday() async {
    return record;
  }

  @override
  Future<WorkRecord?> findByDate({required DateTime workDate}) async {
    final WorkRecord? existingRecord = record;
    if (existingRecord == null) {
      return null;
    }
    final DateTime targetDate = DateTime(
      workDate.year,
      workDate.month,
      workDate.day,
    );
    return existingRecord.workDate == targetDate ? existingRecord : null;
  }

  @override
  Future<List<WorkRecord>> findByMonth({
    required int year,
    required int month,
  }) async {
    throw const WorkRecordRepositoryException('unexpected findByMonth call');
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
    final WorkRecord? existingRecord = record;
    if (existingRecord == null) {
      throw const WorkRecordRepositoryException(
        'action=updateToday rule=missing record',
      );
    }
    record = existingRecord.copyWith(
      id: existingRecord.id,
      workDate: existingRecord.workDate,
      clockInAt: clockInAt,
      clockOutAt: clockOutAt,
      tags: tags,
      memo: memo,
      createdAt: existingRecord.createdAt,
      updatedAt: now(),
    );
    return record!;
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
    final WorkRecordRepositoryException? error = updateError;
    if (error != null) {
      throw error;
    }
    final DateTime targetDate = DateTime(
      workDate.year,
      workDate.month,
      workDate.day,
    );
    final WorkRecord? existingRecord = await findByDate(workDate: targetDate);
    record = existingRecord == null
        ? WorkRecord(
            id: 'record-1',
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
    return record!;
  }

  @override
  Future<void> deleteToday() async {
    throw const WorkRecordRepositoryException('unexpected deleteToday call');
  }

  @override
  Future<void> deleteByDate({required DateTime workDate}) async {
    deleteByDateCallCount += 1;
    final WorkRecordRepositoryException? error = deleteError;
    if (error != null) {
      throw error;
    }
    if (record == null) {
      throw const WorkRecordRepositoryException(
        'action=deleteToday rule=missing record',
      );
    }
    record = null;
  }
}
