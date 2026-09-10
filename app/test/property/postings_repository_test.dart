import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wudget/data/database.dart';
import 'package:wudget/data/postings_repository.dart';

void main() {
  late WudgetDatabase db;
  late PostingsRepository repo;

  setUp(() {
    db = WudgetDatabase(NativeDatabase.memory());
    repo = PostingsRepository(db);
  });

  tearDown(() => db.close());

  Future<void> seedAccountAndCategory() async {
    await db.into(db.accounts).insert(AccountsCompanion.insert(
          id: 'acc1',
          name: 'Cash',
          type: 'cash',
          currency: 'IDR',
          updatedAt: 0,
        ));
    await db.into(db.categories).insert(CategoriesCompanion.insert(
          id: 'cat1',
          name: 'Makan',
          kind: 'expense',
          iconKey: 'food',
          hueIndex: 0,
          sortOrder: 0,
          updatedAt: 0,
        ));
  }

  test('balanced postings (expense: account leg negative, category leg positive) write cleanly', () async {
    await seedAccountAndCategory();
    await repo.insertTransaction(
      transaction: TransactionsCompanion.insert(
        id: 'tx1',
        kind: 'expense',
        occurredAt: 0,
        tzOffsetMinutes: 0,
        updatedAt: 0,
      ),
      postings: [
        PostingsCompanion.insert(
          id: 'p1',
          transactionId: 'tx1',
          amountMinor: -15000,
          currency: 'IDR',
          baseAmountMinor: -15000,
          accountId: const Value('acc1'),
        ),
        PostingsCompanion.insert(
          id: 'p2',
          transactionId: 'tx1',
          amountMinor: 15000,
          currency: 'IDR',
          baseAmountMinor: 15000,
          categoryId: const Value('cat1'),
        ),
      ],
    );

    final postings = await db.select(db.postings).get();
    expect(postings.length, 2);
  });

  test('unbalanced postings throw and write nothing (property, 200 random cases)', () async {
    await seedAccountAndCategory();
    final rng = Random(7);
    for (var i = 0; i < 200; i++) {
      final a = rng.nextInt(200000) - 100000;
      var b = rng.nextInt(200000) - 100000;
      if (a + b == 0) b += 1; // force imbalance
      final sum = a + b;

      expect(
        () => repo.insertTransaction(
          transaction: TransactionsCompanion.insert(
            id: 'tx-$i',
            kind: 'expense',
            occurredAt: 0,
            tzOffsetMinutes: 0,
            updatedAt: 0,
          ),
          postings: [
            PostingsCompanion.insert(
              id: 'p-$i-a',
              transactionId: 'tx-$i',
              amountMinor: a,
              currency: 'IDR',
              baseAmountMinor: a,
              accountId: const Value('acc1'),
            ),
            PostingsCompanion.insert(
              id: 'p-$i-b',
              transactionId: 'tx-$i',
              amountMinor: b,
              currency: 'IDR',
              baseAmountMinor: b,
              categoryId: const Value('cat1'),
            ),
          ],
        ),
        throwsA(isA<UnbalancedPostingsException>().having((e) => e.baseAmountSum, 'sum', sum)),
      );
    }

    final rows = await db.select(db.transactions).get();
    expect(rows, isEmpty);
  });
}
