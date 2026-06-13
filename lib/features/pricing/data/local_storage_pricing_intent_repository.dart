import '../../../core/models/pricing_intent_event.dart';
import '../../../core/storage/key_value_storage.dart';
import '../domain/pricing_intent_repository.dart';

typedef PricingIntentClock = DateTime Function();
typedef PricingIntentIdGenerator = String Function();

final class LocalStoragePricingIntentRepository
    implements PricingIntentRepository {
  const LocalStoragePricingIntentRepository({
    required this.storage,
    required this.clock,
    required this.idGenerator,
  });

  final KeyValueStorage storage;
  final PricingIntentClock clock;
  final PricingIntentIdGenerator idGenerator;

  static const String pricingIntentEventsTable = 'pricing_intent_events';

  @override
  Future<PricingIntentEvent> save({
    required PricingIntentEventType eventType,
    required PricingPlan? selectedPlan,
    required String sourceScreen,
  }) async {
    final DateTime now = clock();
    final PricingIntentEvent event = PricingIntentEvent(
      id: idGenerator(),
      eventType: eventType,
      selectedPlan: selectedPlan,
      sourceScreen: sourceScreen,
      occurredAt: now,
      createdAt: now,
    );
    await storage.write(
      table: pricingIntentEventsTable,
      key: event.id,
      value: event.toMap(),
    );
    return event;
  }

  @override
  Future<List<PricingIntentEvent>> findAll() async {
    final Map<String, Map<String, Object?>> rows = await storage.readAll(
      table: pricingIntentEventsTable,
    );
    final List<PricingIntentEvent> events = <PricingIntentEvent>[];
    for (final MapEntry<String, Map<String, Object?>> row in rows.entries) {
      events.add(_parseEventMap(key: row.key, map: row.value));
    }
    return _sortEvents(events);
  }
}

PricingIntentEvent _parseEventMap({
  required String key,
  required Map<String, Object?> map,
}) {
  try {
    return PricingIntentEvent.fromMap(map);
  } on PricingIntentEventParseException catch (error) {
    throw PricingIntentRepositoryException(
      'action=parse table=${LocalStoragePricingIntentRepository.pricingIntentEventsTable} key=$key cause=${error.message}',
    );
  } on ArgumentError catch (error) {
    throw PricingIntentRepositoryException(
      'action=parse table=${LocalStoragePricingIntentRepository.pricingIntentEventsTable} key=$key cause=${error.message}',
    );
  }
}

List<PricingIntentEvent> _sortEvents(List<PricingIntentEvent> events) {
  final List<PricingIntentEvent> sortedEvents = List<PricingIntentEvent>.of(
    events,
  );
  sortedEvents.sort((PricingIntentEvent left, PricingIntentEvent right) {
    final int occurredCompare = left.occurredAt.compareTo(right.occurredAt);
    if (occurredCompare != 0) {
      return occurredCompare;
    }
    return left.id.compareTo(right.id);
  });
  return sortedEvents;
}
