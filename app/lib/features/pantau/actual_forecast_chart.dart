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
  });

  final Period period;
  final Map<int, int> dailyExpenseMinor;
  final int? todayIndex;
  final int forecastTotalMinor;

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

    final maxY = [running, forecastTotalMinor].reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            _formatter.formatCompact(Money.fromMinor(maxY, 'IDR')),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        SizedBox(
          height: 160,
          child: CustomPaint(
            painter: _ChartPainter(
              cumulative: cumulative,
              todayIndex: todayIndex,
              forecastTotalMinor: forecastTotalMinor,
              maxY: maxY == 0 ? 1 : maxY,
              tokens: tokens,
            ),
          ),
        ),
        const SizedBox(height: WudgetTokens.space2),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendDot(color: tokens.accent),
            const SizedBox(width: WudgetTokens.space1),
            const Text('Aktual'),
            const SizedBox(width: WudgetTokens.space4),
            _LegendDash(color: tokens.ink2), // ink3 fails the 3:1 component bar — see DECISIONS.md, Sprint 18
            const SizedBox(width: WudgetTokens.space1),
            const Text('Perkiraan'),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: WudgetTokens.space1),
          child: Text(
            'Rupiah kumulatif per hari periode ini',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
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
    required this.maxY,
    required this.tokens,
  });

  final List<int> cumulative;
  final int? todayIndex;
  final int forecastTotalMinor;
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

    final actualEnd = todayIndex == null ? cumulative.length - 1 : todayIndex!.clamp(0, cumulative.length - 1);

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

    if (todayIndex != null && todayIndex! < cumulative.length - 1) {
      final start = _point(size, actualEnd, cumulative[actualEnd].toDouble());
      final end = _point(size, cumulative.length - 1, forecastTotalMinor.toDouble());
      _drawDashedLine(canvas, start, end, tokens.ink2); // ink3 fails the 3:1 component bar
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Color color) {
    const dashLength = 6.0;
    const gapLength = 4.0;
    final total = (end - start).distance;
    final direction = (end - start) / total;
    var covered = 0.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5;
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
      oldDelegate.forecastTotalMinor != forecastTotalMinor;
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) =>
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

class _LegendDash extends StatelessWidget {
  const _LegendDash({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) => Container(width: 14, height: 2, color: color);
}
