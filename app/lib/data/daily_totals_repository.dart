import 'package:drift/drift.dart';

import 'actual_transactions.dart';
import 'database.dart';

const _millisPerDay = 86400000;

/// The local calendar day a UTC-millis timestamp falls on, per its
/// transaction's own `tz_offset_minutes` — so a transaction made while
/// travelling lands on the day the user actually experienced it (see
/// plan/03-architecture.md, "so 'which day' survives travel").
int dayBucketFor(int occurredAtUtcMillis, int tzOffsetMinutes) {
  final localMillis = occurredAtUtcMillis + tzOffsetMinutes * 60000;
  return localMillis ~/ _millisPerDay;
}

/// Maintains `daily_totals`: one row per local day, net of every
/// account-leg posting on transactions that land on it (soft-deleted
/// transactions excluded). A transfer's two account legs share one
/// transaction, so they always cancel to zero within the same day —
/// transfers correctly contribute nothing to the day's net.
class DailyTotalsRepository {
  DailyTotalsRepository(this._db);
  final WudgetDatabase _db;

  /// Recomputes the aggregate row for the day [transactionId] falls on.
  /// Call within the same db.transaction() as the write/delete that
  /// touched it, so the aggregate can never be read half-updated.
  Future<void> recomputeForTransaction(String transactionId) async {
    final day = await dayForTransaction(transactionId);
    if (day != null) await recomputeDay(day);
  }

  /// The day bucket a (possibly about-to-be-deleted) transaction is on —
  /// fetch this before removing the row, since recomputing needs to know
  /// which day to refresh afterward.
  Future<int?> dayForTransaction(String transactionId) async {
    final tx = await (_db.select(_db.transactions)..where((t) => t.id.equals(transactionId)))
        .getSingleOrNull();
    if (tx == null) return null;
    return dayBucketFor(tx.occurredAt, tx.tzOffsetMinutes);
  }

  /// Rebuilds every day's row from scratch. `daily_totals` is a derived
  /// cache, not a source of truth, so it isn't part of the JSON export —
  /// call this once after a restore instead. See DECISIONS.md, Sprint 6.
  /// Day buckets in [startDay, endDayExclusive) holding at least one actual entry.
  Future<Set<int>> entryDays(int startDay, int endDayExclusive) async {
    // A day of slack each side: occurredAt is UTC, the bucket is local.
    final rows = await (_db.select(_db.transactions)
          ..where((t) =>
              isActualTransaction(t) &
              t.occurredAt.isBetweenValues((startDay - 1) * _millisPerDay, (endDayExclusive + 1) * _millisPerDay)))
        .get();
    return {
      for (final t in rows) dayBucketFor(t.occurredAt, t.tzOffsetMinutes),
    }..removeWhere((d) => d < startDay || d >= endDayExclusive);
  }

  Future<void> recomputeAll() async {
    final transactions = await (_db.select(_db.transactions)
          ..where((t) => isActualTransaction(t)))
        .get();
    final days = transactions.map((t) => dayBucketFor(t.occurredAt, t.tzOffsetMinutes)).toSet();
    await _db.delete(_db.dailyTotals).go();
    for (final day in days) {
      await recomputeDay(day);
    }
  }

  Future<void> recomputeDay(int day) async {
    final dayStartLocal = day * _millisPerDay;
    final dayEndLocal = dayStartLocal + _millisPerDay;
    // Every transaction stores its own tz offset, so "is this row in
    // [day]" has to be evaluated per-row rather than with one WHERE range
    // on occurredAt (UTC). A generous +/-1 day pad on occurredAt bounds the
    // SQL scan to a handful of rows regardless of total history size, and
    // exact membership is refined in Dart on that small set.
    final scanStart = dayStartLocal - _millisPerDay;
    final scanEnd = dayEndLocal + _millisPerDay;

    final rows = await (_db.select(_db.postings).join([
      innerJoin(_db.transactions, _db.transactions.id.equalsExp(_db.postings.transactionId)),
    ])
          ..where(_db.postings.accountId.isNotNull() &
              isActualTransaction(_db.transactions) &
              _db.transactions.occurredAt.isBiggerOrEqualValue(scanStart) &
              _db.transactions.occurredAt.isSmallerThanValue(scanEnd)))
        .get();

    var netMinor = 0;
    for (final row in rows) {
      final tx = row.readTable(_db.transactions);
      final localMillis = tx.occurredAt + tx.tzOffsetMinutes * 60000;
      if (localMillis >= dayStartLocal && localMillis < dayEndLocal) {
        netMinor += row.readTable(_db.postings).amountMinor;
      }
    }

    await _db.into(_db.dailyTotals).insertOnConflictUpdate(
          DailyTotalsCompanion.insert(day: Value(day), netMinor: netMinor),
        );
  }
}
