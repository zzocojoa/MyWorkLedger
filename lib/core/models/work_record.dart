enum WorkRecordTag {
  overtime,
  delayedCheckout,
  holidayWork;

  static WorkRecordTag fromStorageValue(String value) {
    for (final WorkRecordTag tag in WorkRecordTag.values) {
      if (tag.name == value) {
        return tag;
      }
    }
    throw WorkRecordParseException(
      'model=WorkRecord field=tags value=$value rule=known WorkRecordTag',
    );
  }
}

final class WorkRecordParseException implements Exception {
  const WorkRecordParseException(this.message);

  final String message;

  @override
  String toString() {
    return 'WorkRecordParseException: $message';
  }
}

final class WorkRecord {
  WorkRecord({
    required this.id,
    required this.workDate,
    required this.clockInAt,
    required this.clockOutAt,
    required List<WorkRecordTag> tags,
    required this.memo,
    required this.createdAt,
    required this.updatedAt,
  }) : tags = List<WorkRecordTag>.unmodifiable(tags) {
    _validateWorkRecord(this);
  }

  final String id;
  final DateTime workDate;
  final DateTime? clockInAt;
  final DateTime? clockOutAt;
  final List<WorkRecordTag> tags;
  final String? memo;
  final DateTime createdAt;
  final DateTime updatedAt;

  WorkRecord copyWith({
    required String id,
    required DateTime workDate,
    required DateTime? clockInAt,
    required DateTime? clockOutAt,
    required List<WorkRecordTag> tags,
    required String? memo,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) {
    return WorkRecord(
      id: id,
      workDate: workDate,
      clockInAt: clockInAt,
      clockOutAt: clockOutAt,
      tags: tags,
      memo: memo,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'work_date': _formatDateOnly(workDate),
      'clock_in_at': clockInAt?.toIso8601String(),
      'clock_out_at': clockOutAt?.toIso8601String(),
      'tags': tags.map((WorkRecordTag tag) => tag.name).toList(),
      'memo': memo,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static WorkRecord fromMap(Map<String, Object?> map) {
    return WorkRecord(
      id: _readString(map, 'id'),
      workDate: _readDateOnly(map, 'work_date'),
      clockInAt: _readNullableDateTime(map, 'clock_in_at'),
      clockOutAt: _readNullableDateTime(map, 'clock_out_at'),
      tags: _readTags(map, 'tags'),
      memo: _readNullableString(map, 'memo'),
      createdAt: _readDateTime(map, 'created_at'),
      updatedAt: _readDateTime(map, 'updated_at'),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is WorkRecord &&
            id == other.id &&
            workDate == other.workDate &&
            clockInAt == other.clockInAt &&
            clockOutAt == other.clockOutAt &&
            _listEquals(tags, other.tags) &&
            memo == other.memo &&
            createdAt == other.createdAt &&
            updatedAt == other.updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      workDate,
      clockInAt,
      clockOutAt,
      Object.hashAll(tags),
      memo,
      createdAt,
      updatedAt,
    );
  }
}

void _validateWorkRecord(WorkRecord record) {
  if (record.id.isEmpty) {
    throw ArgumentError.value(record.id, 'id', 'must not be empty');
  }
  if (!_isDateOnly(record.workDate)) {
    throw ArgumentError.value(record.workDate, 'workDate', 'must be date only');
  }
  if (record.clockInAt != null &&
      record.clockOutAt != null &&
      record.clockOutAt!.isBefore(record.clockInAt!)) {
    throw ArgumentError.value(
      record.clockOutAt,
      'clockOutAt',
      'must be greater than or equal to clockInAt',
    );
  }
  if (record.tags.toSet().length != record.tags.length) {
    throw ArgumentError.value(
      record.tags,
      'tags',
      'must not contain duplicates',
    );
  }
  final String? memo = record.memo;
  if (memo != null && memo.length > 500) {
    throw ArgumentError.value(memo, 'memo', 'must be 500 characters or fewer');
  }
  if (record.updatedAt.isBefore(record.createdAt)) {
    throw ArgumentError.value(
      record.updatedAt,
      'updatedAt',
      'must be greater than or equal to createdAt',
    );
  }
}

String _readString(Map<String, Object?> map, String field) {
  if (!map.containsKey(field)) {
    throw WorkRecordParseException(
      'model=WorkRecord field=$field rule=required',
    );
  }
  final Object? value = map[field];
  if (value is String && value.isNotEmpty) {
    return value;
  }
  throw WorkRecordParseException(
    'model=WorkRecord field=$field value=$value rule=non-empty String',
  );
}

String? _readNullableString(Map<String, Object?> map, String field) {
  if (!map.containsKey(field)) {
    throw WorkRecordParseException(
      'model=WorkRecord field=$field rule=required nullable field',
    );
  }
  final Object? value = map[field];
  if (value == null || value is String) {
    return value as String?;
  }
  throw WorkRecordParseException(
    'model=WorkRecord field=$field value=$value rule=String or null',
  );
}

DateTime _readDateOnly(Map<String, Object?> map, String field) {
  final String value = _readString(map, field);
  final RegExp datePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  if (!datePattern.hasMatch(value)) {
    throw WorkRecordParseException(
      'model=WorkRecord field=$field value=$value rule=YYYY-MM-DD',
    );
  }
  final DateTime parsed = DateTime.parse(value);
  if (_formatDateOnly(parsed) != value) {
    throw WorkRecordParseException(
      'model=WorkRecord field=$field value=$value rule=valid calendar date',
    );
  }
  return DateTime(parsed.year, parsed.month, parsed.day);
}

DateTime _readDateTime(Map<String, Object?> map, String field) {
  final String value = _readString(map, field);
  return _parseDateTime(value, field);
}

DateTime? _readNullableDateTime(Map<String, Object?> map, String field) {
  if (!map.containsKey(field)) {
    throw WorkRecordParseException(
      'model=WorkRecord field=$field rule=required nullable field',
    );
  }
  final Object? value = map[field];
  if (value == null) {
    return null;
  }
  if (value is String) {
    return _parseDateTime(value, field);
  }
  throw WorkRecordParseException(
    'model=WorkRecord field=$field value=$value rule=ISO-8601 String or null',
  );
}

DateTime _parseDateTime(String value, String field) {
  try {
    return DateTime.parse(value);
  } on FormatException {
    throw WorkRecordParseException(
      'model=WorkRecord field=$field value=$value rule=valid ISO-8601 DateTime',
    );
  }
}

List<WorkRecordTag> _readTags(Map<String, Object?> map, String field) {
  if (!map.containsKey(field)) {
    throw WorkRecordParseException(
      'model=WorkRecord field=$field rule=required',
    );
  }
  final Object? value = map[field];
  if (value is! List<Object?>) {
    throw WorkRecordParseException(
      'model=WorkRecord field=$field value=$value rule=List<String>',
    );
  }
  final List<WorkRecordTag> tags = value.map((Object? item) {
    if (item is String) {
      return WorkRecordTag.fromStorageValue(item);
    }
    throw WorkRecordParseException(
      'model=WorkRecord field=$field value=$item rule=String tag',
    );
  }).toList();
  if (tags.toSet().length != tags.length) {
    throw WorkRecordParseException(
      'model=WorkRecord field=$field value=$value rule=unique tags',
    );
  }
  return tags;
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
