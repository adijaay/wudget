import 'package:flutter/material.dart';

import '../../core/money.dart';
import '../../core/money_formatter.dart';
import '../../design/tokens.dart';
import '../../domain/period.dart';

const _formatter = MoneyFormatter();

/// Cumulative spend across [period]'s days: solid where actually recorded,
/// dashed from today to the period's end at the forecast rate — chart rule
/// 5, "forecast is always visually distinct and labelled". [todayIndex] is
/// null when the period is entirely in the past (nothing left to forecast).
class ActualForecastChart extends StatelessWidget {
  const ActualForecastChart({
    super.key,
    required this.period,
    required this.dailyExpenseMinor,
    required this.todayIndex,
    required this.forecastTotalMinor,
    this.baselineTotalMinor,
  });

  final Period period;
  final Map<int, int> dailyExpenseMinor;
  final int? todayIndex;
  final int forecastTotalMinor;

  /// Last period's total, drawn as a labelled dashed reference line so the
  /// forecast can be read against something. Null when there is no previous
  /// period, in which case no line is drawn rather than a line at zero.
  final int? baselineTotalMinor;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final totalDays = period.endDayExclusive - period.startDay;

    final cumulative = <int>[];
    var running = 0;
    for (var i = 0; i < totalDays; i++) {
      running += dailyExpenseMinor[period.startDay + i] ?? 0;
      cumulative.add(running);
    }

    final maxY = [running, forecastTotalMinor, baselineTotalMinor ?? 0]
        .reduce((a, b) => a > b ? a : b);
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            _formatter.formatCompact(Money.fromMinor(maxY, 'IDR')),
            style: text.bodySmall,
          ),
        ),
        SizedBox(
          height: 150,
          child: CustomPaint(
            painter: _ChartPainter(
              cumulative: cumulative,
              todayIndex: todayIndex,
              forecastTotalMinor: forecastTotalMinor,
              baselineTotalMinor: baselineTotalMinor,
              maxY: maxY == 0 ? 1 : maxY,
              tokens: tokens,
            ),
          ),
        ),
        // Day axis: the first day, today, and the last, which is all the
        // reader needs to place the bend in the line.
        Row(
          children: [
            Expanded(child: Text('1', style: text.bodySmall)),
            if (todayIndex != null)
              Text('hari ini', style: text.bodySmall),
            Expanded(
              child: Text(
                '$totalDays',
                style: text.bodySmall,
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
        const SizedBox(height: WudgetTokens.space2),
        Row(
          children: [
            _LegendDash(color: tokens.accent, dashed: false),
            const SizedBox(width: WudgetTokens.space2),
            Text('Sudah terjadi', style: text.bodySmall),
            const SizedBox(width: WudgetTokens.space3),
            // The reference line needs naming too: unlabelled, a second
            // dashed line just reads as more forecast (chart rule 5).
            if (baselineTotalMinor != null) ...[
              _LegendDash(color: tokens.ink3, dashed: true),
              const SizedBox(width: WudgetTokens.space2),
              Text('Biasanya', style: text.bodySmall),
              const SizedBox(width: WudgetTokens.space3),
            ],
            // ink3 fails the 3:1 component bar, so the dashed forecast uses
            // ink2 — see DECISIONS.md, Sprint 18.
            _LegendDash(color: tokens.ink2, dashed: true),
            const SizedBox(width: WudgetTokens.space2),
            Text('Perkiraan', style: text.bodySmall),
          ],
        ),
      ],
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.cumulative,
    required this.todayIndex,
    required this.forecastTotalMinor,
    required this.baselineTotalMinor,
    required this.maxY,
    required this.tokens,
  });

  final List<int> cumulative;
  final int? todayIndex;
  final int forecastTotalMinor;
  final int? baselineTotalMinor;
  final int maxY;
  final WudgetTokens tokens;

  Offset _point(Size size, int index, num value) {
    final x = cumulative.length <= 1 ? 0.0 : size.width * index / (cumulative.length - 1);
    final y = size.height * (1 - value / maxY);
    return Offset(x, y);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (cumulative.isEmpty) return;

    final axisPaint = Paint()
      ..color = tokens.ink3.withOpacity(0.3)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), axisPaint);

    // Last period's total as a reference line, so the forecast is read
    // against something rather than floating on its own.
    final baseline = baselineTotalMinor;
    if (baseline != null && baseline > 0) {
      final y = size.height * (1 - baseline / maxY);
      // ink3, thinner: a static reference, visually subordinate to the
      // projection it is there to be read against.
      _drawDashedLine(canvas, Offset(0, y), Offset(size.width, y), tokens.ink3, strokeWidth: 1.2);
    }

    final actualEnd = todayIndex == null ? cumulative.length - 1 : todayIndex!.clamp(0, cumulative.length - 1);

    // Where today sits, so the bend between recorded and projected is not
    // something the reader has to infer.
    if (todayIndex != null && cumulative.length > 1) {
      final x = size.width * actualEnd / (cumulative.length - 1);
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        Paint()
          ..color = tokens.border
          ..strokeWidth = 1,
      );
    }

    final actualPath = Path()..moveTo(_point(size, 0, 0).dx, _point(size, 0, 0).dy);
    for (var i = 0; i <= actualEnd; i++) {
      final p = _point(size, i, cumulative[i].toDouble());
      actualPath.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      actualPath,
      Paint()
        ..color = tokens.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    final todayPoint = _point(size, actualEnd, cumulative[actualEnd].toDouble());
    canvas.drawCircle(todayPoint, 4, Paint()..color = tokens.accent);

    if (todayIndex != null && todayIndex! < cumulative.length - 1) {
      final end = _point(size, cumulative.length - 1, forecastTotalMinor.toDouble());
      // ink3 fails the 3:1 component bar, so the projection uses ink2.
      _drawDashedLine(canvas, todayPoint, end, tokens.ink2);
      canvas.drawCircle(
        end,
        3.4,
        Paint()
          ..color = tokens.ink2
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Color color, {
    num strokeWidth = 2.5, // `num` per the repo-wide float guard
  }) {
    const dashLength = 6.0;
    const gapLength = 4.0;
    final total = (end - start).distance;
    if (total == 0) return;
    final direction = (end - start) / total;
    var covered = 0.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth.toDouble();
    while (covered < total) {
      final segmentEnd = (covered + dashLength).clamp(0.0, total);
      canvas.drawLine(start + direction * covered, start + direction * segmentEnd, paint);
      covered += dashLength + gapLength;
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) =>
      oldDelegate.cumulative != cumulative ||
      oldDelegate.todayIndex != todayIndex ||
      oldDelegate.forecastTotalMinor != forecastTotalMinor ||
      oldDelegate.baselineTotalMinor != baselineTotalMinor;
}

/// Solid for what happened, dashed for what is projected: the legend has to
/// carry the same distinction the lines do, or the labels mean nothing.
class _LegendDash extends StatelessWidget {
  const _LegendDash({required this.color, required this.dashed});
  final Color color;
  final bool dashed;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 16,
        height: 3,
        child: dashed
            ? Row(
                // stretch, or a childless DecoratedBox collapses to zero
                // height and the dashes simply do not appear.
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    if (i > 0) const SizedBox(width: 2),
                    Expanded(child: DecoratedBox(decoration: BoxDecoration(color: color))),
                  ],
                ],
              )
            : DecoratedBox(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
      );
}
