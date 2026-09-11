import '../core/money.dart';
import '../core/money_formatter.dart';
import '../domain/reminder.dart';
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
