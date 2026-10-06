import 'package:flutter_test/flutter_test.dart';
import 'package:wudget/domain/period.dart';

int _day(int year, int month, int day) =>
    DateTime.utc(year, month, day).difference(DateTime.utc(1970, 1, 1)).inDays;

void main() {
  group('clampPeriodStartDay', () {
    test('caps at 28', () {
      expect(clampPeriodStartDay(31), 28);
      expect(clampPeriodStartDay(29), 28);
    });

    test('floors at 1', () {
      expect(clampPeriodStartDay(0), 1);
      expect(clampPeriodStartDay(-5), 1);
    });

    test('passes through valid values', () {
      expect(clampPeriodStartDay(25), 25);
    });
  });

  group('Period.containing, month start day 1', () {
    test('a day mid-month lands in that calendar month', () {
      final period = Period.containing(_day(2026, 3, 15), monthStartDay: 1);
      expect(period.startDate, DateTime.utc(2026, 3, 1));
      expect(period.lastDate, DateTime.utc(2026, 3, 31));
    });

    test('December rolls into a January end', () {
      final period = Period.containing(_day(2026, 12, 10), monthStartDay: 1);
      expect(period.startDate, DateTime.utc(2026, 12, 1));
      expect(period.lastDate, DateTime.utc(2026, 12, 31));
      expect(period.next.startDate, DateTime.utc(2027, 1, 1));
    });
  });

  group('Period.containing, a payday-aligned start day', () {
    test('before the start day falls in the previous month\'s period', () {
      final period = Period.containing(_day(2026, 3, 20), monthStartDay: 25);
      expect(period.startDate, DateTime.utc(2026, 2, 25));
      expect(period.lastDate, DateTime.utc(2026, 3, 24));
    });

    test('on or after the start day falls in this month\'s period', () {
      final period = Period.containing(_day(2026, 3, 25), monthStartDay: 25);
      expect(period.startDate, DateTime.utc(2026, 3, 25));
      expect(period.lastDate, DateTime.utc(2026, 4, 24));
    });

    test('a start day capped to 28 never lands on a short February', () {
      final period = Period.containing(_day(2026, 2, 20), monthStartDay: 28);
      expect(period.startDate, DateTime.utc(2026, 1, 28));
      expect(period.lastDate, DateTime.utc(2026, 2, 27));
    });
  });

  group('next / previous', () {
    test('round-trip back to the same period', () {
      final period = Period.containing(_day(2026, 6, 5), monthStartDay: 10);
      expect(period.next.previous, period);
    });

    test('contains is true only within [startDay, endDayExclusive)', () {
      final period = Period.containing(_day(2026, 3, 15), monthStartDay: 1);
      expect(period.contains(_day(2026, 3, 1)), isTrue);
      expect(period.contains(_day(2026, 3, 31)), isTrue);
      expect(period.contains(_day(2026, 2, 28)), isFalse);
      expect(period.contains(_day(2026, 4, 1)), isFalse);
    });
  });

  group('R3.4 custom start, payday 25th', () {
    Period setNow(int today, {required bool later}) {
      final c = setNowEndChoices(today, monthStartDay: 25);
      return Period(startDay: today, endDayExclusive: later ? c.later : c.coming, monthStartDay: 25);
    }

    Period effective(int today, Period custom) => effectivePeriod(today,
        monthStartDay: 25, customStart: custom.startDay, customEndExclusive: custom.endDayExclusive);

    test('set on 7 Oct ends 24 Oct', () {
      final custom = setNow(_day(2026, 10, 7), later: false);
      final p = effective(_day(2026, 10, 7), custom);
      expect(p.startDate, DateTime.utc(2026, 10, 7));
      expect(p.lastDate, DateTime.utc(2026, 10, 24));
      expect(p.next.startDate, DateTime.utc(2026, 10, 25));
      expect(p.next.lastDate, DateTime.utc(2026, 11, 24));
    });

    test('set on 20 Oct ends 24 Nov; 25 Nov starts a normal period', () {
      final custom = setNow(_day(2026, 10, 20), later: true);
      expect(effective(_day(2026, 11, 3), custom).startDate, DateTime.utc(2026, 10, 20));
      expect(effective(_day(2026, 11, 24), custom).lastDate, DateTime.utc(2026, 11, 24));
      final after = effective(_day(2026, 11, 25), custom);
      expect(after, Period.containing(_day(2026, 11, 25), monthStartDay: 25));
      expect(after.startDate, DateTime.utc(2026, 11, 25));
      expect(after.lastDate, DateTime.utc(2026, 12, 24));
    });

    test('no override is exactly Period.containing', () {
      expect(effectivePeriod(_day(2026, 10, 7), monthStartDay: 25),
          Period.containing(_day(2026, 10, 7), monthStartDay: 25));
    });
  });

  group('R3.5 Atur sekarang default chip', () {
    test('on the 14th the coming 24th is the default', () {
      final c = setNowEndChoices(_day(2026, 10, 14), monthStartDay: 25);
      expect(c.laterIsDefault, isFalse);
      expect(c.coming, _day(2026, 10, 25));
      expect(c.later, _day(2026, 11, 25));
    });

    test('on the 15th the 24th after it is the default', () {
      final c = setNowEndChoices(_day(2026, 10, 15), monthStartDay: 25);
      expect(c.laterIsDefault, isTrue);
      expect(c.later, _day(2026, 11, 25));
    });
  });
}
