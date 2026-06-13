final class LeaveBalanceParseException implements Exception {
  const LeaveBalanceParseException(this.message);

  final String message;

  @override
  String toString() {
    return 'LeaveBalanceParseException: $message';
  }
}

final class LeaveBalance {
  LeaveBalance({
    required this.id,
    required this.year,
    required this.totalLeaveMinutes,
    required this.createdAt,
    required this.updatedAt,
  }) {
    _validateLeaveBalance(this);
  }

  final String id;
  final int year;
  final int totalLeaveMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;

  LeaveBalance copyWith({
    required String id,
    required int year,
    required int totalLeaveMinutes,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) {
    return LeaveBalance(
      id: id,
      year: year,
      totalLeaveMinutes: totalLeaveMinutes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'year': year,
      'total_leave_minutes': totalLeaveMinutes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static LeaveBalance fromMap(Map<String, Object?> map) {
    return LeaveBalance(
      id: _readString(map, 'id'),
      year: _readInt(map, 'year'),
      totalLeaveMinutes: _readInt(map, 'total_leave_minutes'),
      createdAt: _readDateTime(map, 'created_at'),
      updatedAt: _readDateTime(map, 'updated_at'),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is LeaveBalance &&
            id == other.id &&
            year == other.year &&
            totalLeaveMinutes == other.totalLeaveMinutes &&
            createdAt == other.createdAt &&
            updatedAt == other.updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(id, year, totalLeaveMinutes, createdAt, updatedAt);
  }
}

void _validateLeaveBalance(LeaveBalance balance) {
  if (balance.id.isEmpty) {
    throw ArgumentError.value(balance.id, 'id', 'must not be empty');
  }
  if (balance.year < 2000 || balance.year > 2100) {
    throw ArgumentError.value(
      balance.year,
      'year',
      'must be between 2000 and 2100',
    );
  }
  if (balance.totalLeaveMinutes < 0) {
    throw ArgumentError.value(
      balance.totalLeaveMinutes,
      'totalLeaveMinutes',
      'must be greater than or equal to 0',
    );
  }
  if (balance.totalLeaveMinutes % 30 != 0) {
    throw ArgumentError.value(
      balance.totalLeaveMinutes,
      'totalLeaveMinutes',
      'must be divisible by 30',
    );
  }
  if (balance.updatedAt.isBefore(balance.createdAt)) {
    throw ArgumentError.value(
      balance.updatedAt,
      'updatedAt',
      'must be greater than or equal to createdAt',
    );
  }
}

String _readString(Map<String, Object?> map, String field) {
  if (!map.containsKey(field)) {
    throw LeaveBalanceParseException(
      'model=LeaveBalance field=$field rule=required',
    );
  }
  final Object? value = map[field];
  if (value is String && value.isNotEmpty) {
    return value;
  }
  throw LeaveBalanceParseException(
    'model=LeaveBalance field=$field value=$value rule=non-empty String',
  );
}

int _readInt(Map<String, Object?> map, String field) {
  if (!map.containsKey(field)) {
    throw LeaveBalanceParseException(
      'model=LeaveBalance field=$field rule=required',
    );
  }
  final Object? value = map[field];
  if (value is int) {
    return value;
  }
  throw LeaveBalanceParseException(
    'model=LeaveBalance field=$field value=$value rule=int',
  );
}

DateTime _readDateTime(Map<String, Object?> map, String field) {
  final String value = _readString(map, field);
  try {
    return DateTime.parse(value);
  } on FormatException {
    throw LeaveBalanceParseException(
      'model=LeaveBalance field=$field value=$value rule=valid ISO-8601 DateTime',
    );
  }
}
