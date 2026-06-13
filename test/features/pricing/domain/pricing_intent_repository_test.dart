import 'package:flutter_test/flutter_test.dart';
import 'package:workledger/core/models/pricing_intent_event.dart';
import 'package:workledger/features/pricing/data/local_storage_pricing_intent_repository.dart';
import 'package:workledger/features/pricing/domain/pricing_intent_repository.dart';

import '../../../core/storage/in_memory_key_value_storage.dart';

void main() {
  group('LocalStoragePricingIntentRepository', () {
    test(
      'saves and reads pricing intent events sorted by occurrence',
      () async {
        int idValue = 0;
        DateTime now = DateTime.parse('2026-06-12T18:42:00');
        final InMemoryKeyValueStorage storage = InMemoryKeyValueStorage.empty();
        final LocalStoragePricingIntentRepository repository =
            _createRepository(
              storage: storage,
              clock: () => now,
              idGenerator: () {
                idValue += 1;
                return 'pricing-event-$idValue';
              },
            );

        final PricingIntentEvent reportEvent = await repository.save(
          eventType: PricingIntentEventType.reportButtonTapped,
          selectedPlan: null,
          sourceScreen: 'monthly_summary',
        );
        now = DateTime.parse('2026-06-12T18:43:00');
        final PricingIntentEvent reportPassEvent = await repository.save(
          eventType: PricingIntentEventType.reportPassTapped,
          selectedPlan: PricingPlan.reportPass,
          sourceScreen: 'pricing_fake_door',
        );

        final List<PricingIntentEvent> events = await repository.findAll();

        expect(reportEvent.id, 'pricing-event-1');
        expect(
          reportEvent.eventType,
          PricingIntentEventType.reportButtonTapped,
        );
        expect(reportEvent.selectedPlan, isNull);
        expect(reportEvent.sourceScreen, 'monthly_summary');
        expect(reportEvent.occurredAt, DateTime.parse('2026-06-12T18:42:00'));
        expect(reportPassEvent.id, 'pricing-event-2');
        expect(events, <PricingIntentEvent>[reportEvent, reportPassEvent]);
      },
    );

    test('throws explicit error when stored event cannot parse', () async {
      final InMemoryKeyValueStorage storage = InMemoryKeyValueStorage.empty();
      await storage.write(
        table: LocalStoragePricingIntentRepository.pricingIntentEventsTable,
        key: 'broken-event',
        value: <String, Object?>{
          'id': 'broken-event',
          'event_type': 'unknown',
          'selected_plan': null,
          'source_screen': 'pricing_fake_door',
          'occurred_at': '2026-06-12T18:42:00',
          'created_at': '2026-06-12T18:42:00',
        },
      );
      final LocalStoragePricingIntentRepository repository = _createRepository(
        storage: storage,
        clock: () => DateTime.parse('2026-06-12T18:42:00'),
        idGenerator: () => 'unused-id',
      );

      expect(
        () => repository.findAll(),
        throwsA(isA<PricingIntentRepositoryException>()),
      );
    });
  });
}

LocalStoragePricingIntentRepository _createRepository({
  required InMemoryKeyValueStorage storage,
  required DateTime Function() clock,
  required String Function() idGenerator,
}) {
  return LocalStoragePricingIntentRepository(
    storage: storage,
    clock: clock,
    idGenerator: idGenerator,
  );
}
