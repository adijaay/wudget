import 'package:flutter/material.dart';

import '../../data/category_rank_queries.dart';
import '../../design/components.dart';
import '../../design/tokens.dart';

/// Chart rule 4: "a ranked list beats a second pie". Rank, the category's
/// own hue as a small square, the transaction count and share, and the
/// amount — the four things a person actually asks of a spending breakdown,
/// per design/Pantau.dc.html.
class CategoryRankedList extends StatelessWidget {
  const CategoryRankedList({super.key, required this.ranks, this.limit = 4});
  final List<CategoryRank> ranks;

  /// Top N, with the rest folded into one "Lainnya" row rather than a long
  /// tail nobody reads (chart rule 2's five-segment cap, same idea).
  final int limit;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    if (ranks.isEmpty) {
      return WudgetCard(
        child: Text(
          'Belum ada pengeluaran berkategori di periode ini.',
          style: text.bodyMedium,
        ),
      );
    }

    final total = ranks.fold<int>(0, (a, r) => a + r.amountMinor);
    final shown = ranks.take(limit).toList();
    final restAmount = ranks.skip(limit).fold<int>(0, (a, r) => a + r.amountMinor);
    final restCount = ranks.skip(limit).fold<int>(0, (a, r) => a + r.count);

    return WudgetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Paling banyak keluar', style: text.titleLarge),
              Text(
                ranks.length > limit ? 'Kategori · Top $limit' : 'Kategori',
                style: text.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: WudgetTokens.space3),
          for (var i = 0; i < shown.length; i++)
            _RankRow(
              rank: i + 1,
              hueIndex: shown[i].hueIndex,
              name: shown[i].name,
              count: shown[i].count,
              amountMinor: shown[i].amountMinor,
              share: total == 0 ? 0 : shown[i].amountMinor / total,
            ),
          if (restAmount > 0)
            _RankRow(
              rank: limit + 1,
              hueIndex: null,
              name: 'Kategori lainnya',
              count: restCount,
              amountMinor: restAmount,
              share: total == 0 ? 0 : restAmount / total,
            ),
        ],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.rank,
    required this.hueIndex,
    required this.name,
    required this.count,
    required this.amountMinor,
    required this.share,
  });
  final int rank;
  final int? hueIndex;
  final String name;
  final int count;
  final int amountMinor;
  final num share;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: WudgetTokens.space3),
      child: Row(
        children: [
          SizedBox(
            width: 14,
            child: Text(
              '$rank',
              style: text.bodySmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: WudgetTokens.space2),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: hueIndex == null ? tokens.ink3 : tokens.hueFor(hueIndex!),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: WudgetTokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: text.titleSmall?.copyWith(fontSize: 13.5)),
                const SizedBox(height: 1),
                // The count and the share together, because an amount alone
                // does not say whether it was one big purchase or forty
                // small ones.
                Text('$count transaksi · ${(share * 100).round()}%', style: text.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: WudgetTokens.space2),
          AmountText(
            minor: amountMinor,
            showSymbol: false,
            style: text.titleSmall?.copyWith(fontSize: 13.5),
          ),
        ],
      ),
    );
  }
}
