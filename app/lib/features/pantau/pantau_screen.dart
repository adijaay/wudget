import 'dart:async';

import 'package:drift/drift.dart' show TableUpdateQuery;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/perf.dart';
import '../../core/money.dart';
import '../../core/money_formatter.dart';
import '../../core/providers.dart';
import '../../data/category_rank_queries.dart';
import '../../data/feature_flags_repository.dart';
import '../../data/period_aggregate_queries.dart';
import '../../design/components.dart';
import '../../design/tokens.dart';
import '../../domain/flow.dart';
import '../../domain/pace.dart';
import '../../domain/period.dart';
import '../../domain/period_close.dart';
import '../../domain/pola.dart';
import '../period/period_selector.dart';
import 'actual_forecast_chart.dart';
import 'aliran_view.dart';
import 'category_ranked_list.dart';
import 'month_compare_chart.dart';
import 'pace_ring.dart';
import 'period_close_sheet.dart';
import 'pola_view.dart';
import 'week_bar_chart.dart';

const _formatter = MoneyFormatter();
const _waitingDays = 14;
final _monthLabel = DateFormat('MMM yyyy', 'id_ID');

/// How far back the weekday averages look. Clamped to the user's first
/// transaction, so a three-week-old install never reports a Sunday average
/// diluted by weeks it was not installed for.
const _weekdayWindowDays = 90;

