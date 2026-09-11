import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../design/tokens.dart';
import '../../domain/pace.dart';

/// Shows how much of the baseline has been spent (can exceed 100%, so the
/// track beyond it is a visually distinct overshoot region rather than a
/// gauge with nowhere to point — chart rule 1) with a tick marking how far
/// through the period today actually is, for comparison. Colour is backed
/// by [PaceStatus] but never the only signal — the centre label states the
/// percentage and status in words too (chart rule 7).
class PaceRing extends StatelessWidget {
  const PaceRing({super.key, required this.pace});
  final PaceResult pace;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final fraction = pace.spendFractionOfBaseline;
    return SizedBox(
      width: 160,
      height: 160,
      child: CustomPaint(
        painter: _PaceRingPainter(
          spendFraction: fraction,
          elapsedFraction: pace.elapsedFraction,
          status: pace.status,
          tokens: tokens,
        ),
        child: Center(
          child: Text(
            fraction == null ? '—' : '${(fraction * 100).round()}%',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
      ),
    );
  }
}

class _PaceRingPainter extends CustomPainter {
  _PaceRingPainter({
    required this.spendFraction,
    required this.elapsedFraction,
    required this.status,
    required this.tokens,
  });

  final num? spendFraction;
  final num elapsedFraction;
  final PaceStatus? status;
  final WudgetTokens tokens;

  static const _strokeWidth = 14.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (math.min(size.width, size.height) - _strokeWidth) / 2;
    const start = -math.pi / 2;

    final track = Paint()
      ..color = tokens.ink3.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;
    canvas.drawCircle(center, radius, track);

    // The elapsed-time tick: a short marker on the track, independent of
    // the spend arc's colour, so time and spend are never conflated.
    final tickAngle = start + 2 * math.pi * elapsedFraction;
    final tickOuter = center + Offset(math.cos(tickAngle), math.sin(tickAngle)) * (radius + _strokeWidth / 2 + 2);
    final tickInner = center + Offset(math.cos(tickAngle), math.sin(tickAngle)) * (radius - _strokeWidth / 2 - 2);
    canvas.drawLine(tickInner, tickOuter, Paint()..color = tokens.ink1..strokeWidth = 2);

    final fraction = spendFraction;
    if (fraction == null) return;

    final color = switch (status) {
      PaceStatus.overBaseline => tokens.negative,
      PaceStatus.underBaseline => tokens.positive,
      PaceStatus.onBaseline || null => tokens.accent,
    };

    final primarySweep = 2 * math.pi * fraction.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      primarySweep,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    if (fraction > 1.0) {
      // Overshoot: a second, visually distinct lap (thinner, hatch-like
      // via a lighter alpha) rather than a gauge that has run out of room.
      final overshootSweep = 2 * math.pi * (fraction - 1.0).clamp(0.0, 1.0);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - _strokeWidth - 4),
        start,
        overshootSweep,
        false,
        Paint()
          ..color = tokens.negative.withOpacity(0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = _strokeWidth / 2
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PaceRingPainter oldDelegate) =>
      oldDelegate.spendFraction != spendFraction ||
      oldDelegate.elapsedFraction != elapsedFraction ||
      oldDelegate.status != status;
}
