import 'pace.dart' show tagihanCategoryId;
import 'payday.dart' show tabunganCategoryId;

/// One category's spend for a period — the subset of
/// `data/category_rank_queries.dart`'s `CategoryRank` this pure function
/// needs, restated here so domain/ has no dependency on data/.
typedef CategorySpend = ({String key, String name, int amountMinor});

/// What the period-close ritual shows — plan/02-flows.md #7: "total in,
/// total out, the largest category, and the one thing that differed most
/// from the previous period," plus one interpreted sentence and the
/// surplus. Built once from already-fetched data, so it's pure and
/// testable without a database.
class PeriodCloseSummary {
  const PeriodCloseSummary({
    required this.incomeMinor,
    required this.expenseMinor,
    required this.largestCategoryName,
    required this.largestCategoryAmountMinor,
    required this.mostChangedCategoryName,
    required this.mostChangedCategoryDeltaMinor,
  });

  final int incomeMinor;
  final int expenseMinor;

  /// Null only when there's no categorised spend at all this period —
  /// `buildPeriodCloseSummary` returns null entirely in that case, so
  /// these are non-null whenever a summary exists.
  final String? largestCategoryName;
  final int largestCategoryAmountMinor;

  /// The category whose spend changed the most (in either direction)
  /// against the previous period — null if there's no previous period to
  /// compare against.
  final String? mostChangedCategoryName;

  /// Signed: positive means it grew versus the previous period.
  final int mostChangedCategoryDeltaMinor;

  int get surplusMinor => incomeMinor - expenseMinor;

  /// One sentence a person would say out loud — chart rule 6.
  String sentence(String Function(int minor) formatCompact) {
    final expense = formatCompact(expenseMinor);
    if (mostChangedCategoryName == null) {
      return 'Periode ini kamu menghabiskan $expense, paling banyak di $largestCategoryName.';
    }
    final direction = mostChangedCategoryDeltaMinor >= 0 ? 'naik' : 'turun';
    final delta = formatCompact(mostChangedCategoryDeltaMinor.abs());
    return 'Periode ini kamu menghabiskan $expense. $mostChangedCategoryName $direction $delta '
        'dibanding periode sebelumnya.';
  }
}

/// Builds the summary from the closing period's and previous period's
/// ranked category spend — null when there's nothing to summarise, so the
/// ritual can be skipped entirely rather than shown as an empty ceremony
/// (plan/02-flows.md: "No data for the closing period: skip the ritual").
PeriodCloseSummary? buildPeriodCloseSummary({
  required int incomeMinor,
  required int expenseMinor,
  required List<CategorySpend> closingRanks,
  required List<CategorySpend> previousRanks,
}) {
  if (closingRanks.isEmpty) return null;

  final largest = closingRanks.first;

  final nameByKey = <String, String>{};
  final closingByKey = <String, int>{};
  final previousByKey = <String, int>{};
  for (final r in closingRanks) {
    nameByKey[r.key] = r.name;
    closingByKey[r.key] = r.amountMinor;
  }
  for (final r in previousRanks) {
    nameByKey.putIfAbsent(r.key, () => r.name);
    previousByKey[r.key] = r.amountMinor;
  }

  String? mostChangedName;
  var mostChangedDelta = 0;
  for (final key in nameByKey.keys) {
    final delta = (closingByKey[key] ?? 0) - (previousByKey[key] ?? 0);
    if (delta.abs() > mostChangedDelta.abs()) {
      mostChangedDelta = delta;
      mostChangedName = nameByKey[key];
    }
  }
  // No previous-period data at all means there's nothing honest to
  // compare against yet, not a delta of zero for every category.
  if (previousRanks.isEmpty) {
    mostChangedName = null;
    mostChangedDelta = 0;
  }

  return PeriodCloseSummary(
    incomeMinor: incomeMinor,
    expenseMinor: expenseMinor,
    largestCategoryName: largest.name,
    largestCategoryAmountMinor: largest.amountMinor,
    mostChangedCategoryName: mostChangedName,
    mostChangedCategoryDeltaMinor: mostChangedDelta,
  );
}

/// The shareable recap card (screen 5): only the user's own numbers.
class PeriodRecap {
  const PeriodRecap({
    required this.planMinor,
    required this.spentMinor,
    this.bestHeldName,
    this.bestHeldPercent = 0,
    this.overName,
    this.overMinor = 0,
    this.overCount = 0,
  });

  final int planMinor;
  final int spentMinor;
  final String? bestHeldName;
  final int bestHeldPercent;
  final String? overName;
  final int overMinor;
  final int overCount;

  int get leftoverMinor => planMinor - spentMinor;

  String sentence(String Function(int minor) format) {
    final head = leftoverMinor >= 0
        ? 'Sisa ${format(leftoverMinor)}.'
        : 'Lewat ${format(-leftoverMinor)} dari rencana.';
    final tail = switch (overCount) {
      0 => 'Semua kantong aman.',
      1 => '$overName lewat sedikit, yang lain aman.',
      _ => '$overName lewat paling banyak.',
    };
    return '$head $tail';
  }
}

/// Spent comes from [summary] so the card and the close sheet agree; money
/// moved into Tabungan is savings, so it counts neither as spent nor as over.
PeriodRecap? buildPeriodRecap({
  required PeriodCloseSummary summary,
  required Map<String, int> planByKey,
  required Map<String, int> spentByKey,
  required Map<String, String> nameByKey,
}) {
  final plan = {...planByKey}..remove(tabunganCategoryId);
  plan.removeWhere((_, v) => v <= 0);
  if (plan.isEmpty) return null;

  String? bestKey;
  num? bestShare;
  String? overKey;
  var overMinor = 0;
  var overCount = 0;
  for (final MapEntry(:key, value: planned) in plan.entries) {
    final spent = spentByKey[key] ?? 0;
    final share = spent / planned;
    if (key != tagihanCategoryId && (bestShare == null || share < bestShare)) {
      bestShare = share;
      bestKey = key;
    }
    if (spent > planned) {
      overCount++;
      if (spent - planned > overMinor) {
        overMinor = spent - planned;
        overKey = key;
      }
    }
  }

  return PeriodRecap(
    planMinor: plan.values.fold(0, (a, b) => a + b),
    spentMinor: summary.expenseMinor - (spentByKey[tabunganCategoryId] ?? 0),
    bestHeldName: bestKey == null ? null : nameByKey[bestKey] ?? bestKey,
    bestHeldPercent: bestKey == null ? 0 : (bestShare! * 100).round(),
    overName: overKey == null ? null : nameByKey[overKey] ?? overKey,
    overMinor: overMinor,
    overCount: overCount,
  );
}
