import 'package:flutter_test/flutter_test.dart';
import 'package:wudget/domain/flow.dart';

({String name, int amountMinor, int hueIndex}) _rank(String name, int amount, [int hue = 0]) =>
    (name: name, amountMinor: amount, hueIndex: hue);

({String key, String name, int amountMinor, int hueIndex}) _keyed(
  String key,
  int amount, [
  int hue = 0,
]) =>
    (key: key, name: key, amountMinor: amount, hueIndex: hue);

void main() {
  group('buildFlowBreakdown', () {
    test('a period with no income has nothing to draw', () {
      expect(
        buildFlowBreakdown(incomeMinor: 0, expenseMinor: 50000, ranks: [_rank('Makan', 50000)]),
        isNull,
      );
    });

    test('bands never exceed five named plus one remainder', () {
      final flow = buildFlowBreakdown(
        incomeMinor: 1000000,
        expenseMinor: 280000,
        ranks: [
          for (var i = 0; i < 9; i++) _rank('Kategori $i', 100000 - i * 10000, i),
        ],
      )!;
      expect(flow.bands.length, maxNamedFlowBands + 1);
      expect(flow.bands.last.isRemainder, isTrue);
      expect(flow.bands.take(maxNamedFlowBands).every((b) => !b.isRemainder), isTrue);
    });

    test('bands plus savings account for every rupiah of income', () {
      final flow = buildFlowBreakdown(
        incomeMinor: 850000000,
        expenseMinor: 621000000,
        ranks: [
          _rank('Rumah', 210000000, 3),
          _rank('Makan', 178000000, 0),
          _rank('Transport', 103000000, 1),
          _rank('Belanja', 47000000, 2),
          _rank('Hiburan', 50000000, 4),
          _rank('Kesehatan', 33000000, 5),
        ],
      )!;
      final banded = flow.bands.fold<int>(0, (sum, b) => sum + b.amountMinor);
      expect(banded, flow.spentMinor);
      expect(banded + flow.savedMinor, flow.incomeMinor);
    });

    test('spend with no category joins the remainder instead of vanishing', () {
      // Expense is 100000 but only 60000 is categorised. Without this, the
      // bands would total less than the trunk they hang off.
      final flow = buildFlowBreakdown(
        incomeMinor: 500000,
        expenseMinor: 100000,
        ranks: [_rank('Makan', 60000)],
      )!;
      expect(flow.bands.fold<int>(0, (s, b) => s + b.amountMinor), 100000);
      expect(flow.bands.last.isRemainder, isTrue);
      expect(flow.bands.last.amountMinor, 40000);
    });

    test('no remainder band when the named categories are the whole spend', () {
      final flow = buildFlowBreakdown(
        incomeMinor: 500000,
        expenseMinor: 60000,
        ranks: [_rank('Makan', 60000)],
      )!;
      expect(flow.bands.length, 1);
      expect(flow.bands.single.isRemainder, isFalse);
    });

    test('spending more than you earned is a deficit, not a zero-width band', () {
      final flow = buildFlowBreakdown(
        incomeMinor: 100000,
        expenseMinor: 150000,
        ranks: [_rank('Makan', 150000)],
      )!;
      expect(flow.isDeficit, isTrue);
      expect(flow.savedMinor, -50000);
    });

    test('saved fraction drives the "dari tiap Rp 100.000" sentence', () {
      final flow = buildFlowBreakdown(
        incomeMinor: 850000000,
        expenseMinor: 621000000,
        ranks: [_rank('Rumah', 621000000)],
      )!;
      expect((flow.savedFraction * 100).round(), 27);
    });
  });

  group('buildCategoryDeltas', () {
    test('sorted by size of movement, not by amount spent', () {
      final deltas = buildCategoryDeltas(
        current: [_keyed('Rumah', 210000000), _keyed('Belanja', 47000000)],
        previous: [_keyed('Rumah', 210000000), _keyed('Belanja', 35000000)],
      );
      // Rumah is by far the bigger category but it did not move.
      expect(deltas.first.name, 'Belanja');
      expect(deltas.first.deltaMinor, 12000000);
      expect(deltas.last.isFlat, isTrue);
    });

    test('a category that stopped entirely still shows, as a move to zero', () {
      final deltas = buildCategoryDeltas(
        current: [_keyed('Makan', 50000)],
        previous: [_keyed('Makan', 50000), _keyed('Hiburan', 30000)],
      );
      final hiburan = deltas.firstWhere((d) => d.name == 'Hiburan');
      expect(hiburan.deltaMinor, -30000);
    });

    test('a brand new category is a move from zero', () {
      final deltas = buildCategoryDeltas(
        current: [_keyed('Kesehatan', 80000)],
        previous: const [],
      );
      expect(deltas.single.deltaMinor, 80000);
    });
  });
}
