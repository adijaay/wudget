import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/money.dart';
import '../../core/money_formatter.dart';
import '../../core/providers.dart';
import '../../data/category_rank_queries.dart';
import '../../data/feature_flags_repository.dart';
import '../../data/period_aggregate_queries.dart';
import '../../design/components.dart';
import '../../design/tokens.dart';
import '../../domain/pace.dart';
import '../../domain/period.dart';
import '../../domain/period_close.dart';
import '../period/period_selector.dart';
import 'actual_forecast_chart.dart';
import 'category_ranked_list.dart';
import 'pace_ring.dart';
import 'period_close_sheet.dart';
import 'week_bar_chart.dart';

const _formatter = MoneyFormatter();
const _waitingDays = 14;

int _todayDayBucket() {
  final now = DateTime.now();
  return DateTime.utc(now.year, now.month, now.day).difference(DateTime.utc(1970, 1, 1)).inDays;
}

/// Pantau: the review surface. Leads with pace against elapsed time and a
/// forecast, not the remaining balance, unless the framing experiment's
/// flag says otherwise — plan/01-features.md and plan/05-sprints.md
/// Sprint 11. Built to design/Pantau.dc.html.
class PantauScreen extends ConsumerStatefulWidget {
  const PantauScreen({super.key});

  @override
  ConsumerState<PantauScreen> createState() => _PantauScreenState();
}

