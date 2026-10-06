import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../design/tokens.dart';
import '../../domain/contrast.dart';
import '../../domain/pola.dart';

final _weekdayLabel = DateFormat('EEE', 'id_ID');

/// One cell's five-step ramp, derived from the themed accent rather than
/// hardcoded, so it follows a change of accent and works in both themes.
///
/// The ramp stops short of the pure accent: the accent itself means
/// "active" everywhere else in this app, and today's ring uses it. A data
/// step that reached full accent would collide with that.
Color spendRampColor(WudgetTokens tokens, int step) {
  const stops = [0.16, 0.32, 0.50, 0.68, 0.86];
  return Color.lerp(tokens.surfaceMuted, tokens.accent, stops[step])!;
}

/// Whichever of the two inks clears AA on [background]. Computed rather
/// than assumed, because the ramp's midpoint is exactly where a fixed
/// choice stops being readable — and where it fails differs between light
/// and dark.
Color readableInkOn(WudgetTokens tokens, Color background) {
  return contrastRatio(tokens.ink1, background) >= contrastMinNormalText
      ? tokens.ink1
      : tokens.inkOnAccent;
}

/// A month of spending, one value per cell.
///
/// Deliberately one value and not two: research/07-ui-audit.md records a
/// competitor packing two numbers into each heatmap cell, which is past
/// the point where the cell encodes anything. Days with no spend carry
/// their own shape rather than the palest step, and days that have not
/// happened yet are drawn empty rather than as a zero (chart rule 8).
class SpendCalendar extends StatelessWidget {
  const SpendCalendar({
    super.key,
    required this.startDay,
    required this.endDayExclusive,
    required this.dailyExpenseMinor,
    required this.todayDay,
  });

  final int startDay;
  final int endDayExclusive;
  final Map<int, int> dailyExpenseMinor;
  final int todayDay;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final text = Theme.of(context).textTheme;

    final maxMinor = dailyExpenseMinor.values.fold<int>(0, (a, b) => a > b ? a : b);

    // Pad the first row so the 1st lands under its real weekday.
    final leadingBlanks = weekdayIndexOf(startDay);
    final cells = <Widget>[
      for (var i = 0; i < leadingBlanks; i++) const SizedBox.shrink(),
      for (var day = startDay; day < endDayExclusive; day++)
        _Cell(
          day: day,
          label: '${DateTime.utc(1970, 1, 1).add(Duration(days: day)).day}',
          amountMinor: dailyExpenseMinor[day] ?? 0,
          maxMinor: maxMinor,
          isFuture: day > todayDay,
          isToday: day == todayDay,
        ),
    ];

    final rows = <Widget>[];
    for (var i = 0; i < cells.length; i += 7) {
      final week = cells.sublist(i, (i + 7).clamp(0, cells.length));
      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Row(
          children: [
            for (var c = 0; c < 7; c++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.5),
                  child: c < week.length ? week[c] : const SizedBox.shrink(),
                ),
              ),
          ],
        ),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            // Read off real dates rather than a hardcoded list, so the
            // header follows the locale the rest of the app formats in.
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Text(
                  _weekdayLabel.format(DateTime.utc(1970, 1, 5).add(Duration(days: i))),
                  textAlign: TextAlign.center,
                  style: text.labelSmall?.copyWith(color: tokens.ink2),
                ),
              ),
          ],
        ),
        const SizedBox(height: WudgetTokens.space1),
        ...rows,
        const SizedBox(height: WudgetTokens.space2),
        _Legend(maxMinor: maxMinor),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.day,
    required this.label,
    required this.amountMinor,
    required this.maxMinor,
    required this.isFuture,
    required this.isToday,
  });

  final int day;
  final String label;
  final int amountMinor;
  final int maxMinor;
  final bool isFuture;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final text = Theme.of(context).textTheme;
    final step = isFuture ? null : spendIntensityStep(amountMinor, maxMinor: maxMinor);

    final Color? fill = step == null ? null : spendRampColor(tokens, step);
    final ink = fill != null
        ? readableInkOn(tokens, fill)
        : isFuture
            ? tokens.ink2
            : tokens.ink1;

    // Three distinct treatments, so the state never rests on hue alone:
    // a filled cell spent something, a ringed cell spent nothing, and an
    // unmarked cell has not happened yet.
    final Border? border = isToday
        ? Border.all(color: tokens.accent, width: 2)
        : (!isFuture && step == null)
            ? Border.all(color: Color.lerp(tokens.border, tokens.accent, 0.45)!, width: 1.5)
            : null;

    return Semantics(
      label: isFuture
          ? '$label, belum jalan'
          : step == null
              ? '$label, tidak ada pengeluaran'
              : null,
      child: Container(
        constraints: const BoxConstraints(minHeight: 38),
        decoration: BoxDecoration(
          color: fill,
          border: border,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          label,
          style: text.labelMedium?.copyWith(
            color: ink,
            fontWeight: isToday ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.maxMinor});
  final int maxMinor;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(color: tokens.ink2);

    Widget swatch(Color? fill, {Border? border}) => Container(
          width: 13,
          height: 13,
          decoration: BoxDecoration(
            color: fill,
            border: border,
            borderRadius: BorderRadius.circular(4),
          ),
        );

    return Wrap(
      spacing: WudgetTokens.space4,
      runSpacing: WudgetTokens.space2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < spendIntensitySteps; i++) ...[
              swatch(spendRampColor(tokens, i)),
              const SizedBox(width: 3),
            ],
            const SizedBox(width: 3),
            Text('sedikit ke banyak', style: style),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            swatch(null,
                border: Border.all(color: Color.lerp(tokens.border, tokens.accent, 0.45)!, width: 1.5)),
            const SizedBox(width: 6),
            Text('tanpa pengeluaran', style: style),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            swatch(null, border: Border.all(color: tokens.accent, width: 2)),
            const SizedBox(width: 6),
            Text('hari ini', style: style),
          ],
        ),
      ],
    );
  }
}
