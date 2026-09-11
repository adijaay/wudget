import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wudget/data/budget_history_queries.dart';
import 'package:wudget/data/database.dart';
import 'package:wudget/data/postings_repository.dart';

void main() {
  late WudgetDatabase db;
  late PostingsRepository postings;
  late BudgetHistoryQueries queries;

  setUp(() async {
    db = WudgetDatabase(NativeDatabase.memory());
    postings = PostingsRepository(db);
    queries = BudgetHistoryQueries(db);

    const now = 0;
    await db.into(db.categories).insert(CategoriesCompanion.insert(
          id: 'cat_makan', name: 'Makan', kind: 'expense', iconKey: 'food', hueIndex: 0, sortOrder: 0, updatedAt: now,
        ));
    await db.into(db.categories).insert(CategoriesCompanion.insert(
          id: 'cat_makan_sarapan', parentId: const Value('cat_makan'), name: 'Sarapan', kind: 'expense',
          iconKey: 'food', hueIndex: 0, sortOrder: 1, updatedAt: now,
        ));
    await db.into(db.categories).insert(CategoriesCompanion.insert(
          id: 'cat_darurat', name: 'Darurat', kind: 'expense', iconKey: 'warning', hueIndex: 1, sortOrder: 2,
          updatedAt: now, isIrregular: const Value(true),
        ));
  });

  tearDown(() => db.close());

  Future<void> expense(String id, String categoryId, DateTime at, int amountMinor) {
    return postings.insertTransaction(
      transaction: TransactionsCompanion.insert(
        id: id,
        kind: 'expense',
        occurredAt: at.millisecondsSinceEpoch,
        tzOffsetMinutes: 0,
        updatedAt: 0,
      ),
      postings: [
        PostingsCompanion.insert(id: '${id}a', transactionId: id, accountId: const Value('acc'),
            amountMinor: -amountMinor, currency: 'IDR', baseAmountMinor: -amountMinor),
        PostingsCompanion.insert(id: '${id}c', transactionId: id, categoryId: Value(categoryId),
            amountMinor: amountMinor, currency: 'IDR', baseAmountMinor: amountMinor),
      ],
    );
  }

  test('a subcategory\'s spend rolls up to its top-level category key', () async {
    await expense('tx1', 'cat_makan', DateTime.utc(2026, 3, 5), 10000);
    await expense('tx2', 'cat_makan_sarapan', DateTime.utc(2026, 3, 6), 5000);

    final byKey = await queries.categorySpendByKey(
      DateTime.utc(2026, 3, 1).difference(DateTime.utc(1970, 1, 1)).inDays,
      DateTime.utc(2026, 4, 1).difference(DateTime.utc(1970, 1, 1)).inDays,
    );
    expect(byKey['cat_makan'], 15000);
    expect(byKey.containsKey('cat_makan_sarapan'), isFalse);
  });

  test('an irregular category pools under the irregular key, not its own', () async {
    await expense('tx1', 'cat_darurat', DateTime.utc(2026, 3, 5), 200000);

    final byKey = await queries.categorySpendByKey(
      DateTime.utc(2026, 3, 1).difference(DateTime.utc(1970, 1, 1)).inDays,
      DateTime.utc(2026, 4, 1).difference(DateTime.utc(1970, 1, 1)).inDays,
    );
    expect(byKey[irregularBudgetKey], 200000);
    expect(byKey.containsKey('cat_darurat'), isFalse);
  });

  test('displayNameFor resolves a category name, and the fixed irregular label', () async {
    expect(await queries.displayNameFor('cat_makan'), 'Makan');
    expect(await queries.displayNameFor(irregularBudgetKey), 'Pengeluaran tidak rutin');
  });
}
