import '../../../core/models/pricing_intent_event.dart';

abstract interface class PricingIntentRepository {
  Future<PricingIntentEvent> save({
    required PricingIntentEventType eventType,
    required PricingPlan? selectedPlan,
    required String sourceScreen,
  });

  Future<List<PricingIntentEvent>> findAll();
}

final class PricingIntentRepositoryException implements Exception {
  const PricingIntentRepositoryException(this.message);

  final String message;

  @override
  String toString() {
    return 'PricingIntentRepositoryException: $message';
  }
}
