import 'package:drift/drift.dart';

import 'database.dart';

/// A materialised, not-yet-confirmed instance — Sprint 13's "upcoming"
/// half of the recurring/bills screen.
class UpcomingInstance {
  const UpcomingInstance({
    required this.transactionId,
    required this.recurrenceId,
    required this.dueDay,
    required this.amountMinor,
    required this.accountId,
    this.categoryId,
    this.note,
  });
  final String transactionId;
  final String recurrenceId;
  final int dueDay;
  final int amountMinor;
  final String accountId;
  final String? categoryId;
  final String? note;
}

/// Reads for the recurring/bills screen. The rule math itself
/// (`RecurrenceRule`, `RecurrenceTemplate`) stays in domain/recurrence.dart
/// and data/recurrence_repository.dart — this class only assembles what
/// the UI needs to display, from raw rows.
class RecurringQueries {
  RecurringQueries(this._db);
  final WudgetDatabase _db;

  Future<List<UpcomingInstance>> upcoming() async {
    final rows = await (_db.select(_db.transactions)
          ..where((t) => t.isProjected.equals(true) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.occurredAt)]))
        .get();
    if (rows.isEmpty) return [];

    final txIds = rows.map((t) => t.id).toList();
    final postings = await (_db.select(_db.postings)..where((p) => p.transactionId.isIn(txIds))).get();
    final legsByTx = <String, List<Posting>>{};
    for (final p in postings) {
      legsByTx.putIfAbsent(p.transactionId, () => []).add(p);
    }

    final instances = <UpcomingInstance>[];
    for (final tx in rows) {
      final legs = legsByTx[tx.id];
      if (legs == null) continue;
      final accountLeg = _firstOrNull(legs, (p) => p.accountId != null);
      if (accountLeg == null) continue;
      final categoryLeg = _firstOrNull(legs, (p) => p.categoryId != null);
      instances.add(UpcomingInstance(
        transactionId: tx.id,
        recurrenceId: tx.recurrenceId!,
        dueDay: tx.occurredAt ~/ 86400000,
        amountMinor: accountLeg.amountMinor.abs(),
        accountId: accountLeg.accountId!,
        categoryId: categoryLeg?.categoryId,
        note: tx.note,
      ));
    }
    return instances;
  }

  /// Active rules — a recurrence not (soft-)deleted. Display fields (next
  /// due date, template contents) are derived by the screen from the raw
  /// row, using the same `RecurrenceRule`/`RecurrenceTemplate` the
  /// materialisation engine uses.
  Future<List<Recurrence>> activeRules() {
    return (_db.select(_db.recurrences)..where((r) => r.deletedAt.isNull())).get();
  }

  T? _firstOrNull<T>(List<T> items, bool Function(T) test) {
    for (final item in items) {
      if (test(item)) return item;
    }
    return null;
  }
}
