import 'package:drift/drift.dart';

import '../domain/period.dart';
import 'database.dart';

/// The one settings row, created lazily on first write. See plan/05-sprints.md
/// Sprint 8, "configurable month start day".
class SettingsRepository {
  SettingsRepository(this._db);
  final WudgetDatabase _db;

  Stream<int> watchPeriodStartDay() => watchRow().map((row) => row?.periodStartDay ?? defaultPeriodStartDay);

  /// Null until the first write on a new install.
  Stream<AppSetting?> watchRow() => (_db.select(_db.appSettings)..where((s) => s.id.equals(0))).watchSingleOrNull();

  Future<AppSetting?> getRow() => (_db.select(_db.appSettings)..where((s) => s.id.equals(0))).getSingleOrNull();

  Future<Period> effectivePeriodFor(int today) async => effectivePeriodFromRow(await getRow(), today);

  Future<void> setCustomPeriod(int startDay, int endDayExclusive, int amountMinor) => _write(AppSettingsCompanion(
        customPeriodAmountMinor: Value(amountMinor),
        customPeriodStart: Value(startDay),
        customPeriodEndExclusive: Value(endDayExclusive),
      ));

  Future<void> confirmPayday(int periodStartDay, int salaryMinor) => _write(AppSettingsCompanion(
        paydayConfirmedPeriodStart: Value(periodStartDay),
        lastSalaryMinor: Value(salaryMinor),
      ));

  Future<void> snoozePayday(int today) => _write(AppSettingsCompanion(paydaySnoozedDay: Value(today)));

  Future<void> _write(AppSettingsCompanion values) =>
      _db.into(_db.appSettings).insertOnConflictUpdate(values.copyWith(id: const Value(0)));

  Future<void> setPeriodStartDay(int day) {
    return _db.into(_db.appSettings).insertOnConflictUpdate(
          AppSettingsCompanion.insert(id: const Value(0), periodStartDay: Value(clampPeriodStartDay(day))),
        );
  }

  /// Null means no period close has ever been acknowledged.
  Future<int?> getLastAcknowledgedPeriodClose() async {
    final row = await (_db.select(_db.appSettings)..where((s) => s.id.equals(0))).getSingleOrNull();
    return row?.lastAcknowledgedPeriodClose;
  }

  Future<void> setLastAcknowledgedPeriodClose(int periodStartDay) {
    return _db.into(_db.appSettings).insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            id: const Value(0),
            lastAcknowledgedPeriodClose: Value(periodStartDay),
          ),
        );
  }
}

Period effectivePeriodFromRow(AppSetting? row, int today) => effectivePeriod(
      today,
      monthStartDay: row?.periodStartDay ?? defaultPeriodStartDay,
      customStart: row?.customPeriodStart,
      customEndExclusive: row?.customPeriodEndExclusive,
    );

/// Payday card: in a normal period, not yet confirmed for it, not put off today.
bool paydayCardDue(AppSetting? row, int today) {
  final period = effectivePeriodFromRow(row, today);
  if (row != null && period.startDay == row.customPeriodStart) return false;
  return row?.paydayConfirmedPeriodStart != period.startDay && row?.paydaySnoozedDay != today;
}
