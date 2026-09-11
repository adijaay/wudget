import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wudget/data/database.dart';
import 'package:wudget/data/period_aggregate_queries.dart';
import 'package:wudget/data/postings_repository.dart';
import 'package:wudget/data/recurrence_repository.dart';
import 'package:wudget/data/spending_queries.dart';
import 'package:wudget/data/wallets_repository.dart';
import 'package:wudget/domain/period.dart';
import 'package:wudget/domain/recurrence.dart';

int _day(int year, int month, int day) =>
    DateTime.utc(year, month, day).difference(DateTime.utc(1970, 1, 1)).inDays;

void main() {
  late WudgetDatabase db;
  late RecurrenceRepository recurrences;

  setUp(() async {
    db = WudgetDatabase(NativeDatabase.memory());
    recurrences = RecurrenceRepository(db);
    await db.into(db.accounts).insert(AccountsCompanion.insert(
          id: 'acc', name: 'Tunai', type: 'cash', currency: 'IDR', updatedAt: 0,
        ));
  });

  tearDown(() => db.close());

  Future<String> materializedFutureBill(int day) async {
    final id = await recurrences.create(
      template: const RecurrenceTemplate(
        kind: 'expense', accountId: 'acc', categoryId: 'cat', currency: 'IDR', fixedAmountMinor: 200000,
      ),
      rule: RecurrenceRule(freq: RecurrenceFreq.monthly, byMonthDay: 1, startsOn: day),
    );
    await recurrences.materializeAll(toDayInclusive: day);
    return id;
  }

  test('a projected instance does not move a wallet balance', () async {
    final farFuture = _day(2027, 1, 1);
    await materializedFutureBill(farFuture);

    final wallet = (await WalletsRepository(db).watchWallets().first).single;
    expect(wallet.balanceMinor, 0); // the projected bill hasn't happened yet
  });

  test('a projected instance does not count toward totalCategorySpendMinor', () async {
    await materializedFutureBill(_day(2027, 1, 1));
    expect(await totalCategorySpendMinor(db), 0);
  });

  test('a projected instance does not count toward a period\'s totals', () async {
    final day = _day(2027, 1, 1);
    await materializedFutureBill(day);

    final period = Period.containing(day, monthStartDay: 1);
    final totals = await PeriodAggregateQueries(db).totalsFor(period);
    expect(totals.expenseMinor, 0);
  });

  test('confirming the instance makes it count everywhere', () async {
    final day = _day(2027, 1, 1);
    final recurrenceId = await materializedFutureBill(day);
    final txId = (await (db.select(db.transactions)..where((t) => t.recurrenceId.equals(recurrenceId)))
            .getSingle())
        .id;

    await recurrences.confirmInstance(txId);

    final wallet = (await WalletsRepository(db).watchWallets().first).single;
    expect(wallet.balanceMinor, -200000); // account leg: money leaving
    expect(await totalCategorySpendMinor(db), 200000); // category leg: expense is positive
  });

  test('an ordinary confirmed transaction is unaffected by the predicate', () async {
    await PostingsRepository(db).insertTransaction(
      transaction: TransactionsCompanion.insert(
        id: 'tx1', kind: 'expense', occurredAt: 0, tzOffsetMinutes: 0, updatedAt: 0,
      ),
      postings: [
        PostingsCompanion.insert(id: 'p1a', transactionId: 'tx1', accountId: const Value('acc'),
            amountMinor: -10000, currency: 'IDR', baseAmountMinor: -10000),
        PostingsCompanion.insert(id: 'p1c', transactionId: 'tx1', categoryId: const Value('cat'),
            amountMinor: 10000, currency: 'IDR', baseAmountMinor: 10000),
      ],
    );
    expect(await totalCategorySpendMinor(db), 10000);
  });
}
