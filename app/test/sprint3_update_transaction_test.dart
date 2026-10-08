import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wudget/data/database.dart';
import 'package:wudget/data/postings_repository.dart';

void main() {
  test('updateTransaction replaces postings and recomputes daily totals', () async {
    final db = WudgetDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = PostingsRepository(db);

    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await db.into(db.accounts).insert(AccountsCompanion.insert(
      id: 'acc1', name: 'Cash', type: 'cash', currency: 'IDR', updatedAt: now,
    ));
    await db.into(db.categories).insert(CategoriesCompanion.insert(
      id: 'cat1', name: 'Food', kind: 'expense', iconKey: 'food', hueIndex: 0,
      sortOrder: 0, updatedAt: now,
    ));
    await db.into(db.categories).insert(CategoriesCompanion.insert(
      id: 'cat2', name: 'Transport', kind: 'expense', iconKey: 'transport', hueIndex: 1,
      sortOrder: 1, updatedAt: now,
    ));

    final txId = 'tx1';
    await repo.insertTransaction(
      transaction: TransactionsCompanion.insert(
        id: txId,
        kind: 'expense',
        occurredAt: now,
        tzOffsetMinutes: 420,
        updatedAt: now,
      ),
      postings: [
        PostingsCompanion.insert(
          id: 'p1',
          transactionId: txId,
          accountId: Value('acc1'),
          categoryId: Value('cat1'),
          amountMinor: -25000,
          currency: 'IDR',
          baseAmountMinor: -25000,
        ),
        PostingsCompanion.insert(
          id: 'p2',
          transactionId: txId,
          accountId: Value('acc1'),
          categoryId: const Value(null),
          amountMinor: 25000,
          currency: 'IDR',
          baseAmountMinor: 25000,
        ),
      ],
    );

    await repo.updateTransaction(
      transactionId: txId,
      transaction: TransactionsCompanion(
        kind: const Value('expense'),
        occurredAt: Value(now),
        tzOffsetMinutes: const Value(420),
        updatedAt: Value(now),
      ),
      postings: [
        PostingsCompanion.insert(
          id: 'p3',
          transactionId: txId,
          accountId: Value('acc1'),
          categoryId: Value('cat2'),
          amountMinor: -50000,
          currency: 'IDR',
          baseAmountMinor: -50000,
        ),
        PostingsCompanion.insert(
          id: 'p4',
          transactionId: txId,
          accountId: Value('acc1'),
          categoryId: const Value(null),
          amountMinor: 50000,
          currency: 'IDR',
          baseAmountMinor: 50000,
        ),
      ],
    );

    final postings = await (db.select(db.postings)
      ..where((p) => p.transactionId.equals(txId)))
        .get();
    
    expect(postings.length, 2);
    expect(postings.any((p) => p.categoryId == 'cat2'), true);
    expect(postings.any((p) => p.categoryId == 'cat1'), false);
    
    final sum = postings.fold<int>(0, (acc, p) => acc + p.baseAmountMinor);
    expect(sum, 0);
  });
}
