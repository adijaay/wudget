import 'package:flutter_test/flutter_test.dart';
import 'package:wudget/domain/pola.dart';

void main() {
  group('weekdayIndexOf', () {
    test('day bucket 0 is Thursday, so the Monday-first index is 3', () {
      // 1970-01-01 was a Thursday. Getting this wrong rotates the whole
      // weekday chart, which still looks plausible — hence the test.
      expect(weekdayIndexOf(0), 3);
      expect(weekdayIndexOf(4), 0); // 1970-01-05, a Monday
      expect(weekdayIndexOf(2), 5); // 1970-01-03, a Saturday
      expect(weekdayIndexOf(3), 6); // 1970-01-04, a Sunday
    });

    test('matches DateTime.weekday across a run of real dates', () {
      for (var day = 20000; day < 20040; day++) {
        final date = DateTime.utc(1970, 1, 1).add(Duration(days: day));
        expect(weekdayIndexOf(day), date.weekday - 1, reason: 'day $day is $date');
      }
    });
  });

  group('computeWeekdayPattern', () {
    test('a day with no spend counts in the denominator, not as a gap', () {
      // Two Mondays in the window; the user spent on one of them only.
      const monday = 20010; // weekdayIndexOf -> 0
      expect(weekdayIndexOf(monday), 0);
      final pattern = computeWeekdayPattern(
        dailyExpenseMinor: {monday: 100000},
        sinceDayInclusive: monday,
        untilDayExclusive: monday + 14,
      );
      expect(pattern.dayCount[0], 2);
      // 100000 over two Mondays, not 100000 over the one with spend.
      expect(pattern.averageFor(0), 50000);
    });

    test('a weekday absent from the window averages null, never zero', () {
      const monday = 20010;
      final pattern = computeWeekdayPattern(
        dailyExpenseMinor: const {},
        sinceDayInclusive: monday,
        untilDayExclusive: monday + 3, // Mon, Tue, Wed only
      );
      expect(pattern.averageFor(0), 0);
      expect(pattern.averageFor(4), isNull); // no Friday in the window
    });

    test('weekend average pools totals rather than averaging two means', () {
      // Window holds two Saturdays but only one Sunday, so the mean of the
      // two weekday means would not equal the true per-day average.
      const saturday = 20008;
      expect(weekdayIndexOf(saturday), 5);
      final pattern = computeWeekdayPattern(
        dailyExpenseMinor: {
          saturday: 300000,
          saturday + 1: 100000, // Sunday
          saturday + 7: 200000, // second Saturday
        },
        sinceDayInclusive: saturday,
        untilDayExclusive: saturday + 8,
      );
      expect(pattern.dayCount[5], 2);
      expect(pattern.dayCount[6], 1);
      // Pooled: 600000 over three weekend days.
      expect(pattern.weekendAverageMinor, 200000);
      // The mean-of-means would have been (250000 + 100000) / 2 = 175000.
      expect(pattern.weekendAverageMinor, isNot(175000));
    });

    test('peak weekday is null when nothing was spent at all', () {
      final pattern = computeWeekdayPattern(
        dailyExpenseMinor: const {},
        sinceDayInclusive: 20000,
        untilDayExclusive: 20030,
      );
      expect(pattern.peakWeekdayIndex, isNull);
    });
  });

  group('spendIntensityStep', () {
    test('a day with no spend is null, not the palest step', () {
      expect(spendIntensityStep(0, maxMinor: 100000), isNull);
      expect(spendIntensityStep(-500, maxMinor: 100000), isNull);
    });

    test('the month worst day lands on the darkest step', () {
      expect(spendIntensityStep(100000, maxMinor: 100000), spendIntensitySteps - 1);
    });

    test('steps rise monotonically and stay in range', () {
      var previous = -1;
      for (var amount = 1; amount <= 100000; amount += 997) {
        final step = spendIntensityStep(amount, maxMinor: 100000)!;
        expect(step, inInclusiveRange(0, spendIntensitySteps - 1));
        expect(step, greaterThanOrEqualTo(previous));
        previous = step;
      }
    });

    test('the smallest spend of the month is still visible as step 0', () {
      expect(spendIntensityStep(1, maxMinor: 100000), 0);
    });
  });

  group('computeDailyAllowance', () {
    test('no budget set means no number, not zero per day', () {
      expect(
        computeDailyAllowance(budgetTotalMinor: 0, spentMinor: 50000, daysRemaining: 10),
        isNull,
      );
    });

    test('the last day of a period has no days left to spread over', () {
      expect(
        computeDailyAllowance(budgetTotalMinor: 100000, spentMinor: 0, daysRemaining: 0),
        isNull,
      );
    });

    test('spreads what is left over the days that are left', () {
      final allowance = computeDailyAllowance(
        budgetTotalMinor: 450000000,
        spentMinor: 243000000,
        daysRemaining: 19,
      )!;
      expect(allowance.remainingMinor, 207000000);
      expect(
        allowance.perDayMinor,
        207000000 ~/ 19 ~/ dailyAllowanceStepMinor * dailyAllowanceStepMinor,
      );
      expect(allowance.isOverBudget, isFalse);
    });

    test('the per-day figure rounds down to a readable step, never up', () {
      // 2.070.000 over 19 days is 108.947 exactly. Following 109.000 every
      // day would overspend the budget; following 108.000 cannot.
      final allowance = computeDailyAllowance(
        budgetTotalMinor: 4500000,
        spentMinor: 2430000,
        daysRemaining: 19,
      )!;
      expect(allowance.perDayMinor, 108000);
      expect(allowance.perDayMinor * allowance.daysRemaining,
          lessThanOrEqualTo(allowance.remainingMinor));
    });

    test('over budget reports the overspend and no allowance', () {
      final allowance = computeDailyAllowance(
        budgetTotalMinor: 100000,
        spentMinor: 150000,
        daysRemaining: 5,
      )!;
      expect(allowance.isOverBudget, isTrue);
      expect(allowance.remainingMinor, -50000);
      // Never a negative daily allowance, which would render as a negative
      // amount the user is somehow allowed to spend.
      expect(allowance.perDayMinor, 0);
    });
  });
}
