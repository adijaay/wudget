import 'money.dart';

/// Sign style for a rendered amount.
enum MoneySign {
  /// No sign shown regardless of value (used for a wallet balance, which is
  /// not "in" or "out").
  none,

  /// Always show a leading `+`/`-`, even for zero (`+0`). Used for
  /// transaction rows, per DESIGN.md: expense negative, income positive,
  /// explicit sign so colour is never the only signal (antislop R-25).
  explicit,
}

/// The single formatter every screen renders amounts through. No widget
/// calls `NumberFormat` or builds a currency string by hand — that is what
/// let three of the six competitor apps in research/07-ui-audit.md show
/// the same fact two different ways on one screen.
class MoneyFormatter {
  const MoneyFormatter({this.locale = 'id_ID'});

  final String locale;

  /// Full amount, e.g. "Rp 15.000" or "$12.50". Never abbreviated — use
  /// [formatCompact] for chart axes, and only when the full value also
  /// appears elsewhere on screen (DESIGN.md, "Abbreviation").
  ///
  /// [showSymbol] false drops the currency symbol for rows inside a card
  /// whose group header already carries it (design/Catat.dc.html prints
  /// "Rp 63.000" on the day header and a bare "15.000" on each row). The
  /// symbol is never dropped from a total or a standalone figure.
  String format(Money money, {MoneySign sign = MoneySign.none, bool showSymbol = true}) {
    final info = money.currencyInfo;
    final major = money.minor.abs() / info.minorUnitsPerMajor;
    final digits = _groupThousands(
      info.exponent == 0 ? major.round().toString() : major.toStringAsFixed(info.exponent),
    );
    final signStr = switch (sign) {
      MoneySign.none => money.isNegative ? '-' : '',
      MoneySign.explicit => money.isNegative ? '-' : '+',
    };
    // Non-breaking space between symbol and digits, per DESIGN.md.
    return showSymbol ? '$signStr${info.symbol} $digits' : '$signStr$digits';
  }

  /// Abbreviated form for chart axes only ("4,5jt", "250rb"). The full
  /// value must appear elsewhere on the same screen — see the chart rules
  /// in plan/04-ux-design.md.
  String formatCompact(Money money) {
    final info = money.currencyInfo;
    final major = money.minor.abs() / info.minorUnitsPerMajor;
    String body;
    if (major >= 1000000000) {
      body = '${_trimZero(major / 1000000000)}M';
    } else if (major >= 1000000) {
      body = '${_trimZero(major / 1000000)}jt';
    } else if (major >= 1000) {
      body = '${_trimZero(major / 1000)}rb';
    } else {
      body = major.round().toString();
    }
    return '${info.symbol} $body';
  }

  String _trimZero(double v) {
    final s = v.toStringAsFixed(1);
    final trimmed = s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
    return trimmed.replaceAll('.', ','); // Indonesian decimal separator
  }

  /// Groups the integer part with `.` and marks any decimal fraction with
  /// `,`, per Indonesian convention (1.234.567,89) — the opposite of the
  /// en_US convention this locale must never silently fall back to.
  String _groupThousands(String digits) {
    final dotIndex = digits.indexOf('.');
    final intPart = dotIndex == -1 ? digits : digits.substring(0, dotIndex);
    final fracPart = dotIndex == -1 ? '' : ',${digits.substring(dotIndex + 1)}';
    final buffer = StringBuffer();
    for (var i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buffer.write('.');
      buffer.write(intPart[i]);
    }
    return '$buffer$fracPart';
  }
}
