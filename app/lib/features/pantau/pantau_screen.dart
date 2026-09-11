import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../core/money_formatter.dart';
import '../../core/providers.dart';
import '../../data/period_aggregate_queries.dart';
import '../../design/tokens.dart';
import '../../domain/pace.dart';
import '../period/period_selector.dart';
import 'actual_forecast_chart.dart';
import 'pace_ring.dart';

const _formatter = MoneyFormatter();
const _waitingDays = 14;

int _todayDayBucket() {
  final now = DateTime.now();
  return DateTime.utc(now.year, now.month, now.day).difference(DateTime.utc(1970, 1, 1)).inDays;
}

/// Pantau: the review surface. Leads with pace against elapsed time and a
/// forecast, not the remaining balance — plan/01-features.md, "Pace and
/// forecast, instead of remaining balance". See plan/05-sprints.md Sprint 9.
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
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final queries = ref.read(periodAggregateQueriesProvider);
    final period = ref.read(currentPeriodProvider);
    final firstDay = await queries.firstTransactionDay();
    final totals = await queries.totalsFor(period);
    final daily = await queries.dailyExpenseMinor(period);
    final baseline = await queries.previousPeriodBaselineExpenseMinor(period);
    if (!mounted) return;
    setState(() {
      _firstDay = firstDay;
      _totals = totals;
      _dailyExpense = daily;
      _baselineExpenseMinor = baseline;
      _loaded = true;
    });
  }

  void _showRemainingBalance(BuildContext context) {
    final totals = _totals!;
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
      appBar: AppBar(title: const Text('Pantau')),
      body: daysSinceFirst < _waitingDays
          ? _WaitingState(daysSoFar: daysSinceFirst)
          : _PaceBody(
              totals: _totals!,
              dailyExpense: _dailyExpense,
              baselineExpenseMinor: _baselineExpenseMinor,
              todayDay: todayDay,
              onTapRemaining: () => _showRemainingBalance(context),
            ),
    );
  }
}

class _PaceBody extends ConsumerWidget {
  const _PaceBody({
    required this.totals,
    required this.dailyExpense,
    required this.baselineExpenseMinor,
    required this.todayDay,
    required this.onTapRemaining,
  });

  final PeriodTotals totals;
  final Map<int, int> dailyExpense;
  final int? baselineExpenseMinor;
  final int todayDay;
  final VoidCallback onTapRemaining;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(currentPeriodProvider);
    final totalDays = period.endDayExclusive - period.startDay;
    final daysElapsed = (todayDay - period.startDay + 1).clamp(1, totalDays);
    final pace = computePace(
      daysElapsed: daysElapsed,
      totalDaysInPeriod: totalDays,
      spendMinor: totals.expenseMinor,
      baselineTotalMinor: baselineExpenseMinor,
    );
    final todayIndex = period.contains(todayDay) ? todayDay - period.startDay : null;
    final sentence = pace.sentence((minor) => _formatter.formatCompact(Money.fromMinor(minor, 'IDR')));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(WudgetTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PeriodSelector(),
          const SizedBox(height: WudgetTokens.space5),
          Center(child: PaceRing(pace: pace)),
          const SizedBox(height: WudgetTokens.space4),
          Text(
            sentence ?? 'Belum ada periode sebelumnya untuk dibandingkan.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: WudgetTokens.space2),
          Center(
            child: TextButton(
              onPressed: onTapRemaining,
              child: const Text('Lihat sisa saldo periode ini'),
            ),
          ),
          const SizedBox(height: WudgetTokens.space5),
          ActualForecastChart(
            period: period,
            dailyExpenseMinor: dailyExpense,
            todayIndex: todayIndex,
            forecastTotalMinor: pace.forecastTotalMinor,
          ),
        ],
      ),
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
