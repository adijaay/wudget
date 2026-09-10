import 'currency.dart';

/// An amount of money as an integer count of the currency's smallest unit.
///
/// Never a `double`. Three of the six competitor apps audited in
/// `research/07-ui-audit.md` render the same fact two different ways on one
/// screen (a rounded tile next to a precise total, a currency mismatch
/// between a header and its rows). That class of bug is what this type
/// exists to make structurally impossible: there is exactly one
/// representation of an amount, and rendering happens only through
/// `MoneyFormatter`.
class Money {
  const Money._(this.minor, this.currency);

  /// Build from a whole count of minor units (e.g. 15000 for Rp 15.000,
  /// or 1250 for USD 12.50).
  factory Money.fromMinor(int minor, String currency) {
    if (!CurrencyInfo.isKnown(currency)) {
      throw ArgumentError.value(currency, 'currency', 'Unknown currency code');
    }
    return Money._(minor, currency.toUpperCase());
  }

  /// Build from a major-unit decimal amount, e.g. `Money.fromMajor(12.50, 'USD')`.
  /// Rounds to the nearest minor unit; only ever call this at an input
  /// boundary (parsing user text), never inside arithmetic.
  factory Money.fromMajor(num major, String currency) {
    final info = CurrencyInfo.of(currency);
    final minor = (major * info.minorUnitsPerMajor).round();
    return Money._(minor, currency.toUpperCase());
  }

  factory Money.zero(String currency) => Money.fromMinor(0, currency);

  final int minor;
  final String currency;

  CurrencyInfo get currencyInfo => CurrencyInfo.of(currency);

  bool get isZero => minor == 0;
  bool get isNegative => minor < 0;
  bool get isPositive => minor > 0;

  Money get abs => minor < 0 ? Money._(-minor, currency) : this;
  Money get negated => Money._(-minor, currency);

  void _assertSameCurrency(Money other) {
    if (other.currency != currency) {
      throw StateError(
        'Cannot combine $currency and ${other.currency} directly; convert '
        'through an explicit, dated exchange rate first (see FX handling in '
        'plan/03-architecture.md). Money arithmetic never coerces currencies.',
      );
    }
  }

  Money operator +(Money other) {
    _assertSameCurrency(other);
    return Money._(minor + other.minor, currency);
  }

  Money operator -(Money other) {
    _assertSameCurrency(other);
    return Money._(minor - other.minor, currency);
  }

  Money operator -() => negated;

  bool operator <(Money other) {
    _assertSameCurrency(other);
    return minor < other.minor;
  }

  bool operator <=(Money other) {
    _assertSameCurrency(other);
    return minor <= other.minor;
  }

  bool operator >(Money other) {
    _assertSameCurrency(other);
    return minor > other.minor;
  }

  bool operator >=(Money other) {
    _assertSameCurrency(other);
    return minor >= other.minor;
  }

  /// Split into [n] roughly-equal parts whose minor units sum back to this
  /// amount exactly — the remainder (from integer division) is distributed
  /// one minor unit at a time to the first parts, so nothing is lost or
  /// invented. Needed for the split-transaction flow (plan/02-flows.md #2)
  /// where a user divides one amount across several categories.
  List<Money> splitEvenly(int n) {
    if (n <= 0) throw ArgumentError.value(n, 'n', 'must be positive');
    final base = minor ~/ n;
    final remainder = minor - base * n;
    return List<Money>.generate(n, (i) {
      final extra = i < remainder.abs() ? remainder.sign : 0;
      return Money._(base + extra, currency);
    });
  }

  /// The major-unit decimal value, for interop with things that genuinely
  /// need a number (e.g. a chart library's axis). Never round-trip this
  /// back into a new `Money` for a running balance — accumulate in minor
  /// units and only convert to major at the final render step.
  double toMajorForDisplayOnly() => minor / currencyInfo.minorUnitsPerMajor;

  @override
  bool operator ==(Object other) =>
      other is Money && other.minor == minor && other.currency == currency;

  @override
  int get hashCode => Object.hash(minor, currency);

  @override
  String toString() => 'Money($minor $currency)';
}

/// Sums a list of same-currency amounts. Throws if the list is empty (there
/// is no currency to default to) or mixes currencies.
Money sumMoney(Iterable<Money> amounts) {
  final list = amounts.toList();
  if (list.isEmpty) {
    throw ArgumentError('sumMoney requires at least one amount');
  }
  var total = Money.zero(list.first.currency);
  for (final m in list) {
    total = total + m;
  }
  return total;
}
