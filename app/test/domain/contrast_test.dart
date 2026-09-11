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

  // The rebuild to the mockups (design/*.dc.html) introduced four new
  // grounds — the card, the muted inset, the dark emphasis block, and the
  // accent fill — and text lands on all of them. Each pairing below is one
  // the app actually draws, checked rather than assumed: the lightened
  // accentOnInverse exists precisely because the plain accent measured
  // 2.94:1 on surfaceInverse.
  for (final (themeName, t) in [('light', WudgetTokens.light), ('dark', WudgetTokens.dark)]) {
    group('$themeName theme, text on every ground it lands on', () {
      test('ink1 and ink2 on the card surface', () {
        assertTextPair('$themeName ink1/surfaceCard', t.ink1, t.surfaceCard);
        assertTextPair('$themeName ink2/surfaceCard', t.ink2, t.surfaceCard);
      });
      test('ink1 and ink2 on the muted surface (chips, numpad keys, inset rows)', () {
        assertTextPair('$themeName ink1/surfaceMuted', t.ink1, t.surfaceMuted);
        assertTextPair('$themeName ink2/surfaceMuted', t.ink2, t.surfaceMuted);
      });
      test('amounts on the card surface', () {
        assertTextPair('$themeName positive/surfaceCard', t.positive, t.surfaceCard);
        assertTextPair('$themeName negative/surfaceCard', t.negative, t.surfaceCard);
      });
      test('the emphasis block: inkInverse and its secondary', () {
        assertTextPair('$themeName inkInverse/surfaceInverse', t.inkInverse, t.surfaceInverse);
        assertTextPair('$themeName inkInverse2/surfaceInverse', t.inkInverse2, t.surfaceInverse);
      });
      test('the undo action on the emphasis block (a snackbar)', () {
        assertTextPair('$themeName accentOnInverse/surfaceInverse', t.accentOnInverse, t.surfaceInverse);
      });
      test('a label on an accent fill (primary button, save key, selected segment)', () {
        assertTextPair('$themeName inkOnAccent/accent', t.inkOnAccent, t.accent);
      });
      test('the warning tone, on the ground it is actually drawn on', () {
        // InsetNotice tints the ground with the warning colour itself, so
        // the readable pairing is the warning ink against the card beneath.
        assertTextPair('$themeName warning/surfaceCard', t.warning, t.surfaceCard);
      });
      test('an interactive outline clears the component bar', () {
        // Input borders and the wallet picker's outline carry meaning, so
        // the plain card border is not enough for them (antislop-human).
        assertComponentPair('$themeName borderStrong/surfaceCard', t.borderStrong, t.surfaceCard);
      });
      test('every category hue as an icon chip: glyph on its own tint', () {
        final failures = <String>[];
        for (var i = 0; i < t.categoryHues.length; i++) {
          final onTint = contrastRatio(t.categoryInks[i], t.categoryTints[i]);
          if (onTint < contrastMinNormalText) {
            failures.add('$themeName categoryInks[$i] on its tint: ${onTint.toStringAsFixed(2)}');
          }
          // The tint is a chip ground on the card, and the hue is also used
          // as a bare 8px dot in the ranked list, so it needs the 3:1 bar.
          final hueOnCard = contrastRatio(t.categoryHues[i], t.surfaceCard);
          if (hueOnCard < contrastMinLargeTextOrComponent) {
            failures.add('$themeName categoryHues[$i] on card: ${hueOnCard.toStringAsFixed(2)}');
          }
          // The hue itself is a border on a selected tile/chip, against the
          // tint it encloses as well as the card it sits on.
          final hueOnTint = contrastRatio(t.categoryHues[i], t.categoryTints[i]);
          if (hueOnTint < contrastMinLargeTextOrComponent) {
            failures.add('$themeName categoryHues[$i] on its tint: ${hueOnTint.toStringAsFixed(2)}');
          }
        }
        expect(failures, isEmpty, reason: failures.join('; '));
      });
    });
  }

  group('the delete-swipe background (a fixed color, not a theme token)', () {
    // ledger_screen.dart deliberately does not use tokens.negative here —
    // see DECISIONS.md, Sprint 18: that token is tuned as a *text* color
    // per theme, not guaranteed to hold a white icon as a background.
    test('white icon on Colors.red.shade700 meets AA in both themes, being theme-independent',
        () => assertTextPair('white/red.shade700', const Color(0xFFFFFFFF), Colors.red.shade700));
  });
}
