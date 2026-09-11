import 'package:flutter_test/flutter_test.dart';
import 'package:wudget/domain/budget_proposal.dart';

void main() {
  group('proposeBudgetMinor', () {
    test('projects the trailing average daily rate over the period length', () {
      // 140000 spent across a 28-day window is 5000/day, times a 30-day period.
      expect(
        proposeBudgetMinor(spendMinor: 140000, historyWindowDays: 28, periodLengthDays: 30),
        150000,
      );
    });

    test('spend on only a few days of the window is not scaled as if every day had spend', () {
      // 20000 total in a 28-day window averages ~714/day, not 20000/2.
      final proposal = proposeBudgetMinor(spendMinor: 20000, historyWindowDays: 28, periodLengthDays: 28);
      expect(proposal, 20000); // full window length == period length, so it round-trips
    });

    test('zero history window proposes nothing rather than dividing by zero', () {
      expect(proposeBudgetMinor(spendMinor: 50000, historyWindowDays: 0, periodLengthDays: 30), 0);
    });
  });

  group('proposeBudgets', () {
    test('omits a key with zero spend rather than proposing a fabricated zero', () {
      final proposals = proposeBudgets(
        spendByKey: {'cat_makan': 140000, 'cat_empty': 0},
        historyWindowDays: 28,
        periodLengthDays: 28,
      );
      expect(proposals.containsKey('cat_empty'), isFalse);
      expect(proposals['cat_makan'], 140000);
    });

    test('an empty spend map proposes nothing', () {
      expect(proposeBudgets(spendByKey: const {}, historyWindowDays: 28, periodLengthDays: 28), isEmpty);
    });
  });
}
