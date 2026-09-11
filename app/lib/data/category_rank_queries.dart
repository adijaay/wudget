import 'package:drift/drift.dart';

import 'actual_transactions.dart';
import 'daily_totals_repository.dart' show dayBucketFor;
import 'database.dart';

const _millisPerDay = 86400000;

/// One row of the category ranked list: chart rule 4, "a ranked list beats
/// a second pie" — carries amount, share and transaction count together,
/// same as plan/04-ux-design.md specifies.
class CategoryRank {
  const CategoryRank({required this.key, required this.name, required this.amountMinor, required this.count});
  final String key;
  final String name;
  final int amountMinor;
  final int count;
}

/// Expense spend ranked by category for one period, top-level categories
/// only (subcategory spend rolls up to its parent, same as budgets) —
/// plan/05-sprints.md Sprint 11.
class CategoryRankQueries {
  CategoryRankQueries(this._db);
  final WudgetDatabase _db;

  Future<List<CategoryRank>> rankedSpend(int sinceDayInclusive, int untilDayExclusive) async {
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

    final amountByKey = <String, int>{};
    final countByKey = <String, int>{};
    final nameByKey = <String, String>{};

    for (final row in rows) {
      final tx = row.readTable(_db.transactions);
      final day = dayBucketFor(tx.occurredAt, tx.tzOffsetMinutes);
      if (day < sinceDayInclusive || day >= untilDayExclusive) continue;

      final category = row.readTable(_db.categories);
      final isTopLevel = category.parentId == null;
      final key = isTopLevel ? category.id : category.parentId!;
      amountByKey[key] = (amountByKey[key] ?? 0) + row.readTable(_db.postings).amountMinor.abs();
      countByKey[key] = (countByKey[key] ?? 0) + 1;
      if (isTopLevel) nameByKey[key] = category.name;
    }

    // A parent category might only ever be spent on through a subcategory,
    // never directly — resolve its name separately rather than requiring
    // every key to have appeared as its own top-level row above.
    for (final key in amountByKey.keys) {
      nameByKey.putIfAbsent(key, () => key);
    }
    final missingNames = amountByKey.keys.where((k) => nameByKey[k] == k).toList();
    if (missingNames.isNotEmpty) {
      final parentRows = await (_db.select(_db.categories)..where((c) => c.id.isIn(missingNames))).get();
      for (final c in parentRows) {
        nameByKey[c.id] = c.name;
      }
    }

    final ranks = amountByKey.entries
        .map((e) => CategoryRank(key: e.key, name: nameByKey[e.key] ?? e.key, amountMinor: e.value, count: countByKey[e.key]!))
        .toList()
      ..sort((a, b) => b.amountMinor.compareTo(a.amountMinor));
    return ranks;
  }
}
