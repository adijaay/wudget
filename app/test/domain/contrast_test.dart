import 'package:flutter/material.dart' show Color, Colors;
import 'package:flutter_test/flutter_test.dart';
import 'package:wudget/design/tokens.dart';
import 'package:wudget/domain/contrast.dart';

// Every pairing here is a real Color assignment against `surface` found in
// lib/ (see DECISIONS.md, Sprint 18) — not every token that exists, only
// the ones the app actually draws with, per plan/05-sprints.md's own
// wording: "Contrast assertions on every token pair actually used."
void main() {
  void assertTextPair(String label, Color foreground, Color background) {
    final ratio = contrastRatio(foreground, background);
    expect(
      ratio,
      greaterThanOrEqualTo(contrastMinNormalText),
      reason: '$label: ratio ${ratio.toStringAsFixed(2)} is below the AA normal-text minimum '
          '($contrastMinNormalText)',
    );
  }

  void assertComponentPair(String label, Color foreground, Color background) {
    final ratio = contrastRatio(foreground, background);
    expect(
      ratio,
      greaterThanOrEqualTo(contrastMinLargeTextOrComponent),
      reason: '$label: ratio ${ratio.toStringAsFixed(2)} is below the AA large-text/component '
          'minimum ($contrastMinLargeTextOrComponent)',
    );
  }

  group('contrastRatio itself', () {
    test('black on white is the maximum, 21.0', () {
      expect(contrastRatio(const Color(0xFF000000), const Color(0xFFFFFFFF)), closeTo(21.0, 0.01));
    });

    test('identical colors give a ratio of 1.0', () {
      expect(contrastRatio(const Color(0xFF777777), const Color(0xFF777777)), closeTo(1.0, 0.01));
    });

    test('is symmetric regardless of argument order', () {
      const a = Color(0xFF333333);
      const b = Color(0xFFEEEEEE);
      expect(contrastRatio(a, b), contrastRatio(b, a));
    });

    test('matches the documented reference pairing: #777777 on white fails normal text', () {
      // From antislop-human's reference table.
      final ratio = contrastRatio(const Color(0xFF777777), const Color(0xFFFFFFFF));
      expect(ratio, closeTo(4.48, 0.05));
      expect(ratio, lessThan(contrastMinNormalText));
    });
  });

  group('light theme, text against surface', () {
    test('ink1 (primary text)', () => assertTextPair('light ink1/surface', WudgetTokens.light.ink1, WudgetTokens.light.surface));
    test('positive (income amounts)', () => assertTextPair('light positive/surface', WudgetTokens.light.positive, WudgetTokens.light.surface));
    test('negative (expense amounts, warnings)', () => assertTextPair('light negative/surface', WudgetTokens.light.negative, WudgetTokens.light.surface));
  });

  group('dark theme, text against surface', () {
    test('ink1 (primary text)', () => assertTextPair('dark ink1/surface', WudgetTokens.dark.ink1, WudgetTokens.dark.surface));
    test('positive (income amounts)', () => assertTextPair('dark positive/surface', WudgetTokens.dark.positive, WudgetTokens.dark.surface));
    test('negative (expense amounts, warnings)', () => assertTextPair('dark negative/surface', WudgetTokens.dark.negative, WudgetTokens.dark.surface));
  });

  group('non-text components against surface', () {
    test('light accent (FAB, chart lines)', () => assertComponentPair('light accent/surface', WudgetTokens.light.accent, WudgetTokens.light.surface));
    test('dark accent (FAB, chart lines)', () => assertComponentPair('dark accent/surface', WudgetTokens.dark.accent, WudgetTokens.dark.surface));
    // ink3 is intentionally left unasserted here: its only remaining uses
    // (the chart's baseline axis, a progress bar's unfilled track) are
    // purely decorative — the data itself is carried by the accent-colored
    // line or fill next to them, not by ink3. WCAG's 1.4.11 non-text
    // contrast requirement exempts purely decorative graphics, and the two
    // uses that *did* carry information (the forecast legend dash, the
    // dashed forecast line) were moved to ink2 — see DECISIONS.md, Sprint 18.

    test('every category hue, both themes', () {
      final failures = <String>[];
      for (var i = 0; i < WudgetTokens.light.categoryHues.length; i++) {
        final ratio = contrastRatio(WudgetTokens.light.categoryHues[i], WudgetTokens.light.surface);
        if (ratio < contrastMinLargeTextOrComponent) {
          failures.add('light categoryHues[$i]: ${ratio.toStringAsFixed(2)}');
        }
      }
      for (var i = 0; i < WudgetTokens.dark.categoryHues.length; i++) {
        final ratio = contrastRatio(WudgetTokens.dark.categoryHues[i], WudgetTokens.dark.surface);
        if (ratio < contrastMinLargeTextOrComponent) {
          failures.add('dark categoryHues[$i]: ${ratio.toStringAsFixed(2)}');
        }
      }
      expect(failures, isEmpty, reason: failures.join(', '));
    });
  });

  group('the delete-swipe background (a fixed color, not a theme token)', () {
    // ledger_screen.dart deliberately does not use tokens.negative here —
    // see DECISIONS.md, Sprint 18: that token is tuned as a *text* color
    // per theme, not guaranteed to hold a white icon as a background.
    test('white icon on Colors.red.shade700 meets AA in both themes, being theme-independent',
        () => assertTextPair('white/red.shade700', const Color(0xFFFFFFFF), Colors.red.shade700));
  });
}
