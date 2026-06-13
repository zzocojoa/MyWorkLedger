import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workledger/core/models/pricing_intent_event.dart';
import 'package:workledger/features/pricing/domain/pricing_intent_repository.dart';
import 'package:workledger/features/pricing/presentation/pricing_fake_door_screen.dart';

void main() {
  testWidgets('shows pricing fake-door copy without payment state', (
    WidgetTester tester,
  ) async {
    final _FakePricingIntentRepository repository =
        _FakePricingIntentRepository(
          failingEventTypes: <PricingIntentEventType>{},
        );

    await tester.pumpWidget(_buildScreen(repository: repository));
    await tester.pump();

    expect(find.text('월간 리포트'), findsOneWidget);
    expect(find.textContaining('리포트 기능을 준비 중입니다'), findsOneWidget);
    expect(find.text('실제 결제는 진행되지 않습니다.'), findsOneWidget);
    expect(find.text('Report Pass'), findsOneWidget);
    expect(find.text('Pro'), findsOneWidget);
    expect(find.text('관심 있음'), findsNWidgets(2));
    expect(find.text('결제 완료'), findsNothing);
    expect(find.text('영수증'), findsNothing);
    expect(find.text('구독 관리'), findsNothing);
    expect(
      repository.savedEvents.first.eventType,
      PricingIntentEventType.pricingScreenViewed,
    );
  });

  testWidgets('saves report pass and pro interest events', (
    WidgetTester tester,
  ) async {
    final _FakePricingIntentRepository repository =
        _FakePricingIntentRepository(
          failingEventTypes: <PricingIntentEventType>{},
        );

    await tester.pumpWidget(_buildScreen(repository: repository));
    await tester.pump();

    await tester.tap(find.byKey(const Key('reportPassInterestButton')));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.byKey(const Key('proInterestButton')));
    await tester.pump();
    await tester.pump();

    expect(
      repository.savedEvents.map((PricingIntentEvent event) => event.eventType),
      <PricingIntentEventType>[
        PricingIntentEventType.pricingScreenViewed,
        PricingIntentEventType.reportPassTapped,
        PricingIntentEventType.proPlanTapped,
      ],
    );
    expect(repository.savedEvents[1].selectedPlan, PricingPlan.reportPass);
    expect(repository.savedEvents[2].selectedPlan, PricingPlan.pro);
    expect(find.text('관심을 기록했습니다. MVP 테스트 중인 기능입니다.'), findsOneWidget);
  });

  testWidgets('shows Korean error when plan interest save fails', (
    WidgetTester tester,
  ) async {
    final _FakePricingIntentRepository repository =
        _FakePricingIntentRepository(
          failingEventTypes: <PricingIntentEventType>{
            PricingIntentEventType.reportPassTapped,
          },
        );

    await tester.pumpWidget(_buildScreen(repository: repository));
    await tester.pump();

    await tester.tap(find.byKey(const Key('reportPassInterestButton')));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('가격 관심 이벤트를 저장할 수 없습니다.'), findsOneWidget);
    expect(find.textContaining('eventType=reportPassTapped'), findsOneWidget);
  });
}

Widget _buildScreen({required _FakePricingIntentRepository repository}) {
  return MaterialApp(home: PricingFakeDoorScreen(repository: repository));
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
