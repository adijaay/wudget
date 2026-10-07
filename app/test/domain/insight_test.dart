import 'package:flutter_test/flutter_test.dart';
import 'package:wudget/domain/flow.dart';
import 'package:wudget/domain/insight.dart';
import 'package:wudget/domain/pola.dart';

void main() {
  const a = Insight(key: 'a', text: 'A');
  const b = Insight(key: 'b', text: 'B');

  test('jatah with the mockup numbers: Rp 2.394.000 over 18 days is Rp 133.000', () {
    final allowance = computeDailyAllowance(budgetTotalMinor: 4500000, spentMinor: 2106000, daysRemaining: 18)!;
    expect(allowance.remainingMinor, 2394000);
    expect(allowance.perDayMinor, 133000);
  });

  test('the sentence shown yesterday is not picked today', () {
    final picked = pickDailyInsight(candidates: [a, b], recent: [(day: 9, key: 'a')], today: 10);
    expect(picked?.key, 'b');
  });

  test('a sentence shown earlier today stays for the rest of the day', () {
    final picked = pickDailyInsight(candidates: [a, b], recent: [(day: 10, key: 'b')], today: 10);
    expect(picked?.key, 'b');
  });

  test('nothing new means nothing, never a stale sentence', () {
    final recent = [(day: 9, key: 'a'), (day: 8, key: 'b')];
    expect(pickDailyInsight(candidates: [a, b], recent: recent, today: 10), isNull);
    expect(pickDailyInsight(candidates: const [], recent: const [], today: 10), isNull);
  });

  test('a sentence older than the last seven can come back', () {
    final recent = [for (var i = 0; i < 7; i++) (day: 9 - i, key: 'x$i'), (day: 1, key: 'a')];
    expect(pickDailyInsight(candidates: [a], recent: recent, today: 10)?.key, 'a');
  });

  test('candidates come from Pola and Aliran results', () {
    final candidates = insightCandidates(
      weekDeltas: const [CategoryDelta(name: 'Makan', deltaMinor: -84000, hueIndex: 0)],
      pattern: computeWeekdayPattern(
        // Day 4 is a Monday; two full weeks, spend on four weekdays, Saturday the peak.
        dailyExpenseMinor: {4: 10000, 6: 10000, 9: 50000, 10: 30000, 13: 10000},
        sinceDayInclusive: 4,
        untilDayExclusive: 18,
      ),
      lastPeriodFlow: buildFlowBreakdown(incomeMinor: 1000000, expenseMinor: 800000, ranks: const []),
    );
    expect(candidates.map((c) => c.text.replaceAll(' ', ' ')), [
      'Makan minggu ini Rp 84.000 lebih sedikit dari minggu lalu.',
      'Akhir pekan rata-rata Rp 20.000 per hari, hari kerja Rp 3.000.',
      'Pengeluaranmu paling besar biasanya di hari Sabtu.',
      'Periode lalu, dari tiap Rp 100.000 yang masuk, Rp 20.000 tersisa.',
    ]);
  });

  test('one entry is not a pattern: no weekday or weekend sentence', () {
    final candidates = insightCandidates(
      pattern: computeWeekdayPattern(dailyExpenseMinor: {6: 25000}, sinceDayInclusive: 4, untilDayExclusive: 18),
    );
    expect(candidates, isEmpty);
  });
}