class _PantauScreenState extends ConsumerState<PantauScreen> {
  int? _firstDay;
  PeriodTotals? _totals;
  Map<int, int> _dailyExpense = const {};
  int? _baselineExpenseMinor;
  List<CategoryRank> _categoryRanks = const [];
  List<int> _weekDays = const [];
  Map<int, int> _weekExpense = const {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPeriodClose());
  }

  /// Fires once per period boundary and is dismissible — plan/02-flows.md
  /// #7. Checked once on entering Pantau, not on every manual period-
  /// selector navigation (that's browsing history, not a boundary event).
  Future<void> _checkPeriodClose() async {
    final settings = ref.read(settingsRepositoryProvider);
    final periodQueries = ref.read(periodAggregateQueriesProvider);
    final rankQueries = ref.read(categoryRankQueriesProvider);

    final closing = ref.read(currentPeriodProvider).previous;
    final beforeClosing = closing.previous;

    final lastAck = await settings.getLastAcknowledgedPeriodClose();
    if (lastAck != null && lastAck >= closing.startDay) return;

    if (!mounted) return;

    if (lastAck != null && beforeClosing.startDay > lastAck) {
      await showModalBottomSheet(
        context: context,
        builder: (_) => LapsedReturnSheet(onClose: () => Navigator.of(context).pop()),
      );
      await settings.setLastAcknowledgedPeriodClose(closing.startDay);
      return;
    }

    final totals = await periodQueries.totalsFor(closing);
    final closingRanks = await rankQueries.rankedSpend(closing.startDay, closing.endDayExclusive);
    final previousRanks =
        await rankQueries.rankedSpend(beforeClosing.startDay, beforeClosing.endDayExclusive);

    final summary = buildPeriodCloseSummary(
      incomeMinor: totals.incomeMinor,
      expenseMinor: totals.expenseMinor,
      closingRanks: [
        for (final r in closingRanks) (key: r.key, name: r.name, amountMinor: r.amountMinor)
      ],
      previousRanks: [
        for (final r in previousRanks) (key: r.key, name: r.name, amountMinor: r.amountMinor)
      ],
    );
    if (summary == null) return; // no data for the closing period — skip the ritual entirely

    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => PeriodCloseSheet(
        summary: summary,
        periodLabel: periodCloseLabel(closing.startDate),
        onClose: () => Navigator.of(context).pop(),
      ),
    );
    await settings.setLastAcknowledgedPeriodClose(closing.startDay);
  }

  Future<void> _load() async {
    final queries = ref.read(periodAggregateQueriesProvider);
    final period = ref.read(currentPeriodProvider);
    final today = _todayDayBucket();

    final firstDay = await queries.firstTransactionDay();
    final totals = await queries.totalsFor(period);
    final daily = await queries.dailyExpenseMinor(period);
    final baseline = await queries.previousPeriodBaselineExpenseMinor(period);
    final ranks =
        await ref.read(categoryRankQueriesProvider).rankedSpend(period.startDay, period.endDayExclusive);
    final weekDays = List<int>.generate(7, (i) => today - 6 + i);
    final weekExpense = await queries.dailyExpenseMinorInRange(weekDays.first, today + 1);

    final paceFirst = await ref
        .read(featureFlagsRepositoryProvider)
        .getBool(paceFirstFlagKey, defaultValue: true);
    await ref.read(analyticsRepositoryProvider).logEvent(
      'pantau_viewed',
      props: {'variant': paceFirst ? 'pace_first' : 'remaining_first'},
    );

    if (!mounted) return;
    setState(() {
      _firstDay = firstDay;
      _totals = totals;
      _dailyExpense = daily;
      _baselineExpenseMinor = baseline;
      _categoryRanks = ranks;
      _weekDays = weekDays;
      _weekExpense = weekExpense;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(currentPeriodProvider, (previous, next) {
      if (previous != next) _load();
    });

    if (!_loaded) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pantau')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final todayDay = _todayDayBucket();
    final daysSinceFirst = _firstDay == null ? 0 : todayDay - _firstDay! + 1;
    final period = ref.watch(currentPeriodProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pantau')),
      body: daysSinceFirst < _waitingDays
          ? _WaitingState(
              daysSoFar: daysSinceFirst,
              totals: _totals!,
              daysElapsedInPeriod: (todayDay - period.startDay + 1)
                  .clamp(1, period.endDayExclusive - period.startDay),
            )
          : _ReviewBody(
              totals: _totals!,
              dailyExpense: _dailyExpense,
              baselineExpenseMinor: _baselineExpenseMinor,
              todayDay: todayDay,
              categoryRanks: _categoryRanks,
              weekDays: _weekDays,
              weekExpense: _weekExpense,
            ),
    );
  }
}

class _ReviewBody extends ConsumerWidget {
  const _ReviewBody({
    required this.totals,
    required this.dailyExpense,
    required this.baselineExpenseMinor,
    required this.todayDay,
    required this.categoryRanks,
    required this.weekDays,
    required this.weekExpense,
  });

  final PeriodTotals totals;
  final Map<int, int> dailyExpense;
  final int? baselineExpenseMinor;
  final int todayDay;
  final List<CategoryRank> categoryRanks;
  final List<int> weekDays;
  final Map<int, int> weekExpense;

  PaceResult _computePace(Period period) {
    final totalDays = period.endDayExclusive - period.startDay;
    final daysElapsed = (todayDay - period.startDay + 1).clamp(1, totalDays);
    return computePace(
      daysElapsed: daysElapsed,
      totalDaysInPeriod: totalDays,
      spendMinor: totals.expenseMinor,
      baselineTotalMinor: baselineExpenseMinor,
    );
  }

  void _showRemainingBalance(BuildContext context) {
    final remaining = totals.incomeMinor - totals.expenseMinor;
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(WudgetTokens.space5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sisa periode ini', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: WudgetTokens.space2),
              AmountText(
                minor: remaining,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: WudgetTokens.space2),
              Text(
                'Pemasukan periode ini dikurangi pengeluarannya. Ini bukan '
                'target, dan bukan saldo semua kantong.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(currentPeriodProvider);
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final text = Theme.of(context).textTheme;

    const padding = EdgeInsets.fromLTRB(
      WudgetTokens.space4,
      0,
      WudgetTokens.space4,
      WudgetTokens.space6,
    );

    // An empty period (usually one paged back to, from before the user
    // started tracking) gets its own state rather than a pace ring and a
    // chart with nothing honest to draw — plan/04-ux-design.md, "Pantau,
    // empty period: which period is empty, how to reach one that is not."
    if (totals.expenseMinor == 0 && totals.incomeMinor == 0 && categoryRanks.isEmpty) {
      return ListView(
        padding: padding,
        children: [
          const PeriodSelector(),
          const SizedBox(height: WudgetTokens.space4),
          WudgetCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.event_busy_outlined, size: 26, color: tokens.ink2),
                const SizedBox(height: WudgetTokens.space3),
                Text('Tidak ada catatan di periode ini', style: text.titleLarge),
                const SizedBox(height: WudgetTokens.space2),
                Text(
                  'Geser ke periode lain pakai tanda panah di atas untuk melihat riwayat.',
                  style: text.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      );
    }

    final paceFirst = ref.watch(paceFirstFramingProvider).valueOrNull ?? true;
    final pace = _computePace(period);
    final remaining = totals.incomeMinor - totals.expenseMinor;
    final todayIndex = period.contains(todayDay) ? todayDay - period.startDay : null;

    return ListView(
      padding: padding,
      children: [
        const PeriodSelector(),
        const SizedBox(height: WudgetTokens.space4),
        if (paceFirst) ...[
          _PaceCard(pace: pace),
          const SizedBox(height: WudgetTokens.space3),
          _ForecastCard(
            pace: pace,
            period: period,
            dailyExpense: dailyExpense,
            todayIndex: todayIndex,
          ),
          const SizedBox(height: WudgetTokens.space3),
          // Remaining balance lives behind a tap, not on the hero: the
          // research found leading with it is what drives the "I have money
          // left so I can spend" reading the pace framing exists to avoid.
          _TapRow(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Lihat sisa anggaran',
            onTap: () => _showRemainingBalance(context),
          ),
        ] else ...[
          // The other arm of the framing experiment: remaining first, pace
          // behind the tap. Same data, opposite emphasis.
          WudgetCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SISA PERIODE INI', style: text.labelMedium),
                const SizedBox(height: WudgetTokens.space1),
                AmountText(minor: remaining, style: text.headlineMedium?.copyWith(fontSize: 30)),
              ],
            ),
          ),
          const SizedBox(height: WudgetTokens.space3),
          _TapRow(
            icon: Icons.insights_outlined,
            label: 'Lihat laju & perkiraan',
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (context) => SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(WudgetTokens.space4),
                  child: Column(
                    children: [
                      _PaceCard(pace: pace),
                      const SizedBox(height: WudgetTokens.space3),
                      _ForecastCard(
                        pace: pace,
                        period: period,
                        dailyExpense: dailyExpense,
                        todayIndex: todayIndex,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: WudgetTokens.space5),
        const SectionLabel('Tujuh hari terakhir'),
        WudgetCard(
          child: WeekBarChart(days: weekDays, dailyExpenseMinor: weekExpense),
        ),
        const SizedBox(height: WudgetTokens.space5),
        CategoryRankedList(ranks: categoryRanks),
      ],
    );
  }
}

/// The pace card: ring, the one sentence, the two numbers behind it, and a
/// signed delta against elapsed time. The delta carries an arrow as well as
/// a colour, so over-pace is legible without seeing hue (chart rule 7).
class _PaceCard extends StatelessWidget {
  const _PaceCard({required this.pace});
  final PaceResult pace;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final sentence = pace.sentence((minor) => _formatter.formatCompact(Money.fromMinor(minor, 'IDR')));
    final fraction = pace.spendFractionOfBaseline;
    final deltaPoints =
        fraction == null ? null : ((fraction - pace.elapsedFraction) * 100).round();

    return WudgetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              PaceRing(pace: pace),
              const SizedBox(width: WudgetTokens.space4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('LAJU BELANJA', style: text.labelMedium),
                    const SizedBox(height: WudgetTokens.space1),
                    Text(
                      sentence ?? 'Belum ada periode sebelumnya untuk dibandingkan.',
                      style: text.bodyLarge,
                    ),
                    if (pace.baselineTotalMinor != null) ...[
                      const SizedBox(height: WudgetTokens.space2),
                      Text(
                        '${_formatter.format(Money.fromMinor(pace.spendMinor, 'IDR'))} '
                        'dari ${_formatter.format(Money.fromMinor(pace.baselineTotalMinor!, 'IDR'))} biasanya',
                        style: text.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (deltaPoints != null && deltaPoints.abs() >= 1) ...[
            const SizedBox(height: WudgetTokens.space3),
            InsetNotice(
              icon: deltaPoints > 0 ? Icons.arrow_upward : Icons.arrow_downward,
              message: deltaPoints > 0
                  ? '+$deltaPoints poin di atas waktu berjalan'
                  : '$deltaPoints poin di bawah waktu berjalan',
              tone: deltaPoints > 0 ? NoticeTone.warning : NoticeTone.positive,
            ),
          ],
        ],
      ),
    );
  }
}

/// Actual against forecast. The projection is dashed and labelled, and the
/// heading states the figure in words, because a forecast drawn like a fact
/// is a lie (chart rule 5).
class _ForecastCard extends StatelessWidget {
  const _ForecastCard({
    required this.pace,
    required this.period,
    required this.dailyExpense,
    required this.todayIndex,
  });
  final PaceResult pace;
  final Period period;
  final Map<int, int> dailyExpense;
  final int? todayIndex;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final baseline = pace.baselineTotalMinor;
    final over = baseline == null ? null : pace.forecastTotalMinor - baseline;

    return WudgetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Perkiraan akhir periode', style: text.titleLarge),
              AmountText(minor: pace.forecastTotalMinor, style: text.titleLarge),
            ],
          ),
          const SizedBox(height: WudgetTokens.space1),
          Text(
            switch (over) {
              null => 'Belum ada periode sebelumnya untuk dibandingkan, jadi ini laju kamu sendiri.',
              final o when o > 0 =>
                'Kalau lajunya begini terus, lewat ${_formatter.format(Money.fromMinor(o, 'IDR'))} dari biasanya.',
              final o when o < 0 =>
                'Kalau lajunya begini terus, ${_formatter.format(Money.fromMinor(-o, 'IDR'))} lebih hemat dari biasanya.',
              _ => 'Kalau lajunya begini terus, hasilnya mirip seperti biasanya.',
            },
            style: text.bodyMedium,
          ),
          const SizedBox(height: WudgetTokens.space3),
          ActualForecastChart(
            period: period,
            dailyExpenseMinor: dailyExpense,
            todayIndex: todayIndex,
            forecastTotalMinor: pace.forecastTotalMinor,
            baselineTotalMinor: baseline,
          ),
        ],
      ),
    );
  }
}

