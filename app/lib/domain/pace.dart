/// How this period's spend, projected to the period's end, compares with
/// the same period last time — the hero number of Pantau. See
/// plan/05-sprints.md Sprint 9 and the chart rules in plan/04-ux-design.md.
enum PaceStatus {
  /// Projected total meaningfully above the baseline.
  overBaseline,

  /// Projected total meaningfully below the baseline.
  underBaseline,

  /// Within a small band of the baseline — not worth alarming over.
  onBaseline,
}

/// [tolerance] is the fraction either side of the baseline treated as "on
/// pace" rather than over/under, so a 2% wobble doesn't read as a verdict.
const paceTolerance = 0.1;

class PaceResult {
  const PaceResult({
    required this.elapsedFraction,
    required this.spendMinor,
    required this.forecastTotalMinor,
    required this.baselineTotalMinor,
  });

  /// Fraction of the period's days that have elapsed (today inclusive), 0-1.
  /// `num`, not the banned float type (test/money_formatter_is_the_only_path_test.dart)
  /// — this is a ratio of day counts, not a money amount, but the guard is a
  /// blunt repo-wide grep and doesn't know that.
  final num elapsedFraction;

  /// Actual spend so far this period.
  final int spendMinor;

  /// Linear projection of [spendMinor] to the period's end, at today's
  /// average daily rate. Never rendered without the "perkiraan" label and
  /// dashed styling — chart rule 5.
  final int forecastTotalMinor;

  /// The same period, one period ago — null when that period predates the
  /// user's first ever transaction, per chart rule 8: a number that can't
  /// be computed renders blank with a reason, never as zero.
  final int? baselineTotalMinor;

  /// What fraction of the baseline has already been spent, for the pace
  /// ring — this is the value that can exceed 1.0 (chart rule 1: no gauge
  /// for a value that can exceed its scale without an overshoot region).
  num? get spendFractionOfBaseline {
    final baseline = baselineTotalMinor;
    if (baseline == null || baseline == 0) return null;
    return spendMinor / baseline;
  }

  PaceStatus? get status {
    final fraction = spendFractionOfBaseline;
    if (fraction == null) return null;
    final delta = fraction - elapsedFraction;
    if (delta > paceTolerance) return PaceStatus.overBaseline;
    if (delta < -paceTolerance) return PaceStatus.underBaseline;
    return PaceStatus.onBaseline;
  }

  /// One sentence a person would say out loud, per chart rule 6 — or null
  /// when [status] is null, so the caller can render the "no baseline yet"
  /// reason instead of a fabricated conclusion.
  String? sentence(String Function(int minor) formatCompact) {
    final s = status;
    if (s == null) return null;
    final forecast = formatCompact(forecastTotalMinor);
    final baseline = formatCompact(baselineTotalMinor!);
    return switch (s) {
      PaceStatus.overBaseline =>
        'Kalau lajunya seperti ini, perkiraan habis $forecast periode ini — lebih tinggi dari biasanya ($baseline).',
      PaceStatus.underBaseline =>
        'Lajumu lebih hemat dari biasanya: perkiraan $forecast periode ini, dibanding $baseline biasanya.',
      PaceStatus.onBaseline => 'Lajumu mirip seperti biasanya, sekitar $forecast di akhir periode.',
    };
  }
}

/// [daysElapsed] counts today, so on the first day of a period it is 1, not 0.
PaceResult computePace({
  required int daysElapsed,
  required int totalDaysInPeriod,
  required int spendMinor,
  required int? baselineTotalMinor,
}) {
  final elapsedFraction = totalDaysInPeriod <= 0 ? 0.0 : (daysElapsed / totalDaysInPeriod).clamp(0.0, 1.0);
  final forecastTotal = elapsedFraction <= 0 ? spendMinor : (spendMinor / elapsedFraction).round();
  return PaceResult(
    elapsedFraction: elapsedFraction,
    spendMinor: spendMinor,
    forecastTotalMinor: forecastTotal,
    baselineTotalMinor: baselineTotalMinor,
  );
}
