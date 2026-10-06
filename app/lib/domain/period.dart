final _epoch = DateTime.utc(1970, 1, 1);

/// Clamped per plan/05-sprints.md Sprint 8: "configurable month start day,
/// capped at 28" — so every month has one, no February edge case to design
/// around.
int clampPeriodStartDay(int day) => day.clamp(1, 28);

DateTime _dateForDayBucket(int day) => _epoch.add(Duration(days: day));
int _dayBucketForDate(DateTime date) => date.difference(_epoch).inDays;

/// A month-aligned budgeting period, e.g. payday-to-payday. Boundaries are
/// expressed as local day buckets in the same integer space as
/// `dayBucketFor` (data/spending_queries.dart), so a period composes
/// directly with `daily_totals` and ledger queries without a timezone
/// conversion at the boundary.
class Period {
  const Period({required this.startDay, required this.endDayExclusive, required this.monthStartDay});

  /// Inclusive first day bucket of the period.
  final int startDay;

  /// Exclusive day bucket the period ends at (the next period's startDay).
  final int endDayExclusive;

  final int monthStartDay;

  /// The period containing [todayDayBucket], given a [monthStartDay]
  /// (clamped to 1-28). If today's day-of-month is before the start day,
  /// the period began in the previous calendar month.
  factory Period.containing(int todayDayBucket, {required int monthStartDay}) {
    final startDay = clampPeriodStartDay(monthStartDay);
    final today = _dateForDayBucket(todayDayBucket);
    final periodMonthStart = today.day >= startDay
        ? DateTime.utc(today.year, today.month, startDay)
        : DateTime.utc(today.year, today.month - 1, startDay);
    final periodMonthEnd = DateTime.utc(periodMonthStart.year, periodMonthStart.month + 1, startDay);
    return Period(
      startDay: _dayBucketForDate(periodMonthStart),
      endDayExclusive: _dayBucketForDate(periodMonthEnd),
      monthStartDay: startDay,
    );
  }

  Period get next {
    final start = _dateForDayBucket(endDayExclusive);
    final end = DateTime.utc(start.year, start.month + 1, monthStartDay);
    return Period(startDay: endDayExclusive, endDayExclusive: _dayBucketForDate(end), monthStartDay: monthStartDay);
  }

  Period get previous {
    final end = _dateForDayBucket(startDay);
    final start = DateTime.utc(end.year, end.month - 1, monthStartDay);
    return Period(startDay: _dayBucketForDate(start), endDayExclusive: startDay, monthStartDay: monthStartDay);
  }

  DateTime get startDate => _dateForDayBucket(startDay);

  /// Last day actually in the period (endDayExclusive minus one day).
  DateTime get lastDate => _dateForDayBucket(endDayExclusive - 1);

  bool contains(int dayBucket) => dayBucket >= startDay && dayBucket < endDayExclusive;

  @override
  bool operator ==(Object other) =>
      other is Period && other.startDay == startDay && other.endDayExclusive == endDayExclusive;

  @override
  int get hashCode => Object.hash(startDay, endDayExclusive);
}

/// Today's local day bucket. Lives here rather than in each screen,
/// because two screens with their own copy is two places for the
/// midnight-rollover bug to hide.
int todayDayBucket() {
  final now = DateTime.now();
  return DateTime.utc(now.year, now.month, now.day).difference(DateTime.utc(1970, 1, 1)).inDays;
}
