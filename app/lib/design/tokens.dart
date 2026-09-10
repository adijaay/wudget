import 'package:flutter/material.dart';

/// Design tokens for wudget. Values here are placeholders until the
/// [CONFIRM] items in DESIGN.md (accent colour, typeface) are locked — see
/// plan/05-sprints.md, "Decision deadlines". No feature should declare its
/// own colour, spacing, radius or elevation; read it from here.
class WudgetTokens extends ThemeExtension<WudgetTokens> {
  const WudgetTokens({
    required this.ink1,
    required this.ink2,
    required this.ink3,
    required this.surface,
    required this.accent,
    required this.positive,
    required this.negative,
    required this.categoryHues,
  });

  final Color ink1; // primary text
  final Color ink2; // secondary text
  final Color ink3; // disabled / hint text
  final Color surface;
  final Color accent; // active state and primary action only
  final Color positive; // income
  final Color negative; // expense / over-budget
  final List<Color> categoryHues; // 8 hues, same hue = same category everywhere

  // Spacing: 4pt base, six-step scale.
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 24;
  static const double space6 = 32;

  // Radius: control, card, sheet. Not one pill radius on everything.
  static const double radiusControl = 8;
  static const double radiusCard = 16;
  static const double radiusSheet = 24;

  // Elevation: two levels only — the FAB and the capture sheet.
  static const double elevationRaised = 2;
  static const double elevationLifted = 8;

  static const WudgetTokens light = WudgetTokens(
    ink1: Color(0xFF1A1B1E),
    ink2: Color(0xFF53565C),
    ink3: Color(0xFF9AA0A6),
    surface: Color(0xFFFFFFFF),
    accent: Color(0xFF2E7D5B), // placeholder, pending brand accent [CONFIRM]
    positive: Color(0xFF2E7D5B),
    negative: Color(0xFFB3261E),
    categoryHues: [
      Color(0xFFEF6C57),
      Color(0xFFF2A93C),
      Color(0xFF4FAE7C),
      Color(0xFF3E8FC1),
      Color(0xFF6C6FC4),
      Color(0xFFB05FC0),
      Color(0xFFD4577E),
      Color(0xFF8A6D4E),
    ],
  );

  static const WudgetTokens dark = WudgetTokens(
    ink1: Color(0xFFF1F1F2),
    ink2: Color(0xFFC2C6CC),
    ink3: Color(0xFF7A7F87),
    surface: Color(0xFF141518),
    accent: Color(0xFF57B98A),
    positive: Color(0xFF57B98A),
    negative: Color(0xFFE5867E),
    categoryHues: [
      Color(0xFFF08D7C),
      Color(0xFFF5BF6E),
      Color(0xFF74C79B),
      Color(0xFF6AABDA),
      Color(0xFF9092D6),
      Color(0xFFC98AD6),
      Color(0xFFDD8AA4),
      Color(0xFFAB8D6E),
    ],
  );

  @override
  WudgetTokens copyWith({
    Color? ink1,
    Color? ink2,
    Color? ink3,
    Color? surface,
    Color? accent,
    Color? positive,
    Color? negative,
    List<Color>? categoryHues,
  }) {
    return WudgetTokens(
      ink1: ink1 ?? this.ink1,
      ink2: ink2 ?? this.ink2,
      ink3: ink3 ?? this.ink3,
      surface: surface ?? this.surface,
      accent: accent ?? this.accent,
      positive: positive ?? this.positive,
      negative: negative ?? this.negative,
      categoryHues: categoryHues ?? this.categoryHues,
    );
  }

  @override
  WudgetTokens lerp(ThemeExtension<WudgetTokens>? other, double t) {
    if (other is! WudgetTokens) return this;
    return WudgetTokens(
      ink1: Color.lerp(ink1, other.ink1, t)!,
      ink2: Color.lerp(ink2, other.ink2, t)!,
      ink3: Color.lerp(ink3, other.ink3, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      positive: Color.lerp(positive, other.positive, t)!,
      negative: Color.lerp(negative, other.negative, t)!,
      categoryHues: [
        for (var i = 0; i < categoryHues.length; i++)
          Color.lerp(categoryHues[i], other.categoryHues[i], t)!,
      ],
    );
  }
}

ThemeData buildWudgetTheme(WudgetTokens tokens, Brightness brightness) {
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: ColorScheme.fromSeed(
      seedColor: tokens.accent,
      brightness: brightness,
    ),
    scaffoldBackgroundColor: tokens.surface,
    extensions: [tokens],
  );
}
