import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wudget/data/database.dart';
import 'package:wudget/data/notification_scheduler.dart';
import 'package:wudget/data/recurrence_repository.dart';
import 'package:wudget/data/reminder_orchestrator.dart';
import 'package:wudget/domain/recurrence.dart';

int _day(int year, int month, int day) =>
    DateTime.utc(year, month, day).difference(DateTime.utc(1970, 1, 1)).inDays;

class _ScheduledCall {
  _ScheduledCall({required this.transactionId, required this.title, required this.body});
  final String transactionId;
  final String title;
  final String body;
}

class _FakeScheduler implements ReminderScheduler {
  final scheduled = <_ScheduledCall>[];
  final cancelled = <String>[];

  @override
  Future<void> scheduleForInstance({
    required String transactionId,
    required int dueDay,
    required String title,
    required String body,
    required String deepLinkPayload,
    int hour = 9,
  }) async {
    scheduled.add(_ScheduledCall(transactionId: transactionId, title: title, body: body));
  }

  @override
  Future<void> cancelForInstance(String transactionId) async {
    cancelled.add(transactionId);
  }
}

void main() {
  late WudgetDatabase db;
  late RecurrenceRepository recurrences;
  late _FakeScheduler scheduler;

  setUp(() async {
    db = WudgetDatabase(NativeDatabase.memory());
    recurrences = RecurrenceRepository(db);
    scheduler = _FakeScheduler();
    await db.into(db.categories).insert(CategoriesCompanion.insert(
          id: 'cat_tagihan', name: 'Tagihan', kind: 'expense', iconKey: 'receipt', hueIndex: 0, sortOrder: 0, updatedAt: 0,
        ));
    await db.into(db.accounts).insert(AccountsCompanion.insert(
          id: 'acc_cash', name: 'Tunai', type: 'cash', currency: 'IDR',
          openingMinor: const Value(90000), updatedAt: 0,
        ));
  });

  tearDown(() => db.close());

  test('names the shortfall when the wallet cannot cover the bill', () async {
    await recurrences.create(
      template: const RecurrenceTemplate(
        kind: 'expense', accountId: 'acc_cash', categoryId: 'cat_tagihan', currency: 'IDR',
        fixedAmountMinor: 150000, note: 'Listrik',
      ),
      rule: RecurrenceRule(freq: RecurrenceFreq.monthly, byMonthDay: 1, startsOn: _day(2026, 3, 1)),
    );
    await recurrences.materializeAll(toDayInclusive: _day(2026, 3, 1));

    await scheduleUpcomingReminders(db, scheduler);

    expect(scheduler.scheduled, hasLength(1));
    expect(scheduler.scheduled.single.title, 'Listrik');
    expect(scheduler.scheduled.single.body, contains('kurang'));
  });

  test('falls back to the category name when the instance has no note', () async {
    await recurrences.create(
      template: const RecurrenceTemplate(
        kind: 'expense', accountId: 'acc_cash', categoryId: 'cat_tagihan', currency: 'IDR', fixedAmountMinor: 20000,
      ),
      rule: RecurrenceRule(freq: RecurrenceFreq.monthly, byMonthDay: 1, startsOn: _day(2026, 3, 1)),
    );
    await recurrences.materializeAll(toDayInclusive: _day(2026, 3, 1));

    await scheduleUpcomingReminders(db, scheduler);

    expect(scheduler.scheduled.single.title, 'Tagihan');
    expect(scheduler.scheduled.single.body, isNot(contains('kurang'))); // wallet covers it
  });

  test('schedules nothing when there are no upcoming instances', () async {
    await scheduleUpcomingReminders(db, scheduler);
    expect(scheduler.scheduled, isEmpty);
  });
}
