import 'package:flutter_test/flutter_test.dart';
import 'package:workledger/core/models/pricing_intent_event.dart';
import 'package:workledger/features/pricing/domain/pricing_intent_repository.dart';
import 'package:workledger/features/pricing/domain/record_pricing_intent.dart';

void main() {
  test('records intent through repository', () async {
    final _FakePricingIntentRepository repository =
        _FakePricingIntentRepository();

    final PricingIntentEvent event = await recordPricingIntent(
      repository: repository,
      eventType: PricingIntentEventType.proPlanTapped,
      selectedPlan: PricingPlan.pro,
      sourceScreen: 'pricing_fake_door',
    );

    expect(event.eventType, PricingIntentEventType.proPlanTapped);
    expect(event.selectedPlan, PricingPlan.pro);
    expect(repository.savedEvents, <PricingIntentEvent>[event]);
  });
}

final class _FakePricingIntentRepository implements PricingIntentRepository {
  final List<PricingIntentEvent> savedEvents = <PricingIntentEvent>[];

  @override
  Future<PricingIntentEvent> save({
    required PricingIntentEventType eventType,
    required PricingPlan? selectedPlan,
    required String sourceScreen,
  }) async {
    final PricingIntentEvent event = PricingIntentEvent(
      id: 'event-${savedEvents.length + 1}',
      eventType: eventType,
      selectedPlan: selectedPlan,
      sourceScreen: sourceScreen,
      occurredAt: DateTime.parse('2026-06-12T18:42:00'),
      createdAt: DateTime.parse('2026-06-12T18:42:00'),
    );
    savedEvents.add(event);
    return event;
  }

  @override
  Future<List<PricingIntentEvent>> findAll() async {
    return List<PricingIntentEvent>.of(savedEvents);
  }
}
