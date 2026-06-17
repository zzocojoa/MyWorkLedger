import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workledger/core/theme/workledger_design_tokens.dart';
import 'package:workledger/features/leave/data/local_storage_leave_repository.dart';
import 'package:workledger/features/leave/presentation/leave_management_screen.dart';

import '../../../core/storage/in_memory_key_value_storage.dart';

void main() {
  testWidgets('shows initial leave management screen', (
    WidgetTester tester,
  ) async {
    final LocalStorageLeaveRepository repository = _createRepository();

    await tester.pumpWidget(_buildScreen(repository: repository));
    await tester.pump();
    await tester.pump();

    expect(find.text('연차 관리'), findsOneWidget);
    expect(find.text('기준 연도'), findsOneWidget);
    expect(find.text('2026'), findsOneWidget);
    expect(find.text('남은 연차'), findsOneWidget);
    expect(find.text('총 연차'), findsNothing);
    expect(find.byKey(const Key('totalLeaveDaysField')), findsNothing);
    expect(find.text('연차 사용 추가'), findsNWidgets(2));
    expect(find.text('사용 내역이 없습니다'), findsOneWidget);
  });

  testWidgets('adds leave usage and displays usage list', (
    WidgetTester tester,
  ) async {
    final LocalStorageLeaveRepository repository = _createRepository();
    await repository.saveBalance(year: 2026, totalLeaveMinutes: 15 * 480);

    await tester.pumpWidget(_buildScreen(repository: repository));
    await tester.pump();
    await tester.pump();

    await tester.enterText(
      find.byKey(const Key('usageDateField')),
      '2026-06-10',
    );
    await tester.enterText(find.byKey(const Key('usageDaysField')), '0');
    await tester.enterText(find.byKey(const Key('usageHoursField')), '4');
    await tester.enterText(find.byKey(const Key('usageMemoField')), '오전 반차');
    await _tapAddUsageButton(tester);
    await tester.pump();
    await tester.pump();

    expect(find.text('14일 4시간'), findsOneWidget);
    expect(find.text('총 15일 0시간 · 사용 4시간'), findsOneWidget);
    expect(find.text('06-10'), findsOneWidget);
    expect(find.text('4시간'), findsWidgets);
    expect(find.text('오전 반차'), findsOneWidget);
  });

  testWidgets('blocks leave usage before total leave registration', (
    WidgetTester tester,
  ) async {
    final LocalStorageLeaveRepository repository = _createRepository();

    await tester.pumpWidget(_buildScreen(repository: repository));
    await tester.pump();
    await tester.pump();

    await tester.enterText(
      find.byKey(const Key('usageDateField')),
      '2026-06-10',
    );
    await tester.enterText(find.byKey(const Key('usageDaysField')), '1');
    await tester.enterText(find.byKey(const Key('usageHoursField')), '0');
    await _tapAddUsageButton(tester);
    await tester.pump();

    expect(find.textContaining('총 연차에서 올해 총 연차를 먼저 등록'), findsOneWidget);
    expect(await repository.findUsagesByYear(year: 2026), isEmpty);
    expect(find.text('사용 내역이 없습니다'), findsOneWidget);
  });

  testWidgets('resets registered leave usage amounts from app bar action', (
    WidgetTester tester,
  ) async {
    final LocalStorageLeaveRepository repository = _createRepository();
    await repository.saveBalance(year: 2026, totalLeaveMinutes: 15 * 480);

    await tester.pumpWidget(_buildScreen(repository: repository));
    await tester.pump();
    await tester.pump();

    await tester.enterText(
      find.byKey(const Key('usageDateField')),
      '2026-06-26',
    );
    await tester.enterText(find.byKey(const Key('usageDaysField')), '1');
    await tester.enterText(find.byKey(const Key('usageHoursField')), '0');
    await _tapAddUsageButton(tester);
    await tester.pump();
    await tester.pump();

    expect(find.text('06-26'), findsOneWidget);
    expect(find.text('총 15일 0시간 · 사용 1일 0시간'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, '리셋'));
    await tester.pumpAndSettle();
    expect(find.text('연차 사용 내역을 초기화할까요?'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, '초기화'));
    await tester.pump();
    await tester.pump();

    expect(await repository.findUsagesByYear(year: 2026), isEmpty);
    expect(find.text('15일'), findsOneWidget);
    expect(find.text('총 15일 0시간 · 사용 0시간'), findsOneWidget);
    expect(find.text('사용 내역이 없습니다'), findsOneWidget);
    expect(find.text('06-26'), findsNothing);
  });

  testWidgets('deletes leave usage after confirmation and refreshes summary', (
    WidgetTester tester,
  ) async {
    final LocalStorageLeaveRepository repository = _createRepository();
    await repository.saveBalance(year: 2026, totalLeaveMinutes: 15 * 480);

    await tester.pumpWidget(_buildScreen(repository: repository));
    await tester.pump();
    await tester.pump();

    await tester.enterText(
      find.byKey(const Key('usageDateField')),
      '2026-06-10',
    );
    await tester.enterText(find.byKey(const Key('usageDaysField')), '0');
    await tester.enterText(find.byKey(const Key('usageHoursField')), '4');
    await tester.enterText(find.byKey(const Key('usageMemoField')), '오전 반차');
    await _tapAddUsageButton(tester);
    await tester.pump();
    await tester.pump();

    await tester.ensureVisible(find.byIcon(Icons.delete_outline));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(find.text('연차 사용을 삭제할까요?'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, '삭제'));
    await tester.pump();
    await tester.pump();

    expect(find.text('15일'), findsOneWidget);
    expect(find.text('총 15일 0시간 · 사용 0시간'), findsOneWidget);
    expect(find.text('사용 내역이 없습니다'), findsOneWidget);
    expect(find.text('오전 반차'), findsNothing);
  });

  testWidgets('shows exceeded state after overuse', (
    WidgetTester tester,
  ) async {
    final LocalStorageLeaveRepository repository = _createRepository();
    await repository.saveBalance(year: 2026, totalLeaveMinutes: 480);

    await tester.pumpWidget(_buildScreen(repository: repository));
    await tester.pump();
    await tester.pump();

    await tester.enterText(
      find.byKey(const Key('usageDateField')),
      '2026-06-10',
    );
    await tester.enterText(find.byKey(const Key('usageDaysField')), '2');
    await tester.enterText(find.byKey(const Key('usageHoursField')), '0');
    await _tapAddUsageButton(tester);
    await tester.pump();
    await tester.pump();

    expect(find.text('초과 1일'), findsOneWidget);
    expect(find.text('초과 사용 중'), findsOneWidget);
    expect(find.text('총 1일 0시간 · 사용 2일 0시간'), findsOneWidget);
  });

  testWidgets('shows validation error for non 30-minute input', (
    WidgetTester tester,
  ) async {
    final LocalStorageLeaveRepository repository = _createRepository();
    await repository.saveBalance(year: 2026, totalLeaveMinutes: 15 * 480);

    await tester.pumpWidget(_buildScreen(repository: repository));
    await tester.pump();
    await tester.pump();

    await tester.enterText(
      find.byKey(const Key('usageDateField')),
      '2026-06-10',
    );
    await tester.enterText(find.byKey(const Key('usageDaysField')), '0');
    await tester.enterText(find.byKey(const Key('usageHoursField')), '0.25');
    await _tapAddUsageButton(tester);
    await tester.pump();

    expect(find.textContaining('연차 사용을 추가할 수 없습니다.'), findsOneWidget);
    expect(find.textContaining('30분 이상'), findsOneWidget);
  });
}

Widget _buildScreen({required LocalStorageLeaveRepository repository}) {
  return MaterialApp(
    theme: createWorkLedgerTheme(),
    home: LeaveManagementScreen(
      repository: repository,
      now: () => DateTime(2026, 6, 12, 9),
    ),
  );
}

LocalStorageLeaveRepository _createRepository() {
  int idValue = 0;
  return LocalStorageLeaveRepository(
    storage: InMemoryKeyValueStorage.empty(),
    clock: () => DateTime.parse('2026-06-12T09:00:00'),
    idGenerator: () {
      idValue += 1;
      return 'leave-$idValue';
    },
  );
}

Future<void> _tapAddUsageButton(WidgetTester tester) async {
  final Finder button = find.widgetWithText(OutlinedButton, '연차 사용 추가');
  await tester.ensureVisible(button);
  await tester.pump();
  await tester.tap(button);
}
