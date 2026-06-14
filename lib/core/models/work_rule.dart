final class WorkRuleParseException implements Exception {
  const WorkRuleParseException(this.message);

  final String message;

  @override
  String toString() {
    return 'WorkRuleParseException: $message';
  }
}

const int workRuleDefaultNightWorkStartTimeMinutes = 22 * 60;

final class WorkRule {
  WorkRule({
    required this.id,
    required this.regularStartTimeMinutes,
    required this.regularEndTimeMinutes,
    required this.overtimeStartTimeMinutes,
    required this.nightWorkStartTimeMinutes,
    required this.breakMinutes,
    required List<int> workWeekdays,
    required this.createdAt,
    required this.updatedAt,
  }) : workWeekdays = List<int>.unmodifiable(workWeekdays) {
    _validateWorkRule(this);
  }

  final String id;
  final int regularStartTimeMinutes;
  final int regularEndTimeMinutes;
  final int overtimeStartTimeMinutes;
  final int nightWorkStartTimeMinutes;
  final int breakMinutes;
  final List<int> workWeekdays;
  final DateTime createdAt;
  final DateTime updatedAt;

  WorkRule copyWith({
    required String id,
    required int regularStartTimeMinutes,
    required int regularEndTimeMinutes,
    required int overtimeStartTimeMinutes,
    required int nightWorkStartTimeMinutes,
    required int breakMinutes,
    required List<int> workWeekdays,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) {
    return WorkRule(
      id: id,
      regularStartTimeMinutes: regularStartTimeMinutes,
      regularEndTimeMinutes: regularEndTimeMinutes,
      overtimeStartTimeMinutes: overtimeStartTimeMinutes,
      nightWorkStartTimeMinutes: nightWorkStartTimeMinutes,
      breakMinutes: breakMinutes,
      workWeekdays: workWeekdays,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'regular_start_time_minutes': regularStartTimeMinutes,
      'regular_end_time_minutes': regularEndTimeMinutes,
      'overtime_start_time_minutes': overtimeStartTimeMinutes,
      'night_work_start_time_minutes': nightWorkStartTimeMinutes,
      'break_minutes': breakMinutes,
      'work_weekdays': workWeekdays,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static WorkRule fromMap(Map<String, Object?> map) {
    final int regularEndTimeMinutes = _readInt(map, 'regular_end_time_minutes');
    return WorkRule(
      id: _readString(map, 'id'),
      regularStartTimeMinutes: _readInt(map, 'regular_start_time_minutes'),
      regularEndTimeMinutes: regularEndTimeMinutes,
      overtimeStartTimeMinutes: _readOptionalInt(
        map,
        'overtime_start_time_minutes',
        fallback: regularEndTimeMinutes,
      ),
      nightWorkStartTimeMinutes: _readOptionalInt(
        map,
        'night_work_start_time_minutes',
        fallback: workRuleDefaultNightWorkStartTimeMinutes,
      ),
      breakMinutes: _readInt(map, 'break_minutes'),
      workWeekdays: _readWeekdays(map, 'work_weekdays'),
      createdAt: _readDateTime(map, 'created_at'),
      updatedAt: _readDateTime(map, 'updated_at'),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is WorkRule &&
            id == other.id &&
            regularStartTimeMinutes == other.regularStartTimeMinutes &&
            regularEndTimeMinutes == other.regularEndTimeMinutes &&
            overtimeStartTimeMinutes == other.overtimeStartTimeMinutes &&
            nightWorkStartTimeMinutes == other.nightWorkStartTimeMinutes &&
            breakMinutes == other.breakMinutes &&
            _listEquals(workWeekdays, other.workWeekdays) &&
            createdAt == other.createdAt &&
            updatedAt == other.updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      regularStartTimeMinutes,
      regularEndTimeMinutes,
      overtimeStartTimeMinutes,
      nightWorkStartTimeMinutes,
      breakMinutes,
      Object.hashAll(workWeekdays),
      createdAt,
      updatedAt,
    );
  }
}

void _validateWorkRule(WorkRule rule) {
  if (rule.id.isEmpty) {
    throw ArgumentError.value(rule.id, 'id', 'must not be empty');
  }
  _validateMinuteOfDay(
    value: rule.regularStartTimeMinutes,
    field: 'regularStartTimeMinutes',
  );
  _validateMinuteOfDay(
    value: rule.regularEndTimeMinutes,
    field: 'regularEndTimeMinutes',
  );
  _validateMinuteOfDay(
    value: rule.overtimeStartTimeMinutes,
    field: 'overtimeStartTimeMinutes',
  );
  _validateMinuteOfDay(
    value: rule.nightWorkStartTimeMinutes,
    field: 'nightWorkStartTimeMinutes',
  );
  if (rule.regularEndTimeMinutes <= rule.regularStartTimeMinutes) {
    throw ArgumentError.value(
      rule.regularEndTimeMinutes,
      'regularEndTimeMinutes',
      'must be greater than regularStartTimeMinutes',
    );
  }
  if (rule.overtimeStartTimeMinutes < rule.regularEndTimeMinutes) {
    throw ArgumentError.value(
      rule.overtimeStartTimeMinutes,
      'overtimeStartTimeMinutes',
      'must be greater than or equal to regularEndTimeMinutes',
    );
  }
  if (rule.breakMinutes < 0) {
    throw ArgumentError.value(
      rule.breakMinutes,
      'breakMinutes',
      'must be greater than or equal to 0',
    );
  }
  if (rule.breakMinutes % 30 != 0) {
    throw ArgumentError.value(
      rule.breakMinutes,
      'breakMinutes',
      'must be divisible by 30',
    );
  }
  if (rule.workWeekdays.isEmpty) {
    throw ArgumentError.value(
      rule.workWeekdays,
      'workWeekdays',
      'must not be empty',
    );
  }
  if (rule.workWeekdays.toSet().length != rule.workWeekdays.length) {
    throw ArgumentError.value(
      rule.workWeekdays,
      'workWeekdays',
      'must not contain duplicates',
    );
  }
  for (final int weekday in rule.workWeekdays) {
    if (weekday < DateTime.monday || weekday > DateTime.sunday) {
      throw ArgumentError.value(
        rule.workWeekdays,
        'workWeekdays',
        'must contain values between 1 and 7',
      );
    }
  }
  if (rule.updatedAt.isBefore(rule.createdAt)) {
    throw ArgumentError.value(
      rule.updatedAt,
      'updatedAt',
      'must be greater than or equal to createdAt',
    );
  }
}

void _validateMinuteOfDay({required int value, required String field}) {
  if (value < 0 || value > 1439) {
    throw ArgumentError.value(value, field, 'must be between 0 and 1439');
  }
}

String _readString(Map<String, Object?> map, String field) {
  if (!map.containsKey(field)) {
    throw WorkRuleParseException('model=WorkRule field=$field rule=required');
  }
  final Object? value = map[field];
  if (value is String && value.isNotEmpty) {
    return value;
  }
  throw WorkRuleParseException(
    'model=WorkRule field=$field value=$value rule=non-empty String',
  );
}

int _readInt(Map<String, Object?> map, String field) {
  if (!map.containsKey(field)) {
    throw WorkRuleParseException('model=WorkRule field=$field rule=required');
  }
  final Object? value = map[field];
  if (value is int) {
    return value;
  }
  throw WorkRuleParseException(
    'model=WorkRule field=$field value=$value rule=int',
  );
}

int _readOptionalInt(
  Map<String, Object?> map,
  String field, {
  required int fallback,
}) {
  if (!map.containsKey(field)) {
    return fallback;
  }
  final Object? value = map[field];
  if (value is int) {
    return value;
  }
  throw WorkRuleParseException(
    'model=WorkRule field=$field value=$value rule=int',
  );
}

List<int> _readWeekdays(Map<String, Object?> map, String field) {
  if (!map.containsKey(field)) {
    throw WorkRuleParseException('model=WorkRule field=$field rule=required');
  }
  final Object? value = map[field];
  if (value is! List<Object?>) {
    throw WorkRuleParseException(
      'model=WorkRule field=$field value=$value rule=List<int>',
    );
  }
  return value
      .map((Object? item) {
        if (item is int) {
          return item;
        }
        throw WorkRuleParseException(
          'model=WorkRule field=$field value=$item rule=int weekday',
        );
      })
      .toList(growable: false);
}

DateTime _readDateTime(Map<String, Object?> map, String field) {
  final String value = _readString(map, field);
  try {
    return DateTime.parse(value);
  } on FormatException {
    throw WorkRuleParseException(
      'model=WorkRule field=$field value=$value rule=valid ISO-8601 DateTime',
    );
  }
}

bool _listEquals<T>(List<T> left, List<T> right) {
  if (left.length != right.length) {
    return false;
  }
  for (int index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}
