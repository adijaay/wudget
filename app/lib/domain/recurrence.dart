final _epoch = DateTime.utc(1970, 1, 1);

DateTime _dateForDayBucket(int day) => _epoch.add(Duration(days: day));
int _dayBucketForDate(DateTime date) => date.difference(_epoch).inDays;

enum RecurrenceFreq { daily, weekly, monthly, yearly }

/// Shifts a due date off a weekend without altering the underlying
/// schedule — plan/03-architecture.md: "`weekend_rule` shifts the due date
/// without altering the underlying schedule." The next occurrence is
/// always computed from the *logical* (unshifted) date, never the shifted
/// one, so a shift can never compound across occurrences.
enum WeekendRule { none, before, after }

/// A recurrence's schedule. Pure and DB-free so the date arithmetic is
/// tested directly — plan/05-sprints.md Sprint 12's edge-case suite.
class RecurrenceRule {
  const RecurrenceRule({
    required this.freq,
    this.intervalN = 1,
    this.byMonthDay,
    this.byWeekday,
    this.weekendRule = WeekendRule.none,
    required this.startsOn,
    this.endsOn,
  });

  final RecurrenceFreq freq;

  /// Every Nth occurrence of [freq] (e.g. every 2 weeks).
  final int intervalN;

  /// 1-31, or -1 for "the last day of the month" — monthly/yearly only.
  final int? byMonthDay;

  /// ISO weekday, 1 (Monday) - 7 (Sunday) — weekly only.
  final int? byWeekday;

  final WeekendRule weekendRule;

  /// Day bucket the schedule starts from (inclusive).
  final int startsOn;

  /// Day bucket the schedule stops at (inclusive), or null for no end.
  final int? endsOn;

  /// The logical (unshifted) day bucket for the occurrence index [n]
  /// (0-based, n=0 is the first occurrence on or after [startsOn]).
  int logicalOccurrence(int n) {
    return switch (freq) {
      RecurrenceFreq.daily => startsOn + n * intervalN,
      RecurrenceFreq.weekly => _weeklyOccurrence(n),
      RecurrenceFreq.monthly => _monthlyOccurrence(n),
      RecurrenceFreq.yearly => _yearlyOccurrence(n),
    };
  }

  int _weeklyOccurrence(int n) {
    final startDate = _dateForDayBucket(startsOn);
    final weekday = byWeekday ?? startDate.weekday;
    // The first occurrence on or after startsOn with the target weekday.
    final daysToFirst = (weekday - startDate.weekday) % 7;
    final first = startsOn + (daysToFirst < 0 ? daysToFirst + 7 : daysToFirst);
    return first + n * intervalN * 7;
  }

  int _monthlyOccurrence(int n) {
    final startDate = _dateForDayBucket(startsOn);
    final monthDay = byMonthDay ?? startDate.day;
    final targetMonthIndex = startDate.year * 12 + (startDate.month - 1) + n * intervalN;
    final year = targetMonthIndex ~/ 12;
    final month = targetMonthIndex % 12 + 1;
    return _dayBucketForDate(_clampedMonthDate(year, month, monthDay));
  }

  int _yearlyOccurrence(int n) {
    final startDate = _dateForDayBucket(startsOn);
    final monthDay = byMonthDay ?? startDate.day;
    final year = startDate.year + n * intervalN;
    return _dayBucketForDate(_clampedMonthDate(year, startDate.month, monthDay));
  }

  /// Day 31 in a 30-day month (or 29/28 in February) clamps to that
  /// month's last day — recomputed fresh every call, so the clamp is never
  /// carried into the next month (plan/03-architecture.md: "A clamp never
  /// becomes permanent").
  static DateTime _clampedMonthDate(int year, int month, int day) {
    if (day == -1) {
      final firstOfNextMonth = DateTime.utc(year, month + 1, 1);
      return firstOfNextMonth.subtract(const Duration(days: 1));
    }
    final lastDayOfMonth = DateTime.utc(year, month + 1, 1).subtract(const Duration(days: 1)).day;
    return DateTime.utc(year, month, day > lastDayOfMonth ? lastDayOfMonth : day);
  }

  /// The actual due date after [weekendRule] is applied — the schedule
  /// itself keeps using [logicalOccurrence] for the next one.
  int shiftForWeekend(int logicalDay) {
    if (weekendRule == WeekendRule.none) return logicalDay;
    final weekday = _dateForDayBucket(logicalDay).weekday;
    if (weekday < 6) return logicalDay; // Mon-Fri
    return switch (weekendRule) {
      WeekendRule.before => logicalDay - (weekday - 5), // back to Friday
      WeekendRule.after => logicalDay + (8 - weekday), // forward to Monday
      WeekendRule.none => logicalDay,
    };
  }

  /// Logical occurrence day buckets with `startsOn <= day <= toDayInclusive`
  /// (and `<= endsOn` if set) — the raw schedule, before weekend shifting
  /// or overrides. Used by the materialisation engine to know which
  /// instances should exist by a given watermark.
  List<int> logicalOccurrencesThrough(int toDayInclusive) {
    if (toDayInclusive < startsOn) return [];
    final results = <int>[];
    for (var n = 0; ; n++) {
      final day = logicalOccurrence(n);
      if (day > toDayInclusive) break;
      if (endsOn != null && day > endsOn!) break;
      results.add(day);
    }
    return results;
  }
}
