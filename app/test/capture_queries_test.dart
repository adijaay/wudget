import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wudget/data/capture_queries.dart';
import 'package:wudget/data/database.dart';
import 'package:wudget/domain/period.dart';

Future<void> _writeExpense(
  WudgetDatabase db, {
  required String id,
  required String accountId,
  required String categoryId,
  required int amountMinor,
  required int occurredAt,
  String? note,
}) {
  return db.transaction(() async {
    await db.into(db.transactions).insert(TransactionsCompanion.insert(
          id: id,
          kind: 'expense',
          occurredAt: occurredAt,
          tzOffsetMinutes: 420,
          note: Value.absentIfNull(note),
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

  // Local hour [hour] (UTC+7, as the rows are written), [daysAgo] before 7 Oct 2026.
  int at(int hour, {int daysAgo = 1}) =>
      DateTime.utc(2026, 10, 7 - daysAgo, hour).millisecondsSinceEpoch - 7 * 3600000;
  final noon = DateTime(2026, 10, 7, 12);
  final morning = DateTime(2026, 10, 7, 7);

  Future<void> lunchAndCommuteHistory() async {
    for (var i = 0; i < 8; i++) {
      await _writeExpense(db, id: 'tr$i', accountId: 'acc_cash', categoryId: 'cat_transport',
          amountMinor: 12000, occurredAt: at(7, daysAgo: i + 1), note: 'Ojek');
    }
    for (var i = 0; i < 5; i++) {
      await _writeExpense(db, id: 'mk$i', accountId: 'acc_cash', categoryId: 'cat_makan',
          amountMinor: 18000, occurredAt: at(12, daysAgo: i + 1), note: 'Warung');
    }
  }

  test('lunch-hour history puts Makan first at 12:00, Transport first at 07:00', () async {
    await lunchAndCommuteHistory();
    expect(await queries.rankedCategoryIds('expense', noon), ['cat_makan', 'cat_transport']);
    expect(await queries.rankedCategoryIds('expense', morning), ['cat_transport', 'cat_makan']);
  });

  test('a new user, or one under ten entries, gets the default order', () async {
    expect(await queries.rankedCategoryIds('expense', noon), isEmpty);
    for (var i = 0; i < minEntriesForRanking - 1; i++) {
      await _writeExpense(db, id: 'm$i', accountId: 'acc_cash', categoryId: 'cat_makan',
          amountMinor: 1000, occurredAt: at(12));
    }
    expect(await queries.rankedCategoryIds('expense', noon), isEmpty);
  });

  test('entries older than 90 days do not count', () async {
    for (var i = 0; i < 12; i++) {
      await _writeExpense(db, id: 'old$i', accountId: 'acc_cash', categoryId: 'cat_makan',
          amountMinor: 1000, occurredAt: at(12, daysAgo: 100));
    }
    expect(await queries.rankedCategoryIds('expense', noon), isEmpty);
  });

  test('quick chips group note, category and amount, ranked for the hour', () async {
    await lunchAndCommuteHistory();
    await _writeExpense(db, id: 'nonote', accountId: 'acc_cash', categoryId: 'cat_makan',
        amountMinor: 5000, occurredAt: at(12));

    final chips = await queries.quickChips(noon);
    expect(chips.map((c) => c.note), ['Warung', 'Ojek']);
    expect(chips.first.categoryId, 'cat_makan');
    expect(chips.first.amountMinor, 18000);
    expect((await queries.quickChips(morning)).first.note, 'Ojek');
  });

  test('saves without a wallet go to the oldest wallet still in use; old wallets stay readable', () async {
    expect(await queries.defaultAccountId(), 'acc_cash');
    await (db.update(db.accounts)..where((a) => a.id.equals('acc_cash')))
        .write(const AccountsCompanion(archivedAt: Value(1)));
    expect(await queries.defaultAccountId(), 'acc_bank');
    expect((await db.select(db.accounts).get()).length, 2);
  });

  test('kantong remaining is the budget minus this period spend, null without a budget', () async {
    final period = Period.containing(
      DateTime.utc(2026, 10, 7).difference(DateTime.utc(1970)).inDays,
      monthStartDay: 1,
    );
    expect(await queries.kantongRemaining('cat_makan', period), isNull);
    await db.into(db.budgets).insert(BudgetsCompanion.insert(key: 'cat_makan', amountMinor: 100000, updatedAt: 0));
    await lunchAndCommuteHistory();
    expect(await queries.kantongRemaining('cat_makan', period), 100000 - 5 * 18000);
  });
}
