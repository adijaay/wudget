import 'package:flutter_test/flutter_test.dart';
import 'package:wudget/domain/reminder.dart';

String _fmt(int minor) => 'Rp${(minor / 1000).round()}rb';

void main() {
  group('reminderBody', () {
    test('names the expense and the shortfall when the wallet can\'t cover it', () {
      final body = reminderBody(
        itemLabel: 'Listrik',
        amountMinor: 150000,
        walletBalanceMinor: 90000,
        walletName: 'Tunai',
        formatMoney: _fmt,
      );
      expect(body, contains('Listrik'));
      expect(body, contains('Rp150rb'));
      expect(body, contains('Tunai'));
      expect(body, contains('kurang'));
      expect(body, contains('Rp60rb'));
    });

    test('names just the due amount, no shortfall clause, when the wallet covers it', () {
      final body = reminderBody(
        itemLabel: 'Listrik',
        amountMinor: 150000,
        walletBalanceMinor: 500000,
        walletName: 'Tunai',
        formatMoney: _fmt,
      );
      expect(body, contains('Listrik'));
      expect(body, contains('Rp150rb'));
      expect(body, isNot(contains('kurang')));
    });

    test('an exact-balance wallet is not treated as a shortfall', () {
      final body = reminderBody(
        itemLabel: 'Listrik',
        amountMinor: 150000,
        walletBalanceMinor: 150000,
        walletName: 'Tunai',
        formatMoney: _fmt,
      );
      expect(body, isNot(contains('kurang')));
    });
  });

  group('reminderBodyForRange', () {
    test('states the expected range, not a single fabricated number', () {
      final body = reminderBodyForRange(
        itemLabel: 'Listrik',
        expectedMinMinor: 100000,
        expectedMaxMinor: 200000,
        formatMoney: _fmt,
      );
      expect(body, contains('Listrik'));
      expect(body, contains('Rp100rb'));
      expect(body, contains('Rp200rb'));
    });
  });
}
