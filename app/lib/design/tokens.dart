import 'package:flutter/material.dart';

/// Design tokens for wudget, ported from the mockups in `design/` (authored
/// in OKLCH) via `tool/oklch.py`. The accent is Petrol, oklch(0.52 0.09 205),
/// chosen from the three candidates in `design/Tokens.dc.html` because it
/// survives sitting next to GoPay, OVO, DANA, ShopeePay, BCA and Mandiri
/// brand colours on a wallet card, which bright blue and orange do not.
///
/// No feature declares its own colour, spacing, radius or elevation; it
/// reads it from here. Every pairing below is asserted in
/// `test/domain/contrast_test.dart` rather than eyeballed.
class WudgetTokens extends ThemeExtension<WudgetTokens> {
  const WudgetTokens({
    required this.ink1,
    required this.ink2,
    required this.ink3,
    required this.inkInverse,
    required this.inkInverse2,
    required this.inkOnAccent,
    required this.surface,
    required this.surfaceCard,
    required this.surfaceMuted,
    required this.surfaceInverse,
    required this.border,
    required this.borderStrong,
    required this.hairline,
    required this.accent,
    required this.accentOnInverse,
    required this.positive,
    required this.negative,
    required this.warning,
    required this.categoryHues,
    required this.categoryTints,
    required this.categoryInks,
  });

  final Color ink1; // primary text
  final Color ink2; // secondary text, still above 4.5:1 on every surface
  final Color ink3; // decoration only: chart baselines, dividers. Never text.
  final Color inkInverse; // text on surfaceInverse
  final Color inkInverse2; // secondary text on surfaceInverse
  final Color inkOnAccent; // text and icons on an accent fill
  final Color surface; // page ground
  final Color surfaceCard; // the card sitting on the page
  final Color surfaceMuted; // chips, numpad keys, inset rows
  final Color surfaceInverse; // the one emphasis block per screen
  final Color border; // card outline: separation, carries no information
  final Color borderStrong; // outline of an interactive control, clears 3:1
  final Color hairline; // divider between rows inside one card
  final Color accent; // active state and primary action only
  // The accent lightened for an action sitting on surfaceInverse (the undo
  // in a snackbar). The plain accent is only 2.94:1 there, so reusing it
  // would have shipped an unreadable Batalkan on the dark bar.
  final Color accentOnInverse;
  final Color positive; // income
  final Color negative; // expense
  final Color warning; // over budget, over pace
  final List<Color> categoryHues; // 8 fixed hues, same hue = same category
  final List<Color> categoryTints; // the hue as an icon-chip ground
  final List<Color> categoryInks; // the glyph drawn on that ground

  /// Spacing: 4pt base. The mockups' row padding (13-14px) rounds to
  /// [space3]/[space4]; nothing needs a fifth intermediate step.
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 24;
  static const double space6 = 32;

  /// Radius: three values, deliberately not one pill on everything (R-11).
  /// A different corner is a hierarchy tool, so control, card and sheet each
  /// keep their own.
  static const double radiusControl = 10;
  static const double radiusChip = 11; // the 38px icon chip on a list row
  static const double radiusCard = 14;
  static const double radiusTile = 14; // the 46px category tile
  static const double radiusSheet = 20;
  static const double radiusPill = 999; // template and subcategory chips only

  /// Elevation: two levels. Only the capture button and the sheet lift; if
  /// everything lifted, elevation would say nothing (R-12).
  static const double elevationRaised = 2;
  static const double elevationLifted = 8;

  /// Sizes the mockups repeat, so a screen never invents its own.
  static const double iconChip = 38;
  static const double categoryTile = 46;
  static const double minTapTarget = 44; // R-03
  static const double navBarHeight = 64;
  static const double captureButton = 56;

  static const String fontFamily = 'Plus Jakarta Sans';

  /// The platform's own faces, for any codepoint the bundled one lacks.
  static const List<String> fontFamilyFallback = ['Roboto', 'Segoe UI', 'sans-serif'];

