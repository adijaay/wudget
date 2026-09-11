import 'package:flutter_test/flutter_test.dart';
import 'package:wudget/domain/csv_parser.dart';

void main() {
  test('splits plain comma-separated rows', () {
    final rows = parseCsv('a,b,c\n1,2,3\n');
    expect(rows, [
      ['a', 'b', 'c'],
      ['1', '2', '3'],
    ]);
  });

  test('a quoted field may contain a comma', () {
    final rows = parseCsv('Date,Note,Amount\n2026-01-01,"Beli, bayar tunai",15000\n');
    expect(rows[1], ['2026-01-01', 'Beli, bayar tunai', '15000']);
  });

  test('a doubled quote inside a quoted field is one literal quote', () {
    final rows = parseCsv('Note\n"She said ""hi"""\n');
    expect(rows[1], ['She said "hi"']);
  });

  test('handles both \\n and \\r\\n line endings', () {
    final rows = parseCsv('a,b\r\n1,2\r\n3,4\n');
    expect(rows, [
      ['a', 'b'],
      ['1', '2'],
      ['3', '4'],
    ]);
  });

  test('strips a leading UTF-8 BOM', () {
    final rows = parseCsv('﻿a,b\n1,2\n');
    expect(rows[0], ['a', 'b']);
  });

  test('a trailing row with no final newline is still included', () {
    final rows = parseCsv('a,b\n1,2');
    expect(rows, [
      ['a', 'b'],
      ['1', '2'],
    ]);
  });
}
