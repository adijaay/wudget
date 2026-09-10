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

/// The only path that writes a transaction and its postings. Enforces the
/// sum-to-zero invariant from plan/03-architecture.md before the write
/// reaches the database, rather than trusting every call site to remember.
class PostingsRepository {
  PostingsRepository(this._db);
  final WudgetDatabase _db;

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
    });
  }
}