  static const WudgetTokens light = WudgetTokens(
    ink1: Color(0xFF201914),
    ink2: Color(0xFF665B53),
    ink3: Color(0xFF8A7E75),
    inkInverse: Color(0xFFF7F5F1),
    inkInverse2: Color(0xFFC2BDB7),
    inkOnAccent: Color(0xFFFDFCFA),
    surface: Color(0xFFFCFAF6),
    surfaceCard: Color(0xFFFEFDFB),
    surfaceMuted: Color(0xFFF2F0EC),
    surfaceInverse: Color(0xFF2A221D),
    border: Color(0xFFE8E4DF),
    borderStrong: Color(0xFF8A8580),
    hairline: Color(0xFFEEEAE7),
    accent: Color(0xFF007781),
    accentOnInverse: Color(0xFF86CBD3),
    positive: Color(0xFF21763C),
    negative: Color(0xFFAF3C3A),
    warning: Color(0xFFAF5331),
    categoryHues: [
      Color(0xFFB97057), // Makan
      Color(0xFF238994), // Transport
      Color(0xFF92689C), // Belanja
      Color(0xFF6B8451), // Tagihan
      Color(0xFF6379AA), // Hiburan
      Color(0xFF459173), // Kesehatan
      // Darkened from oklch(0.62 0.09 85) to 0.58: at the mockup's lightness
      // this hue measured only 2.96:1 against its own tint, so a selected
      // chip's border would have been invisible inside the chip.
      Color(0xFF937636), // Pendidikan
      Color(0xFF867867), // Lainnya
    ],
    categoryTints: [
      Color(0xFFFFDFD2),
      Color(0xFFCAF0F5),
      Color(0xFFF4E0F9),
      Color(0xFFE0EDD4),
      Color(0xFFDCE8FF),
      Color(0xFFD0F1E1),
      Color(0xFFF4E6CA),
      Color(0xFFEEE6DE),
    ],
    categoryInks: [
      Color(0xFF81412A),
      Color(0xFF00626C),
      Color(0xFF6A4573),
      Color(0xFF475E2F),
      Color(0xFF405480),
      Color(0xFF176449),
      Color(0xFF6B510F),
      Color(0xFF605344),
    ],
  );

  /// Dark is a full counterpart, not a tint-inverted afterthought (R-34):
  /// warm neutrals like the light theme, the accent lightened so it still
  /// clears its bar, and an accent fill that carries dark text instead of
  /// white.
  static const WudgetTokens dark = WudgetTokens(
    ink1: Color(0xFFF3F1EE),
    ink2: Color(0xFFBCB6AF),
    ink3: Color(0xFF857F79),
    inkInverse: Color(0xFFF7F5F1),
    inkInverse2: Color(0xFFC2BDB7),
    inkOnAccent: Color(0xFF0E1819),
    surface: Color(0xFF14110E),
    surfaceCard: Color(0xFF1F1B18),
    surfaceMuted: Color(0xFF292623),
    surfaceInverse: Color(0xFF352F2A),
    border: Color(0xFF383531),
    borderStrong: Color(0xFF7F7973),
    hairline: Color(0xFF302D2A),
    accent: Color(0xFF61BFC9),
    accentOnInverse: Color(0xFF86CBD3),
    positive: Color(0xFF76C788),
    negative: Color(0xFFEB827B),
    warning: Color(0xFFF49F81),
    categoryHues: [
      Color(0xFFE1957A),
      Color(0xFF5DBBC6),
      Color(0xFFC499CE),
      Color(0xFF9AB580),
      Color(0xFF92AADE),
      Color(0xFF71BD9D),
      Color(0xFFC5A767),
      Color(0xFFB7A897),
    ],
    categoryTints: [
      Color(0xFF43251A),
      Color(0xFF0A3438),
      Color(0xFF38263C),
      Color(0xFF27321C),
      Color(0xFF242D42),
      Color(0xFF153528),
      Color(0xFF382C11),
      Color(0xFF332D26),
    ],
    categoryInks: [
      Color(0xFFF2B39D),
      Color(0xFF8BD2DA),
      Color(0xFFD9B6E2),
      Color(0xFFB7CDA1),
      Color(0xFFB0C4EF),
      Color(0xFF98D3B9),
      Color(0xFFDAC18F),
      Color(0xFFCFC2B4),
    ],
  );

  Color hueFor(int index) => categoryHues[index % categoryHues.length];
  Color tintFor(int index) => categoryTints[index % categoryTints.length];
  Color inkFor(int index) => categoryInks[index % categoryInks.length];

