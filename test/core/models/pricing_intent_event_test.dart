import 'package:flutter_test/flutter_test.dart';
import 'package:workledger/core/models/pricing_intent_event.dart';

void main() {
  group('PricingIntentEvent', () {
    test('serializes and parses a non-plan event', () {
      final PricingIntentEvent event = PricingIntentEvent(
        id: 'event-1',
        eventType: PricingIntentEventType.pricingScreenViewed,
        selectedPlan: null,
        sourceScreen: 'monthly_summary',
        occurredAt: DateTime.parse('2026-06-12T18:42:00'),
        createdAt: DateTime.parse('2026-06-12T18:42:01'),
      );

      final Map<String, Object?> map = event.toMap();
      final PricingIntentEvent parsed = PricingIntentEvent.fromMap(map);

      expect(map['event_type'], 'pricingScreenViewed');
      expect(map['selected_plan'], isNull);
      expect(parsed, event);
    });

    test('serializes and parses a plan click event', () {
      final PricingIntentEvent event = PricingIntentEvent(
        id: 'event-2',
        eventType: PricingIntentEventType.reportPassTapped,
        selectedPlan: PricingPlan.reportPass,
        sourceScreen: 'pricing',
        occurredAt: DateTime.parse('2026-06-12T18:43:00'),
        createdAt: DateTime.parse('2026-06-12T18:43:01'),
      );

      final Map<String, Object?> map = event.toMap();
      final PricingIntentEvent parsed = PricingIntentEvent.fromMap(map);

      expect(map['selected_plan'], 'reportPass');
      expect(parsed, event);
    });

    test('copyWith requires explicit values and returns a changed event', () {
      final PricingIntentEvent event = PricingIntentEvent(
        id: 'event-1',
        eventType: PricingIntentEventType.reportButtonTapped,
        selectedPlan: null,
        sourceScreen: 'monthly_summary',
        occurredAt: DateTime.parse('2026-06-12T18:42:00'),
        createdAt: DateTime.parse('2026-06-12T18:42:01'),
      );

      final PricingIntentEvent changed = event.copyWith(
        id: event.id,
        eventType: PricingIntentEventType.proPlanTapped,
        selectedPlan: PricingPlan.pro,
        sourceScreen: 'pricing',
        occurredAt: DateTime.parse('2026-06-12T18:43:00'),
        createdAt: event.createdAt,
      );

      expect(changed.eventType, PricingIntentEventType.proPlanTapped);
      expect(changed.selectedPlan, PricingPlan.pro);
      expect(event.selectedPlan, isNull);
    });

    test('throws on missing required map field', () {
      final Map<String, Object?> map = <String, Object?>{
        'id': 'event-1',
        'selected_plan': null,
        'source_screen': 'monthly_summary',
        'occurred_at': '2026-06-12T18:42:00.000',
        'created_at': '2026-06-12T18:42:01.000',
      };

      expect(
        () => PricingIntentEvent.fromMap(map),
        throwsA(isA<PricingIntentEventParseException>()),
      );
    });

    test('throws on wrong map field type', () {
      final Map<String, Object?> map = <String, Object?>{
        'id': 'event-1',
        'event_type': 'pricingScreenViewed',
        'selected_plan': 1,
        'source_screen': 'monthly_summary',
        'occurred_at': '2026-06-12T18:42:00.000',
        'created_at': '2026-06-12T18:42:01.000',
      };

      expect(
        () => PricingIntentEvent.fromMap(map),
        throwsA(isA<PricingIntentEventParseException>()),
      );
    });

    test('throws on invalid ISO date', () {
      final Map<String, Object?> map = <String, Object?>{
        'id': 'event-1',
        'event_type': 'pricingScreenViewed',
        'selected_plan': null,
        'source_screen': 'monthly_summary',
        'occurred_at': 'not-a-date',
        'created_at': '2026-06-12T18:42:01.000',
      };

      expect(
        () => PricingIntentEvent.fromMap(map),
        throwsA(isA<PricingIntentEventParseException>()),
      );
    });

    test('throws when plan click event has mismatched selected plan', () {
      expect(
        () => PricingIntentEvent(
          id: 'event-1',
          eventType: PricingIntentEventType.reportPassTapped,
          selectedPlan: PricingPlan.pro,
          sourceScreen: 'pricing',
          occurredAt: DateTime.parse('2026-06-12T18:42:00'),
          createdAt: DateTime.parse('2026-06-12T18:42:01'),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
