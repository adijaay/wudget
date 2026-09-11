import 'package:drift/drift.dart';

import 'database.dart';

/// One entry in the frequency-templates row: a (category, last amount,
/// last wallet) combination seen recently, tapped to fill the sheet in one
/// go. See plan/05-sprints.md Sprint 4, "Frequency templates row".
class CaptureTemplate {
  const CaptureTemplate({
    required this.categoryId,
    required this.lastAmountMinor,
    required this.accountId,
    required this.count,
  });
  final String categoryId;
  final int lastAmountMinor;
  final String accountId;
  final int count;
}

/// Read-only queries the capture sheet needs that don't belong to the
/// write path in PostingsRepository. Grouping happens in Dart over a
/// small, already-fetched window rather than in SQL — at personal-finance
/// data volumes (tens of transactions a day) that is simpler to read than
/// a group-by-with-last-value query, and just as fast.
/// ponytail: re-profile if `scanLimit` rows ever means real latency.
class CaptureQueries {
  CaptureQueries(this._db);
  final WudgetDatabase _db;

  Future<List<CaptureTemplate>> topTemplates(
    String kind, {
    int limit = 5,
    int scanLimit = 100,
  }) async {
    final catLeg = _db.alias(_db.postings, 'cat_leg');
    final acctLeg = _db.alias(_db.postings, 'acct_leg');

    final rows = await (_db.select(catLeg).join([
      innerJoin(_db.transactions, _db.transactions.id.equalsExp(catLeg.transactionId)),
      innerJoin(
        acctLeg,
        acctLeg.transactionId.equalsExp(catLeg.transactionId) & acctLeg.accountId.isNotNull(),
      ),
    ])
          ..where(catLeg.categoryId.isNotNull() & _db.transactions.kind.equals(kind))
          ..orderBy([OrderingTerm.desc(_db.transactions.occurredAt)])
          ..limit(scanLimit))
        .get();

    final byCategory = <String, List<TypedResult>>{};
    for (final row in rows) {
      final categoryId = row.readTable(catLeg).categoryId!;
      byCategory.putIfAbsent(categoryId, () => []).add(row);
    }

    final templates = byCategory.entries.map((entry) {
      final mostRecent = entry.value.first; // rows arrive ordered by occurredAt desc
      return CaptureTemplate(
        categoryId: entry.key,
        lastAmountMinor: mostRecent.readTable(catLeg).amountMinor.abs(),
        accountId: mostRecent.readTable(acctLeg).accountId!,
        count: entry.value.length,
      );
    }).toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    return templates.take(limit).toList();
  }

  /// The account most recently paired with [categoryId] in a transaction,
  /// or null if the category has never been used. Backs "the wallet
  /// defaults to the last one used for this category" (plan/01-features.md).
  Future<String?> lastAccountIdForCategory(String categoryId) async {
    final catLeg = _db.alias(_db.postings, 'cat_leg');
    final acctLeg = _db.alias(_db.postings, 'acct_leg');

    final row = await (_db.select(catLeg).join([
      innerJoin(_db.transactions, _db.transactions.id.equalsExp(catLeg.transactionId)),
      innerJoin(
        acctLeg,
        acctLeg.transactionId.equalsExp(catLeg.transactionId) & acctLeg.accountId.isNotNull(),
      ),
    ])
          ..where(catLeg.categoryId.equals(categoryId))
          ..orderBy([OrderingTerm.desc(_db.transactions.occurredAt)])
          ..limit(1))
        .getSingleOrNull();

    return row?.readTable(acctLeg).accountId;
  }
}
