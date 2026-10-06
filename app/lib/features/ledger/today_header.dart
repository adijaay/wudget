import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/money.dart';
import '../../core/money_formatter.dart';
import '../../design/components.dart';
import '../../design/tokens.dart';
import '../../domain/pola.dart';
import '../pantau/week_bar_chart.dart';

const _formatter = MoneyFormatter();
final _fullDate = DateFormat('EEEE, d MMMM yyyy', 'id_ID');

/// What the Catat header needs, loaded once by the ledger screen.
class TodayHeaderData {
  const TodayHeaderData({
    required this.todayDay,
    required this.todaySpendMinor,
    required this.allowance,
    required this.weekDays,
    required this.weekExpense,
  });

  final int todayDay;
  final int todaySpendMinor;

  /// Null when no budget is set for the period, or on its last day — both
  /// cases print the reason instead of a number.
  final DailyAllowance? allowance;
  final List<int> weekDays;
  final Map<int, int> weekExpense;
}

/// The head of the Catat tab: today framed as a day, then the week behind
/// it. Built to design/CatatHariIni.dc.html.
///
/// This is deliberately a day-sized figure and not the period's remaining
/// balance. research/05-behavioral-research.md section 11 found a live
/// remaining-balance display raises late-period spending, because
/// certainty about the remainder licenses using it — the same finding that
/// keeps Pantau's hero on pace rather than on what is left.
///
/// No frequent-item chips here: the capture sheet already offers them at
/// the moment they are useful, and a second copy on this screen would be
/// two controls doing one job.
class TodayHeader extends StatelessWidget {
  const TodayHeader({super.key, required this.data});

  final TodayHeaderData data;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final text = Theme.of(context).textTheme;
    final allowance = data.allowance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _fullDate.format(DateTime.utc(1970, 1, 1).add(Duration(days: data.todayDay))),
          style: text.labelMedium?.copyWith(color: tokens.ink2),
        ),
        const SizedBox(height: WudgetTokens.space3),
        WudgetCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (allowance == null) ...[
                Text('Belum ada anggaran periode ini', style: text.titleSmall),
                const SizedBox(height: WudgetTokens.space2),
                Text(
                  'Jatah per hari dihitung dari anggaran dibagi sisa hari. '
                  'Tanpa anggaran tidak ada angka yang jujur untuk dibagi.',
                  style: text.bodyMedium?.copyWith(color: tokens.ink2),
                ),
              ] else if (allowance.isOverBudget) ...[
                Text('SUDAH LEWAT ANGGARAN', style: text.labelMedium),
                const SizedBox(height: WudgetTokens.space1),
                AmountText(
                  minor: -allowance.remainingMinor,
                  style: text.headlineMedium?.copyWith(fontSize: 30),
                  color: tokens.warning,
                ),
                const SizedBox(height: WudgetTokens.space2),
                Text(
                  'Lewat sebanyak itu dengan ${allowance.daysRemaining} hari tersisa. '
                  'Tidak ada jatah harian yang tersisa untuk dibagi.',
                  style: text.bodyMedium?.copyWith(color: tokens.ink2),
                ),
              ] else ...[
                Text('JATAH PER HARI', style: text.labelMedium),
                const SizedBox(height: WudgetTokens.space1),
                AmountText(
                  minor: allowance.perDayMinor,
                  style: text.headlineMedium?.copyWith(fontSize: 30),
                ),
                const SizedBox(height: WudgetTokens.space1),
                Text(
                  'Sisa ${_formatter.format(Money.fromMinor(allowance.remainingMinor, 'IDR'))} '
                  'dibagi ${allowance.daysRemaining} hari yang tersisa',
                  style: text.bodyMedium?.copyWith(color: tokens.ink2),
                ),
                const SizedBox(height: WudgetTokens.space3),
                Divider(height: 1, color: tokens.hairline),
                const SizedBox(height: WudgetTokens.space3),
                _TodayAgainstAllowance(
                  spentMinor: data.todaySpendMinor,
                  perDayMinor: allowance.perDayMinor,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: WudgetTokens.space4),
        const SectionLabel('Tujuh hari terakhir'),
        WudgetCard(
          child: WeekBarChart(days: data.weekDays, dailyExpenseMinor: data.weekExpense),
        ),
      ],
    );
  }
}

/// Today's spend against today's allowance: one bar, one meaning. The
/// verdict carries an icon as well as a colour, so over-allowance reads
/// without seeing hue (chart rule 7).
class _TodayAgainstAllowance extends StatelessWidget {
  const _TodayAgainstAllowance({required this.spentMinor, required this.perDayMinor});

  final int spentMinor;
  final int perDayMinor;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final text = Theme.of(context).textTheme;

    final over = spentMinor > perDayMinor;
    final fraction = perDayMinor == 0 ? 1.0 : (spentMinor / perDayMinor).clamp(0.0, 1.0);
    final difference = (perDayMinor - spentMinor).abs();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Keluar hari ini',
                  style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            ),
            AmountText(minor: spentMinor, style: text.titleSmall),
          ],
        ),
        const SizedBox(height: WudgetTokens.space2),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 12,
            backgroundColor: tokens.surfaceMuted,
            valueColor: AlwaysStoppedAnimation(over ? tokens.warning : tokens.accent),
          ),
        ),
        const SizedBox(height: WudgetTokens.space2),
        Row(
          children: [
            Icon(
              over ? Icons.trending_up : Icons.check,
              size: 16,
              color: over ? tokens.warning : tokens.positive,
            ),
            const SizedBox(width: WudgetTokens.space2),
            Expanded(
              child: Text(
                over
                    ? 'Lewat ${_formatter.format(Money.fromMinor(difference, 'IDR'))} dari jatah hari ini'
                    : 'Masih ${_formatter.format(Money.fromMinor(difference, 'IDR'))} di bawah jatah',
                style: text.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: over ? tokens.warning : tokens.positive,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
