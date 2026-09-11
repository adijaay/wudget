import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wudget/data/database.dart';
import 'package:wudget/data/recurrence_repository.dart';
import 'package:wudget/domain/recurrence.dart';

int _day(int year, int month, int day) =>
    DateTime.utc(year, month, day).difference(DateTime.utc(1970, 1, 1)).inDays;

void main() {
  late WudgetDatabase db;
  late RecurrenceRepository repo;

  setUp(() {
    db = WudgetDatabase(NativeDatabase.memory());
    repo = RecurrenceRepository(db);
  });

  tearDown(() => db.close());

  const template = RecurrenceTemplate(
    kind: 'expense',
    accountId: 'acc',
    categoryId: 'cat',
    currency: 'IDR',
    fixedAmountMinor: 50000,
  );

  test('materialises one projected transaction per occurrence through the watermark', () async {
    final id = await repo.create(
      template: template,
      rule: RecurrenceRule(freq: RecurrenceFreq.monthly, byMonthDay: 1, startsOn: _day(2026, 1, 1)),
    );

    await repo.materializeAll(toDayInclusive: _day(2026, 3, 15));

    final rows = await (db.select(db.transactions)..where((t) => t.recurrenceId.equals(id))).get();
    expect(rows, hasLength(3)); // Jan 1, Feb 1, Mar 1
    expect(rows.every((r) => r.isProjected), isTrue);

    final postings = await db.select(db.postings).get();
    expect(postings, hasLength(6)); // 2 legs each
  });

  test('is idempotent: materialising to the same or an earlier watermark generates nothing new', () async {
    final id = await repo.create(
      template: template,
      rule: RecurrenceRule(freq: RecurrenceFreq.monthly, byMonthDay: 1, startsOn: _day(2026, 1, 1)),
    );

    await repo.materializeAll(toDayInclusive: _day(2026, 3, 15));
    await repo.materializeAll(toDayInclusive: _day(2026, 3, 15)); // same watermark again
    await repo.materializeAll(toDayInclusive: _day(2026, 2, 1)); // earlier watermark

    final rows = await (db.select(db.transactions)..where((t) => t.recurrenceId.equals(id))).get();
    expect(rows, hasLength(3));
  });

  test('the 31st in a 30-day month clamps, without becoming permanent', () async {
    final id = await repo.create(
      template: template,
      rule: RecurrenceRule(freq: RecurrenceFreq.monthly, byMonthDay: 31, startsOn: _day(2026, 1, 31)),
    );
    await repo.materializeAll(toDayInclusive: _day(2026, 5, 31));

    final query = db.select(db.transactions)
      ..where((t) => t.recurrenceId.equals(id))
      ..orderBy([(t) => OrderingTerm.asc(t.occurredAt)]);
    final dates = (await query.get()).map((r) => DateTime.utc(1970, 1, 1).add(Duration(days: r.occurredAt ~/ 86400000)));
    expect(dates, [
      DateTime.utc(2026, 1, 31),
      DateTime.utc(2026, 2, 28),
      DateTime.utc(2026, 3, 31),
      DateTime.utc(2026, 4, 30),
      DateTime.utc(2026, 5, 31),
    ]);
  });

  test('a Sunday due date shifts per weekend_rule without moving the schedule itself', () async {
    // 2026-03-01 is a Sunday.
    final id = await repo.create(
      template: template,
      rule: RecurrenceRule(
        freq: RecurrenceFreq.monthly,
        byMonthDay: 1,
        weekendRule: WeekendRule.after,
        startsOn: _day(2026, 3, 1),
      ),
    );
    await repo.materializeAll(toDayInclusive: _day(2026, 4, 1));

    final rows = await (db.select(db.transactions)..where((t) => t.recurrenceId.equals(id))).get();
    final days = rows.map((r) => r.occurredAt ~/ 86400000).toList()..sort();
    expect(DateTime.utc(1970, 1, 1).add(Duration(days: days[0])), DateTime.utc(2026, 3, 2)); // shifted to Monday
    expect(DateTime.utc(1970, 1, 1).add(Duration(days: days[1])), DateTime.utc(2026, 4, 1)); // Wed, no shift needed
  });

  test('a skipped instance generates nothing for that occurrence, others unaffected', () async {
    final id = await repo.create(
      template: template,
      rule: RecurrenceRule(freq: RecurrenceFreq.monthly, byMonthDay: 1, startsOn: _day(2026, 1, 1)),
    );
    await repo.skipInstance(id, _day(2026, 2, 1));
    await repo.materializeAll(toDayInclusive: _day(2026, 3, 15));

    final rows = await (db.select(db.transactions)..where((t) => t.recurrenceId.equals(id))).get();
    expect(rows, hasLength(2)); // Jan and Mar, not Feb
  });

  test('an early payment (move) lands on the new date, not the logical one', () async {
    final id = await repo.create(
      template: template,
      rule: RecurrenceRule(freq: RecurrenceFreq.monthly, byMonthDay: 15, startsOn: _day(2026, 1, 15)),
    );
    // Paid a week early in February.
    await repo.moveInstance(id, _day(2026, 2, 15), _day(2026, 2, 8));
    await repo.materializeAll(toDayInclusive: _day(2026, 2, 28));

    final rows = await (db.select(db.transactions)..where((t) => t.recurrenceId.equals(id))).get();
    final febDay = rows.map((r) => r.occurredAt ~/ 86400000).firstWhere((d) => d != _day(2026, 1, 15));
    expect(DateTime.utc(1970, 1, 1).add(Duration(days: febDay)), DateTime.utc(2026, 2, 8));
  });

  test('amend changes only the amended occurrence\'s amount', () async {
    final id = await repo.create(
      template: template,
      rule: RecurrenceRule(freq: RecurrenceFreq.monthly, byMonthDay: 1, startsOn: _day(2026, 1, 1)),
    );
    await repo.amendInstance(id, _day(2026, 2, 1), 75000);
    await repo.materializeAll(toDayInclusive: _day(2026, 3, 15));

    final rows = await (db.select(db.postings).join([
      innerJoin(db.transactions, db.transactions.id.equalsExp(db.postings.transactionId)),
    ])
          ..where(db.transactions.recurrenceId.equals(id) & db.postings.accountId.isNotNull()))
        .get();

    final byMonth = <int, int>{
      for (final r in rows) (r.readTable(db.transactions).occurredAt ~/ 86400000): r.readTable(db.postings).amountMinor.abs(),
    };
    expect(byMonth[_day(2026, 1, 1)], 50000);
    expect(byMonth[_day(2026, 2, 1)], 75000);
    expect(byMonth[_day(2026, 3, 1)], 50000);
  });

  test('confirmInstance clears is_projected', () async {
    final id = await repo.create(
      template: template,
      rule: RecurrenceRule(freq: RecurrenceFreq.monthly, byMonthDay: 1, startsOn: _day(2026, 1, 1)),
    );
    await repo.materializeAll(toDayInclusive: _day(2026, 1, 15));
    final txId = (await (db.select(db.transactions)..where((t) => t.recurrenceId.equals(id))).getSingle()).id;

    await repo.confirmInstance(txId);

    final row = await (db.select(db.transactions)..where((t) => t.id.equals(txId))).getSingle();
    expect(row.isProjected, isFalse);
  });

  test('editFutureFrom ends the old rule and starts a new one, leaving past instances alone', () async {
    final id = await repo.create(
      template: template,
      rule: RecurrenceRule(freq: RecurrenceFreq.monthly, byMonthDay: 1, startsOn: _day(2026, 1, 1)),
    );
    await repo.materializeAll(toDayInclusive: _day(2026, 3, 1)); // Jan, Feb, Mar all generated at 50000

    const raisedTemplate = RecurrenceTemplate(
      kind: 'expense', accountId: 'acc', categoryId: 'cat', currency: 'IDR', fixedAmountMinor: 90000,
    );
    final newId = await repo.editFutureFrom(
      recurrenceId: id,
      effectiveFrom: _day(2026, 4, 1),
      newTemplate: raisedTemplate,
      newRule: RecurrenceRule(freq: RecurrenceFreq.monthly, byMonthDay: 1, startsOn: _day(2026, 4, 1)),
    );
    await repo.materializeAll(toDayInclusive: _day(2026, 5, 1));

    final oldSeries = await (db.select(db.transactions)..where((t) => t.recurrenceId.equals(id))).get();
    expect(oldSeries, hasLength(3)); // still just Jan, Feb, Mar — untouched by the edit

    final newSeries = await (db.select(db.postings).join([
      innerJoin(db.transactions, db.transactions.id.equalsExp(db.postings.transactionId)),
    ])
          ..where(db.transactions.recurrenceId.equals(newId) & db.postings.accountId.isNotNull()))
        .get();
    expect(newSeries, hasLength(2)); // Apr, May
    expect(newSeries.every((r) => r.readTable(db.postings).amountMinor.abs() == 90000), isTrue);
  });

  test('a varies-amount item with no override uses its expected minimum as the placeholder', () async {
    const variesTemplate = RecurrenceTemplate(kind: 'expense', accountId: 'acc', categoryId: 'cat', currency: 'IDR');
    final id = await repo.create(
      template: variesTemplate,
      rule: RecurrenceRule(freq: RecurrenceFreq.monthly, byMonthDay: 1, startsOn: _day(2026, 1, 1)),
      amountMode: 'varies',
      expectedMinMinor: 100000,
      expectedMaxMinor: 200000,
    );
    await repo.materializeAll(toDayInclusive: _day(2026, 1, 15));

    final posting = await (db.select(db.postings).join([
      innerJoin(db.transactions, db.transactions.id.equalsExp(db.postings.transactionId)),
    ])
          ..where(db.transactions.recurrenceId.equals(id) & db.postings.accountId.isNotNull()))
        .getSingle();
    expect(posting.readTable(db.postings).amountMinor.abs(), 100000);
  });
}
