import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wudget/data/database.dart';
import 'package:wudget/data/notification_scheduler.dart';
import 'package:wudget/data/recurrence_repository.dart';
import 'package:wudget/data/reminder_orchestrator.dart';
import 'package:wudget/data/feature_flags_repository.dart';
import 'package:wudget/data/postings_repository.dart';
import 'package:wudget/data/settings_repository.dart';
import 'package:wudget/domain/recurrence.dart';
import 'package:wudget/domain/reminder_schedule.dart';

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

  final reminders = <int, ({int day, int hour, String title, String body})>{};

  @override
  Future<void> scheduleReminder({
    required int id,
    required int day,
    required int hour,
    required String title,
    required String body,
    String? payload,
  }) async {
    reminders[id] = (day: day, hour: hour, title: title, body: body);
  }

  @override
  Future<void> cancelReminder(int id) async => reminders.remove(id);
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

  group('retention reminders', () {
    // Wednesday 7 Oct 2026, 10:00 local.
    final now = DateTime(2026, 10, 7, 10);
    final today = _day(2026, 10, 7);

    Future<void> saveAt(DateTime at) async {
      final id = 'tx${at.millisecondsSinceEpoch}';
      await PostingsRepository(db).insertTransaction(
        transaction: TransactionsCompanion.insert(
          id: id, kind: 'expense', occurredAt: at.toUtc().millisecondsSinceEpoch,
          tzOffsetMinutes: at.timeZoneOffset.inMinutes, updatedAt: 0,
        ),
        postings: [
          PostingsCompanion.insert(id: '${id}a', transactionId: id, accountId: const Value('acc_cash'),
              amountMinor: -1000, currency: 'IDR', baseAmountMinor: -1000),
          PostingsCompanion.insert(id: '${id}c', transactionId: id, categoryId: const Value('cat_tagihan'),
              amountMinor: 1000, currency: 'IDR', baseAmountMinor: 1000),
        ],
      );
      await db.into(db.analyticsEvents).insert(AnalyticsEventsCompanion.insert(
            id: 'ev$id', name: 'capture_save', occurredAt: at.toUtc().millisecondsSinceEpoch,
          ));
    }

    test('evening reminder at the usual hour, skipped on a logged day', () async {
      await saveAt(DateTime(2026, 10, 1, 21, 5));
      await saveAt(DateTime(2026, 10, 2, 21, 40));
      await saveAt(DateTime(2026, 10, 3, 12));
      await saveAt(DateTime(2026, 10, 7, 8)); // today is logged

      await scheduleRetentionReminders(db, scheduler, now: now);

      expect(scheduler.reminders.containsKey(eveningReminderBaseId), isFalse);
      final tomorrow = scheduler.reminders[eveningReminderBaseId + 1]!;
      expect(tomorrow.day, today + 1);
      expect(tomorrow.hour, 21);
      expect(tomorrow.title, 'Belum ada catatan hari ini');
    });

    test('a save today cancels a reminder scheduled before it', () async {
      await scheduleRetentionReminders(db, scheduler, now: now);
      expect(scheduler.reminders[eveningReminderBaseId]!.day, today);

      await saveAt(DateTime(2026, 10, 7, 11));
      await scheduleRetentionReminders(db, scheduler, now: now);
      expect(scheduler.reminders.containsKey(eveningReminderBaseId), isFalse);
    });

    test('payday asks the card question on the next 25th; weekly recap on Sunday', () async {
      await SettingsRepository(db).confirmPayday(_day(2026, 9, 25), 7500000);
      await scheduleRetentionReminders(db, scheduler, now: now);

      final payday = scheduler.reminders[paydayReminderId]!;
      expect(payday.day, _day(2026, 10, 25));
      expect(payday.body, contains('sudah masuk?'));
      expect(scheduler.reminders[weeklyRecapReminderId]!.day, _day(2026, 10, 11));
    });

    test('all three can be turned off, and nothing else is scheduled', () async {
      final flags = FeatureFlagsRepository(db);
      await flags.setBool(eveningReminderKey, false);
      await flags.setBool(paydayReminderKey, false);
      await flags.setBool(weeklyRecapReminderKey, false);
      await scheduleRetentionReminders(db, scheduler, now: now);
      expect(scheduler.reminders, isEmpty);
    });

    test('usual hour: most common, later on a tie, kept in the evening', () {
      expect(usualLoggingHour(const []), 20);
      expect(usualLoggingHour([DateTime(2026, 1, 1, 19), DateTime(2026, 1, 2, 21)]), 21);
      expect(usualLoggingHour([DateTime(2026, 1, 1, 12), DateTime(2026, 1, 2, 12)]), 17);
      expect(usualLoggingHour([DateTime(2026, 1, 1, 23)]), 21);
    });
  });
}
