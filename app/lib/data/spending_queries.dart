import 'package:drift/drift.dart';

import 'actual_transactions.dart';
import 'database.dart';

/// Sum of every posting's category leg — i.e. actual spending/income,
/// never transfers. A transfer (including a card payment) has no category
/// leg by construction (plan/03-architecture.md, "How the four kinds map
/// to postings"), so it is structurally excluded here rather than filtered
/// by transaction kind — the same guarantee Pantau's aggregates read from
/// (Sprint 8+). Soft-deleted and projected-but-unconfirmed transactions
/// (Sprint 12's shared `isActualTransaction` predicate) are excluded too.
Future<int> totalCategorySpendMinor(WudgetDatabase db) async {
  final rows = await (db.select(db.postings).join([
    innerJoin(db.transactions, db.transactions.id.equalsExp(db.postings.transactionId)),
  ])
        ..where(db.postings.categoryId.isNotNull() & isActualTransaction(db.transactions)))
      .get();
  return rows.fold<int>(0, (sum, row) => sum + row.readTable(db.postings).amountMinor);
}
