import 'package:flutter_test/flutter_test.dart';
import 'package:wudget/domain/period_close.dart';

String _fmt(int minor) => 'Rp${(minor / 1000).round()}rb';

void main() {
  group('buildPeriodCloseSummary', () {
    test('null with no categorised spend this period — the ritual is skipped, not empty', () {
      final summary = buildPeriodCloseSummary(
        incomeMinor: 500000,
        expenseMinor: 0,
        closingRanks: const [],
        previousRanks: const [],
      );
      expect(summary, isNull);
    });

    test('the largest category is the top of the closing ranks', () {
      final summary = buildPeriodCloseSummary(
        incomeMinor: 500000,
        expenseMinor: 300000,
        closingRanks: const [
          (key: 'cat_makan', name: 'Makan', amountMinor: 200000),
          (key: 'cat_transport', name: 'Transport', amountMinor: 100000),
        ],
        previousRanks: const [],
      );
      expect(summary!.largestCategoryName, 'Makan');
      expect(summary.largestCategoryAmountMinor, 200000);
    });

    test('no previous period means no most-changed category, not a zero delta', () {
      final summary = buildPeriodCloseSummary(
        incomeMinor: 500000,
        expenseMinor: 200000,
        closingRanks: const [(key: 'cat_makan', name: 'Makan', amountMinor: 200000)],
        previousRanks: const [],
      );
      expect(summary!.mostChangedCategoryName, isNull);
      expect(summary.sentence(_fmt), isNot(contains('naik')));
      expect(summary.sentence(_fmt), isNot(contains('turun')));
    });

    test('picks the category with the largest absolute change, in either direction', () {
      final summary = buildPeriodCloseSummary(
        incomeMinor: 500000,
        expenseMinor: 300000,
        closingRanks: const [
          (key: 'cat_makan', name: 'Makan', amountMinor: 150000), // +50000
          (key: 'cat_transport', name: 'Transport', amountMinor: 50000), // -150000
        ],
        previousRanks: const [
          (key: 'cat_makan', name: 'Makan', amountMinor: 100000),
          (key: 'cat_transport', name: 'Transport', amountMinor: 200000),
        ],
      );
      expect(summary!.mostChangedCategoryName, 'Transport');
      expect(summary.mostChangedCategoryDeltaMinor, -150000);
      expect(summary.sentence(_fmt), contains('turun'));
    });

    test('a category dropped entirely still counts as a change, via its previous amount', () {
      final summary = buildPeriodCloseSummary(
        incomeMinor: 500000,
        expenseMinor: 50000,
        closingRanks: const [(key: 'cat_makan', name: 'Makan', amountMinor: 50000)],
        previousRanks: const [
          (key: 'cat_makan', name: 'Makan', amountMinor: 50000),
          (key: 'cat_hiburan', name: 'Hiburan', amountMinor: 300000),
        ],
      );
      expect(summary!.mostChangedCategoryName, 'Hiburan');
      expect(summary.mostChangedCategoryDeltaMinor, -300000);
    });

    test('surplusMinor is income minus expense', () {
      final summary = buildPeriodCloseSummary(
        incomeMinor: 500000,
        expenseMinor: 300000,
        closingRanks: const [(key: 'cat_makan', name: 'Makan', amountMinor: 300000)],
        previousRanks: const [],
      );
      expect(summary!.surplusMinor, 200000);
    });
  });
}