  @override
  WudgetTokens copyWith({
    Color? ink1,
    Color? ink2,
    Color? ink3,
    Color? inkInverse,
    Color? inkInverse2,
    Color? inkOnAccent,
    Color? surface,
    Color? surfaceCard,
    Color? surfaceMuted,
    Color? surfaceInverse,
    Color? border,
    Color? borderStrong,
    Color? hairline,
    Color? accent,
    Color? accentOnInverse,
    Color? positive,
    Color? negative,
    Color? warning,
    List<Color>? categoryHues,
    List<Color>? categoryTints,
    List<Color>? categoryInks,
  }) {
    return WudgetTokens(
      ink1: ink1 ?? this.ink1,
      ink2: ink2 ?? this.ink2,
      ink3: ink3 ?? this.ink3,
      inkInverse: inkInverse ?? this.inkInverse,
      inkInverse2: inkInverse2 ?? this.inkInverse2,
      inkOnAccent: inkOnAccent ?? this.inkOnAccent,
      surface: surface ?? this.surface,
      surfaceCard: surfaceCard ?? this.surfaceCard,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      surfaceInverse: surfaceInverse ?? this.surfaceInverse,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      hairline: hairline ?? this.hairline,
      accent: accent ?? this.accent,
      accentOnInverse: accentOnInverse ?? this.accentOnInverse,
      positive: positive ?? this.positive,
      negative: negative ?? this.negative,
      warning: warning ?? this.warning,
      categoryHues: categoryHues ?? this.categoryHues,
      categoryTints: categoryTints ?? this.categoryTints,
      categoryInks: categoryInks ?? this.categoryInks,
    );
  }

