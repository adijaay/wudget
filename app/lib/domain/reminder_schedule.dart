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
