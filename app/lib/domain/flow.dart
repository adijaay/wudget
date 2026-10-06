/// The arithmetic behind Pantau's "Aliran" view: one closed period's money
/// from where it came in to where it went out. Built to
/// design/Aliran.dc.html.
///
/// A flow diagram is only honest about a period that has finished, so the
/// caller passes a closed period. A period still running would draw bands
/// that grow after you look away.
library;

/// One outgoing band of the flow.
class FlowBand {
  const FlowBand({required this.name, required this.amountMinor, required this.hueIndex});
  final String name;
  final int amountMinor;

  /// The category's own hue index, so a band is the same colour this
  /// category carries everywhere else. -1 for the pooled remainder, which
  /// has no category of its own.
  final int hueIndex;

  bool get isRemainder => hueIndex < 0;
}

/// Chart rule 2 in design/Tokens.dc.html: at most five named slices, the
/// rest pooled into one remainder.
const maxNamedFlowBands = 5;

/// Income split into what was spent and what was left, and the spend split
/// into categories.
class FlowBreakdown {
  const FlowBreakdown({
    required this.incomeMinor,
    required this.spentMinor,
    required this.savedMinor,
    required this.bands,
  });

  final int incomeMinor;
  final int spentMinor;

  /// Income minus spend. Negative when the period spent more than it
  /// earned, which the diagram cannot draw as a band — see [isDeficit].
  final int savedMinor;

  /// The spend, broken into at most [maxNamedFlowBands] named bands plus
  /// one pooled remainder. Ordered largest first, remainder last.
  final List<FlowBand> bands;

  /// A period that spent more than it earned has no "ditabung" band, and
  /// drawing one at zero width would imply it merely rounded away. The
  /// view says so in words instead.
  bool get isDeficit => savedMinor < 0;

  /// Saved as a fraction of income, for "dari tiap Rp 100.000 yang masuk".
  /// `num`, not the banned float type — this is a ratio, not an amount.
  num get savedFraction => incomeMinor == 0 ? 0 : savedMinor / incomeMinor;
}

/// Null when the period has no income: a flow with no source has nothing
/// honest to draw, so the view renders the reason rather than a diagram
/// hanging off a zero (chart rule 8).
FlowBreakdown? buildFlowBreakdown({
  required int incomeMinor,
  required int expenseMinor,
  required List<({String name, int amountMinor, int hueIndex})> ranks,
  String remainderLabel = 'Lainnya',
}) {
  if (incomeMinor <= 0) return null;

  final sorted = [...ranks]..sort((a, b) => b.amountMinor.compareTo(a.amountMinor));
  final named = sorted.take(maxNamedFlowBands);
  final pooled = sorted.skip(maxNamedFlowBands).fold<int>(0, (sum, r) => sum + r.amountMinor);

  // The ranked categories can total less than the period's expense when a
  // transaction carries no category leg. That difference is real spend, so
  // it joins the remainder rather than vanishing and leaving the bands
  // narrower than the trunk they hang off.
  final categorised = sorted.fold<int>(0, (sum, r) => sum + r.amountMinor);
  final uncategorised = expenseMinor - categorised;
  final remainder = pooled + (uncategorised > 0 ? uncategorised : 0);

  return FlowBreakdown(
    incomeMinor: incomeMinor,
    spentMinor: expenseMinor,
    savedMinor: incomeMinor - expenseMinor,
    bands: [
      for (final r in named)
        FlowBand(name: r.name, amountMinor: r.amountMinor, hueIndex: r.hueIndex),
      if (remainder > 0)
        FlowBand(name: remainderLabel, amountMinor: remainder, hueIndex: -1),
    ],
  );
}

/// One category's movement between two periods, for "yang berubah dari"
/// the period before. Direction is carried by the sign and by an arrow in
/// the view, never by colour alone.
class CategoryDelta {
  const CategoryDelta({
    required this.name,
    required this.deltaMinor,
    required this.hueIndex,
  });
  final String name;
  final int deltaMinor;
  final int hueIndex;

  bool get isFlat => deltaMinor == 0;
}

/// Per-category change from [previous] to [current], largest movement
/// first. Categories present in only one of the two periods count as a
/// move from or to zero, so a category that stopped entirely still shows.
List<CategoryDelta> buildCategoryDeltas({
  required List<({String key, String name, int amountMinor, int hueIndex})> current,
  required List<({String key, String name, int amountMinor, int hueIndex})> previous,
  int limit = 5,
}) {
  final previousByKey = {for (final r in previous) r.key: r.amountMinor};
  final nameByKey = <String, String>{};
  final hueByKey = <String, int>{};
  for (final r in [...previous, ...current]) {
    nameByKey[r.key] = r.name;
    hueByKey[r.key] = r.hueIndex;
  }

  final deltas = <CategoryDelta>[];
  for (final key in {...previousByKey.keys, ...current.map((r) => r.key)}) {
    final now = current.where((r) => r.key == key).fold<int>(0, (s, r) => s + r.amountMinor);
    final delta = now - (previousByKey[key] ?? 0);
    deltas.add(CategoryDelta(
      name: nameByKey[key] ?? key,
      deltaMinor: delta,
      hueIndex: hueByKey[key] ?? 0,
    ));
  }

  deltas.sort((a, b) => b.deltaMinor.abs().compareTo(a.deltaMinor.abs()));
  return deltas.take(limit).toList();
}
