import '../../../core/models/pricing_intent_event.dart';
import 'pricing_intent_repository.dart';

Future<PricingIntentEvent> recordPricingIntent({
  required PricingIntentRepository repository,
  required PricingIntentEventType eventType,
  required PricingPlan? selectedPlan,
  required String sourceScreen,
}) async {
  return repository.save(
    eventType: eventType,
    selectedPlan: selectedPlan,
    sourceScreen: sourceScreen,
  );
}
