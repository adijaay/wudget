import 'dart:convert';

import 'package:drift/drift.dart';

import 'database.dart';

/// The user-edited budget amounts, keyed by category (or 'irregular' for
/// the pooled bucket). See plan/05-sprints.md Sprint 10 ??? the user edits a
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

  /// Keeps today's plan as the plan of the period starting [periodStartDay],
  /// so that period's recap still compares against it after Budgets changes.
  Future<void> snapshotFor(int periodStartDay) async {
    final all = await _snapshots();
    all['$periodStartDay'] = await getAll();
    await _db.into(_db.appSettings).insertOnConflictUpdate(
          AppSettingsCompanion(id: const Value(0), budgetSnapshotsJson: Value(jsonEncode(all))),
        );
  }

  /// The plan the period starting [periodStartDay] ran on; current budgets if none was kept.
  Future<Map<String, int>> planFor(int periodStartDay) async =>
      (await _snapshots())['$periodStartDay'] ?? await getAll();

  Future<Map<String, Map<String, int>>> _snapshots() async {
    final row = await (_db.select(_db.appSettings)..where((s) => s.id.equals(0))).getSingleOrNull();
    final raw = row?.budgetSnapshotsJson;
    if (raw == null) return {};
    return {
      for (final MapEntry(:key, :value) in (jsonDecode(raw) as Map<String, dynamic>).entries)
        key: (value as Map<String, dynamic>).cast<String, int>(),
    };
  }
}
