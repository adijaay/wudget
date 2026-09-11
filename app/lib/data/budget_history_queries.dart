import 'package:drift/drift.dart';

import 'actual_transactions.dart';
import 'daily_totals_repository.dart' show dayBucketFor;
import 'database.dart';

const _millisPerDay = 86400000;

/// The category key a budget row groups under: an irregular category (its
/// own or an ancestor's) pools into one shared bucket regardless of which
/// leaf it was logged against — plan/01-features.md, "The irregular
/// expense bucket" — everything else rolls up to its top-level category,
/// so one budget covers a category and all its subcategories together.
const irregularBudgetKey = 'irregular';

/// Expense-only spend, grouped by [irregularBudgetKey]/category-id key,
/// over one day range. Used both for a trailing lookback window (budget
/// proposals) and for one period (the pace shown against a saved budget) —
/// same shape of question, just a different range, so one query serves
/// both call sites (BudgetProposalScreen and the review screen's pace row).
class BudgetHistoryQueries {
  BudgetHistoryQueries(this._db);
  final WudgetDatabase _db;

  Future<Map<String, int>> categorySpendByKey(int sinceDayInclusive, int untilDayExclusive) async {
    final scanStart = sinceDayInclusive * _millisPerDay - _millisPerDay;
    final scanEnd = untilDayExclusive * _millisPerDay + _millisPerDay;

    final rows = await (_db.select(_db.postings).join([
      innerJoin(_db.transactions, _db.transactions.id.equalsExp(_db.postings.transactionId)),
      innerJoin(_db.categories, _db.categories.id.equalsExp(_db.postings.categoryId)),
    ])
          ..where(_db.postings.categoryId.isNotNull() &
              _db.transactions.kind.equals('expense') &
              isActualTransaction(_db.transactions) &
              _db.transactions.occurredAt.isBiggerOrEqualValue(scanStart) &
              _db.transactions.occurredAt.isSmallerThanValue(scanEnd)))
        .get();

    final byKey = <String, int>{};
    for (final row in rows) {
      final tx = row.readTable(_db.transactions);
      final day = dayBucketFor(tx.occurredAt, tx.tzOffsetMinutes);
      if (day < sinceDayInclusive || day >= untilDayExclusive) continue;

      final category = row.readTable(_db.categories);
      final key = category.isIrregular ? irregularBudgetKey : (category.parentId ?? category.id);
      final amount = row.readTable(_db.postings).amountMinor.abs();
      byKey[key] = (byKey[key] ?? 0) + amount;
    }
    return byKey;
  }

  /// Display name for a budget row: the category's own name, or the
  /// irregular bucket's fixed label.
  Future<String> displayNameFor(String key) async {
    if (key == irregularBudgetKey) return 'Pengeluaran tidak rutin';
    final category =
        await (_db.select(_db.categories)..where((c) => c.id.equals(key))).getSingleOrNull();
    return category?.name ?? key;
  }
}
