enum QuickRecordMode {
  currentTimeOnly,
  chooseBeforeSave;

  static QuickRecordMode fromStorageValue(String value) {
    for (final QuickRecordMode mode in QuickRecordMode.values) {
      if (mode.name == value) {
        return mode;
      }
    }
    throw QuickRecordSettingsParseException(
      'model=QuickRecordSettings field=mode value=$value rule=known QuickRecordMode',
    );
  }
}

final class QuickRecordSettingsParseException implements Exception {
  const QuickRecordSettingsParseException(this.message);

  final String message;

  @override
  String toString() {
    return 'QuickRecordSettingsParseException: $message';
  }
}

final class QuickRecordSettings {
  const QuickRecordSettings({
    required this.mode,
    required this.createdAt,
    required this.updatedAt,
  });

  final QuickRecordMode mode;
  final DateTime createdAt;
  final DateTime updatedAt;

  QuickRecordSettings copyWith({
    required QuickRecordMode mode,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) {
    return QuickRecordSettings(
      mode: mode,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'mode': mode.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static QuickRecordSettings fromMap(Map<String, Object?> map) {
    final QuickRecordSettings settings = QuickRecordSettings(
      mode: QuickRecordMode.fromStorageValue(_readString(map, 'mode')),
      createdAt: _readDateTime(map, 'created_at'),
      updatedAt: _readDateTime(map, 'updated_at'),
    );
    _validateQuickRecordSettings(settings);
    return settings;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is QuickRecordSettings &&
            mode == other.mode &&
            createdAt == other.createdAt &&
            updatedAt == other.updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(mode, createdAt, updatedAt);
  }
}

void _validateQuickRecordSettings(QuickRecordSettings settings) {
  if (settings.updatedAt.isBefore(settings.createdAt)) {
    throw QuickRecordSettingsParseException(
      'model=QuickRecordSettings field=updated_at value=${settings.updatedAt.toIso8601String()} rule=must be greater than or equal to created_at',
    );
  }
}

String _readString(Map<String, Object?> map, String field) {
  if (!map.containsKey(field)) {
    throw QuickRecordSettingsParseException(
      'model=QuickRecordSettings field=$field rule=required',
    );
  }
  final Object? value = map[field];
  if (value is String && value.isNotEmpty) {
    return value;
  }
  throw QuickRecordSettingsParseException(
    'model=QuickRecordSettings field=$field value=$value rule=non-empty String',
  );
}

DateTime _readDateTime(Map<String, Object?> map, String field) {
  final String value = _readString(map, field);
  try {
    return DateTime.parse(value);
  } on FormatException {
    throw QuickRecordSettingsParseException(
      'model=QuickRecordSettings field=$field value=$value rule=valid ISO-8601 DateTime',
    );
  }
}
