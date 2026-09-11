import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wudget/data/database.dart';
import 'package:wudget/data/postings_repository.dart';
import 'package:wudget/data/spending_queries.dart';

void main() {
  test('a card payment (transfer) does not appear in spending statistics', () async {
    final db = WudgetDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = PostingsRepository(db);

    await db.into(db.accounts).insert(AccountsCompanion.insert(
          id: 'bank', name: 'Bank', type: 'bank', currency: 'IDR', updatedAt: 0,
        ));
    await db.into(db.accounts).insert(AccountsCompanion.insert(
          id: 'card', name: 'Kartu', type: 'card', currency: 'IDR', updatedAt: 0,
        ));
    await db.into(db.categories).insert(CategoriesCompanion.insert(
          id: 'cat1', name: 'Makan', kind: 'expense', iconKey: 'x', hueIndex: 0,
          sortOrder: 0, updatedAt: 0,
        ));

    // A real expense on the card: account leg negative, category leg positive.
    await repo.insertTransaction(
      transaction: TransactionsCompanion.insert(
        id: 'tx_purchase', kind: 'expense', occurredAt: 0, tzOffsetMinutes: 0, updatedAt: 0,
      ),
      postings: [
        PostingsCompanion.insert(
          id: 'p1', transactionId: 'tx_purchase', accountId: const Value('card'),
          amountMinor: -50000, currency: 'IDR', baseAmountMinor: -50000,
        ),
        PostingsCompanion.insert(
          id: 'p2', transactionId: 'tx_purchase', categoryId: const Value('cat1'),
          amountMinor: 50000, currency: 'IDR', baseAmountMinor: 50000,
        ),
      ],
    );

    expect(await totalCategorySpendMinor(db), 50000);

    // Paying the card off: a transfer, bank -> card, no category leg at all.
    await repo.insertTransaction(
      transaction: TransactionsCompanion.insert(
        id: 'tx_payment', kind: 'transfer', occurredAt: 1, tzOffsetMinutes: 0, updatedAt: 0,
      ),
      postings: [
        PostingsCompanion.insert(
          id: 'p3', transactionId: 'tx_payment', accountId: const Value('bank'),
          amountMinor: -50000, currency: 'IDR', baseAmountMinor: -50000,
        ),
        PostingsCompanion.insert(
          id: 'p4', transactionId: 'tx_payment', accountId: const Value('card'),
          amountMinor: 50000, currency: 'IDR', baseAmountMinor: 50000,
        ),
      ],
    );

    // The card payment moved money but must not double, halve or otherwise
    // change what counts as spending — it has no category leg to sum.
    expect(await totalCategorySpendMinor(db), 50000);
  });
}
