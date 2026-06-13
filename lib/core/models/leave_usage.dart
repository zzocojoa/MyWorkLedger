final class LeaveUsageParseException implements Exception {
  const LeaveUsageParseException(this.message);

  final String message;

  @override
  String toString() {
    return 'LeaveUsageParseException: $message';
  }
}

final class LeaveUsage {
  LeaveUsage({
    required this.id,
    required this.usedOn,
    required this.usedLeaveMinutes,
    required this.memo,
    required this.createdAt,
    required this.updatedAt,
  }) {
    _validateLeaveUsage(this);
  }

  final String id;
  final DateTime usedOn;
  final int usedLeaveMinutes;
  final String? memo;
  final DateTime createdAt;
  final DateTime updatedAt;

  LeaveUsage copyWith({
    required String id,
    required DateTime usedOn,
    required int usedLeaveMinutes,
    required String? memo,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) {
    return LeaveUsage(
      id: id,
      usedOn: usedOn,
      usedLeaveMinutes: usedLeaveMinutes,
      memo: memo,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'used_on': _formatDateOnly(usedOn),
      'used_leave_minutes': usedLeaveMinutes,
      'memo': memo,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static LeaveUsage fromMap(Map<String, Object?> map) {
    return LeaveUsage(
      id: _readString(map, 'id'),
      usedOn: _readDateOnly(map, 'used_on'),
      usedLeaveMinutes: _readInt(map, 'used_leave_minutes'),
      memo: _readNullableString(map, 'memo'),
      createdAt: _readDateTime(map, 'created_at'),
      updatedAt: _readDateTime(map, 'updated_at'),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is LeaveUsage &&
            id == other.id &&
            usedOn == other.usedOn &&
            usedLeaveMinutes == other.usedLeaveMinutes &&
            memo == other.memo &&
            createdAt == other.createdAt &&
            updatedAt == other.updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      usedOn,
      usedLeaveMinutes,
      memo,
      createdAt,
      updatedAt,
    );
  }
}

void _validateLeaveUsage(LeaveUsage usage) {
  if (usage.id.isEmpty) {
    throw ArgumentError.value(usage.id, 'id', 'must not be empty');
  }
  if (!_isDateOnly(usage.usedOn)) {
    throw ArgumentError.value(usage.usedOn, 'usedOn', 'must be date only');
  }
  if (usage.usedLeaveMinutes < 30) {
    throw ArgumentError.value(
      usage.usedLeaveMinutes,
      'usedLeaveMinutes',
      'must be greater than or equal to 30',
    );
  }
  if (usage.usedLeaveMinutes % 30 != 0) {
    throw ArgumentError.value(
      usage.usedLeaveMinutes,
      'usedLeaveMinutes',
      'must be divisible by 30',
    );
  }
  final String? memo = usage.memo;
  if (memo != null && memo.length > 500) {
    throw ArgumentError.value(memo, 'memo', 'must be 500 characters or fewer');
  }
  if (usage.updatedAt.isBefore(usage.createdAt)) {
    throw ArgumentError.value(
      usage.updatedAt,
      'updatedAt',
      'must be greater than or equal to createdAt',
    );
  }
}

String _readString(Map<String, Object?> map, String field) {
  if (!map.containsKey(field)) {
    throw LeaveUsageParseException(
      'model=LeaveUsage field=$field rule=required',
    );
  }
  final Object? value = map[field];
  if (value is String && value.isNotEmpty) {
    return value;
  }
  throw LeaveUsageParseException(
    'model=LeaveUsage field=$field value=$value rule=non-empty String',
  );
}

String? _readNullableString(Map<String, Object?> map, String field) {
  if (!map.containsKey(field)) {
    throw LeaveUsageParseException(
      'model=LeaveUsage field=$field rule=required nullable field',
    );
  }
  final Object? value = map[field];
  if (value == null || value is String) {
    return value as String?;
  }
  throw LeaveUsageParseException(
    'model=LeaveUsage field=$field value=$value rule=String or null',
  );
}

int _readInt(Map<String, Object?> map, String field) {
  if (!map.containsKey(field)) {
    throw LeaveUsageParseException(
      'model=LeaveUsage field=$field rule=required',
    );
  }
  final Object? value = map[field];
  if (value is int) {
    return value;
  }
  throw LeaveUsageParseException(
    'model=LeaveUsage field=$field value=$value rule=int',
  );
}

DateTime _readDateOnly(Map<String, Object?> map, String field) {
  final String value = _readString(map, field);
  final RegExp datePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  if (!datePattern.hasMatch(value)) {
    throw LeaveUsageParseException(
      'model=LeaveUsage field=$field value=$value rule=YYYY-MM-DD',
    );
  }
  final DateTime parsed = DateTime.parse(value);
  if (_formatDateOnly(parsed) != value) {
    throw LeaveUsageParseException(
      'model=LeaveUsage field=$field value=$value rule=valid calendar date',
    );
  }
  return DateTime(parsed.year, parsed.month, parsed.day);
}

DateTime _readDateTime(Map<String, Object?> map, String field) {
  final String value = _readString(map, field);
  try {
    return DateTime.parse(value);
  } on FormatException {
    throw LeaveUsageParseException(
      'model=LeaveUsage field=$field value=$value rule=valid ISO-8601 DateTime',
    );
  }
}

String _formatDateOnly(DateTime value) {
  final String year = value.year.toString().padLeft(4, '0');
  final String month = value.month.toString().padLeft(2, '0');
  final String day = value.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

bool _isDateOnly(DateTime value) {
  return value.hour == 0 &&
      value.minute == 0 &&
      value.second == 0 &&
      value.millisecond == 0 &&
      value.microsecond == 0;
}
