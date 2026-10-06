import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../design/tokens.dart';
import '../../domain/pola.dart';

final _weekdayLabel = DateFormat('EEE', 'id_ID');

/// Average spend per weekday, Monday first — Pola's "akhir pekan berapa
/// kali lipat".
///
/// The weekend pair is drawn darker and carries a bracket beneath it, so
/// the grouping survives without colour: the bracket is the signal, the
/// shade only reinforces it.
class WeekdayBarChart extends StatelessWidget {
  const WeekdayBarChart({super.key, required this.pattern});

  final WeekdayPattern pattern;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final text = Theme.of(context).textTheme;

    final averages = [for (var i = 0; i < 7; i++) pattern.averageFor(i) ?? 0];
    final maxValue = averages.fold<int>(0, (a, b) => a > b ? a : b);
    final peak = pattern.peakWeekdayIndex;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 108,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        // widthFactor as well as heightFactor: the box has
                        // no intrinsic size, and FractionallySizedBox only
                        // tightens the axis it is given a factor for, so
                        // without this the bar renders zero pixels wide.
                        widthFactor: 1,
                        heightFactor: maxValue == 0 ? 0 : averages[i] / maxValue,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: i >= 5
                                ? Color.lerp(tokens.surfaceMuted, tokens.accent, 0.62)
                                : Color.lerp(tokens.surfaceMuted, tokens.accent, 0.34),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: WudgetTokens.space1),
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Text(
                  _weekdayLabel.format(DateTime.utc(1970, 1, 5).add(Duration(days: i))),
                  textAlign: TextAlign.center,
                  style: text.labelSmall?.copyWith(
                    color: i == peak ? tokens.ink1 : tokens.ink2,
                    fontWeight: i == peak ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        // The bracket spans the last two sevenths of the row.
        Row(
          children: [
            const Expanded(flex: 5, child: SizedBox.shrink()),
            Expanded(
              flex: 2,
              child: Column(
                // Stretch, or the CustomPaint below gets a loose width and
                // draws at zero — it has no child to take its size from.
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 5,
                    child: CustomPaint(painter: _BracketPainter(color: tokens.ink2)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'akhir pekan',
                    textAlign: TextAlign.center,
                    style: text.labelSmall?.copyWith(color: tokens.ink2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BracketPainter extends CustomPainter {
  _BracketPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(3, 0), Offset(size.width - 3, 0), paint);
    canvas.drawLine(const Offset(3, 0), Offset(3, size.height), paint);
    canvas.drawLine(Offset(size.width - 3, 0), Offset(size.width - 3, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _BracketPainter oldDelegate) => oldDelegate.color != color;
}
