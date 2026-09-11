import 'database.dart';

/// The user-edited budget amounts, keyed by category (or 'irregular' for
/// the pooled bucket). See plan/05-sprints.md Sprint 10 — the user edits a
/// proposal rather than authoring one, so this repository only ever writes
/// what a person has actually confirmed or changed.
class BudgetsRepository {
  BudgetsRepository(this._db);
  final WudgetDatabase _db;

  Stream<Map<String, int>> watchAll() {
    return _db.select(_db.budgets).watch().map(
          (rows) => {for (final row in rows) row.key: row.amountMinor},
        );
  }

  /// One-shot read, for a caller that just needs the current snapshot once
  /// (e.g. BudgetScreen's load) rather than a live subscription.
  Future<Map<String, int>> getAll() async {
    final rows = await _db.select(_db.budgets).get();
    return {for (final row in rows) row.key: row.amountMinor};
  }

  Future<void> setAmount(String key, int amountMinor) {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    return _db.into(_db.budgets).insertOnConflictUpdate(
          BudgetsCompanion.insert(key: key, amountMinor: amountMinor, updatedAt: now),
        );
  }
}
