import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wudget/data/category_rank_queries.dart';
import 'package:wudget/data/database.dart';
import 'package:wudget/data/postings_repository.dart';

void main() {
  late WudgetDatabase db;
  late PostingsRepository postings;
  late CategoryRankQueries queries;

  setUp(() async {
    db = WudgetDatabase(NativeDatabase.memory());
    postings = PostingsRepository(db);
    queries = CategoryRankQueries(db);

    await db.into(db.categories).insert(CategoriesCompanion.insert(
          id: 'cat_makan', name: 'Makan', kind: 'expense', iconKey: 'food', hueIndex: 0, sortOrder: 0, updatedAt: 0,
        ));
    await db.into(db.categories).insert(CategoriesCompanion.insert(
          id: 'cat_makan_sarapan', parentId: const Value('cat_makan'), name: 'Sarapan', kind: 'expense',
          iconKey: 'food', hueIndex: 0, sortOrder: 1, updatedAt: 0,
        ));
    await db.into(db.categories).insert(CategoriesCompanion.insert(
          id: 'cat_transport', name: 'Transport', kind: 'expense', iconKey: 'car', hueIndex: 1, sortOrder: 2, updatedAt: 0,
        ));
  });

  tearDown(() => db.close());

  Future<void> expense(String id, String categoryId, DateTime at, int amountMinor) {
    return postings.insertTransaction(
      transaction: TransactionsCompanion.insert(
        id: id, kind: 'expense', occurredAt: at.millisecondsSinceEpoch, tzOffsetMinutes: 0, updatedAt: 0,
      ),
      postings: [
        PostingsCompanion.insert(id: '${id}a', transactionId: id, accountId: const Value('acc'),
            amountMinor: -amountMinor, currency: 'IDR', baseAmountMinor: -amountMinor),
        PostingsCompanion.insert(id: '${id}c', transactionId: id, categoryId: Value(categoryId),
            amountMinor: amountMinor, currency: 'IDR', baseAmountMinor: amountMinor),
      ],
    );
  }

  test('ranks by amount descending, rolling subcategory spend into its parent', () async {
    await expense('tx1', 'cat_makan', DateTime.utc(2026, 3, 5), 30000);
    await expense('tx2', 'cat_makan_sarapan', DateTime.utc(2026, 3, 6), 20000);
    await expense('tx3', 'cat_transport', DateTime.utc(2026, 3, 7), 15000);

    final ranks = await queries.rankedSpend(
      DateTime.utc(2026, 3, 1).difference(DateTime.utc(1970, 1, 1)).inDays,
      DateTime.utc(2026, 4, 1).difference(DateTime.utc(1970, 1, 1)).inDays,
    );

    expect(ranks.map((r) => r.key), ['cat_makan', 'cat_transport']);
    expect(ranks[0].amountMinor, 50000);
    expect(ranks[0].count, 2);
    expect(ranks[0].name, 'Makan');
    expect(ranks[1].amountMinor, 15000);
    expect(ranks[1].count, 1);
  });

  test('a category with no spend is simply absent, not a zero row', () async {
    final ranks = await queries.rankedSpend(
      DateTime.utc(2026, 3, 1).difference(DateTime.utc(1970, 1, 1)).inDays,
      DateTime.utc(2026, 4, 1).difference(DateTime.utc(1970, 1, 1)).inDays,
    );
    expect(ranks, isEmpty);
  });
}
