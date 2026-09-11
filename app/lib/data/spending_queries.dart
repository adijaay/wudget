import 'database.dart';

/// Sum of every posting's category leg — i.e. actual spending/income,
/// never transfers. A transfer (including a card payment) has no category
/// leg by construction (plan/03-architecture.md, "How the four kinds map
/// to postings"), so it is structurally excluded here rather than filtered
/// by transaction kind — the same guarantee Pantau's aggregates will read
/// from once that tab exists (Sprint 8+).
Future<int> totalCategorySpendMinor(WudgetDatabase db) async {
  final postings = await (db.select(db.postings)..where((p) => p.categoryId.isNotNull())).get();
  return postings.fold<int>(0, (sum, p) => sum + p.amountMinor);
}
