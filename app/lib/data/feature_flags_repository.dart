import 'database.dart';

/// The pace-first vs. remaining-first Pantau framing, per plan/05-sprints.md
/// Sprint 11 — "built behind a flag so both framings can be measured".
/// Pace-first is the plan's stated default (plan/01-features.md).
const paceFirstFlagKey = 'pace_first_framing';

/// Small boolean feature-flag store — see the `FeatureFlags` table.
class FeatureFlagsRepository {
  FeatureFlagsRepository(this._db);
  final WudgetDatabase _db;

  Stream<bool> watchBool(String key, {required bool defaultValue}) {
    final query = _db.select(_db.featureFlags)..where((f) => f.key.equals(key));
    return query.watchSingleOrNull().map((row) => row?.value ?? defaultValue);
  }

  /// One-shot read — for a caller (e.g. an analytics log line) that just
  /// needs the current value once, not a live subscription. See
  /// DECISIONS.md, Sprint 10, on why `.watch().first` is the wrong tool
  /// for that.
  Future<bool> getBool(String key, {required bool defaultValue}) async {
    final row = await (_db.select(_db.featureFlags)..where((f) => f.key.equals(key))).getSingleOrNull();
    return row?.value ?? defaultValue;
  }

  Future<void> setBool(String key, bool value) {
    return _db.into(_db.featureFlags).insertOnConflictUpdate(
          FeatureFlagsCompanion.insert(key: key, value: value),
        );
  }
}
