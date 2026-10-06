const tabunganCategoryId = 'cat_tabungan';

/// Last period's income (plus money on hand for an "Atur sekarang" period)
/// minus its spending; an overspent period leaves 0.
int periodLeftoverMinor({required int incomeMinor, required int expenseMinor, int onHandMinor = 0}) {
  final left = onHandMinor + incomeMinor - expenseMinor;
  return left > 0 ? left : 0;
}

/// Every rupiah of [totalMinor] placed: the kantong as given, the rest to
/// Tabungan (never below 0). Any Tabungan amount in [kantong] is replaced.
Map<String, int> placeEveryRupiah(int totalMinor, Map<String, int> kantong) {
  final rest = {...kantong}..remove(tabunganCategoryId);
  final placed = rest.values.fold<int>(0, (a, b) => a + b);
  return {...rest, tabunganCategoryId: totalMinor > placed ? totalMinor - placed : 0};
}
