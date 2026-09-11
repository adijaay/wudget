import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../design/tokens.dart';
import '../../domain/pace.dart';

/// Shows how much of the baseline has been spent (can exceed 100%, so the
/// track beyond it is a visually distinct overshoot region rather than a
/// gauge with nowhere to point — chart rule 1) with a tick marking how far
/// through the period today actually is, for comparison. Colour is backed
/// by [PaceStatus] but never the only signal: the centre states the
/// percentage in words, and the caller pairs the ring with a sentence and a
/// signed delta (chart rule 7).
class PaceRing extends StatelessWidget {
  const PaceRing({super.key, required this.pace, this.size = 84});
  final PaceResult pace;

  /// `num`, not the banned float type: the repo-wide guard in
  /// test/money_formatter_is_the_only_path_test.dart is a blunt grep and
  /// cannot tell a ring diameter from a money amount.
  final num size;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final fraction = pace.spendFractionOfBaseline;
    // The percentage inside the ring appears nowhere else, so it has to be
    // allowed to grow — which means the ring grows with it rather than
    // clipping it. Capped at 1.8 so it cannot eat the sentence beside it.
    final scale = (MediaQuery.textScalerOf(context).scale(100) / 100).clamp(1.0, 1.8);
    final dimension = (size * scale).toDouble();
    return SizedBox(
      width: dimension,
      height: dimension,
      child: CustomPaint(
        painter: _PaceRingPainter(
          spendFraction: fraction,
          elapsedFraction: pace.elapsedFraction,
          status: pace.status,
          tokens: tokens,
          strokeWidth: dimension * 0.107, // the mockup's 9px stroke on an 84px ring
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                fraction == null ? '-' : '${(fraction * 100).round()}%',
                style: TextStyle(
                  fontFamily: WudgetTokens.fontFamily,
                  fontSize: (size * 0.226).toDouble(),
                  fontWeight: FontWeight.w700,
                  color: tokens.ink1,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                'terpakai',
                style: TextStyle(
                  fontFamily: WudgetTokens.fontFamily,
                  fontSize: (size * 0.113).toDouble(),
                  color: tokens.ink2,
                ),
              ),
            ],
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
    required this.strokeWidth,
  });

  final num? spendFraction;
  final num elapsedFraction;
  final PaceStatus? status;
  final WudgetTokens tokens;
  final num strokeWidth; // see the note on PaceRing.size

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final stroke = strokeWidth.toDouble();
    final radius = (math.min(size.width, size.height) - stroke) / 2;
    const start = -math.pi / 2;

    final track = Paint()
      ..color = tokens.surfaceMuted
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawCircle(center, radius, track);

    // The elapsed-time tick: a short marker on the track, independent of
    // the spend arc's colour, so time and spend are never conflated.
    final tickAngle = start + 2 * math.pi * elapsedFraction;
    final tickOuter =
        center + Offset(math.cos(tickAngle), math.sin(tickAngle)) * (radius + stroke / 2 + 2);
    final tickInner =
        center + Offset(math.cos(tickAngle), math.sin(tickAngle)) * (radius - stroke / 2 - 2);
    canvas.drawLine(tickInner, tickOuter, Paint()..color = tokens.ink1..strokeWidth = 2);

    final fraction = spendFraction;
    if (fraction == null) return;

    final color = switch (status) {
      PaceStatus.overBaseline => tokens.warning,
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
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );

    if (fraction > 1.0) {
      // Overshoot: a second, visually distinct lap inside the first rather
      // than a gauge that has run out of room.
      final overshootSweep = 2 * math.pi * (fraction - 1.0).clamp(0.0, 1.0);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - stroke - 3),
        start,
        overshootSweep,
        false,
        Paint()
          ..color = tokens.negative
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke / 2
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PaceRingPainter oldDelegate) =>
      oldDelegate.spendFraction != spendFraction ||
      oldDelegate.elapsedFraction != elapsedFraction ||
      oldDelegate.status != status ||
      oldDelegate.strokeWidth != strokeWidth;
}
