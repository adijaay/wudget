import 'package:drift/drift.dart';

import '../domain/period.dart';
import 'database.dart';

/// The one settings row, created lazily on first write. See plan/05-sprints.md
/// Sprint 8, "configurable month start day".
class SettingsRepository {
  SettingsRepository(this._db);
  final WudgetDatabase _db;

  Stream<int> watchPeriodStartDay() {
    final query = _db.select(_db.appSettings)..where((s) => s.id.equals(0));
    return query.watchSingleOrNull().map((row) => row?.periodStartDay ?? 1);
  }

  Future<void> setPeriodStartDay(int day) {
    return _db.into(_db.appSettings).insertOnConflictUpdate(
          AppSettingsCompanion.insert(id: const Value(0), periodStartDay: Value(clampPeriodStartDay(day))),
        );
  }
}
