import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/money.dart';
import '../../core/money_formatter.dart';
import '../../design/tokens.dart';

const _formatter = MoneyFormatter();
final _dayLabel = DateFormat('EEE', 'id_ID');

/// Daily expense for the trailing 7 days, one bar per day, per
/// plan/04-ux-design.md's allowed v1 charts ("the daily bar for a week").
/// Axis labelled with the day and, on the tallest bar, the amount — chart
/// rule 9.
class WeekBarChart extends StatelessWidget {
  const WeekBarChart({super.key, required this.days, required this.dailyExpenseMinor});

  /// The 7 day buckets to show, oldest first.
  final List<int> days;
  final Map<int, int> dailyExpenseMinor;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final values = [for (final d in days) dailyExpenseMinor[d] ?? 0];
    final maxValue = values.fold<int>(0, (a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // No title of its own: the section label above the card says what
        // this is, and repeating it inside would print the same fact twice.
        SizedBox(
          height: 120,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < days.length; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    // The value label sizes itself naturally (so it never
                    // clips at a larger text scale); the bar then claims
                    // whatever height is left via Expanded, rather than a
                    // fixed pixel count that assumed a fixed label height —
                    // see DECISIONS.md, Sprint 18.
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (values[i] > 0 && values[i] == maxValue)
                          Text(
                            _formatter.formatCompact(Money.fromMinor(values[i], 'IDR')),
                            textAlign: TextAlign.center,
                            // One line: a seventh of the width is narrower
                            // than "Rp 252rb", and wrapping it mid-amount
                            // reads as two numbers.
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.visible,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              // Without widthFactor the bar rendered zero
                              // pixels wide: FractionallySizedBox only
                              // tightens the axis it has a factor for, and
                              // the Align above hands it a loose width, so
                              // a DecoratedBox with no intrinsic size
                              // collapsed. This chart had been drawing
                              // nothing but its axis labels.
                              widthFactor: 1,
                              heightFactor: maxValue == 0 ? 0 : values[i] / maxValue,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: tokens.accent,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
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
            for (final d in days)
              Expanded(
                child: Text(
                  _dayLabel.format(DateTime.utc(1970, 1, 1).add(Duration(days: d))),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
