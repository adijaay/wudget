import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../core/money_formatter.dart';
import '../../core/providers.dart';
import '../../data/budget_history_queries.dart';
import '../../design/tokens.dart';
import '../../domain/budget_proposal.dart';

const _formatter = MoneyFormatter();
const _lookbackDays = 28;

int _todayDayBucket() {
  final now = DateTime.now();
  return DateTime.utc(now.year, now.month, now.day).difference(DateTime.utc(1970, 1, 1)).inDays;
}

class _BudgetRow {
  _BudgetRow({required this.key, required this.name, required this.amountMinor, required this.spentMinor});
  final String key;
  final String name;
  final int amountMinor;
  final int spentMinor;
}

/// Budget review and edit: every row starts pre-filled from
/// [proposeBudgets], the user edits rather than authors — plan/05-sprints.md
/// Sprint 10. A category with no spend history in the lookback window (and
/// no budget already saved) has nothing honest to propose, so it simply
/// isn't a row — "no user is ever shown a blank budget field" means never
/// shown blank, not shown blank-then-filled.
class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  List<_BudgetRow>? _rows;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final period = ref.read(currentPeriodProvider);
    final periodLengthDays = period.endDayExclusive - period.startDay;
    final today = _todayDayBucket();

    final aggregateQueries = ref.read(periodAggregateQueriesProvider);
    final historyQueries = ref.read(budgetHistoryQueriesProvider);
    final budgetsRepo = ref.read(budgetsRepositoryProvider);

    final firstDay = await aggregateQueries.firstTransactionDay();
    final sinceDay = firstDay == null ? today + 1 : (firstDay > today - _lookbackDays + 1 ? firstDay : today - _lookbackDays + 1);
    final historyWindowDays = firstDay == null ? 0 : today - sinceDay + 1;

    final lookbackSpend = firstDay == null ? <String, int>{} : await historyQueries.categorySpendByKey(sinceDay, today + 1);
    final proposals = proposeBudgets(
      spendByKey: lookbackSpend,
      historyWindowDays: historyWindowDays,
      periodLengthDays: periodLengthDays,
    );
    final saved = await budgetsRepo.getAll();
    final currentSpend = await historyQueries.categorySpendByKey(period.startDay, period.endDayExclusive);

    final keys = {...proposals.keys, ...saved.keys}.toList()
      ..sort((a, b) {
        if (a == irregularBudgetKey) return 1;
        if (b == irregularBudgetKey) return -1;
        return 0;
      });

    final rows = <_BudgetRow>[];
    for (final key in keys) {
      rows.add(_BudgetRow(
        key: key,
        name: await historyQueries.displayNameFor(key),
        amountMinor: saved[key] ?? proposals[key]!,
        spentMinor: currentSpend[key] ?? 0,
      ));
    }

    if (!mounted) return;
    setState(() => _rows = rows);
  }

  Future<void> _save(String key, int amountMinor) async {
    await ref.read(budgetsRepositoryProvider).setAmount(key, amountMinor);
    setState(() {
      _rows = _rows!
          .map((r) => r.key == key ? _BudgetRow(key: r.key, name: r.name, amountMinor: amountMinor, spentMinor: r.spentMinor) : r)
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows;
    return Scaffold(
      appBar: AppBar(title: const Text('Anggaran')),
      body: rows == null
          ? const Center(child: CircularProgressIndicator())
          : rows.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(WudgetTokens.space5),
                    child: Text(
                      'Belum ada riwayat pengeluaran untuk diusulkan sebagai anggaran.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(WudgetTokens.space4),
                  itemCount: rows.length,
                  itemBuilder: (context, index) => _BudgetRowTile(
                    row: rows[index],
                    onSave: (minor) => _save(rows[index].key, minor),
                  ),
                ),
    );
  }
}

class _BudgetRowTile extends StatelessWidget {
  const _BudgetRowTile({required this.row, required this.onSave});
  final _BudgetRow row;
  final ValueChanged<int> onSave;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final over = row.amountMinor > 0 && row.spentMinor > row.amountMinor;
    final fraction = row.amountMinor <= 0 ? 0.0 : row.spentMinor / row.amountMinor;
    final controller = TextEditingController(text: row.amountMinor.toString());

    return Card(
      margin: const EdgeInsets.only(bottom: WudgetTokens.space3),
      child: Padding(
        padding: const EdgeInsets.all(WudgetTokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(row.name, style: Theme.of(context).textTheme.titleMedium),
                ),
                if (over) ...[
                  Icon(Icons.warning_amber_rounded, color: tokens.negative, size: 18),
                  const SizedBox(width: WudgetTokens.space1),
                  Text('Lebih dari anggaran', style: TextStyle(color: tokens.negative)),
                ],
              ],
            ),
            const SizedBox(height: WudgetTokens.space2),
            Text(
              '${_formatter.format(Money.fromMinor(row.spentMinor, 'IDR'))} terpakai',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: WudgetTokens.space2),
            ClipRRect(
              borderRadius: BorderRadius.circular(WudgetTokens.radiusControl),
              child: LinearProgressIndicator(
                value: fraction.clamp(0.0, 1.0),
                minHeight: 8,
                color: over ? tokens.negative : tokens.accent,
                backgroundColor: tokens.ink3.withOpacity(0.2),
              ),
            ),
            const SizedBox(height: WudgetTokens.space3),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Anggaran (Rp)', isDense: true),
              onSubmitted: (v) {
                final minor = int.tryParse(v);
                if (minor != null && minor >= 0) onSave(minor);
              },
            ),
          ],
        ),
      ),
    );
  }
}
