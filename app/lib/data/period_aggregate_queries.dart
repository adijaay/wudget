import 'package:drift/drift.dart';

import '../domain/period.dart';
import 'daily_totals_repository.dart' show dayBucketFor;
import 'database.dart';

const _millisPerDay = 86400000;

/// A period's totals, each a positive magnitude. `expenseMinor` and
/// `incomeMinor` are read straight off the category leg of expense/income
/// transactions, so a transfer (no category leg) never contributes — same
/// guarantee as `totalCategorySpendMinor` in spending_queries.dart, scoped
/// to one period instead of all time.
class PeriodTotals {
  const PeriodTotals({required this.expenseMinor, required this.incomeMinor});
  final int expenseMinor;
  final int incomeMinor;
}

/// Per-period reads for Pantau. Bounded by the period's day range (a month
/// at most), so unlike an all-time scan this stays fast without a
/// dedicated cache table — see DECISIONS.md, Sprint 8.
class PeriodAggregateQueries {
  PeriodAggregateQueries(this._db);
  final WudgetDatabase _db;

  Future<PeriodTotals> totalsFor(Period period) async {
    final scanStart = period.startDay * _millisPerDay - _millisPerDay;
    final scanEnd = period.endDayExclusive * _millisPerDay + _millisPerDay;

    final rows = await (_db.select(_db.postings).join([
      innerJoin(_db.transactions, _db.transactions.id.equalsExp(_db.postings.transactionId)),
    ])
          ..where(_db.postings.categoryId.isNotNull() &
              _db.transactions.deletedAt.isNull() &
              _db.transactions.occurredAt.isBiggerOrEqualValue(scanStart) &
              _db.transactions.occurredAt.isSmallerThanValue(scanEnd)))
        .get();

    var expenseMinor = 0;
    var incomeMinor = 0;
    for (final row in rows) {
      final tx = row.readTable(_db.transactions);
      final day = dayBucketFor(tx.occurredAt, tx.tzOffsetMinutes);
      if (!period.contains(day)) continue;
      final amount = row.readTable(_db.postings).amountMinor;
      if (tx.kind == 'expense') {
        expenseMinor += amount.abs();
      } else if (tx.kind == 'income') {
        incomeMinor += amount.abs();
      }
    }
    return PeriodTotals(expenseMinor: expenseMinor, incomeMinor: incomeMinor);
  }

  /// The local day the earliest non-deleted transaction falls on, or null
  /// with no history yet. Backs Pantau's first-14-days waiting state.
  Future<int?> firstTransactionDay() async {
    final row = await (_db.select(_db.transactions)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.occurredAt)])
          ..limit(1))
        .getSingleOrNull();
    if (row == null) return null;
    return dayBucketFor(row.occurredAt, row.tzOffsetMinutes);
  }
}
