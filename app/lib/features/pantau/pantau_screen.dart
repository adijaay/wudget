import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../core/money_formatter.dart';
import '../../core/providers.dart';
import '../../data/period_aggregate_queries.dart';
import '../../design/tokens.dart';
import '../period/period_selector.dart';

const _formatter = MoneyFormatter();
const _waitingDays = 14;

/// Pantau: the review surface. This sprint is the shell only — the pace
/// ring and forecast are Sprint 9. See plan/05-sprints.md Sprint 8, "the
/// honest first-14-days waiting state": no insight is shown before the
/// user has two weeks of real data to draw one from
/// (research/06-implications.md).
class PantauScreen extends ConsumerStatefulWidget {
  const PantauScreen({super.key});

  @override
  ConsumerState<PantauScreen> createState() => _PantauScreenState();
}

class _PantauScreenState extends ConsumerState<PantauScreen> {
  int? _firstDay;
  PeriodTotals? _totals;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final queries = ref.read(periodAggregateQueriesProvider);
    final firstDay = await queries.firstTransactionDay();
    final totals = await queries.totalsFor(ref.read(currentPeriodProvider));
    if (!mounted) return;
    setState(() {
      _firstDay = firstDay;
      _totals = totals;
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

    final today = DateTime.now();
    final todayDay = DateTime.utc(today.year, today.month, today.day).difference(DateTime.utc(1970, 1, 1)).inDays;
    final daysSinceFirst = _firstDay == null ? 0 : todayDay - _firstDay! + 1;

    return Scaffold(
      appBar: AppBar(title: const Text('Pantau')),
      body: daysSinceFirst < _waitingDays
          ? _WaitingState(daysSoFar: daysSinceFirst)
          : Padding(
              padding: const EdgeInsets.all(WudgetTokens.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const PeriodSelector(),
                  const SizedBox(height: WudgetTokens.space5),
                  _TotalRow(label: 'Pengeluaran', minor: _totals!.expenseMinor),
                  const SizedBox(height: WudgetTokens.space3),
                  _TotalRow(label: 'Pemasukan', minor: _totals!.incomeMinor),
                ],
              ),
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

class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.label, required this.minor});
  final String label;
  final int minor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyLarge),
        Text(
          _formatter.format(Money.fromMinor(minor, 'IDR')),
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}
