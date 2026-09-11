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
}