class _TapRow extends StatelessWidget {
  const _TapRow({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    return Material(
      color: tokens.surfaceMuted,
      borderRadius: BorderRadius.circular(WudgetTokens.radiusControl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(WudgetTokens.radiusControl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: WudgetTokens.minTapTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: WudgetTokens.space4,
              vertical: WudgetTokens.space3,
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: tokens.ink2),
                const SizedBox(width: WudgetTokens.space3),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 13.5),
                  ),
                ),
                Icon(Icons.chevron_right, size: 18, color: tokens.ink2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The first fourteen days. Not a blank screen: it counts what is being
/// collected, says when the budget proposal arrives, and shows the totals
/// that are already true (design/States.dc.html, "menunggu").
class _WaitingState extends StatelessWidget {
  const _WaitingState({
    required this.daysSoFar,
    required this.totals,
    required this.daysElapsedInPeriod,
  });
  final int daysSoFar;
  final PeriodTotals totals;
  final int daysElapsedInPeriod;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final text = Theme.of(context).textTheme;
    final done = daysSoFar.clamp(0, _waitingDays);
    final remaining = _waitingDays - done;
    final proposalDate = DateTime.now().add(Duration(days: remaining));
    final perDay = daysElapsedInPeriod <= 0 ? 0 : totals.expenseMinor ~/ daysElapsedInPeriod;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        WudgetTokens.space4,
        0,
        WudgetTokens.space4,
        WudgetTokens.space6,
      ),
      children: [
        WudgetCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$done',
                    style: text.headlineMedium?.copyWith(
                      fontSize: 34,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: WudgetTokens.space2),
                  Text('dari $_waitingDays hari', style: text.titleSmall),
                ],
              ),
              const SizedBox(height: WudgetTokens.space3),
              // One segment per day, so progress is countable rather than a
              // percentage nobody can check.
              Row(
                children: [
                  for (var i = 0; i < _waitingDays; i++) ...[
                    if (i > 0) const SizedBox(width: 3),
                    Expanded(
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: i < done ? tokens.accent : tokens.surfaceMuted,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: WudgetTokens.space4),
              Text(
                done <= 0 ? 'Belum ada yang bisa dibaca' : 'Masih ngumpulin kebiasaanmu',
                style: text.titleLarge,
              ),
              const SizedBox(height: WudgetTokens.space2),
              Text(
                done <= 0
                    ? 'Catat beberapa hari dulu. Anggaran yang bagus datang dari '
                        'data, bukan tebakan, jadi Pantau menunggu sampai ada yang jujur dibaca.'
                    : 'Anggaran yang bagus datang dari data, bukan tebakan. '
                        '$remaining hari lagi wudget bisa mengusulkan angka dari belanjamu sendiri.',
                style: text.bodyMedium,
              ),
              const SizedBox(height: WudgetTokens.space3),
              InsetNotice(
                icon: Icons.calendar_month_outlined,
                message: 'Usulan anggaran: ${DateFormat('d MMM', 'id_ID').format(proposalDate)}',
              ),
            ],
          ),
        ),
        if (totals.expenseMinor > 0) ...[
          const SizedBox(height: WudgetTokens.space5),
          const SectionLabel('Sementara ini'),
          CardGroup(
            dividerIndent: WudgetTokens.space3,
            children: [
              CardRow(
                title: 'Keluar periode ini',
                trailing: AmountText(minor: totals.expenseMinor),
              ),
              CardRow(
                title: 'Rata-rata per hari',
                subtitle: 'Dibagi $daysElapsedInPeriod hari yang sudah jalan',
                trailing: AmountText(minor: perDay),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