/// Pantau's three views. "Bulan ini" answers how this period is going,
/// "Pola" when money goes out, "Aliran" where a finished period's money
/// went — plan/04-ux-design.md keeps them on one tab because they are
/// three questions about the same period, not three destinations.
enum PantauView { bulanIni, pola, aliran }

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
  PolaData? _pola;
  AliranData? _aliran;
  PantauView _view = PantauView.bulanIni;
  bool _loaded = false;

  StreamSubscription<void>? _txChangesSubscription;

  @override
  void initState() {
    super.initState();
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPeriodClose());

    // HomeShell keeps every tab alive in an IndexedStack, so this load runs
    // once per app session and never again on a tab switch. Without this,
    // recording an expense from the capture button left Pantau still saying
    // "0 dari 14 hari" with the transaction already in the ledger. Same
    // root cause as the Catat staleness fixed earlier.
    final db = ref.read(databaseProvider);
    _txChangesSubscription = db
        .tableUpdates(TableUpdateQuery.onTable(db.transactions))
        .listen((_) => _load());
  }

  @override
  void dispose() {
    _txChangesSubscription?.cancel();
    super.dispose();
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


  /// Pola and Aliran cost four extra period-bounded reads, so they load on
  /// first open of their segment rather than with the screen.
  ///
  /// Loading all three together took pantau_render from 596ms to 1043ms in
  /// the test runner, for two views a session may never open. Cleared by
  /// [_load], so a recorded transaction or a period change reloads them the
  /// next time they are shown.
  Future<void> _loadSecondaryViews() async {
    final totals = _totals;
    if (totals == null) return;

    final queries = ref.read(periodAggregateQueriesProvider);
    final period = ref.read(currentPeriodProvider);
    final today = todayDayBucket();
    final firstDay = _firstDay;
    final daily = _dailyExpense;
    final ranks = _categoryRanks;

    final totalDays = period.endDayExclusive - period.startDay;
    final daysElapsed = (today - period.startDay + 1).clamp(1, totalDays);
    final isClosed = period.endDayExclusive <= today;

    final weekdayStart = firstDay == null
        ? today
        : (today - _weekdayWindowDays + 1 < firstDay ? firstDay : today - _weekdayWindowDays + 1);
    final weekdayExpense = await queries.dailyExpenseMinorInRange(weekdayStart, today + 1);
    final largest = await queries.largestExpenses(period, limit: 3);

    // A period that starts before the user's first transaction would show
    // an artificially low bar, so it is left out entirely rather than
    // drawn small — the same rule the pace baseline already follows.
    final months = <MonthTotal>[];
    for (final earlier in [period.previous.previous, period.previous]) {
      if (firstDay == null || earlier.startDay < firstDay) continue;
      months.add(MonthTotal(
        label: _monthLabel.format(earlier.startDate),
        totalMinor: (await queries.totalsFor(earlier)).expenseMinor,
      ));
    }
    months.add(MonthTotal(
      label: _monthLabel.format(period.startDate),
      totalMinor: isClosed
          ? totals.expenseMinor
          : computePace(
              daysElapsed: daysElapsed,
              totalDaysInPeriod: totalDays,
              spendMinor: totals.expenseMinor,
              baselineTotalMinor: null,
            ).forecastTotalMinor,
      isForecast: !isClosed,
    ));

    final polaData = PolaData(
      period: period,
      todayDay: today,
      dailyExpense: daily,
      transactionCount: ranks.fold<int>(0, (sum, r) => sum + r.count),
      expenseMinor: totals.expenseMinor,
      weekdayPattern: computeWeekdayPattern(
        dailyExpenseMinor: weekdayExpense,
        sinceDayInclusive: weekdayStart,
        untilDayExclusive: today + 1,
      ),
      weekdayWindowDays: today + 1 - weekdayStart,
      months: months,
      largestExpenses: largest,
    );

    // The previous period is only read when there is a closed period to
    // compare it against, so the common case pays for one query less.
    final previousRanks = isClosed
        ? await ref
            .read(categoryRankQueriesProvider)
            .rankedSpend(period.previous.startDay, period.previous.endDayExclusive)
        : const <CategoryRank>[];

    final aliranData = AliranData(
      isPeriodRunning: !isClosed,
      flow: !isClosed
          ? null
          : buildFlowBreakdown(
              incomeMinor: totals.incomeMinor,
              expenseMinor: totals.expenseMinor,
              ranks: [
                for (final r in ranks)
                  (name: r.name, amountMinor: r.amountMinor, hueIndex: r.hueIndex)
              ],
            ),
      deltas: !isClosed
          ? const []
          : buildCategoryDeltas(
              current: [
                for (final r in ranks)
                  (key: r.key, name: r.name, amountMinor: r.amountMinor, hueIndex: r.hueIndex)
              ],
              previous: [
                for (final r in previousRanks)
                  (key: r.key, name: r.name, amountMinor: r.amountMinor, hueIndex: r.hueIndex)
              ],
            ),
      previousLabel: _monthLabel.format(period.previous.startDate),
    );


    if (!mounted) return;
    setState(() {
      _pola = polaData;
      _aliran = aliranData;
    });
  }

  Future<void> _load() async {
    final render = Stopwatch()..start();
    final queries = ref.read(periodAggregateQueriesProvider);
    final period = ref.read(currentPeriodProvider);
    final today = todayDayBucket();

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
      // Stale the moment the underlying period data changes.
      _pola = null;
      _aliran = null;
      _loaded = true;
    });
    perfMark('pantau_render', render);
    if (_view != PantauView.bulanIni) unawaited(_loadSecondaryViews());
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

    final todayDay = todayDayBucket();
    final daysSinceFirst = _firstDay == null ? 0 : todayDay - _firstDay! + 1;
    final period = ref.watch(currentPeriodProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pantau')),
      // The segment appears only once there is enough history for all
      // three views to say something. During the first fortnight two of
      // them would be empty states, which is a worse first run than not
      // offering them yet.
      body: daysSinceFirst < _waitingDays
          ? _WaitingState(
              daysSoFar: daysSinceFirst,
              totals: _totals!,
              daysElapsedInPeriod: (todayDay - period.startDay + 1)
                  .clamp(1, period.endDayExclusive - period.startDay),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    WudgetTokens.space4,
                    0,
                    WudgetTokens.space4,
                    WudgetTokens.space3,
                  ),
                  child: SegmentedTray<PantauView>(
                    segments: const {
                      PantauView.bulanIni: 'Bulan ini',
                      PantauView.pola: 'Pola',
                      PantauView.aliran: 'Aliran',
                    },
                    value: _view,
                    onChanged: (view) {
                      setState(() => _view = view);
                      if (view != PantauView.bulanIni && _pola == null) {
                        unawaited(_loadSecondaryViews());
                      }
                    },
                  ),
                ),
                Expanded(
                  child: switch (_view) {
                    PantauView.bulanIni => _ReviewBody(
                        totals: _totals!,
                        dailyExpense: _dailyExpense,
                        baselineExpenseMinor: _baselineExpenseMinor,
                        todayDay: todayDay,
                        categoryRanks: _categoryRanks,
                        weekDays: _weekDays,
                        weekExpense: _weekExpense,
                      ),
                    PantauView.pola => _pola == null
                        ? const Center(child: CircularProgressIndicator())
                        : PolaView(data: _pola!),
                    PantauView.aliran => _aliran == null
                        ? const Center(child: CircularProgressIndicator())
                        : AliranView(data: _aliran!),
                  },
                ),
              ],
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
