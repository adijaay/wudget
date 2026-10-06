import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/money.dart';
import '../../core/money_formatter.dart';
import '../../data/period_aggregate_queries.dart';
import '../../design/components.dart';
import '../../design/tokens.dart';
import '../../domain/period.dart';
import '../../domain/pola.dart';
import '../period/period_selector.dart';
import 'month_compare_chart.dart';
import 'spend_calendar.dart';
import 'weekday_bar_chart.dart';

const _formatter = MoneyFormatter();
final _dayMonth = DateFormat('d MMMM', 'id_ID');

/// Everything Pola needs, gathered once by [PantauScreen] so this stays a
/// plain widget over already-loaded data.
class PolaData {
  const PolaData({
    required this.period,
    required this.todayDay,
    required this.dailyExpense,
    required this.transactionCount,
    required this.expenseMinor,
    required this.weekdayPattern,
    required this.weekdayWindowDays,
    required this.months,
    required this.largestExpenses,
  });

  final Period period;
  final int todayDay;
  final Map<int, int> dailyExpense;
  final int transactionCount;
  final int expenseMinor;
  final WeekdayPattern weekdayPattern;

  /// How many days the weekday averages actually cover. Printed, because
  /// "rata-rata per hari" over eleven days and over ninety days are
  /// different claims.
  final int weekdayWindowDays;
  final List<MonthTotal> months;
  final List<LargeExpense> largestExpenses;
}

/// Pantau's "Pola" view: when money goes out, rather than how much is
/// left. Built to design/Pola.dc.html.
class PolaView extends StatelessWidget {
  const PolaView({super.key, required this.data});

  final PolaData data;

  int get _daysElapsed =>
      (data.todayDay - data.period.startDay + 1).clamp(0, data.period.endDayExclusive - data.period.startDay);

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final text = Theme.of(context).textTheme;

    const padding = EdgeInsets.fromLTRB(
      WudgetTokens.space4,
      0,
      WudgetTokens.space4,
      WudgetTokens.space6,
    );

