import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wudget/data/database.dart';
import 'package:wudget/data/recurrence_repository.dart';
import 'package:wudget/data/recurring_queries.dart';
import 'package:wudget/domain/recurrence.dart';

int _day(int year, int month, int day) =>
    DateTime.utc(year, month, day).difference(DateTime.utc(1970, 1, 1)).inDays;

void main() {
  late WudgetDatabase db;
  late RecurrenceRepository recurrences;
  late RecurringQueries queries;

  setUp(() {
    db = WudgetDatabase(NativeDatabase.memory());
    recurrences = RecurrenceRepository(db);
    queries = RecurringQueries(db);
  });

  tearDown(() => db.close());

  test('upcoming lists a materialised instance with its account, category and note', () async {
    final id = await recurrences.create(
      template: const RecurrenceTemplate(
        kind: 'expense', accountId: 'acc', categoryId: 'cat_tagihan', currency: 'IDR',
        fixedAmountMinor: 150000, note: 'Listrik',
      ),
      rule: RecurrenceRule(freq: RecurrenceFreq.monthly, byMonthDay: 1, startsOn: _day(2026, 3, 1)),
    );
    await recurrences.materializeAll(toDayInclusive: _day(2026, 3, 1));

    final upcoming = await queries.upcoming();
    expect(upcoming, hasLength(1));
    expect(upcoming.single.recurrenceId, id);
    expect(upcoming.single.amountMinor, 150000);
    expect(upcoming.single.accountId, 'acc');
    expect(upcoming.single.categoryId, 'cat_tagihan');
    expect(upcoming.single.note, 'Listrik');
  });

  test('upcoming is empty once the instance is confirmed', () async {
    await recurrences.create(
      template: const RecurrenceTemplate(
        kind: 'expense', accountId: 'acc', categoryId: 'cat', currency: 'IDR', fixedAmountMinor: 50000,
      ),
      rule: RecurrenceRule(freq: RecurrenceFreq.monthly, byMonthDay: 1, startsOn: _day(2026, 3, 1)),
    );
    await recurrences.materializeAll(toDayInclusive: _day(2026, 3, 1));
    final txId = (await queries.upcoming()).single.transactionId;

    await recurrences.confirmInstance(txId);

    expect(await queries.upcoming(), isEmpty);
  });

  test('activeRules lists a rule not soft-deleted', () async {
    await recurrences.create(
      template: const RecurrenceTemplate(kind: 'expense', accountId: 'acc', categoryId: 'cat', currency: 'IDR', fixedAmountMinor: 50000),
      rule: RecurrenceRule(freq: RecurrenceFreq.monthly, byMonthDay: 1, startsOn: _day(2026, 3, 1)),
    );
    expect(await queries.activeRules(), hasLength(1));
  });
}
