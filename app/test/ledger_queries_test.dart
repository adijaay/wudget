import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wudget/data/database.dart';
import 'package:wudget/data/ledger_queries.dart';
import 'package:wudget/data/postings_repository.dart';

void main() {
  late WudgetDatabase db;
  late PostingsRepository postings;
  late LedgerQueries ledger;

  setUp(() async {
    db = WudgetDatabase(NativeDatabase.memory());
    postings = PostingsRepository(db);
    ledger = LedgerQueries(db);

    await db.into(db.accounts).insert(AccountsCompanion.insert(
          id: 'cash', name: 'Tunai', type: 'cash', currency: 'IDR', updatedAt: 0,
        ));
    await db.into(db.accounts).insert(AccountsCompanion.insert(
          id: 'bank', name: 'Bank', type: 'bank', currency: 'IDR', updatedAt: 0,
        ));
    await db.into(db.categories).insert(CategoriesCompanion.insert(
          id: 'cat_makan', name: 'Makan', kind: 'expense', iconKey: 'x', hueIndex: 0,
          sortOrder: 0, updatedAt: 0,
        ));
  });

  tearDown(() => db.close());

  Future<void> writeExpense(String id, int occurredAt, {String? note}) {
    return postings.insertTransaction(
      transaction: TransactionsCompanion.insert(
        id: id, kind: 'expense', occurredAt: occurredAt, tzOffsetMinutes: 0,
        note: Value(note), updatedAt: 0,
      ),
      postings: [
        PostingsCompanion.insert(id: '$id-a', transactionId: id, accountId: const Value('cash'),
            amountMinor: -15000, currency: 'IDR', baseAmountMinor: -15000),
        PostingsCompanion.insert(id: '$id-c', transactionId: id, categoryId: const Value('cat_makan'),
            amountMinor: 15000, currency: 'IDR', baseAmountMinor: 15000),
      ],
    );
  }

  test('page() returns newest first with category and account names resolved', () async {
    await writeExpense('tx1', 1000, note: 'sarapan');
    await writeExpense('tx2', 2000);

    final page = await ledger.page(limit: 10, offset: 0);

    expect(page.map((e) => e.transactionId), ['tx2', 'tx1']);
    expect(page[1].categoryName, 'Makan');
    expect(page[1].accountName, 'Tunai');
    expect(page[1].note, 'sarapan');
    expect(page[1].amountMinor, -15000);
  });

  test('a transfer becomes one row naming both accounts, exactly one page slot', () async {
    await postings.insertTransaction(
      transaction: TransactionsCompanion.insert(
        id: 'tx_transfer', kind: 'transfer', occurredAt: 3000, tzOffsetMinutes: 0, updatedAt: 0,
      ),
      postings: [
        PostingsCompanion.insert(id: 'p1', transactionId: 'tx_transfer', accountId: const Value('bank'),
            amountMinor: -50000, currency: 'IDR', baseAmountMinor: -50000),
        PostingsCompanion.insert(id: 'p2', transactionId: 'tx_transfer', accountId: const Value('cash'),
            amountMinor: 50000, currency: 'IDR', baseAmountMinor: 50000),
      ],
    );

    final page = await ledger.page(limit: 10, offset: 0);

    expect(page.length, 1); // not 2, even though there are 2 account-leg postings
    expect(page.single.accountName, 'Bank -> Tunai');
    expect(page.single.categoryName, isNull);
    expect(page.single.amountMinor, -50000);
  });

  test('a soft-deleted transaction is excluded from the page', () async {
    await writeExpense('tx1', 1000);
    await postings.deleteTransaction('tx1');

    expect(await ledger.page(limit: 10, offset: 0), isEmpty);
  });

  test('filter by category excludes everything else, and offset paginates correctly', () async {
    await writeExpense('tx1', 1000);
    await postings.insertTransaction(
      transaction: TransactionsCompanion.insert(
        id: 'tx_transfer', kind: 'transfer', occurredAt: 2000, tzOffsetMinutes: 0, updatedAt: 0,
      ),
      postings: [
        PostingsCompanion.insert(id: 'p1', transactionId: 'tx_transfer', accountId: const Value('bank'),
            amountMinor: -1000, currency: 'IDR', baseAmountMinor: -1000),
        PostingsCompanion.insert(id: 'p2', transactionId: 'tx_transfer', accountId: const Value('cash'),
            amountMinor: 1000, currency: 'IDR', baseAmountMinor: 1000),
      ],
    );

    final filtered =
        await ledger.page(limit: 10, offset: 0, filter: const LedgerFilter(categoryId: 'cat_makan'));
    expect(filtered.map((e) => e.transactionId), ['tx1']);

    await writeExpense('tx2', 500);
    await writeExpense('tx3', 250);
    final firstPage = await ledger.page(limit: 2, offset: 0);
    final secondPage = await ledger.page(limit: 2, offset: 2);
    expect(firstPage.length, 2);
    expect(secondPage.length, 2); // tx1 (expense) + tx_transfer
    expect({...firstPage.map((e) => e.transactionId), ...secondPage.map((e) => e.transactionId)},
        {'tx1', 'tx2', 'tx3', 'tx_transfer'});
  });
}
