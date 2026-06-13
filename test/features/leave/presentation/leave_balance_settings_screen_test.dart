import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workledger/features/leave/data/local_storage_leave_repository.dart';
import 'package:workledger/features/leave/presentation/leave_balance_settings_screen.dart';

import '../../../core/storage/in_memory_key_value_storage.dart';

void main() {
  testWidgets('saves total leave and returns to previous screen', (
    WidgetTester tester,
  ) async {
    final LocalStorageLeaveRepository repository = _createRepository();

    await tester.pumpWidget(_buildScreen(repository: repository));
    await tester.pump();
    await tester.pump();

    await tester.enterText(find.byKey(const Key('totalLeaveDaysField')), '15');
    await tester.enterText(find.byKey(const Key('totalLeaveHoursField')), '0');
    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await tester.pumpAndSettle();

    final balance = await repository.findBalanceByYear(year: 2026);
    expect(balance?.totalLeaveMinutes, 15 * 480);
  });

  testWidgets('shows validation error for non 30-minute total leave input', (
    WidgetTester tester,
  ) async {
    final LocalStorageLeaveRepository repository = _createRepository();

    await tester.pumpWidget(_buildScreen(repository: repository));
    await tester.pump();
    await tester.pump();

    await tester.enterText(find.byKey(const Key('totalLeaveDaysField')), '0');
    await tester.enterText(
      find.byKey(const Key('totalLeaveHoursField')),
      '0.25',
    );
    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await tester.pump();

    expect(find.textContaining('총 연차를 저장할 수 없습니다.'), findsOneWidget);
    expect(find.textContaining('30분 단위'), findsOneWidget);
  });
}

Widget _buildScreen({required LocalStorageLeaveRepository repository}) {
  return MaterialApp(
    home: LeaveBalanceSettingsScreen(
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
