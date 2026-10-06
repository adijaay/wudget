import 'package:flutter_test/flutter_test.dart';
import 'package:wudget/data/database.dart';
import 'package:wudget/data/settings_repository.dart';
import 'package:wudget/domain/payday.dart';

int _day(int year, int month, int day) =>
    DateTime.utc(year, month, day).difference(DateTime.utc(1970, 1, 1)).inDays;

AppSetting _row({int? confirmed, int? snoozed, int? customStart, int? customEnd}) => AppSetting(
      id: 0,
      periodStartDay: 25,
      customPeriodStart: customStart,
      customPeriodEndExclusive: customEnd,
      paydayConfirmedPeriodStart: confirmed,
      paydaySnoozedDay: snoozed,
    );

void main() {
  test('R3.3 mockup: 7.500.000 plus 420.000 is 7.920.000, every rupiah placed', () {
    final total = 7500000 + periodLeftoverMinor(incomeMinor: 7500000, expenseMinor: 7080000);
    expect(total, 7920000);
    final placed = placeEveryRupiah(total, {
      'cat_makan': 2400000,
      'cat_tagihan': 1650000,
      'cat_transport': 900000,
      'cat_belanja': 800000,
      'cat_hiburan': 450000,
      'cat_kesehatan': 300000,
      tabunganCategoryId: 1000000, // last period's own Tabungan is recomputed
    });
    expect(placed[tabunganCategoryId], 1420000);
    expect(placed.values.fold<int>(0, (a, b) => a + b), 7920000);
  });

  test('an overspent period leaves no leftover, and Tabungan never goes negative', () {
    expect(periodLeftoverMinor(incomeMinor: 100, expenseMinor: 300), 0);
    expect(placeEveryRupiah(100, {'cat_makan': 300})[tabunganCategoryId], 0);
  });

  group('R3.2 payday card', () {
    final payday = _day(2026, 10, 25);
    test('shows on the 25th', () => expect(paydayCardDue(_row(), payday), isTrue));
    test('hides once confirmed for this period', () {
      expect(paydayCardDue(_row(confirmed: payday), payday + 3), isFalse);
      expect(paydayCardDue(_row(confirmed: payday), _day(2026, 11, 25)), isTrue);
    });
    test('Belum hides it until tomorrow', () {
      expect(paydayCardDue(_row(snoozed: payday), payday), isFalse);
      expect(paydayCardDue(_row(snoozed: payday), payday + 1), isTrue);
    });
    test('not during an Atur sekarang period', () {
      final row = _row(customStart: _day(2026, 10, 20), customEnd: _day(2026, 11, 25));
      expect(paydayCardDue(row, payday), isFalse);
      expect(paydayCardDue(row, _day(2026, 11, 25)), isTrue);
    });
    test('new install: no row means payday 25', () {
      expect(paydayCardDue(null, payday), isTrue);
    });
  });
}
