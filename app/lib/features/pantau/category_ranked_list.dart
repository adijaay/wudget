import 'package:flutter/material.dart';

import '../../core/money.dart';
import '../../core/money_formatter.dart';
import '../../data/category_rank_queries.dart';
import '../../design/tokens.dart';

const _formatter = MoneyFormatter();

/// Chart rule 4: "a ranked list beats a second pie" — amount, share of the
/// period's total, and transaction count together, plan/04-ux-design.md.
class CategoryRankedList extends StatelessWidget {
  const CategoryRankedList({super.key, required this.ranks});
  final List<CategoryRank> ranks;

  @override
  Widget build(BuildContext context) {
    if (ranks.isEmpty) {
      return const Text('Belum ada pengeluaran berkategori periode ini.');
    }
    final total = ranks.fold<int>(0, (a, r) => a + r.amountMinor);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Kategori', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: WudgetTokens.space2),
        for (final rank in ranks) _CategoryRankRow(rank: rank, shareOfTotal: total == 0 ? 0 : rank.amountMinor / total),
      ],
    );
  }
}

class _CategoryRankRow extends StatelessWidget {
  const _CategoryRankRow({required this.rank, required this.shareOfTotal});
  final CategoryRank rank;
  final num shareOfTotal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: WudgetTokens.space1),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text('${rank.name} · ${rank.count}x'),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatter.format(Money.fromMinor(rank.amountMinor, 'IDR')),
              textAlign: TextAlign.right,
            ),
          ),
          SizedBox(
            width: 48,
            child: Text(
              '${(shareOfTotal * 100).round()}%',
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
