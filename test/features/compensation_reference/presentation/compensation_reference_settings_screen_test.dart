import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workledger/core/models/compensation_reference_setting.dart';
import 'package:workledger/features/compensation_reference/domain/compensation_reference_repository.dart';
import 'package:workledger/features/compensation_reference/presentation/compensation_reference_settings_screen.dart';

void main() {
  testWidgets('saves fixed included setting from form', (
    WidgetTester tester,
  ) async {
    final _FakeCompensationReferenceRepository repository =
        _FakeCompensationReferenceRepository(setting: null, findError: null);

    await tester.pumpWidget(_buildScreen(repository: repository));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('고정 포함 시간 있음'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).at(0), '120');
    await tester.enterText(find.byType(TextField).at(1), '30');
    await tester.enterText(find.byType(TextField).at(2), '60');
    await tester.enterText(find.byType(TextField).at(3), '2026-06');
    await tester.ensureVisible(find.text('저장'));
    await tester.pump();
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(repository.savedMode, CompensationReferenceMode.fixedIncluded);
    expect(repository.savedOvertimeMinutes, 120);
    expect(repository.savedNightMinutes, 30);
    expect(repository.savedHolidayMinutes, 60);
    expect(repository.savedEffectiveFromMonth, DateTime(2026, 6));
  });

  testWidgets('shows unknown setting guidance form state', (
    WidgetTester tester,
  ) async {
    final _FakeCompensationReferenceRepository repository =
        _FakeCompensationReferenceRepository(
          setting: CompensationReferenceSetting(
            id: 'setting-1',
            mode: CompensationReferenceMode.unknown,
            fixedIncludedOvertimeMinutes: 0,
            fixedIncludedNightMinutes: 0,
            fixedIncludedHolidayMinutes: 0,
            effectiveFromMonth: DateTime(2026, 6),
            memo: null,
            createdAt: DateTime(2026, 6, 1),
            updatedAt: DateTime(2026, 6, 1),
          ),
          findError: null,
        );

    await tester.pumpWidget(_buildScreen(repository: repository));
    await tester.pump();
    await tester.pump();

    expect(find.text('비교 방식'), findsOneWidget);
    expect(find.text('잘 모르겠음'), findsOneWidget);
    expect(find.text('연장 근무 포함 시간(분)'), findsNothing);
  });
}

Widget _buildScreen({
  required _FakeCompensationReferenceRepository repository,
}) {
  return MaterialApp(
    home: CompensationReferenceSettingsScreen(
      repository: repository,
      targetMonth: DateTime(2026, 6, 12),
    ),
  );
}

final class _FakeCompensationReferenceRepository
    implements CompensationReferenceRepository {
  _FakeCompensationReferenceRepository({
    required this.setting,
    required this.findError,
  });

  final CompensationReferenceSetting? setting;
  final CompensationReferenceRepositoryException? findError;
  CompensationReferenceMode? savedMode;
  int? savedOvertimeMinutes;
  int? savedNightMinutes;
  int? savedHolidayMinutes;
  DateTime? savedEffectiveFromMonth;

  @override
  Future<CompensationReferenceSetting?> findApplicableForMonth({
    required int year,
    required int month,
  }) async {
    final CompensationReferenceRepositoryException? error = findError;
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
    savedMode = mode;
    savedOvertimeMinutes = fixedIncludedOvertimeMinutes;
    savedNightMinutes = fixedIncludedNightMinutes;
    savedHolidayMinutes = fixedIncludedHolidayMinutes;
    savedEffectiveFromMonth = effectiveFromMonth;
    return CompensationReferenceSetting(
      id: 'setting-saved',
      mode: mode,
      fixedIncludedOvertimeMinutes: fixedIncludedOvertimeMinutes,
      fixedIncludedNightMinutes: fixedIncludedNightMinutes,
      fixedIncludedHolidayMinutes: fixedIncludedHolidayMinutes,
      effectiveFromMonth: effectiveFromMonth,
      memo: memo,
      createdAt: DateTime(2026, 6, 1),
      updatedAt: DateTime(2026, 6, 1),
    );
  }
}
