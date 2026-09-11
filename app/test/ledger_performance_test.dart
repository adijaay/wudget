import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wudget/data/database.dart';
import 'package:wudget/data/ledger_queries.dart';

/// Sprint 6 done-when (plan/05-sprints.md): "10,000 transactions render in
/// under 300ms." This can't measure real device render time from a unit
/// test, so it measures the part the architecture actually depends on: a
/// page fetch stays fast regardless of table size, because it is a bounded
/// LIMIT/OFFSET query rather than a full scan (ledger_queries.dart).
void main() {
  test('a page fetch stays fast with 10,000 transactions in the table', () async {
    final db = WudgetDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await db.into(db.accounts).insert(AccountsCompanion.insert(
          id: 'cash', name: 'Tunai', type: 'cash', currency: 'IDR', updatedAt: 0,
        ));
    await db.into(db.categories).insert(CategoriesCompanion.insert(
          id: 'cat_makan', name: 'Makan', kind: 'expense', iconKey: 'x', hueIndex: 0,
          sortOrder: 0, updatedAt: 0,
        ));

    await db.batch((batch) {
      for (var i = 0; i < 10000; i++) {
        batch.insert(
          db.transactions,
          TransactionsCompanion.insert(
            id: 'tx$i', kind: 'expense', occurredAt: i * 1000, tzOffsetMinutes: 0, updatedAt: 0,
          ),
        );
        batch.insert(
          db.postings,
          PostingsCompanion.insert(id: 'p$i-a', transactionId: 'tx$i', accountId: const Value('cash'),
              amountMinor: -1000, currency: 'IDR', baseAmountMinor: -1000),
        );
        batch.insert(
          db.postings,
          PostingsCompanion.insert(id: 'p$i-c', transactionId: 'tx$i', categoryId: const Value('cat_makan'),
              amountMinor: 1000, currency: 'IDR', baseAmountMinor: 1000),
        );
      }
    });

    final ledger = LedgerQueries(db);
    final stopwatch = Stopwatch()..start();
    final page = await ledger.page(limit: 50, offset: 0);
    stopwatch.stop();

    expect(page.length, 50);
    expect(page.first.transactionId, 'tx9999'); // newest first
    // Generous ceiling for a desktop test-runner query, not the on-device
    // release-build budget itself — that's Sprint 7's performance gate,
    // measured on the real device (see DECISIONS.md).
    expect(stopwatch.elapsedMilliseconds, lessThan(300));
  });
}