    if (data.expenseMinor == 0) {
      return ListView(
        padding: padding,
        children: [
          const PeriodSelector(),
          const SizedBox(height: WudgetTokens.space4),
          WudgetCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.calendar_today_outlined, size: 26, color: tokens.ink2),
                const SizedBox(height: WudgetTokens.space3),
                Text('Polanya belum kelihatan', style: text.titleMedium),
                const SizedBox(height: WudgetTokens.space2),
                Text(
                  'Periode ini belum ada pengeluaran tercatat. Kalender dan '
                  'rata-rata per hari mulai berarti setelah dua mingguan, dan '
                  'perbandingan antar bulan setelah satu periode kamu tutup.',
                  style: text.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: padding,
      children: [
        const PeriodSelector(),
        const SizedBox(height: WudgetTokens.space3),
        _StatStrip(
          daysElapsed: _daysElapsed,
          transactionCount: data.transactionCount,
          expenseMinor: data.expenseMinor,
        ),
        const SizedBox(height: WudgetTokens.space5),

        const SectionLabel('Hari mana yang berat'),
        WudgetCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SpendCalendar(
                startDay: data.period.startDay,
                endDayExclusive: data.period.endDayExclusive,
                dailyExpenseMinor: data.dailyExpense,
                todayDay: data.todayDay,
              ),
              const SizedBox(height: WudgetTokens.space3),
              Divider(height: 1, color: tokens.hairline),
              const SizedBox(height: WudgetTokens.space3),
              Text(_calendarSentence(), style: text.bodyMedium),
            ],
          ),
        ),
        const SizedBox(height: WudgetTokens.space5),

        const SectionLabel('Akhir pekan berapa kali lipat'),
        WudgetCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rata-rata per hari, ${data.weekdayWindowDays} hari terakhir',
                style: text.labelMedium?.copyWith(color: tokens.ink2),
              ),
              const SizedBox(height: WudgetTokens.space3),
              WeekdayBarChart(pattern: data.weekdayPattern),
              const SizedBox(height: WudgetTokens.space3),
              Text(_weekendSentence(), style: text.bodyMedium),
            ],
          ),
        ),
        const SizedBox(height: WudgetTokens.space5),

        if (data.months.length >= 2) ...[
          const SectionLabel('Beberapa periode terakhir'),
          WudgetCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MonthCompareChart(months: data.months),
                // Only a running period has a forecast to caveat. A period
                // paged back to has already landed, and calling its total
                // an estimate would be the opposite of honest.
                if (data.months.any((m) => m.isForecast)) ...[
                  const SizedBox(height: WudgetTokens.space3),
                  Text(
                    'Perkiraan periode ini dihitung dari $_daysElapsed hari. Tagihan '
                    'yang jatuh di awal sudah masuk, jadi angkanya biasanya masih naik.',
                    style: text.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: WudgetTokens.space5),
        ],

        if (data.largestExpenses.isNotEmpty) ...[
          SectionLabel(
            'Nota paling besar',
            trailing: Text(
              '${data.largestExpenses.length} teratas',
              style: text.labelMedium?.copyWith(color: tokens.ink2),
            ),
          ),
          WudgetCard(
            padding: const EdgeInsets.symmetric(vertical: WudgetTokens.space2),
            child: Column(
              children: [
                for (final expense in data.largestExpenses)
                  Builder(builder: (context) {
                    final note = expense.note?.trim();
                    final hasNote = note != null && note.isNotEmpty;
                    final date =
                        _dayMonth.format(DateTime.utc(1970, 1, 1).add(Duration(days: expense.day)));
                    return CardRow(
                      leading: IconChip(
                        icon: Icons.receipt_long_outlined,
                        background:
                            tokens.categoryTints[expense.hueIndex % tokens.categoryTints.length],
                        foreground:
                            tokens.categoryInks[expense.hueIndex % tokens.categoryInks.length],
                      ),
                      // With no note the category name becomes the title, so
                      // the subtitle drops it rather than printing the same
                      // word twice.
                      title: hasNote ? note : (expense.categoryName ?? 'Tanpa kategori'),
                      subtitle: hasNote && expense.categoryName != null
                          ? '$date · ${expense.categoryName}'
                          : date,
                      trailing: AmountText(minor: expense.amountMinor, style: text.titleSmall),
                    );
                  }),
              ],
            ),
          ),
          const SizedBox(height: WudgetTokens.space3),
          Text(_largestSentence(), style: text.bodyMedium?.copyWith(color: tokens.ink2)),
        ],
      ],
    );
  }

  String _calendarSentence() {
    final entries = data.dailyExpense.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final quietDays = [
      for (var day = data.period.startDay; day <= data.todayDay; day++)
        if ((data.dailyExpense[day] ?? 0) == 0) day,
    ].length;

    final parts = <String>[];
    if (entries.isNotEmpty) {
      final worst = entries.first;
      final date = _dayMonth.format(DateTime.utc(1970, 1, 1).add(Duration(days: worst.key)));
      parts.add('Yang paling berat $date, '
          '${_formatter.format(Money.fromMinor(worst.value, 'IDR'))}.');
    }
    if (quietDays > 0) {
      parts.add('$quietDays hari sejauh ini tanpa pengeluaran sama sekali.');
    }
    return parts.join(' ');
  }

  String _weekendSentence() {
    final weekend = data.weekdayPattern.weekendAverageMinor;
    final workday = data.weekdayPattern.workdayAverageMinor;
    // Both halves have to exist before a comparison can be stated at all
    // (chart rule 8) — a window shorter than a week has only one of them.
    if (weekend == null || workday == null) {
      return 'Belum cukup hari untuk membandingkan akhir pekan dengan hari kerja.';
    }
    final weekendText = _formatter.format(Money.fromMinor(weekend, 'IDR'));
    final workdayText = _formatter.format(Money.fromMinor(workday, 'IDR'));
    if (workday == 0) {
      return 'Akhir pekan $weekendText per hari. Hari kerja belum ada pengeluaran.';
    }
    final ratio = weekend / workday;
    final comparison = switch (ratio) {
      >= 1.8 => 'Hampir dua kali hari kerja.',
      >= 1.25 => 'Lebih tinggi dari hari kerja.',
      <= 0.8 => 'Justru lebih rendah dari hari kerja.',
      _ => 'Mirip dengan hari kerja.',
    };
    return 'Akhir pekan $weekendText per hari, hari kerja $workdayText. $comparison';
  }

  String _largestSentence() {
    final total = data.largestExpenses.fold<int>(0, (sum, e) => sum + e.amountMinor);
    final totalText = _formatter.format(Money.fromMinor(total, 'IDR'));
    if (data.expenseMinor == 0) return '';
    final share = (total * 100 / data.expenseMinor).round();
    return '${data.largestExpenses.length} nota ini $totalText, '
        '$share persen dari belanja periode ini.';
  }
}

/// Three numbers the rest of the screen is derived from, on one line. No
/// delta badges: a trend claim needs a comparison period, and these are
/// period-to-date facts, not trends.
class _StatStrip extends StatelessWidget {
  const _StatStrip({
    required this.daysElapsed,
    required this.transactionCount,
    required this.expenseMinor,
  });

  final int daysElapsed;
  final int transactionCount;
  final int expenseMinor;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final text = Theme.of(context).textTheme;

    Widget stat(String value, String label, {int flex = 1}) => Expanded(
          flex: flex,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: text.titleMedium),
              const SizedBox(height: 1),
              Text(label, style: text.labelSmall?.copyWith(color: tokens.ink2)),
            ],
          ),
        );

    final perDay = daysElapsed == 0 ? null : expenseMinor ~/ daysElapsed;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: WudgetTokens.space4,
        vertical: WudgetTokens.space3,
      ),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(WudgetTokens.radiusChip),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          stat('$daysElapsed', 'hari jalan'),
          Container(width: 1, height: 26, color: tokens.border),
          const SizedBox(width: WudgetTokens.space3),
          stat('$transactionCount', 'transaksi'),
          Container(width: 1, height: 26, color: tokens.border),
          const SizedBox(width: WudgetTokens.space3),
          stat(
            perDay == null ? '—' : _formatter.format(Money.fromMinor(perDay, 'IDR')),
            'rata-rata per hari',
            flex: 2,
          ),
        ],
      ),
    );
  }
}
