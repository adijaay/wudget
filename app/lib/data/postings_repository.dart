import 'package:drift/drift.dart';

import 'daily_totals_repository.dart';
import 'database.dart';

/// Thrown when a caller tries to write a transaction whose postings do not
/// sum to zero in base currency — the one invariant the ledger depends on.
class UnbalancedPostingsException implements Exception {
  UnbalancedPostingsException(this.baseAmountSum);
  final int baseAmountSum;

  @override
  String toString() =>
      'UnbalancedPostingsException: postings sum to $baseAmountSum, expected 0';
}

/// The only path that writes, soft-deletes or restores a transaction and
/// its postings. Enforces the sum-to-zero invariant from
/// plan/03-architecture.md before the write reaches the database, and keeps
/// `daily_totals` current so nothing else has to remember to.
class PostingsRepository {
  PostingsRepository(this._db) : _dailyTotals = DailyTotalsRepository(_db);
  final WudgetDatabase _db;
  final DailyTotalsRepository _dailyTotals;

  Future<void> insertTransaction({
    required TransactionsCompanion transaction,
    required List<PostingsCompanion> postings,
  }) {
    final sum = postings.fold<int>(0, (acc, p) => acc + p.baseAmountMinor.value);
    if (sum != 0) throw UnbalancedPostingsException(sum);

    return _db.transaction(() async {
      await _db.into(_db.transactions).insert(transaction);
      for (final posting in postings) {
        await _db.into(_db.postings).insert(posting);
      }
      await _dailyTotals.recomputeForTransaction(transaction.id.value);
    });
  }

  Future<void> updateTransaction({
    required String transactionId,
    required TransactionsCompanion transaction,
    required List<PostingsCompanion> postings,
  }) {
    final sum = postings.fold<int>(0, (acc, p) => acc + p.baseAmountMinor.value);
    if (sum != 0) throw UnbalancedPostingsException(sum);

    return _db.transaction(() async {
      await (_db.update(_db.transactions)..where((t) => t.id.equals(transactionId)))
          .write(transaction);
      
      await (_db.delete(_db.postings)..where((p) => p.transactionId.equals(transactionId))).go();
      
      for (final posting in postings) {
        await _db.into(_db.postings).insert(posting);
      }
      
      await _dailyTotals.recomputeForTransaction(transactionId);
    });
  }

  /// Soft delete: sets `deleted_at`, keeping the row (and its postings) for
  /// audit/undo rather than removing history. See plan/05-sprints.md
  /// Sprint 6, "Edit, soft delete, undo".
  Future<void> deleteTransaction(String transactionId) async {
    await _db.transaction(() async {
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      await (_db.update(_db.transactions)..where((t) => t.id.equals(transactionId)))
          .write(TransactionsCompanion(deletedAt: Value(now), updatedAt: Value(now)));
      await _dailyTotals.recomputeForTransaction(transactionId);
    });
  }

  /// Hard delete: for the undo affordance right after a save, which should
  /// remove the mistake entirely rather than leave a soft-deleted row. Not
  /// for deleting historical entries — that's [deleteTransaction].
  Future<void> undoInsert(String transactionId) async {
    await _db.transaction(() async {
      final day = await _dailyTotals.dayForTransaction(transactionId);
      await (_db.delete(_db.postings)..where((p) => p.transactionId.equals(transactionId))).go();
      await (_db.delete(_db.transactions)..where((t) => t.id.equals(transactionId))).go();
      if (day != null) await _dailyTotals.recomputeDay(day);
    });
  }

  Future<void> restoreTransaction(String transactionId) async {
    await _db.transaction(() async {
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      await (_db.update(_db.transactions)..where((t) => t.id.equals(transactionId)))
          .write(TransactionsCompanion(deletedAt: const Value(null), updatedAt: Value(now)));
      await _dailyTotals.recomputeForTransaction(transactionId);
    });
  }
}
