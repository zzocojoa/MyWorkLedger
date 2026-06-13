import '../../../core/models/compensation_reference_setting.dart';
import '../../../core/storage/key_value_storage.dart';
import '../domain/compensation_reference_repository.dart';

typedef CompensationReferenceClock = DateTime Function();
typedef CompensationReferenceIdGenerator = String Function();

final class LocalStorageCompensationReferenceRepository
    implements CompensationReferenceRepository {
  const LocalStorageCompensationReferenceRepository({
    required this.storage,
    required this.clock,
    required this.idGenerator,
  });

  final KeyValueStorage storage;
  final CompensationReferenceClock clock;
  final CompensationReferenceIdGenerator idGenerator;

  static const String compensationReferenceSettingsTable =
      'compensation_reference_settings';

  @override
  Future<CompensationReferenceSetting?> findApplicableForMonth({
    required int year,
    required int month,
  }) async {
    _validateYearMonth(year: year, month: month);
    final DateTime targetMonth = DateTime(year, month);
    final Map<String, Map<String, Object?>> rows = await storage.readAll(
      table: compensationReferenceSettingsTable,
    );
    final List<CompensationReferenceSetting> settings = rows.entries
        .map((MapEntry<String, Map<String, Object?>> entry) {
          return _parseSettingMap(key: entry.key, map: entry.value);
        })
        .toList(growable: false);
    final List<CompensationReferenceSetting> applicableSettings = settings
        .where((CompensationReferenceSetting setting) {
          return !setting.effectiveFromMonth.isAfter(targetMonth);
        })
        .toList(growable: false);
    if (applicableSettings.isEmpty) {
      return null;
    }
    applicableSettings.sort((
      CompensationReferenceSetting left,
      CompensationReferenceSetting right,
    ) {
      return right.effectiveFromMonth.compareTo(left.effectiveFromMonth);
    });
    return applicableSettings.first;
  }

  @override
  Future<CompensationReferenceSetting> save({
    required CompensationReferenceMode mode,
    required int fixedIncludedOvertimeMinutes,
    required int fixedIncludedNightMinutes,
    required int fixedIncludedHolidayMinutes,
    required DateTime effectiveFromMonth,
    required String? memo,
  }) async {
    final DateTime normalizedMonth = normalizeCompensationReferenceMonth(
      effectiveFromMonth: effectiveFromMonth,
    );
    final String key = _formatSettingKey(effectiveFromMonth: normalizedMonth);
    final DateTime now = clock();
    final Map<String, Object?>? existingMap = await storage.read(
      table: compensationReferenceSettingsTable,
      key: key,
    );
    final CompensationReferenceSetting? existingSetting = existingMap == null
        ? null
        : _parseSettingMap(key: key, map: existingMap);
    final CompensationReferenceSetting setting = existingSetting == null
        ? CompensationReferenceSetting(
            id: idGenerator(),
            mode: mode,
            fixedIncludedOvertimeMinutes: fixedIncludedOvertimeMinutes,
            fixedIncludedNightMinutes: fixedIncludedNightMinutes,
            fixedIncludedHolidayMinutes: fixedIncludedHolidayMinutes,
            effectiveFromMonth: normalizedMonth,
            memo: _normalizeMemo(memo: memo),
            createdAt: now,
            updatedAt: now,
          )
        : existingSetting.copyWith(
            id: existingSetting.id,
            mode: mode,
            fixedIncludedOvertimeMinutes: fixedIncludedOvertimeMinutes,
            fixedIncludedNightMinutes: fixedIncludedNightMinutes,
            fixedIncludedHolidayMinutes: fixedIncludedHolidayMinutes,
            effectiveFromMonth: normalizedMonth,
            memo: _normalizeMemo(memo: memo),
            createdAt: existingSetting.createdAt,
            updatedAt: now,
          );
    await storage.write(
      table: compensationReferenceSettingsTable,
      key: key,
      value: setting.toMap(),
    );
    return setting;
  }
}

CompensationReferenceSetting _parseSettingMap({
  required String key,
  required Map<String, Object?> map,
}) {
  try {
    return CompensationReferenceSetting.fromMap(map);
  } on CompensationReferenceSettingParseException catch (error) {
    throw CompensationReferenceRepositoryException(
      'action=parse table=${LocalStorageCompensationReferenceRepository.compensationReferenceSettingsTable} key=$key cause=${error.message}',
    );
  } on ArgumentError catch (error) {
    throw CompensationReferenceRepositoryException(
      'action=parse table=${LocalStorageCompensationReferenceRepository.compensationReferenceSettingsTable} key=$key cause=${error.message}',
    );
  }
}

void _validateYearMonth({required int year, required int month}) {
  if (year < 2000 || year > 2100) {
    throw CompensationReferenceRepositoryException(
      'action=findApplicableForMonth field=year value=$year rule=between 2000 and 2100',
    );
  }
  if (month < 1 || month > 12) {
    throw CompensationReferenceRepositoryException(
      'action=findApplicableForMonth field=month value=$month rule=between 1 and 12',
    );
  }
}

String _formatSettingKey({required DateTime effectiveFromMonth}) {
  final String month = effectiveFromMonth.month.toString().padLeft(2, '0');
  return '${effectiveFromMonth.year}-$month';
}

String? _normalizeMemo({required String? memo}) {
  final String? value = memo?.trim();
  if (value == null || value.isEmpty) {
    return null;
  }
  return value;
}
