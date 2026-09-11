import 'package:flutter_test/flutter_test.dart';
import 'package:wudget/domain/recurrence.dart';

int _day(int year, int month, int day) =>
    DateTime.utc(year, month, day).difference(DateTime.utc(1970, 1, 1)).inDays;

DateTime _dateOf(int day) => DateTime.utc(1970, 1, 1).add(Duration(days: day));

void main() {
  group('daily', () {
    test('every N days from the start', () {
      final rule = RecurrenceRule(freq: RecurrenceFreq.daily, intervalN: 3, startsOn: _day(2026, 3, 1));
      expect(_dateOf(rule.logicalOccurrence(0)), DateTime.utc(2026, 3, 1));
      expect(_dateOf(rule.logicalOccurrence(1)), DateTime.utc(2026, 3, 4));
      expect(_dateOf(rule.logicalOccurrence(2)), DateTime.utc(2026, 3, 7));
    });
  });

  group('weekly', () {
    test('lands on the requested weekday, not the start date\'s', () {
      // 2026-03-02 is a Monday; ask for Friday (5).
      final rule = RecurrenceRule(
        freq: RecurrenceFreq.weekly,
        byWeekday: DateTime.friday,
        startsOn: _day(2026, 3, 2),
      );
      expect(_dateOf(rule.logicalOccurrence(0)).weekday, DateTime.friday);
      expect(_dateOf(rule.logicalOccurrence(0)), DateTime.utc(2026, 3, 6));
      expect(_dateOf(rule.logicalOccurrence(1)), DateTime.utc(2026, 3, 13));
    });

    test('every N weeks', () {
      final rule = RecurrenceRule(
        freq: RecurrenceFreq.weekly,
        intervalN: 2,
        byWeekday: DateTime.monday,
        startsOn: _day(2026, 3, 2),
      );
      expect(_dateOf(rule.logicalOccurrence(1)), DateTime.utc(2026, 3, 16));
    });
  });

  group('monthly — the 31st in a 30-day month', () {
    test('clamps to the last day, and the clamp is never permanent', () {
      final rule = RecurrenceRule(freq: RecurrenceFreq.monthly, byMonthDay: 31, startsOn: _day(2026, 1, 31));
      // January has 31 days.
      expect(_dateOf(rule.logicalOccurrence(0)), DateTime.utc(2026, 1, 31));
      // April has 30 — clamps.
      expect(_dateOf(rule.logicalOccurrence(3)), DateTime.utc(2026, 4, 30));
      // May has 31 again — the clamp from April must not carry over.
      expect(_dateOf(rule.logicalOccurrence(4)), DateTime.utc(2026, 5, 31));
    });

    test('byMonthDay -1 always means the last day of the month', () {
      final rule = RecurrenceRule(freq: RecurrenceFreq.monthly, byMonthDay: -1, startsOn: _day(2026, 1, 1));
      expect(_dateOf(rule.logicalOccurrence(0)), DateTime.utc(2026, 1, 31));
      expect(_dateOf(rule.logicalOccurrence(1)), DateTime.utc(2026, 2, 28)); // 2026 is not a leap year
    });

    test('leap February', () {
      final rule = RecurrenceRule(freq: RecurrenceFreq.monthly, byMonthDay: 31, startsOn: _day(2024, 1, 31));
      expect(_dateOf(rule.logicalOccurrence(1)), DateTime.utc(2024, 2, 29));
    });
  });

  group('yearly', () {
    test('same month and day, N years later, with the same clamp rule', () {
      final rule = RecurrenceRule(freq: RecurrenceFreq.yearly, byMonthDay: 29, startsOn: _day(2024, 2, 29));
      expect(_dateOf(rule.logicalOccurrence(1)), DateTime.utc(2025, 2, 28)); // not a leap year
      expect(_dateOf(rule.logicalOccurrence(4)), DateTime.utc(2028, 2, 29)); // leap again
    });
  });

  group('weekend rule — a Sunday due date', () {
    test('none leaves it on the weekend', () {
      final rule = RecurrenceRule(freq: RecurrenceFreq.monthly, byMonthDay: 1, startsOn: _day(2026, 3, 1));
      final sunday = _day(2026, 3, 1); // 2026-03-01 is a Sunday
      expect(_dateOf(sunday).weekday, DateTime.sunday);
      expect(rule.shiftForWeekend(sunday), sunday);
    });

    test('before shifts a Sunday back to Friday', () {
      final rule = RecurrenceRule(
        freq: RecurrenceFreq.monthly, byMonthDay: 1, weekendRule: WeekendRule.before, startsOn: _day(2026, 3, 1),
      );
      final sunday = _day(2026, 3, 1);
      expect(_dateOf(rule.shiftForWeekend(sunday)), DateTime.utc(2026, 2, 27));
    });

    test('after shifts a Saturday forward to Monday', () {
      final rule = RecurrenceRule(
        freq: RecurrenceFreq.monthly, byMonthDay: 4, weekendRule: WeekendRule.after, startsOn: _day(2026, 4, 4),
      );
      final saturday = _day(2026, 4, 4); // 2026-04-04 is a Saturday
      expect(_dateOf(saturday).weekday, DateTime.saturday);
      expect(_dateOf(rule.shiftForWeekend(saturday)), DateTime.utc(2026, 4, 6));
    });

    test('the shift never alters the next occurrence\'s base date', () {
      // If the shift leaked into the schedule, month 2's occurrence would
      // drift forward from the shifted Monday instead of the logical 4th.
      final rule = RecurrenceRule(
        freq: RecurrenceFreq.monthly, byMonthDay: 4, weekendRule: WeekendRule.after, startsOn: _day(2026, 4, 4),
      );
      expect(_dateOf(rule.logicalOccurrence(1)), DateTime.utc(2026, 5, 4));
    });
  });

  group('nextOccurrenceOnOrAfter', () {
    test('returns the rule\'s first occurrence when asked for a day before it starts', () {
      final rule = RecurrenceRule(freq: RecurrenceFreq.monthly, byMonthDay: 1, startsOn: _day(2026, 3, 1));
      expect(_dateOf(rule.nextOccurrenceOnOrAfter(_day(2026, 1, 1))), DateTime.utc(2026, 3, 1));
    });

    test('skips past occurrences to the next one on or after the given day', () {
      final rule = RecurrenceRule(freq: RecurrenceFreq.monthly, byMonthDay: 1, startsOn: _day(2026, 1, 1));
      expect(_dateOf(rule.nextOccurrenceOnOrAfter(_day(2026, 4, 15))), DateTime.utc(2026, 5, 1));
    });

    test('a day that is itself an occurrence returns that same day', () {
      final rule = RecurrenceRule(freq: RecurrenceFreq.monthly, byMonthDay: 1, startsOn: _day(2026, 1, 1));
      expect(_dateOf(rule.nextOccurrenceOnOrAfter(_day(2026, 4, 1))), DateTime.utc(2026, 4, 1));
    });
  });

  group('logicalOccurrencesThrough', () {
    test('stops at endsOn even if toDayInclusive is later', () {
      final rule = RecurrenceRule(
        freq: RecurrenceFreq.monthly,
        byMonthDay: 1,
        startsOn: _day(2026, 1, 1),
        endsOn: _day(2026, 3, 1),
      );
      final days = rule.logicalOccurrencesThrough(_day(2026, 12, 1));
      expect(days.map(_dateOf).toList(), [DateTime.utc(2026, 1, 1), DateTime.utc(2026, 2, 1), DateTime.utc(2026, 3, 1)]);
    });

    test('empty before the rule starts', () {
      final rule = RecurrenceRule(freq: RecurrenceFreq.monthly, byMonthDay: 1, startsOn: _day(2026, 6, 1));
      expect(rule.logicalOccurrencesThrough(_day(2026, 3, 1)), isEmpty);
    });
  });
}
