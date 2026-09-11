import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wudget/data/database.dart';
import 'package:wudget/data/period_aggregate_queries.dart';
import 'package:wudget/data/postings_repository.dart';
import 'package:wudget/domain/period.dart';

void main() {
  late WudgetDatabase db;
  late PostingsRepository postings;
  late PeriodAggregateQueries queries;

  setUp(() {
    db = WudgetDatabase(NativeDatabase.memory());
    postings = PostingsRepository(db);
    queries = PeriodAggregateQueries(db);
  });

  tearDown(() => db.close());

  Future<void> insertExpense(String id, DateTime occurredAt, int amountMinor) {
    return postings.insertTransaction(
      transaction: TransactionsCompanion.insert(
        id: id,
        kind: 'expense',
        occurredAt: occurredAt.millisecondsSinceEpoch,
        tzOffsetMinutes: 0,
        updatedAt: 0,
      ),
      postings: [
        PostingsCompanion.insert(
            id: '${id}_a', transactionId: id, accountId: const Value('acc'),
            amountMinor: -amountMinor, currency: 'IDR', baseAmountMinor: -amountMinor),
        PostingsCompanion.insert(
            id: '${id}_c', transactionId: id, categoryId: const Value('cat'),
            amountMinor: amountMinor, currency: 'IDR', baseAmountMinor: amountMinor),
      ],
    );
  }

  Future<void> insertIncome(String id, DateTime occurredAt, int amountMinor) {
    return postings.insertTransaction(
      transaction: TransactionsCompanion.insert(
        id: id,
        kind: 'income',
        occurredAt: occurredAt.millisecondsSinceEpoch,
        tzOffsetMinutes: 0,
        updatedAt: 0,
      ),
      postings: [
        PostingsCompanion.insert(
            id: '${id}_a', transactionId: id, accountId: const Value('acc'),
            amountMinor: amountMinor, currency: 'IDR', baseAmountMinor: amountMinor),
        PostingsCompanion.insert(
            id: '${id}_c', transactionId: id, categoryId: const Value('cat'),
            amountMinor: -amountMinor, currency: 'IDR', baseAmountMinor: -amountMinor),
      ],
    );
  }

  test('totalsFor sums only postings inside the period, expense and income kept apart', () async {
    await insertExpense('tx1', DateTime.utc(2026, 3, 15), 20000);
    await insertIncome('tx2', DateTime.utc(2026, 3, 16), 500000);
    // Outside the period entirely.
    await insertExpense('tx3', DateTime.utc(2026, 2, 28), 99999);

    final period = Period.containing(
      DateTime.utc(2026, 3, 15).difference(DateTime.utc(1970, 1, 1)).inDays,
      monthStartDay: 1,
    );
    final totals = await queries.totalsFor(period);
    expect(totals.expenseMinor, 20000);
    expect(totals.incomeMinor, 500000);
  });

  test('a transfer (no category leg) contributes nothing', () async {
    await postings.insertTransaction(
      transaction: TransactionsCompanion.insert(
        id: 'tx_transfer',
        kind: 'transfer',
        occurredAt: DateTime.utc(2026, 3, 10).millisecondsSinceEpoch,
        tzOffsetMinutes: 0,
        updatedAt: 0,
      ),
      postings: [
        PostingsCompanion.insert(id: 'p_from', transactionId: 'tx_transfer', accountId: const Value('acc_a'),
            amountMinor: -10000, currency: 'IDR', baseAmountMinor: -10000),
        PostingsCompanion.insert(id: 'p_to', transactionId: 'tx_transfer', accountId: const Value('acc_b'),
            amountMinor: 10000, currency: 'IDR', baseAmountMinor: 10000),
      ],
    );

    final period = Period.containing(
      DateTime.utc(2026, 3, 10).difference(DateTime.utc(1970, 1, 1)).inDays,
      monthStartDay: 1,
    );
    final totals = await queries.totalsFor(period);
    expect(totals.expenseMinor, 0);
    expect(totals.incomeMinor, 0);
  });

  test('firstTransactionDay is null with no history, else the earliest day', () async {
    expect(await queries.firstTransactionDay(), isNull);

    await insertExpense('tx1', DateTime.utc(2026, 3, 15), 1000);
    await insertExpense('tx2', DateTime.utc(2026, 3, 10), 1000);

    final expectedDay = DateTime.utc(2026, 3, 10).difference(DateTime.utc(1970, 1, 1)).inDays;
    expect(await queries.firstTransactionDay(), expectedDay);
  });

  test('dailyExpenseMinor buckets by day and excludes income and transfers', () async {
    await insertExpense('tx1', DateTime.utc(2026, 3, 5), 10000);
    await insertExpense('tx2', DateTime.utc(2026, 3, 5), 5000);
    await insertIncome('tx3', DateTime.utc(2026, 3, 6), 999999);

    final period = Period.containing(
      DateTime.utc(2026, 3, 5).difference(DateTime.utc(1970, 1, 1)).inDays,
      monthStartDay: 1,
    );
    final daily = await queries.dailyExpenseMinor(period);
    final day5 = DateTime.utc(2026, 3, 5).difference(DateTime.utc(1970, 1, 1)).inDays;
    expect(daily[day5], 15000);
    expect(daily.values.fold<int>(0, (a, b) => a + b), 15000);
  });

  group('previousPeriodBaselineExpenseMinor', () {
    test('null when the previous period predates any transaction', () async {
      await insertExpense('tx1', DateTime.utc(2026, 3, 15), 10000);
      final period = Period.containing(
        DateTime.utc(2026, 3, 15).difference(DateTime.utc(1970, 1, 1)).inDays,
        monthStartDay: 1,
      );
      expect(await queries.previousPeriodBaselineExpenseMinor(period), isNull);
    });

    test('the previous period\'s expense total once it is a full period of real history', () async {
      await insertExpense('tx0', DateTime.utc(2026, 1, 5), 1000); // first ever, before the baseline period
      await insertExpense('tx1', DateTime.utc(2026, 2, 10), 40000);
      await insertExpense('tx2', DateTime.utc(2026, 3, 15), 10000);
      final period = Period.containing(
        DateTime.utc(2026, 3, 15).difference(DateTime.utc(1970, 1, 1)).inDays,
        monthStartDay: 1,
      );
      expect(await queries.previousPeriodBaselineExpenseMinor(period), 40000);
    });
  });
}
