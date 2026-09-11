import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wudget/data/capture_queries.dart';
import 'package:wudget/data/database.dart';

Future<void> _writeExpense(
  WudgetDatabase db, {
  required String id,
  required String accountId,
  required String categoryId,
  required int amountMinor,
  required int occurredAt,
}) {
  return db.transaction(() async {
    await db.into(db.transactions).insert(TransactionsCompanion.insert(
          id: id,
          kind: 'expense',
          occurredAt: occurredAt,
          tzOffsetMinutes: 420,
          updatedAt: 0,
        ));
    await db.into(db.postings).insert(PostingsCompanion.insert(
          id: '$id-a',
          transactionId: id,
          accountId: Value(accountId),
          amountMinor: -amountMinor,
          currency: 'IDR',
          baseAmountMinor: -amountMinor,
        ));
    await db.into(db.postings).insert(PostingsCompanion.insert(
          id: '$id-c',
          transactionId: id,
          categoryId: Value(categoryId),
          amountMinor: amountMinor,
          currency: 'IDR',
          baseAmountMinor: amountMinor,
        ));
  });
}

void main() {
  late WudgetDatabase db;
  late CaptureQueries queries;

  setUp(() async {
    db = WudgetDatabase(NativeDatabase.memory());
    queries = CaptureQueries(db);
    await db.into(db.accounts).insert(AccountsCompanion.insert(
          id: 'acc_cash', name: 'Tunai', type: 'cash', currency: 'IDR', updatedAt: 0,
        ));
    await db.into(db.accounts).insert(AccountsCompanion.insert(
          id: 'acc_bank', name: 'Bank', type: 'bank', currency: 'IDR', updatedAt: 0,
        ));
    await db.into(db.categories).insert(CategoriesCompanion.insert(
          id: 'cat_makan', name: 'Makan', kind: 'expense', iconKey: 'x', hueIndex: 0,
          sortOrder: 0, updatedAt: 0,
        ));
    await db.into(db.categories).insert(CategoriesCompanion.insert(
          id: 'cat_transport', name: 'Transport', kind: 'expense', iconKey: 'x', hueIndex: 1,
          sortOrder: 1, updatedAt: 0,
        ));
  });

  tearDown(() => db.close());

  test('topTemplates ranks by frequency and returns the most recent amount/account per category',
      () async {
    // Makan: 3 times on cash, most recent amount 20000.
    await _writeExpense(db, id: 't1', accountId: 'acc_cash', categoryId: 'cat_makan', amountMinor: 15000, occurredAt: 1);
    await _writeExpense(db, id: 't2', accountId: 'acc_cash', categoryId: 'cat_makan', amountMinor: 17000, occurredAt: 2);
    await _writeExpense(db, id: 't3', accountId: 'acc_bank', categoryId: 'cat_makan', amountMinor: 20000, occurredAt: 3);
    // Transport: once.
    await _writeExpense(db, id: 't4', accountId: 'acc_cash', categoryId: 'cat_transport', amountMinor: 10000, occurredAt: 4);

    final templates = await queries.topTemplates('expense');

    expect(templates.first.categoryId, 'cat_makan');
    expect(templates.first.count, 3);
    expect(templates.first.lastAmountMinor, 20000);
    expect(templates.first.accountId, 'acc_bank'); // most recent leg, not most frequent

    expect(templates[1].categoryId, 'cat_transport');
    expect(templates[1].count, 1);
  });

  test('lastAccountIdForCategory returns the most recent account, or null if unused', () async {
    expect(await queries.lastAccountIdForCategory('cat_makan'), isNull);

    await _writeExpense(db, id: 't1', accountId: 'acc_cash', categoryId: 'cat_makan', amountMinor: 15000, occurredAt: 1);
    expect(await queries.lastAccountIdForCategory('cat_makan'), 'acc_cash');

    await _writeExpense(db, id: 't2', accountId: 'acc_bank', categoryId: 'cat_makan', amountMinor: 15000, occurredAt: 2);
    expect(await queries.lastAccountIdForCategory('cat_makan'), 'acc_bank');
  });
}
