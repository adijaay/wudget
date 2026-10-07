import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/money.dart';
import '../../core/money_formatter.dart';
import '../../core/providers.dart';
import '../../data/database.dart';
import '../../data/period_aggregate_queries.dart';
import '../../data/settings_repository.dart';
import '../../design/components.dart';
import '../../design/tokens.dart';
import '../../domain/payday.dart';
import '../../domain/period.dart';
import 'budget_review_screen.dart';

const _formatter = MoneyFormatter();
String _rp(int minor) => _formatter.format(Money.fromMinor(minor, 'IDR'));

/// What the payday card needs; null when it should not show.
class PaydayCardData {
  const PaydayCardData({required this.period, required this.lastSalaryMinor, required this.leftoverMinor});
  final Period period;
  final int? lastSalaryMinor;
  final int leftoverMinor;
}

Future<PaydayCardData?> loadPaydayCard(WidgetRef ref, int today) async {
  final row = await ref.read(settingsRepositoryProvider).getRow();
  if (!paydayCardDue(row, today)) return null;
  final period = effectivePeriodFromRow(row, today);
  return PaydayCardData(
    period: period,
    lastSalaryMinor: row?.lastSalaryMinor,
    leftoverMinor: await lastPeriodLeftover(ref, period),
  );
}

/// The period before [period] as it actually ran, custom one included.
Future<int> lastPeriodLeftover(WidgetRef ref, Period period) =>
    lastPeriodLeftoverFor(ref.read(settingsRepositoryProvider), ref.read(periodAggregateQueriesProvider), period);

Future<int> lastPeriodLeftoverFor(SettingsRepository settings, PeriodAggregateQueries queries, Period period) async {
  final row = await settings.getRow();
  final previous = effectivePeriodFromRow(row, period.startDay - 1);
  final totals = await queries.totalsFor(previous);
  final custom = row != null && previous.startDay == row.customPeriodStart;
  return periodLeftoverMinor(
    incomeMinor: totals.incomeMinor,
    expenseMinor: totals.expenseMinor,
    onHandMinor: custom ? row.customPeriodAmountMinor ?? 0 : 0,
  );
}

/// Records the salary as income, remembers it for next month, then opens
/// the review (screen 4b).
Future<void> confirmSalary(BuildContext context, WidgetRef ref, PaydayCardData data, int salaryMinor) async {
  final now = DateTime.now();
  final txId = const Uuid().v4();
  final accountId = await ref.read(captureQueriesProvider).defaultAccountId();
  await ref.read(postingsRepositoryProvider).insertTransaction(
    transaction: TransactionsCompanion.insert(
      id: txId,
      kind: 'income',
      occurredAt: now.toUtc().millisecondsSinceEpoch,
      tzOffsetMinutes: now.timeZoneOffset.inMinutes,
      note: const Value('Gaji'),
      updatedAt: now.toUtc().millisecondsSinceEpoch,
    ),
    postings: [
      PostingsCompanion.insert(
        id: const Uuid().v4(),
        transactionId: txId,
        accountId: Value(accountId),
        amountMinor: salaryMinor,
        currency: 'IDR',
        baseAmountMinor: salaryMinor,
      ),
      PostingsCompanion.insert(
        id: const Uuid().v4(),
        transactionId: txId,
        categoryId: const Value('cat_gaji'),
        amountMinor: -salaryMinor,
        currency: 'IDR',
        baseAmountMinor: -salaryMinor,
      ),
    ],
  );
  await ref.read(settingsRepositoryProvider).confirmPayday(data.period.startDay, salaryMinor);
  await ref.read(analyticsRepositoryProvider).logEvent('payday_confirm', props: {
    'sameAmount': salaryMinor == data.lastSalaryMinor,
  });
  if (!context.mounted) return;
  await Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => BudgetReviewScreen(
      period: data.period,
      newMoneyMinor: salaryMinor,
      leftoverMinor: data.leftoverMinor,
    ),
  ));
}

/// Screen 4a: the app asks, the user confirms.
class PaydayCard extends ConsumerWidget {
  const PaydayCard({super.key, required this.data, required this.todayDay, required this.onChanged});
  final PaydayCardData data;
  final int todayDay;

  /// Called after "Belum" or a confirmation, so home reloads.
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final text = Theme.of(context).textTheme;
    final salary = data.lastSalaryMinor;

    Future<void> otherAmount() async {
      final result = await showAmountSheet(
        context,
        title: 'Gaji periode ini',
        subtitle: 'Jumlah yang masuk ke rekeningmu.',
        buttonLabel: 'Simpan gaji',
        initialMinor: salary ?? 0,
      );
      if (result == null || !context.mounted) return;
      await confirmSalary(context, ref, data, result.amountMinor);
      onChanged();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WudgetCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(todayDay == data.period.startDay ? 'Hari ini gajian' : 'Gajian',
                  style: text.labelMedium?.copyWith(color: tokens.ink2)),
              const SizedBox(height: WudgetTokens.space1),
              Text(salary == null ? 'Gaji periode ini sudah masuk?' : 'Gaji ${_rp(salary)} sudah masuk?', style: text.titleMedium),
              const SizedBox(height: WudgetTokens.space3),
              FilledButton(
                onPressed: () async {
                  if (salary == null) return otherAmount();
                  await confirmSalary(context, ref, data, salary);
                  onChanged();
                },
                child: Text(salary == null ? 'Isi jumlah gaji' : 'Sudah masuk'),
              ),
              const SizedBox(height: WudgetTokens.space2),
              Row(
                children: [
                  // With no salary on record there is no amount to differ from.
                  if (salary != null) ...[
                    Expanded(child: OutlinedButton(onPressed: otherAmount, child: const Text('Beda jumlah'))),
                    const SizedBox(width: WudgetTokens.space2),
                  ],
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        await ref.read(settingsRepositoryProvider).snoozePayday(todayDay);
                        await ref.read(analyticsRepositoryProvider).logEvent('payday_snooze');
                        onChanged();
                      },
                      child: const Text('Belum'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (data.leftoverMinor > 0) ...[
          const SizedBox(height: WudgetTokens.space3),
          WudgetCard(
            child: Text(
              'Periode lalu sisa ${_rp(data.leftoverMinor)}. Nanti ikut masuk ke anggaran baru.',
              style: text.bodyLarge,
            ),
          ),
        ],
      ],
    );
  }
}
