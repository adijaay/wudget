import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wudget/data/database.dart';
import 'package:wudget/data/wallets_repository.dart';

/// Kantong sat on a spinner forever on a real device once the ledger held
/// 10,000 transactions, while Catat and Pantau stayed fast. This reproduces
/// the shape that exposed it: one balance query joining every posting.
void main() {
  test('wallet balances stay fast with 10,000 transactions in the table', () async {
    final db = WudgetDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    for (final id in ['cash', 'gopay', 'bca']) {
      await db.into(db.accounts).insert(AccountsCompanion.insert(
            id: id, name: id, type: 'cash', currency: 'IDR', updatedAt: 0,
          ));
    }
    await db.into(db.categories).insert(CategoriesCompanion.insert(
          id: 'cat_makan', name: 'Makan', kind: 'expense', iconKey: 'x', hueIndex: 0,
          sortOrder: 0, updatedAt: 0,
        ));

    await db.batch((batch) {
      for (var i = 0; i < 10000; i++) {
        batch.insert(db.transactions, TransactionsCompanion.insert(
              id: 'tx$i', kind: 'expense', occurredAt: i * 1000, tzOffsetMinutes: 0, updatedAt: 0,
            ));
        batch.insert(db.postings, PostingsCompanion.insert(
              id: 'p$i-a', transactionId: 'tx$i', accountId: Value(['cash', 'gopay', 'bca'][i % 3]),
              amountMinor: -1000, currency: 'IDR', baseAmountMinor: -1000,
            ));
        batch.insert(db.postings, PostingsCompanion.insert(
              id: 'p$i-c', transactionId: 'tx$i', categoryId: const Value('cat_makan'),
              amountMinor: 1000, currency: 'IDR', baseAmountMinor: 1000,
            ));
      }
    });

    final stopwatch = Stopwatch()..start();
    final wallets = await WalletsRepository(db).watchWallets().first;
    stopwatch.stop();

    expect(wallets, hasLength(3));
    expect(stopwatch.elapsedMilliseconds, lessThan(300),
        reason: 'took ${stopwatch.elapsedMilliseconds}ms');
  });
}
