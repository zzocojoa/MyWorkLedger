enum PricingIntentEventType {
  reportButtonTapped,
  pricingScreenViewed,
  reportPassTapped,
  proPlanTapped,
  fakeDoorResultViewed;

  static PricingIntentEventType fromStorageValue(String value) {
    for (final PricingIntentEventType eventType
        in PricingIntentEventType.values) {
      if (eventType.name == value) {
        return eventType;
      }
    }
    throw PricingIntentEventParseException(
      'model=PricingIntentEvent field=event_type value=$value rule=known PricingIntentEventType',
    );
  }
}

enum PricingPlan {
  reportPass,
  pro;

  static PricingPlan fromStorageValue(String value) {
    for (final PricingPlan plan in PricingPlan.values) {
      if (plan.name == value) {
        return plan;
      }
    }
    throw PricingIntentEventParseException(
      'model=PricingIntentEvent field=selected_plan value=$value rule=known PricingPlan',
    );
  }
}

final class PricingIntentEventParseException implements Exception {
  const PricingIntentEventParseException(this.message);

  final String message;

  @override
  String toString() {
    return 'PricingIntentEventParseException: $message';
  }
}

final class PricingIntentEvent {
  PricingIntentEvent({
    required this.id,
    required this.eventType,
    required this.selectedPlan,
    required this.sourceScreen,
    required this.occurredAt,
    required this.createdAt,
  }) {
    _validatePricingIntentEvent(this);
  }

  final String id;
  final PricingIntentEventType eventType;
  final PricingPlan? selectedPlan;
  final String sourceScreen;
  final DateTime occurredAt;
  final DateTime createdAt;

  PricingIntentEvent copyWith({
    required String id,
    required PricingIntentEventType eventType,
    required PricingPlan? selectedPlan,
    required String sourceScreen,
    required DateTime occurredAt,
    required DateTime createdAt,
  }) {
    return PricingIntentEvent(
      id: id,
      eventType: eventType,
      selectedPlan: selectedPlan,
      sourceScreen: sourceScreen,
      occurredAt: occurredAt,
      createdAt: createdAt,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'event_type': eventType.name,
      'selected_plan': selectedPlan?.name,
      'source_screen': sourceScreen,
      'occurred_at': occurredAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  static PricingIntentEvent fromMap(Map<String, Object?> map) {
    return PricingIntentEvent(
      id: _readString(map, 'id'),
      eventType: PricingIntentEventType.fromStorageValue(
        _readString(map, 'event_type'),
      ),
      selectedPlan: _readNullablePricingPlan(map, 'selected_plan'),
      sourceScreen: _readString(map, 'source_screen'),
      occurredAt: _readDateTime(map, 'occurred_at'),
      createdAt: _readDateTime(map, 'created_at'),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PricingIntentEvent &&
            id == other.id &&
            eventType == other.eventType &&
            selectedPlan == other.selectedPlan &&
            sourceScreen == other.sourceScreen &&
            occurredAt == other.occurredAt &&
            createdAt == other.createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      eventType,
      selectedPlan,
      sourceScreen,
      occurredAt,
      createdAt,
    );
  }
}

void _validatePricingIntentEvent(PricingIntentEvent event) {
  if (event.id.isEmpty) {
    throw ArgumentError.value(event.id, 'id', 'must not be empty');
  }
  if (event.sourceScreen.isEmpty || event.sourceScreen.length > 100) {
    throw ArgumentError.value(
      event.sourceScreen,
      'sourceScreen',
      'must be non-empty and 100 characters or fewer',
    );
  }
  switch (event.eventType) {
    case PricingIntentEventType.reportPassTapped:
      if (event.selectedPlan != PricingPlan.reportPass) {
        throw ArgumentError.value(
          event.selectedPlan,
          'selectedPlan',
          'must be reportPass for reportPassTapped',
        );
      }
    case PricingIntentEventType.proPlanTapped:
      if (event.selectedPlan != PricingPlan.pro) {
        throw ArgumentError.value(
          event.selectedPlan,
          'selectedPlan',
          'must be pro for proPlanTapped',
        );
      }
    case PricingIntentEventType.reportButtonTapped:
    case PricingIntentEventType.pricingScreenViewed:
    case PricingIntentEventType.fakeDoorResultViewed:
      if (event.selectedPlan != null) {
        throw ArgumentError.value(
          event.selectedPlan,
          'selectedPlan',
          'must be null for non-plan events',
        );
      }
  }
}

String _readString(Map<String, Object?> map, String field) {
  if (!map.containsKey(field)) {
    throw PricingIntentEventParseException(
      'model=PricingIntentEvent field=$field rule=required',
    );
  }
  final Object? value = map[field];
  if (value is String && value.isNotEmpty) {
    return value;
  }
  throw PricingIntentEventParseException(
    'model=PricingIntentEvent field=$field value=$value rule=non-empty String',
  );
}

PricingPlan? _readNullablePricingPlan(Map<String, Object?> map, String field) {
  if (!map.containsKey(field)) {
    throw PricingIntentEventParseException(
      'model=PricingIntentEvent field=$field rule=required nullable field',
    );
  }
  final Object? value = map[field];
  if (value == null) {
    return null;
  }
  if (value is String) {
    return PricingPlan.fromStorageValue(value);
  }
  throw PricingIntentEventParseException(
    'model=PricingIntentEvent field=$field value=$value rule=String or null',
  );
}

DateTime _readDateTime(Map<String, Object?> map, String field) {
  final String value = _readString(map, field);
  try {
    return DateTime.parse(value);
  } on FormatException {
    throw PricingIntentEventParseException(
      'model=PricingIntentEvent field=$field value=$value rule=valid ISO-8601 DateTime',
    );
  }
}
