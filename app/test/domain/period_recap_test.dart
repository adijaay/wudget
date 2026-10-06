import 'package:flutter_test/flutter_test.dart';
import 'package:wudget/domain/period_close.dart';

String _fmt(int minor) => 'Rp$minor';

PeriodCloseSummary _summary(int expense) => PeriodCloseSummary(
      incomeMinor: 0,
      expenseMinor: expense,
      largestCategoryName: 'Makan',
      largestCategoryAmountMinor: 0,
      mostChangedCategoryName: null,
      mostChangedCategoryDeltaMinor: 0,
    );

void main() {
  const names = {'cat_makan': 'Makan', 'cat_transport': 'Transport', 'cat_hiburan': 'Hiburan', 'cat_tagihan': 'Tagihan'};

  test('screen 5: spent against plan, best held, the one over, one sentence', () {
    final recap = buildPeriodRecap(
      summary: _summary(1640000),
      planByKey: const {'cat_makan': 1000000, 'cat_transport': 500000, 'cat_hiburan': 200000, 'cat_tagihan': 300000, 'cat_tabungan': 400000},
      spentByKey: const {'cat_makan': 900000, 'cat_transport': 395000, 'cat_hiburan': 270000, 'cat_tagihan': 300000, 'cat_tabungan': 225000},
      nameByKey: names,
    )!;
    expect(recap.planMinor, 2000000); // Tabungan is savings, not plan
    expect(recap.spentMinor, 1415000); // the summary's expense less what went to Tabungan
    expect(recap.bestHeldName, 'Transport');
    expect(recap.bestHeldPercent, 79);
    expect(recap.overName, 'Hiburan');
    expect(recap.overMinor, 70000);
    expect(recap.sentence(_fmt), 'Sisa Rp585000. Hiburan lewat sedikit, yang lain aman.');
  });

  test('over the whole plan and no kantong over says so without a leftover', () {
    final recap = buildPeriodRecap(
      summary: _summary(1200000),
      planByKey: const {'cat_makan': 1000000},
      spentByKey: const {'cat_makan': 1000000},
      nameByKey: names,
    )!;
    expect(recap.leftoverMinor, -200000);
    expect(recap.overName, isNull);
    expect(recap.sentence(_fmt), 'Lewat Rp200000 dari rencana. Semua kantong aman.');
  });

  test('no plan, no recap', () {
    expect(
      buildPeriodRecap(summary: _summary(5), planByKey: const {'cat_tabungan': 9}, spentByKey: const {}, nameByKey: names),
      isNull,
    );
  });
}
