final class CompensationReferenceSettingParseException implements Exception {
  const CompensationReferenceSettingParseException(this.message);

  final String message;

  @override
  String toString() {
    return 'CompensationReferenceSettingParseException: $message';
  }
}

enum CompensationReferenceMode { none, fixedIncluded, unknown }

final class CompensationReferenceSetting {
  CompensationReferenceSetting({
    required this.id,
    required this.mode,
    required this.fixedIncludedAfterRegularEndMinutes,
    required this.effectiveFromMonth,
    required this.memo,
    required this.createdAt,
    required this.updatedAt,
  }) {
    _validateCompensationReferenceSetting(this);
  }

  final String id;
  final CompensationReferenceMode mode;
  final int fixedIncludedAfterRegularEndMinutes;
  final DateTime effectiveFromMonth;
  final String? memo;
  final DateTime createdAt;
  final DateTime updatedAt;

  CompensationReferenceSetting copyWith({
    required String id,
    required CompensationReferenceMode mode,
    required int fixedIncludedAfterRegularEndMinutes,
    required DateTime effectiveFromMonth,
    required String? memo,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) {
    return CompensationReferenceSetting(
      id: id,
      mode: mode,
      fixedIncludedAfterRegularEndMinutes: fixedIncludedAfterRegularEndMinutes,
      effectiveFromMonth: effectiveFromMonth,
      memo: memo,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'mode': mode.name,
      'fixed_included_after_regular_end_minutes':
          fixedIncludedAfterRegularEndMinutes,
      'effective_from_month': effectiveFromMonth.toIso8601String(),
      'memo': memo,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static CompensationReferenceSetting fromMap(Map<String, Object?> map) {
    return CompensationReferenceSetting(
      id: _readString(map, 'id'),
      mode: _readMode(map, 'mode'),
      fixedIncludedAfterRegularEndMinutes:
          _readFixedIncludedAfterRegularEndMinutes(map),
      effectiveFromMonth: _readDateTime(map, 'effective_from_month'),
      memo: _readNullableString(map, 'memo'),
      createdAt: _readDateTime(map, 'created_at'),
      updatedAt: _readDateTime(map, 'updated_at'),
    );
  }

  static int _readFixedIncludedAfterRegularEndMinutes(
    Map<String, Object?> map,
  ) {
    if (map.containsKey('fixed_included_after_regular_end_minutes')) {
      return _readInt(map, 'fixed_included_after_regular_end_minutes');
    }
    return _readInt(map, 'fixed_included_overtime_minutes');
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CompensationReferenceSetting &&
            id == other.id &&
            mode == other.mode &&
            fixedIncludedAfterRegularEndMinutes ==
                other.fixedIncludedAfterRegularEndMinutes &&
            effectiveFromMonth == other.effectiveFromMonth &&
            memo == other.memo &&
            createdAt == other.createdAt &&
            updatedAt == other.updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      mode,
      fixedIncludedAfterRegularEndMinutes,
      effectiveFromMonth,
      memo,
      createdAt,
      updatedAt,
    );
  }
}

DateTime normalizeCompensationReferenceMonth({
  required DateTime effectiveFromMonth,
}) {
  return DateTime(effectiveFromMonth.year, effectiveFromMonth.month);
}

void _validateCompensationReferenceSetting(
  CompensationReferenceSetting setting,
) {
  if (setting.id.isEmpty) {
    throw ArgumentError.value(setting.id, 'id', 'must not be empty');
  }
  _validateNonNegativeMinutes(
    value: setting.fixedIncludedAfterRegularEndMinutes,
    field: 'fixedIncludedAfterRegularEndMinutes',
  );
  if (!_isMonthOnly(setting.effectiveFromMonth)) {
    throw ArgumentError.value(
      setting.effectiveFromMonth,
      'effectiveFromMonth',
      'must be first day of month at midnight',
    );
  }
  final String? memo = setting.memo;
  if (memo != null && memo.length > 500) {
    throw ArgumentError.value(memo, 'memo', 'must be 500 characters or less');
  }
  if (setting.updatedAt.isBefore(setting.createdAt)) {
    throw ArgumentError.value(
      setting.updatedAt,
      'updatedAt',
      'must be greater than or equal to createdAt',
    );
  }
}

void _validateNonNegativeMinutes({required int value, required String field}) {
  if (value < 0) {
    throw ArgumentError.value(
      value,
      field,
      'must be greater than or equal to 0',
    );
  }
}

bool _isMonthOnly(DateTime value) {
  return value.day == 1 &&
      value.hour == 0 &&
      value.minute == 0 &&
      value.second == 0 &&
      value.millisecond == 0 &&
      value.microsecond == 0;
}

String _readString(Map<String, Object?> map, String field) {
  if (!map.containsKey(field)) {
    throw CompensationReferenceSettingParseException(
      'model=CompensationReferenceSetting field=$field rule=required',
    );
  }
  final Object? value = map[field];
  if (value is String && value.isNotEmpty) {
    return value;
  }
  throw CompensationReferenceSettingParseException(
    'model=CompensationReferenceSetting field=$field value=$value rule=non-empty String',
  );
}

String? _readNullableString(Map<String, Object?> map, String field) {
  if (!map.containsKey(field)) {
    throw CompensationReferenceSettingParseException(
      'model=CompensationReferenceSetting field=$field rule=required',
    );
  }
  final Object? value = map[field];
  if (value == null) {
    return null;
  }
  if (value is String) {
    return value;
  }
  throw CompensationReferenceSettingParseException(
    'model=CompensationReferenceSetting field=$field value=$value rule=String or null',
  );
}

int _readInt(Map<String, Object?> map, String field) {
  if (!map.containsKey(field)) {
    throw CompensationReferenceSettingParseException(
      'model=CompensationReferenceSetting field=$field rule=required',
    );
  }
  final Object? value = map[field];
  if (value is int) {
    return value;
  }
  throw CompensationReferenceSettingParseException(
    'model=CompensationReferenceSetting field=$field value=$value rule=int',
  );
}

CompensationReferenceMode _readMode(Map<String, Object?> map, String field) {
  final String value = _readString(map, field);
  for (final CompensationReferenceMode mode
      in CompensationReferenceMode.values) {
    if (mode.name == value) {
      return mode;
    }
  }
  throw CompensationReferenceSettingParseException(
    'model=CompensationReferenceSetting field=$field value=$value rule=valid mode',
  );
}

DateTime _readDateTime(Map<String, Object?> map, String field) {
  final String value = _readString(map, field);
  try {
    return DateTime.parse(value);
  } on FormatException {
    throw CompensationReferenceSettingParseException(
      'model=CompensationReferenceSetting field=$field value=$value rule=valid ISO-8601 DateTime',
    );
  }
}
