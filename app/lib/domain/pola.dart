/// Pure arithmetic behind Pantau's "Pola" view: which weekdays cost more,
/// how hard a given day was relative to the month's worst, and how much is
/// left to spend per remaining day. Built to design/Pola.dc.html and
/// design/CatatHariIni.dc.html.
///
/// Every function here returns null rather than zero when the answer
/// cannot be computed honestly — chart rule 8 in design/Tokens.dc.html,
/// "angka yang tidak bisa dihitung dibiarkan kosong dengan alasannya,
/// tidak pernah ditulis nol".
library;

/// Weekday of a day bucket, Monday = 0 through Sunday = 6. Day bucket 0 is
/// 1970-01-01, a Thursday, hence the +3.
int weekdayIndexOf(int dayBucket) => (dayBucket + 3) % 7;

/// Spend per weekday over a window, for "akhir pekan berapa kali lipat".
class WeekdayPattern {
  const WeekdayPattern({required this.totalMinor, required this.dayCount});

  /// Seven totals, Monday first.
  final List<int> totalMinor;

  /// How many of each weekday the window actually contained. This is the
  /// denominator, so a Tuesday the user spent nothing on still counts as a
  /// Tuesday — averaging only over days with spend would report every
  /// weekday as expensive.
  final List<int> dayCount;

  /// Average for one weekday, or null if the window contained none of it.
  int? averageFor(int weekdayIndex) {
    final days = dayCount[weekdayIndex];
    if (days == 0) return null;
    return totalMinor[weekdayIndex] ~/ days;
  }

  int? get _mondayToFriday => _pooled(0, 5);
  int? get _saturdayToSunday => _pooled(5, 7);

  /// Pooled average for Monday through Friday.
  int? get workdayAverageMinor => _mondayToFriday;

  /// Pooled average for Saturday and Sunday. Pooled from the totals rather
  /// than averaged from the two weekday means, which differ whenever the
  /// window holds an unequal number of Saturdays and Sundays.
  int? get weekendAverageMinor => _saturdayToSunday;

  int? _pooled(int fromIndex, int toIndexExclusive) {
    var total = 0;
    var days = 0;
    for (var i = fromIndex; i < toIndexExclusive; i++) {
      total += totalMinor[i];
      days += dayCount[i];
    }
    if (days == 0) return null;
    return total ~/ days;
  }

  /// The busiest weekday, or null when the window has no spend at all.
  int? get peakWeekdayIndex {
    int? peak;
    var best = 0;
    for (var i = 0; i < 7; i++) {
      final average = averageFor(i);
      if (average == null || average <= best) continue;
      best = average;
      peak = i;
    }
    return peak;
  }
}

/// Buckets [dailyExpenseMinor] by weekday across the whole window. Days
/// absent from the map spent nothing and contribute a zero to their
/// weekday's average, not a gap.
WeekdayPattern computeWeekdayPattern({
  required Map<int, int> dailyExpenseMinor,
  required int sinceDayInclusive,
  required int untilDayExclusive,
}) {
  final totals = List<int>.filled(7, 0);
  final counts = List<int>.filled(7, 0);
  for (var day = sinceDayInclusive; day < untilDayExclusive; day++) {
    final index = weekdayIndexOf(day);
    counts[index] += 1;
    totals[index] += dailyExpenseMinor[day] ?? 0;
  }
  return WeekdayPattern(totalMinor: totals, dayCount: counts);
}

/// How many intensity steps the spend calendar has. Five, because the eye
/// stops separating a single-hue ramp reliably past that.
const spendIntensitySteps = 5;

/// Which of the five steps [amountMinor] falls in, scaled against the
/// month's own worst day so the ramp always uses its full range.
///
/// Returns null for a day with no spend. The calendar draws those as an
/// outlined cell rather than as the palest step, so "nothing happened" and
/// "a little happened" never share an encoding (DESIGN.md: hue alone never
/// carries meaning).
int? spendIntensityStep(int amountMinor, {required int maxMinor}) {
  if (amountMinor <= 0) return null;
  if (maxMinor <= 0) return 0;
  final step = (amountMinor * spendIntensitySteps + maxMinor - 1) ~/ maxMinor;
  return (step - 1).clamp(0, spendIntensitySteps - 1);
}

/// What is left to spend, framed as a day rather than as a month.
///
/// The month-sized "sisa anggaran" is deliberately not the headline
/// anywhere in this app: the field evidence in research/05-behavioral-
/// research.md section 11 is that a live remaining balance raises spending
/// late in the period, because certainty about the remainder licenses
/// using it. A per-day figure is the same fact at a frame short enough to
/// act on.
class DailyAllowance {
  const DailyAllowance({
    required this.remainingMinor,
    required this.daysRemaining,
    required this.perDayMinor,
  });

  /// Budget minus spend. Negative once the period is over budget.
  final int remainingMinor;

  /// Days left in the period, today excluded.
  final int daysRemaining;

  /// [remainingMinor] spread over [daysRemaining], rounded *down* to a
  /// readable step, or zero when there is nothing left to spread.
  ///
  /// Down rather than nearest: an allowance a person follows to the rupiah
  /// should never be able to put them over. The exact quotient is a worse
  /// number to read than it is a target to hit, the same reason Aliran
  /// rounds its "dari tiap Rp 100.000" sentence.
  final int perDayMinor;

  bool get isOverBudget => remainingMinor < 0;
}

/// The step [DailyAllowance.perDayMinor] is rounded down to.
///
/// ponytail: a thousand rupiah, because rupiah has no sub-unit and this
/// app is IDR-first. A currency with cents would want its own step; give
/// this a parameter when a second currency actually needs one.
const dailyAllowanceStepMinor = 1000;

/// Null when no budget is set, or when the period has no days left after
/// today — in both cases there is no honest per-day number, so the caller
/// renders the reason instead.
DailyAllowance? computeDailyAllowance({
  required int budgetTotalMinor,
  required int spentMinor,
  required int daysRemaining,
}) {
  if (budgetTotalMinor <= 0) return null;
  if (daysRemaining <= 0) return null;
  final remaining = budgetTotalMinor - spentMinor;
  final exact = remaining <= 0 ? 0 : remaining ~/ daysRemaining;
  return DailyAllowance(
    remainingMinor: remaining,
    daysRemaining: daysRemaining,
    perDayMinor: exact ~/ dailyAllowanceStepMinor * dailyAllowanceStepMinor,
  );
}
