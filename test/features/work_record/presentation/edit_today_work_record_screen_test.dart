import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workledger/core/models/work_record.dart';
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

    await tester.pumpWidget(_buildScreen(repository: repository, now: now));
    await tester.pump();

    await tester.enterText(find.byKey(const Key('clockInTimeField')), '09:30');
    await tester.enterText(find.byKey(const Key('clockOutTimeField')), '18:40');
    await tester.tap(find.text('퇴근 지연'));
    await tester.enterText(find.byType(TextField).last, '배포 대응 후 퇴근');
    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await tester.pump();

    expect(repository.updateTodayCallCount, 1);
    expect(repository.record!.clockInAt, DateTime(2026, 6, 12, 9, 30));
    expect(repository.record!.clockOutAt, DateTime(2026, 6, 12, 18, 40));
    expect(repository.record!.tags, <WorkRecordTag>[
      WorkRecordTag.overtime,
      WorkRecordTag.delayedCheckout,
    ]);
    expect(repository.record!.memo, '배포 대응 후 퇴근');
  });

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

    await tester.pumpWidget(_buildScreen(repository: repository, now: now));
    await tester.pump();

    await tester.enterText(find.byKey(const Key('clockInTimeField')), '18:42');
    await tester.enterText(find.byKey(const Key('clockOutTimeField')), '09:03');
    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await tester.pump();

    expect(repository.updateTodayCallCount, 0);
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
            'action=updateToday rule=test failure',
          );

    await tester.pumpWidget(_buildScreen(repository: repository, now: now));
    await tester.pump();

    await tester.enterText(find.byKey(const Key('clockInTimeField')), '09:30');
    await tester.enterText(find.byType(TextField).last, '저장 실패 후 유지');
    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await tester.pump();

    expect(repository.updateTodayCallCount, 1);
    expect(
      find.text('저장할 수 없습니다. action=updateToday rule=test failure'),
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

    await tester.pumpWidget(_buildScreen(repository: repository, now: now));
    await tester.pump();

    await tester.tap(find.widgetWithText(OutlinedButton, '오늘 기록 삭제'));
    await tester.pumpAndSettle();
    expect(find.text('오늘 기록을 삭제할까요?'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, '삭제'));
    await tester.pumpAndSettle();

    expect(repository.deleteTodayCallCount, 1);
    expect(repository.record, isNull);
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

    await tester.pumpWidget(_buildScreen(repository: repository, now: now));
    await tester.pump();

    await tester.tap(find.widgetWithText(OutlinedButton, '오늘 기록 삭제'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '취소'));
    await tester.pumpAndSettle();

    expect(repository.deleteTodayCallCount, 0);
    expect(repository.record, record);
  });

  testWidgets('shows unavailable state when today record is missing', (
    WidgetTester tester,
  ) async {
    final DateTime now = DateTime(2026, 6, 12, 20, 0);
    final _FakeWorkRecordRepository repository = _FakeWorkRecordRepository(
      initialRecord: null,
      now: () => now,
    );

    await tester.pumpWidget(_buildScreen(repository: repository, now: now));
    await tester.pump();

    expect(find.text('수정할 오늘 기록이 없습니다.'), findsOneWidget);
    expect(
      tester.widget<TextButton>(find.widgetWithText(TextButton, '저장')).enabled,
      isFalse,
    );
  });
}

Widget _buildScreen({
  required _FakeWorkRecordRepository repository,
  required DateTime now,
}) {
  return MaterialApp(
    home: EditTodayWorkRecordScreen(repository: repository, now: () => now),
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
  int updateTodayCallCount = 0;
  int deleteTodayCallCount = 0;
  WorkRecordRepositoryException? updateError;
  WorkRecordRepositoryException? deleteError;

  @override
  Future<WorkRecord?> findToday() async {
    return record;
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
    updateTodayCallCount += 1;
    final WorkRecordRepositoryException? error = updateError;
    if (error != null) {
      throw error;
    }
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
  Future<void> deleteToday() async {
    deleteTodayCallCount += 1;
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

  @override
  Future<void> deleteByDate({required DateTime workDate}) async {
    throw const WorkRecordRepositoryException('unexpected deleteByDate call');
  }
}
