import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wudget/data/daily_totals_repository.dart';
import 'package:wudget/data/database.dart';
import 'package:wudget/data/postings_repository.dart';

const _wibOffset = 420; // WIB, UTC+7, in minutes

void main() {
  test('dayBucketFor uses the transaction\'s own offset, not UTC, to decide the day', () {
    // 2024-01-15 23:30 UTC is 2024-01-16 06:30 in WIB (UTC+7) — the two
    // offsets must disagree on which day this instant falls on.
    final boundaryUtc = DateTime.utc(2024, 1, 15, 23, 30).millisecondsSinceEpoch;
    expect(dayBucketFor(boundaryUtc, _wibOffset), dayBucketFor(boundaryUtc, 0) + 1);
  });

  test('recomputeForTransaction keeps daily_totals equal to the sum of account-leg postings',
      () async {
    final db = WudgetDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = PostingsRepository(db);

    await db.into(db.accounts).insert(AccountsCompanion.insert(
          id: 'acc1', name: 'Tunai', type: 'cash', currency: 'IDR', updatedAt: 0,
        ));
    await db.into(db.categories).insert(CategoriesCompanion.insert(
          id: 'cat1', name: 'Makan', kind: 'expense', iconKey: 'x', hueIndex: 0,
          sortOrder: 0, updatedAt: 0,
        ));

    final day1Millis = DateTime.utc(2024, 3, 1, 8).millisecondsSinceEpoch;
    final day2Millis = DateTime.utc(2024, 3, 2, 8).millisecondsSinceEpoch;

    await repo.insertTransaction(
      transaction: TransactionsCompanion.insert(
        id: 'tx1', kind: 'expense', occurredAt: day1Millis, tzOffsetMinutes: 0, updatedAt: 0,
      ),
      postings: [
        PostingsCompanion.insert(id: 'p1a', transactionId: 'tx1', accountId: const Value('acc1'),
            amountMinor: -15000, currency: 'IDR', baseAmountMinor: -15000),
        PostingsCompanion.insert(id: 'p1b', transactionId: 'tx1', categoryId: const Value('cat1'),
            amountMinor: 15000, currency: 'IDR', baseAmountMinor: 15000),
      ],
    );
    await repo.insertTransaction(
      transaction: TransactionsCompanion.insert(
        id: 'tx2', kind: 'expense', occurredAt: day2Millis, tzOffsetMinutes: 0, updatedAt: 0,
      ),
      postings: [
        PostingsCompanion.insert(id: 'p2a', transactionId: 'tx2', accountId: const Value('acc1'),
            amountMinor: -5000, currency: 'IDR', baseAmountMinor: -5000),
        PostingsCompanion.insert(id: 'p2b', transactionId: 'tx2', categoryId: const Value('cat1'),
            amountMinor: 5000, currency: 'IDR', baseAmountMinor: 5000),
      ],
    );

    final totals = await db.select(db.dailyTotals).get();
    final byDay = {for (final t in totals) t.day: t.netMinor};
    expect(byDay[dayBucketFor(day1Millis, 0)], -15000);
    expect(byDay[dayBucketFor(day2Millis, 0)], -5000);

    // Soft-deleting tx1 must pull its day's total back to zero.
    await repo.deleteTransaction('tx1');
    final afterDelete = await db.select(db.dailyTotals).get();
    final byDayAfter = {for (final t in afterDelete) t.day: t.netMinor};
    expect(byDayAfter[dayBucketFor(day1Millis, 0)], 0);

    // Restoring brings it back.
    await repo.restoreTransaction('tx1');
    final afterRestore = await db.select(db.dailyTotals).get();
    final byDayRestored = {for (final t in afterRestore) t.day: t.netMinor};
    expect(byDayRestored[dayBucketFor(day1Millis, 0)], -15000);
  });

  test('a transfer contributes nothing to a day net, since its two legs cancel', () async {
    final db = WudgetDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = PostingsRepository(db);

    await db.into(db.accounts).insert(AccountsCompanion.insert(
          id: 'bank', name: 'Bank', type: 'bank', currency: 'IDR', updatedAt: 0,
        ));
    await db.into(db.accounts).insert(AccountsCompanion.insert(
          id: 'cash', name: 'Tunai', type: 'cash', currency: 'IDR', updatedAt: 0,
        ));

    final millis = DateTime.utc(2024, 5, 1, 8).millisecondsSinceEpoch;
    await repo.insertTransaction(
      transaction: TransactionsCompanion.insert(
        id: 'tx1', kind: 'transfer', occurredAt: millis, tzOffsetMinutes: 0, updatedAt: 0,
      ),
      postings: [
        PostingsCompanion.insert(id: 'p1', transactionId: 'tx1', accountId: const Value('bank'),
            amountMinor: -100000, currency: 'IDR', baseAmountMinor: -100000),
        PostingsCompanion.insert(id: 'p2', transactionId: 'tx1', accountId: const Value('cash'),
            amountMinor: 100000, currency: 'IDR', baseAmountMinor: 100000),
      ],
    );

    final totals = await db.select(db.dailyTotals).get();
    expect(totals.single.netMinor, 0);
  });
}
