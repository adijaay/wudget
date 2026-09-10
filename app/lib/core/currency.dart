/// The minor-unit exponent for a currency: how many digits after the
/// decimal point one unit of the currency's smallest denomination
/// represents. IDR and JPY have none; most others have two.
///
/// This table exists so [Money] never hardcodes "divide by 100" — that
/// assumption is wrong for IDR, which is most of what wudget stores.
class CurrencyInfo {
  const CurrencyInfo({required this.code, required this.exponent, required this.symbol});

  final String code;
  final int exponent;
  final String symbol;

  int get minorUnitsPerMajor {
    var v = 1;
    for (var i = 0; i < exponent; i++) {
      v *= 10;
    }
    return v;
  }

  static const _table = <String, CurrencyInfo>{
    'IDR': CurrencyInfo(code: 'IDR', exponent: 0, symbol: 'Rp'),
    'JPY': CurrencyInfo(code: 'JPY', exponent: 0, symbol: '¥'),
    'USD': CurrencyInfo(code: 'USD', exponent: 2, symbol: r'$'),
    'EUR': CurrencyInfo(code: 'EUR', exponent: 2, symbol: '€'),
    'GBP': CurrencyInfo(code: 'GBP', exponent: 2, symbol: '£'),
    'SGD': CurrencyInfo(code: 'SGD', exponent: 2, symbol: 'S\$'),
    'MYR': CurrencyInfo(code: 'MYR', exponent: 2, symbol: 'RM'),
    'AUD': CurrencyInfo(code: 'AUD', exponent: 2, symbol: r'A$'),
  };

  static CurrencyInfo of(String code) {
    final info = _table[code.toUpperCase()];
    if (info == null) {
      throw ArgumentError.value(code, 'code', 'Unknown currency code');
    }
    return info;
  }

  static bool isKnown(String code) => _table.containsKey(code.toUpperCase());
}
