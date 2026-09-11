import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:wudget/domain/reminder_schedule.dart';

int _day(int year, int month, int day) =>
    DateTime.utc(year, month, day).difference(DateTime.utc(1970, 1, 1)).inDays;

void main() {
  setUpAll(() => tzdata.initializeTimeZones());

  test('fires at the requested local hour, not a fixed UTC offset', () {
    final jakarta = tz.getLocation('Asia/Jakarta'); // UTC+7, no DST
    final fireTime = reminderFireTime(location: jakarta, dueDay: _day(2026, 3, 15), hour: 9, minute: 0);
    expect(fireTime.hour, 9);
    expect(fireTime.minute, 0);
    expect(fireTime.timeZoneOffset, const Duration(hours: 7));
  });

  test('a due date on the spring-forward side of US DST still fires at 09:00 local', () {
    final newYork = tz.getLocation('America/New_York');
    // 2026-03-08 is the US spring-forward date (clocks skip 02:00-03:00).
    final beforeChange = reminderFireTime(location: newYork, dueDay: _day(2026, 3, 1), hour: 9, minute: 0);
    final afterChange = reminderFireTime(location: newYork, dueDay: _day(2026, 3, 15), hour: 9, minute: 0);

    expect(beforeChange.hour, 9); // EST, UTC-5
    expect(beforeChange.timeZoneOffset, const Duration(hours: -5));
    expect(afterChange.hour, 9); // EDT, UTC-4 — same local hour, different offset
    expect(afterChange.timeZoneOffset, const Duration(hours: -4));

    // The naive "fixed duration from UTC" bug this guards against: if the
    // fire time were computed as beforeChange's UTC instant plus 14 days,
    // it would land on 08:00 local after the clocks sprang forward.
    final naiveAfterChange = beforeChange.add(const Duration(days: 14));
    expect(naiveAfterChange.hour, isNot(afterChange.hour));
  });

  test('a due date on the fall-back side of US DST still fires at 09:00 local', () {
    final newYork = tz.getLocation('America/New_York');
    // 2026-11-01 is the US fall-back date.
    final beforeChange = reminderFireTime(location: newYork, dueDay: _day(2026, 10, 15), hour: 9, minute: 0);
    final afterChange = reminderFireTime(location: newYork, dueDay: _day(2026, 11, 15), hour: 9, minute: 0);

    expect(beforeChange.timeZoneOffset, const Duration(hours: -4)); // EDT
    expect(afterChange.timeZoneOffset, const Duration(hours: -5)); // EST
    expect(afterChange.hour, 9);
  });
}
