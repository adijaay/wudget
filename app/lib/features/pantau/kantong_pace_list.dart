import 'package:flutter/material.dart';

import '../../core/money.dart';
import '../../core/money_formatter.dart';
import '../../design/components.dart';
import '../../design/tokens.dart';
import '../../domain/pace.dart';

const _formatter = MoneyFormatter();
String _full(int minor) => _formatter.format(Money.fromMinor(minor, 'IDR'));
String _compact(int minor) => _formatter.formatCompact(Money.fromMinor(minor, 'IDR'));

/// Kantong in the order [sortKantongByPace] gives. Over-pace rows carry the
/// warning colour and their spent share as a number, never colour alone.
class KantongPaceList extends StatelessWidget {
  const KantongPaceList({super.key, required this.sorted});
  final List<KantongPace> sorted;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final text = Theme.of(context).textTheme;

    return WudgetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Kantong, yang paling perlu dilihat di atas', style: text.labelMedium),
          for (final k in sorted) ...[
            const SizedBox(height: WudgetTokens.space3),
            // Read as one sentence: "688rb / 800rb" and a bare bar mean little aloud.
            Semantics(
              container: true,
              excludeSemantics: true,
              label: '${k.kantong.name}, ${_full(k.kantong.spentMinor)} dari ${_full(k.kantong.planMinor)}'
                  '${k.isAhead ? ', ${(k.spentShare * 100).round()} persen, lebih cepat dari waktunya' : ''}',
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: tokens.hueFor(k.kantong.hueIndex),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: WudgetTokens.space2),
                    // Wraps the numbers under the name when large text leaves no room.
                    Expanded(
                      child: Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: WudgetTokens.space2,
                        children: [
                          Text(k.kantong.name, style: text.titleSmall),
                          Wrap(spacing: WudgetTokens.space2, children: [
                            if (k.isAhead)
                              Text(
                                '${(k.spentShare * 100).round()}%',
                                style: text.titleSmall?.copyWith(color: tokens.warning),
                              ),
                            Text(
                              '${_compact(k.kantong.spentMinor)} / ${_compact(k.kantong.planMinor)}',
                              style: text.bodySmall?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                            ),
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: k.spentShare.clamp(0, 1).toDouble(),
                    minHeight: 10,
                    backgroundColor: tokens.surfaceMuted,
                    color: k.isAhead ? tokens.warning : tokens.accent,
                  ),
                ),
              ]),
            ),
          ],
        ],
      ),
    );
  }
}
