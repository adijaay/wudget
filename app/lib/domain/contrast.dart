import 'dart:math' as math;

import 'package:flutter/material.dart' show Color;

/// WCAG 2.x relative luminance and contrast ratio — plan/05-sprints.md
/// Sprint 18, "contrast assertions on every token pair actually used."
/// A pure function over `Color`, so every token pair the app actually
/// draws text or a component boundary with can be asserted directly,
/// rather than eyeballed (`antislop-human`'s "grey-on-grey hallucination":
/// contrast must be computed, never asserted by look).
num _channelLuminance(int channel) {
  final c = channel / 255;
  return c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4);
}

num relativeLuminance(Color color) {
  return 0.2126 * _channelLuminance(color.red) +
      0.7152 * _channelLuminance(color.green) +
      0.0722 * _channelLuminance(color.blue);
}

/// Ranges from 1.0 (identical colors) to 21.0 (black on white).
num contrastRatio(Color a, Color b) {
  final la = relativeLuminance(a);
  final lb = relativeLuminance(b);
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

/// WCAG AA for normal-size text.
const contrastMinNormalText = 4.5;

/// WCAG AA for large text (18px+) and for non-text component boundaries
/// (button/chip backgrounds, icons, chart strokes) against their
/// background.
const contrastMinLargeTextOrComponent = 3.0;
