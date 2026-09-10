import 'package:flutter_test/flutter_test.dart';
import 'package:wudget/core/money.dart';
import 'package:wudget/core/money_formatter.dart';

// "Golden" here means: pinned expected strings for every currency/sign/
// magnitude combination the app actually renders. If one of these breaks,
// a screen somewhere just started lying about a number — see the
// formatter-inconsistency defects catalogued in research/07-ui-audit.md.
void main() {
  const f = MoneyFormatter();

  group('IDR (0 decimal, . thousands, Rp prefix)', () {
    test('typical amount', () {
      expect(f.format(Money.fromMinor(15000, 'IDR')), 'Rp 15.000');
    });

    test('large amount, multiple grouping separators', () {
      expect(f.format(Money.fromMinor(15975000, 'IDR')), 'Rp 15.975.000');
    });

    test('zero', () {
      expect(f.format(Money.fromMinor(0, 'IDR')), 'Rp 0');
    });

    test('negative, sign none (wallet balance style)', () {
      expect(f.format(Money.fromMinor(-63000, 'IDR')), '-Rp 63.000');
    });

    test('negative, sign explicit (transaction row style)', () {
      expect(
        f.format(Money.fromMinor(-63000, 'IDR'), sign: MoneySign.explicit),
        '-Rp 63.000',
      );
    });

    test('positive, sign explicit shows +', () {
      expect(
        f.format(Money.fromMinor(8500000, 'IDR'), sign: MoneySign.explicit),
        '+Rp 8.500.000',
      );
    });

    test('zero, sign explicit shows +0 not -0', () {
      expect(
        f.format(Money.fromMinor(0, 'IDR'), sign: MoneySign.explicit),
        '+Rp 0',
      );
    });

    test('under one thousand, no separator', () {
      expect(f.format(Money.fromMinor(500, 'IDR')), 'Rp 500');
    });
  });

  group('USD (2 decimal, id_ID separators: . thousands, , decimal)', () {
    test('typical amount keeps cents', () {
      expect(f.format(Money.fromMinor(1250, 'USD')), '\$ 12,50');
    });

    test('whole dollar amount still shows ,00', () {
      expect(f.format(Money.fromMinor(1200, 'USD')), '\$ 12,00');
    });

    test('large amount groups thousands, keeps decimal', () {
      expect(f.format(Money.fromMinor(123456789, 'USD')), '\$ 1.234.567,89');
    });
  });

  group('JPY (0 decimal, like IDR)', () {
    test('typical amount', () {
      expect(f.format(Money.fromMinor(500, 'JPY')), '¥ 500');
    });
  });

  group('compact form for chart axes only', () {
    test('thousands', () {
      expect(f.formatCompact(Money.fromMinor(250000, 'IDR')), 'Rp 250rb');
    });

    test('millions', () {
      expect(f.formatCompact(Money.fromMinor(4500000, 'IDR')), 'Rp 4,5jt');
    });

    test('under one thousand, no suffix', () {
      expect(f.formatCompact(Money.fromMinor(500, 'IDR')), 'Rp 500');
    });
  });
}
