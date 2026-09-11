/// The bill-reminder copy: names the specific expense and, when the
/// wallet it'll be paid from can't cover it, the shortfall — per
/// plan/05-sprints.md Sprint 13, "Reminder copy naming the specific
/// expense and the shortfall." A generic "you have a bill due" is exactly
/// what every audited competitor already does; naming the number is the
/// point.
String reminderBody({
  required String itemLabel,
  required int amountMinor,
  required int walletBalanceMinor,
  required String walletName,
  required String Function(int minor) formatMoney,
}) {
  final amount = formatMoney(amountMinor);
  final shortfall = amountMinor - walletBalanceMinor;
  if (shortfall > 0) {
    return '$itemLabel $amount jatuh tempo, saldo $walletName ${formatMoney(walletBalanceMinor)}, '
        'kurang ${formatMoney(shortfall)}.';
  }
  return '$itemLabel $amount jatuh tempo hari ini.';
}

/// A variable-amount item names the expected range instead of one number,
/// since the placeholder amount used to materialise it is a lower bound,
/// not a real figure — plan/05-sprints.md Sprint 12, "variable-amount
/// items with an expected range".
String reminderBodyForRange({
  required String itemLabel,
  required int expectedMinMinor,
  required int expectedMaxMinor,
  required String Function(int minor) formatMoney,
}) {
  return '$itemLabel jatuh tempo hari ini, biasanya '
      '${formatMoney(expectedMinMinor)}-${formatMoney(expectedMaxMinor)}.';
}
