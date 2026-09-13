import 'package:flutter_test/flutter_test.dart';
import 'package:wudget/domain/csv_import.dart';

void main() {
  const headers = ['Date', 'Category', 'Amount', 'Account', 'Note', 'Income/Expense'];

  test('parses a well-formed expense row and an income row', () {
    final result = parseImportRows(
      headers: headers,
      dataRows: [
        ['2026-03-05', 'Makan', '15000', 'Tunai', 'sarapan', 'Expense'],
        ['2026-03-06', 'Gaji', '5000000', 'Bank', '', 'Income'],
      ],
      mapping: moneyManagerProfile,
    );

    expect(result.failures, isEmpty);
    expect(result.rows, hasLength(2));
    expect(result.rows[0].kind, 'expense');
    expect(result.rows[0].amountMinor, -15000);
    expect(result.rows[0].categoryName, 'Makan');
    expect(result.rows[0].note, 'sarapan');
    expect(result.rows[1].kind, 'income');
    expect(result.rows[1].amountMinor, 5000000);
    expect(result.rows[1].note, isNull);
  });

  test('infers kind from amount sign when there is no kind column', () {
    const mapping = ColumnMapping(dateColumn: 'Date', amountColumn: 'Amount');
    final result = parseImportRows(
      headers: const ['Date', 'Amount'],
      dataRows: const [
        ['2026-03-05', '-15000'],
        ['2026-03-06', '5000000'],
      ],
      mapping: mapping,
    );
    expect(result.rows[0].kind, 'expense');
    expect(result.rows[0].amountMinor, -15000);
    expect(result.rows[1].kind, 'income');
    expect(result.rows[1].amountMinor, 5000000);
  });

  test('a missing date fails with a row number and reason, other rows still parse', () {
    final result = parseImportRows(
      headers: headers,
      dataRows: [
        ['', 'Makan', '15000', 'Tunai', '', 'Expense'],
        ['2026-03-06', 'Gaji', '5000000', 'Bank', '', 'Income'],
      ],
      mapping: moneyManagerProfile,
    );
    expect(result.rows, hasLength(1));
    expect(result.failures, hasLength(1));
    expect(result.failures.single.rowNumber, 2); // header is row 1
    expect(result.failures.single.reason, contains('Tanggal'));
  });

  test('an unparseable date fails with the row number and the bad value quoted', () {
    final result = parseImportRows(
      headers: headers,
      dataRows: [
        ['not-a-date', 'Makan', '15000', 'Tunai', '', 'Expense'],
      ],
      mapping: moneyManagerProfile,
    );
    expect(result.failures.single.rowNumber, 2);
    expect(result.failures.single.reason, contains('not-a-date'));
  });

  test('an unparseable amount fails, row number counts from the third data row correctly', () {
    final result = parseImportRows(
      headers: headers,
      dataRows: [
        ['2026-03-01', 'Makan', '10000', 'Tunai', '', 'Expense'],
        ['2026-03-02', 'Makan', '20000', 'Tunai', '', 'Expense'],
        ['2026-03-03', 'Makan', 'bukan-angka', 'Tunai', '', 'Expense'],
      ],
      mapping: moneyManagerProfile,
    );
    expect(result.rows, hasLength(2));
    expect(result.failures.single.rowNumber, 4); // header + 2 good rows before it
  });

  test('an unrecognised kind value fails rather than guessing', () {
    final result = parseImportRows(
      headers: headers,
      dataRows: [
        ['2026-03-01', 'Makan', '10000', 'Tunai', '', 'Transfer'],
      ],
      mapping: moneyManagerProfile,
    );
    expect(result.rows, isEmpty);
    expect(result.failures.single.reason, contains('Transfer'));
  });

  test('a thousands-separated amount parses correctly', () {
    final result = parseImportRows(
      headers: headers,
      dataRows: [
        ['2026-03-01', 'Belanja', '1,500,000', 'Tunai', '', 'Expense'],
      ],
      mapping: moneyManagerProfile,
    );
    expect(result.rows.single.amountMinor, -1500000);
  });
}
