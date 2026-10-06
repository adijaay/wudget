import '../core/money.dart';
import '../core/money_formatter.dart';
import '../domain/period.dart';
import '../domain/reminder.dart';
import '../domain/reminder_schedule.dart';
import 'analytics_repository.dart';
import 'daily_totals_repository.dart';
import 'feature_flags_repository.dart';
import 'settings_repository.dart';
import 'database.dart';
import 'notification_scheduler.dart';
import 'recurring_queries.dart';
import 'wallets_repository.dart';

const _formatter = MoneyFormatter();

/// Schedules a reminder for every upcoming (materialised, unconfirmed)
/// instance — called on app open, alongside materialisation itself, per
/// plan/03-architecture.md: "Materialisation runs on app open and on a
/// background trigger." Re-scheduling the same instance is harmless: its
/// notification id is derived from the transaction id
/// (`NotificationScheduler._notificationId`), so a repeat call replaces
/// rather than duplicates.
Future<void> scheduleUpcomingReminders(WudgetDatabase db, ReminderScheduler scheduler) async {
  final upcoming = await RecurringQueries(db).upcoming();
  if (upcoming.isEmpty) return;

  final wallets = {for (final w in await WalletsRepository(db).watchWallets().first) w.account.id: w};
  final categories = {for (final c in await db.select(db.categories).get()) c.id: c.name};

  for (final instance in upcoming) {
    final wallet = wallets[instance.accountId];
    final label = instance.note?.isNotEmpty == true
        ? instance.note!
        : (categories[instance.categoryId] ?? 'Tagihan');

    final body = wallet == null
        ? '$label jatuh tempo: ${_formatter.format(Money.fromMinor(instance.amountMinor, 'IDR'))}.'
        : reminderBody(
            itemLabel: label,
            amountMinor: instance.amountMinor,
            walletBalanceMinor: wallet.balanceMinor,
            walletName: wallet.account.name,
            formatMoney: (minor) => _formatter.format(Money.fromMinor(minor, 'IDR')),
          );

    await scheduler.scheduleForInstance(
      transactionId: instance.transactionId,
      dueDay: instance.dueDay,
      title: label,
      body: body,
      deepLinkPayload: reminderDeepLink(
        categoryId: instance.categoryId,
        accountId: instance.accountId,
        amountMinor: instance.amountMinor,
        note: instance.note ?? '',
        confirmingTransactionId: instance.transactionId,
      ),
    );
  }
}

const eveningReminderBaseId = 1000;
const eveningReminderDays = 7;
const paydayReminderId = 1100;
const weeklyRecapReminderId = 1101;
const _paydayHour = 9;
const _weeklyRecapHour = 19;

/// Rule 7: an evening reminder on each of the next seven days that has no
/// entry yet, the payday question on the next unconfirmed payday, and a
/// weekly recap on Sunday. Called on app open and after every save, so a
/// day logged since the last run loses its reminder.
Future<void> scheduleRetentionReminders(WudgetDatabase db, ReminderScheduler scheduler, {DateTime? now}) async {
  now ??= DateTime.now();
  final today = DateTime.utc(now.year, now.month, now.day).difference(DateTime.utc(1970, 1, 1)).inDays;
  final flags = FeatureFlagsRepository(db);

  for (var i = 0; i < eveningReminderDays; i++) {
    await scheduler.cancelReminder(eveningReminderBaseId + i);
  }
  await scheduler.cancelReminder(paydayReminderId);
  await scheduler.cancelReminder(weeklyRecapReminderId);

  if (await flags.getBool(eveningReminderKey, defaultValue: true)) {
    final hour = usualLoggingHour(
      await AnalyticsRepository(db).captureSaveTimesSince(now.subtract(const Duration(days: 30))),
    );
    final logged = await DailyTotalsRepository(db).entryDays(today, today + eveningReminderDays);
    for (var i = 0; i < eveningReminderDays; i++) {
      if (logged.contains(today + i) || (i == 0 && now.hour >= hour)) continue;
      await scheduler.scheduleReminder(
        id: eveningReminderBaseId + i,
        day: today + i,
        hour: hour,
        title: 'Belum ada catatan hari ini',
        body: 'Kalau tadi ada pengeluaran, ketuk untuk mencatat.',
        payload: 'wudget://capture?kind=expense',
      );
    }
  }

  if (await flags.getBool(paydayReminderKey, defaultValue: true)) {
    final row = await SettingsRepository(db).getRow();
    final payday = row?.periodStartDay ?? defaultPeriodStartDay;
    for (var d = today; d < today + 62; d++) {
      final date = DateTime.utc(1970, 1, 1).add(Duration(days: d));
      if (date.day != payday || !paydayCardDue(row, d)) continue;
      if (d == today && now.hour >= _paydayHour) continue;
      final salary = row?.lastSalaryMinor;
      await scheduler.scheduleReminder(
        id: paydayReminderId,
        day: d,
        hour: _paydayHour,
        title: 'Gajian hari ini',
        body: salary == null ? 'Gaji sudah masuk?' : 'Gaji ${_formatter.format(Money.fromMinor(salary, 'IDR'))} sudah masuk?',
      );
      break;
    }
  }

  if (await flags.getBool(weeklyRecapReminderKey, defaultValue: true)) {
    var sunday = today + (DateTime.sunday - now.weekday) % 7;
    if (sunday == today && now.hour >= _weeklyRecapHour) sunday += 7;
    await scheduler.scheduleReminder(
      id: weeklyRecapReminderId,
      day: sunday,
      hour: _weeklyRecapHour,
      title: 'Rekap minggu ini',
      body: 'Tujuh hari terakhir sudah bisa dilihat di Pantau.',
    );
  }
}
