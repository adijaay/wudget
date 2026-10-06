import 'package:flutter/material.dart';

import '../../core/money.dart';
import '../../core/money_formatter.dart';
import '../../design/components.dart';
import '../../design/tokens.dart';

const _formatter = MoneyFormatter();

/// One bar of the month comparison.
class MonthTotal {
  const MonthTotal({required this.label, required this.totalMinor, this.isForecast = false});
  final String label;
  final int totalMinor;

  /// A forecast bar is drawn as a dashed outline and labelled, never
  /// filled like a month that actually finished — chart rule 5.
  final bool isForecast;
}

/// Total spend for the last few periods side by side, with the running one
/// shown as a forecast rather than as a fact.
///
/// Every bar carries its own value label, so the comparison does not
/// depend on judging bar heights by eye. Values use the compact form and
/// the view prints at least one full amount alongside, per DESIGN.md's
/// abbreviation rule.
class MonthCompareChart extends StatelessWidget {
  const MonthCompareChart({super.key, required this.months});

  final List<MonthTotal> months;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final text = Theme.of(context).textTheme;
    final maxValue = months.fold<int>(0, (a, m) => a > m.totalMinor ? a : m.totalMinor);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 132,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final month in months)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: WudgetTokens.space2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // The label sizes itself first and the bar takes
                        // what is left, so a larger text scale shortens the
                        // bar instead of clipping the number above it.
                        Text(
                          _formatter.formatCompact(Money.fromMinor(month.totalMinor, 'IDR')),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.visible,
                          style: text.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: month.isForecast ? tokens.ink2 : tokens.ink1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              // See the note in weekday_bar_chart.dart: the
                              // width factor is what stops a bar with no
                              // intrinsic size collapsing to nothing.
                              widthFactor: 1,
                              heightFactor: maxValue == 0 ? 0 : month.totalMinor / maxValue,
                              child: month.isForecast
                                  ? CustomPaint(
                                      painter: DashedBorderPainter(
                                        color: tokens.accent,
                                        radius: 6,
                                        strokeWidth: 1.6,
                                      ),
                                    )
                                  : DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: Color.lerp(
                                          tokens.surfaceMuted,
                                          tokens.accent,
                                          month == months.last ? 0.62 : 0.4,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: WudgetTokens.space1),
        Row(
          children: [
            for (final month in months)
              Expanded(
                child: Text(
                  month.label,
                  textAlign: TextAlign.center,
                  style: text.labelSmall?.copyWith(color: tokens.ink2),
                ),
              ),
          ],
        ),
        if (months.any((m) => m.isForecast)) ...[
          const SizedBox(height: WudgetTokens.space2),
          Row(
            children: [
              SizedBox(
                width: 18,
                height: 6,
                child: CustomPaint(
                  painter: DashedBorderPainter(color: tokens.accent, radius: 2, strokeWidth: 1.6),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Perkiraan, belum terjadi',
                style: text.labelSmall?.copyWith(color: tokens.ink2),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
