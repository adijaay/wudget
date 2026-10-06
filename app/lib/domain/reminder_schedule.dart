import 'package:timezone/timezone.dart' as tz;

/// The exact wall-clock instant a reminder should fire: [dueDay] (a day
/// bucket, see `data/daily_totals_repository.dart`'s `dayBucketFor`) at
/// [hour]:[minute] local time in [location]. Built with `TZDateTime`
/// rather than a fixed UTC-millis-plus-offset, because the whole point of
/// scheduling in a timezone (not a duration from now) is that the local
/// hour stays correct across a DST transition — plan/05-sprints.md
/// Sprint 13, "Timezone and DST correctness tests on scheduled delivery".
tz.TZDateTime reminderFireTime({
  required tz.Location location,
  required int dueDay,
  required int hour,
  required int minute,
}) {
  final date = DateTime.utc(1970, 1, 1).add(Duration(days: dueDay));
  return tz.TZDateTime(location, date.year, date.month, date.day, hour, minute);
}

/// The hour the evening reminder fires: the most common local hour among
/// [saves], later hour on a tie, kept in the evening (17 to 21) so it never
/// nags before the day is mostly done. 20 with no history.
int usualLoggingHour(Iterable<DateTime> saves) {
  final counts = <int, int>{};
  for (final s in saves) {
    counts[s.hour] = (counts[s.hour] ?? 0) + 1;
  }
  if (counts.isEmpty) return 20;
  final hour = counts.entries.reduce((a, b) => b.value > a.value || (b.value == a.value && b.key > a.key) ? b : a).key;
  return hour.clamp(17, 21);
}