  @override
  WudgetTokens lerp(ThemeExtension<WudgetTokens>? other, double t) {
    if (other is! WudgetTokens) return this;
    List<Color> lerpList(List<Color> a, List<Color> b) =>
        [for (var i = 0; i < a.length; i++) Color.lerp(a[i], b[i], t)!];
    return WudgetTokens(
      ink1: Color.lerp(ink1, other.ink1, t)!,
      ink2: Color.lerp(ink2, other.ink2, t)!,
      ink3: Color.lerp(ink3, other.ink3, t)!,
      inkInverse: Color.lerp(inkInverse, other.inkInverse, t)!,
      inkInverse2: Color.lerp(inkInverse2, other.inkInverse2, t)!,
      inkOnAccent: Color.lerp(inkOnAccent, other.inkOnAccent, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceCard: Color.lerp(surfaceCard, other.surfaceCard, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      surfaceInverse: Color.lerp(surfaceInverse, other.surfaceInverse, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentOnInverse: Color.lerp(accentOnInverse, other.accentOnInverse, t)!,
      positive: Color.lerp(positive, other.positive, t)!,
      negative: Color.lerp(negative, other.negative, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      categoryHues: lerpList(categoryHues, other.categoryHues),
      categoryTints: lerpList(categoryTints, other.categoryTints),
      categoryInks: lerpList(categoryInks, other.categoryInks),
    );
  }
}

/// The type scale from `design/Tokens.dc.html`. Sizes are the mockup's own,
/// rounded to whole points where it made no visible difference.
TextTheme _buildTextTheme(WudgetTokens tokens) {
  TextStyle base(double size, FontWeight weight, {Color? color, double? height, double? spacing}) =>
      TextStyle(
        fontFamily: WudgetTokens.fontFamily,
        // Plus Jakarta Sans covers Latin and Indonesian fully but not every
        // symbol; without a fallback a missing glyph renders as an empty box.
        fontFamilyFallback: WudgetTokens.fontFamilyFallback,
        fontSize: size,
        fontWeight: weight,
        color: color ?? tokens.ink1,
        height: height,
        letterSpacing: spacing,
      );

  return TextTheme(
    // Screen titles: "Kantong", "Catat", "September sudah kelar".
    headlineMedium: base(24, FontWeight.w700, spacing: -0.24),
    headlineSmall: base(20, FontWeight.w700),
    // A card's own heading: "Paling banyak keluar".
    titleLarge: base(17, FontWeight.w700),
    titleMedium: base(14, FontWeight.w700),
    // A list row's name.
    titleSmall: base(15, FontWeight.w600),
    // The interpreted sentence on the pace card, which has to stay readable
    // at two or three lines.
    bodyLarge: base(15, FontWeight.w600, height: 1.35),
    bodyMedium: base(13, FontWeight.w400, height: 1.5, color: tokens.ink2),
    // Row subtitles ("GoPay, 12:24"). ink2, not ink3: ink3 fails 4.5:1 as
    // text, so the mockup's lighter subtitle grey is deliberately darkened
    // here (R-25 is a hard gate, and it outranks matching the mockup's hex).
    bodySmall: base(12, FontWeight.w400, color: tokens.ink2),
    // Section dividers: "HARIAN", "TOTAL SEMUA KANTONG". Uppercase with mild
    // tracking, which groups a list without the wide-tracked display look
    // R-06 rules out.
    labelLarge: base(14, FontWeight.w600),
    labelMedium: base(11, FontWeight.w700, color: tokens.ink2, spacing: 0.33),
    labelSmall: base(11, FontWeight.w500, color: tokens.ink2),
  );
}

ThemeData buildWudgetTheme(WudgetTokens tokens, Brightness brightness) {
  final scheme = ColorScheme(
    brightness: brightness,
    primary: tokens.accent,
    onPrimary: tokens.inkOnAccent,
    secondary: tokens.accent,
    onSecondary: tokens.inkOnAccent,
    error: tokens.negative,
    onError: tokens.inkOnAccent,
    surface: tokens.surface,
    onSurface: tokens.ink1,
    surfaceContainerLowest: tokens.surfaceCard,
    surfaceContainerLow: tokens.surfaceCard,
    surfaceContainer: tokens.surfaceMuted,
    surfaceContainerHigh: tokens.surfaceMuted,
    surfaceContainerHighest: tokens.surfaceMuted,
    onSurfaceVariant: tokens.ink2,
    outline: tokens.borderStrong,
    outlineVariant: tokens.border,
    inverseSurface: tokens.surfaceInverse,
    onInverseSurface: tokens.inkInverse,
  );
  final text = _buildTextTheme(tokens);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    // Explicit, not ColorScheme.fromSeed: a generated scheme replaced every
    // value above with its own harmonised guess, which is why none of the
    // mockup's colours reached the screen before this.
    colorScheme: scheme,
    scaffoldBackgroundColor: tokens.surface,
    canvasColor: tokens.surface,
    fontFamily: WudgetTokens.fontFamily,
    fontFamilyFallback: WudgetTokens.fontFamilyFallback,
    textTheme: text,
    extensions: [tokens],
    appBarTheme: AppBarTheme(
      backgroundColor: tokens.surface,
      surfaceTintColor: Colors.transparent,
      foregroundColor: tokens.ink1,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: text.headlineMedium,
    ),
    cardTheme: CardThemeData(
      color: tokens.surfaceCard,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(WudgetTokens.radiusCard),
        side: BorderSide(color: tokens.border),
      ),
    ),
    dividerTheme: DividerThemeData(color: tokens.hairline, thickness: 1, space: 1),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: tokens.surfaceCard,
      surfaceTintColor: Colors.transparent,
      modalElevation: WudgetTokens.elevationLifted,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(WudgetTokens.radiusSheet)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: tokens.surfaceInverse,
      contentTextStyle: TextStyle(
        fontFamily: WudgetTokens.fontFamily,
        fontSize: 13,
        color: tokens.inkInverse,
      ),
      actionTextColor: tokens.accentOnInverse,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(WudgetTokens.radiusControl)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: tokens.accent,
        foregroundColor: tokens.inkOnAccent,
        // Height only: Size.fromHeight would set an infinite minimum
        // width, which forces full-width buttons everywhere and cannot be
        // laid out at all inside a Row.
        minimumSize: const Size(0, WudgetTokens.minTapTarget),
        textStyle: text.titleMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(WudgetTokens.radiusControl)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: tokens.ink1,
        side: BorderSide(color: tokens.borderStrong),
        // Height only: Size.fromHeight would set an infinite minimum
        // width, which forces full-width buttons everywhere and cannot be
        // laid out at all inside a Row.
        minimumSize: const Size(0, WudgetTokens.minTapTarget),
        textStyle: text.titleMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(WudgetTokens.radiusControl)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: tokens.accent,
        textStyle: text.titleMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(WudgetTokens.radiusControl)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: tokens.surfaceMuted,
      hintStyle: text.bodyMedium,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: WudgetTokens.space3,
        vertical: WudgetTokens.space3,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(WudgetTokens.radiusControl),
        borderSide: BorderSide(color: tokens.borderStrong),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(WudgetTokens.radiusControl),
        borderSide: BorderSide(color: tokens.borderStrong),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(WudgetTokens.radiusControl),
        borderSide: BorderSide(color: tokens.accent, width: 2),
      ),
    ),
    // The focus ring every keyboard user depends on (R-32): the accent
    // clears 3:1 against every surface it can land on, in both themes.
    focusColor: tokens.accent,
    iconTheme: IconThemeData(color: tokens.ink1, size: 22),
    listTileTheme: ListTileThemeData(
      iconColor: tokens.ink2,
      titleTextStyle: text.titleSmall,
      subtitleTextStyle: text.bodySmall,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: tokens.surfaceMuted,
      selectedColor: tokens.accent,
      side: BorderSide(color: tokens.border),
      labelStyle: text.labelSmall?.copyWith(color: tokens.ink1),
      secondaryLabelStyle: text.labelSmall?.copyWith(color: tokens.inkOnAccent),
      shape: const StadiumBorder(),
      showCheckmark: false,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: tokens.accent),
  );
}
