import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../core/money_formatter.dart';
import '../../core/providers.dart';
import '../../data/category_rank_queries.dart';
import '../../data/feature_flags_repository.dart';
import '../../data/period_aggregate_queries.dart';
import '../../design/tokens.dart';
import '../../domain/pace.dart';
import '../../domain/period.dart';
import '../budget/budget_screen.dart';
import '../period/period_selector.dart';
import '../recurring/recurring_screen.dart';
import 'actual_forecast_chart.dart';
import 'category_ranked_list.dart';
import 'pace_ring.dart';
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
/// Sprint 11.
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
  }

  Future<void> _load() async {
    final queries = ref.read(periodAggregateQueriesProvider);
    final period = ref.read(currentPeriodProvider);
    final today = _todayDayBucket();

    final firstDay = await queries.firstTransactionDay();
    final totals = await queries.totalsFor(period);
    final daily = await queries.dailyExpenseMinor(period);
    final baseline = await queries.previousPeriodBaselineExpenseMinor(period);
    final ranks = await ref.read(categoryRankQueriesProvider).rankedSpend(period.startDay, period.endDayExclusive);
    final weekDays = List<int>.generate(7, (i) => today - 6 + i);
    final weekExpense = await queries.dailyExpenseMinorInRange(weekDays.first, today + 1);

    final paceFirst = await ref.read(featureFlagsRepositoryProvider).getBool(paceFirstFlagKey, defaultValue: true);
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final todayDay = _todayDayBucket();
    final daysSinceFirst = _firstDay == null ? 0 : todayDay - _firstDay! + 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pantau'),
        actions: [
          IconButton(
            icon: const Icon(Icons.event_repeat),
            tooltip: 'Berulang & Tagihan',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RecurringScreen()),
            ),
          ),
          if (daysSinceFirst >= _waitingDays)
            IconButton(
              icon: const Icon(Icons.pie_chart_outline),
              tooltip: 'Anggaran',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BudgetScreen()),
              ),
            ),
        ],
      ),
      body: daysSinceFirst < _waitingDays
          ? _WaitingState(daysSoFar: daysSinceFirst)
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

  void _showPaceDetails(BuildContext context, Period period, PaceResult pace) {
    final todayIndex = period.contains(todayDay) ? todayDay - period.startDay : null;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(WudgetTokens.space5),
        child: SingleChildScrollView(
          child: _PaceDetails(pace: pace, period: period, todayIndex: todayIndex, dailyExpense: dailyExpense),
        ),
      ),
    );
  }

  void _showRemainingBalance(BuildContext context) {
    final remaining = totals.incomeMinor - totals.expenseMinor;
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(WudgetTokens.space5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Sisa periode ini', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: WudgetTokens.space2),
            Text(
              _formatter.format(Money.fromMinor(remaining, 'IDR')),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: WudgetTokens.space2),
            Text(
              'Pemasukan dikurangi pengeluaran periode ini, bukan target.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(currentPeriodProvider);
    final paceFirst = ref.watch(paceFirstFramingProvider).valueOrNull ?? true;
    final pace = _computePace(period);
    final remaining = totals.incomeMinor - totals.expenseMinor;
    final todayIndex = period.contains(todayDay) ? todayDay - period.startDay : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(WudgetTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PeriodSelector(),
          const SizedBox(height: WudgetTokens.space5),
          if (paceFirst) ...[
            _PaceDetails(pace: pace, period: period, todayIndex: todayIndex, dailyExpense: dailyExpense),
            const SizedBox(height: WudgetTokens.space2),
            Center(
              child: TextButton(
                onPressed: () => _showRemainingBalance(context),
                child: const Text('Lihat sisa saldo periode ini'),
              ),
            ),
          ] else ...[
            Center(
              child: Column(
                children: [
                  Text('Sisa periode ini', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: WudgetTokens.space2),
                  Text(
                    _formatter.format(Money.fromMinor(remaining, 'IDR')),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: WudgetTokens.space2),
            Center(
              child: TextButton(
                onPressed: () => _showPaceDetails(context, period, pace),
                child: const Text('Lihat laju & perkiraan'),
              ),
            ),
          ],
          const SizedBox(height: WudgetTokens.space5),
          WeekBarChart(days: weekDays, dailyExpenseMinor: weekExpense),
          const SizedBox(height: WudgetTokens.space5),
          CategoryRankedList(ranks: categoryRanks),
        ],
      ),
    );
  }
}

class _PaceDetails extends StatelessWidget {
  const _PaceDetails({required this.pace, required this.period, required this.todayIndex, required this.dailyExpense});
  final PaceResult pace;
  final Period period;
  final int? todayIndex;
  final Map<int, int> dailyExpense;

  @override
  Widget build(BuildContext context) {
    final sentence = pace.sentence((minor) => _formatter.formatCompact(Money.fromMinor(minor, 'IDR')));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: PaceRing(pace: pace)),
        const SizedBox(height: WudgetTokens.space4),
        Text(
          sentence ?? 'Belum ada periode sebelumnya untuk dibandingkan.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: WudgetTokens.space5),
        ActualForecastChart(
          period: period,
          dailyExpenseMinor: dailyExpense,
          todayIndex: todayIndex,
          forecastTotalMinor: pace.forecastTotalMinor,
        ),
      ],
    );
  }
}

class _WaitingState extends StatelessWidget {
  const _WaitingState({required this.daysSoFar});
  final int daysSoFar;

  @override
  Widget build(BuildContext context) {
    final remaining = _waitingDays - daysSoFar;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(WudgetTokens.space5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.hourglass_top, size: 48),
            const SizedBox(height: WudgetTokens.space4),
            Text(
              daysSoFar <= 0
                  ? 'Catat dulu beberapa hari, Pantau butuh riwayat nyata untuk bicara jujur.'
                  : '$remaining hari lagi sebelum Pantau punya cukup riwayat untuk bicara jujur.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
