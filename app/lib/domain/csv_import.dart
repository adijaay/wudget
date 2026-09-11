import 'package:intl/intl.dart';

/// Which CSV column supplies each field the importer needs, plus how to
/// read a signed amount and a date — plan/03-architecture.md: "Import:
/// Money Manager and Ollo CSV, with a column mapping step." Column names,
/// not indices, so re-ordering a spreadsheet's columns before export
/// doesn't break the mapping.
class ColumnMapping {
  const ColumnMapping({
    required this.dateColumn,
    required this.amountColumn,
    this.categoryColumn,
    this.accountColumn,
    this.noteColumn,
    this.kindColumn,
    this.expenseValue = 'Expense',
    this.incomeValue = 'Income',
    this.dateFormat = 'yyyy-MM-dd',
  });

  final String dateColumn;
  final String amountColumn;
  final String? categoryColumn;
  final String? accountColumn;
  final String? noteColumn;

  /// A column whose value says expense/income directly. When null, the
  /// amount's own sign decides (negative = expense, positive = income) —
  /// the common case for an export that already signs its amounts.
  final String? kindColumn;
  final String expenseValue;
  final String incomeValue;

  final String dateFormat;
}

/// A CSV row parsed into what wudget needs — not yet resolved against
/// real account/category ids, which is `CsvImportRepository`'s job (it
/// needs the database to create-or-match by name).
class ParsedImportRow {
  const ParsedImportRow({
    required this.rowNumber,
    required this.occurredAtUtcMillis,
    required this.amountMinor,
    required this.kind,
    this.categoryName,
    this.accountName,
    this.note,
  });

  /// 1-based, header counted as row 1 — matches [ImportRowFailure.rowNumber].
  final int rowNumber;
  final int occurredAtUtcMillis;

  /// Signed: negative for an expense, positive for income.
  final int amountMinor;
  final String kind; // expense|income
  final String? categoryName;
  final String? accountName;
  final String? note;
}

/// One row that couldn't be parsed — plan/03-architecture.md: "a partial
/// import that keeps the valid rows and reports the failures with row
/// numbers." [rowNumber] is 1-based counting the header as row 1, matching
/// how a person would count lines while looking at the file in a
/// spreadsheet.
class ImportRowFailure {
  const ImportRowFailure({required this.rowNumber, required this.reason});
  final int rowNumber;
  final String reason;
}

class ImportParseResult {
  const ImportParseResult({required this.rows, required this.failures});
  final List<ParsedImportRow> rows;
  final List<ImportRowFailure> failures;
}

/// Parses already-split CSV [dataRows] (header excluded, but counted for
/// row numbering) against [headers] and [mapping]. A row missing its
/// mapped column, or with an unparseable date or amount, becomes a
/// failure — the rest of the import still proceeds.
ImportParseResult parseImportRows({
  required List<String> headers,
  required List<List<String>> dataRows,
  required ColumnMapping mapping,
}) {
  final columnIndex = {for (var i = 0; i < headers.length; i++) headers[i].trim(): i};
  final dateFormat = DateFormat(mapping.dateFormat);

  String? valueOf(List<String> row, String? column) {
    if (column == null) return null;
    final index = columnIndex[column];
    if (index == null || index >= row.length) return null;
    final value = row[index].trim();
    return value.isEmpty ? null : value;
  }

  final rows = <ParsedImportRow>[];
  final failures = <ImportRowFailure>[];

  for (var i = 0; i < dataRows.length; i++) {
    final rowNumber = i + 2; // header is row 1
    final row = dataRows[i];

    final dateText = valueOf(row, mapping.dateColumn);
    if (dateText == null) {
      failures.add(ImportRowFailure(rowNumber: rowNumber, reason: 'missing date'));
      continue;
    }
    DateTime date;
    try {
      date = dateFormat.parseStrict(dateText);
    } catch (_) {
      failures.add(ImportRowFailure(rowNumber: rowNumber, reason: 'unparseable date "$dateText"'));
      continue;
    }

    final amountText = valueOf(row, mapping.amountColumn);
    if (amountText == null) {
      failures.add(ImportRowFailure(rowNumber: rowNumber, reason: 'missing amount'));
      continue;
    }
    final amountValue = num.tryParse(amountText.replaceAll(',', ''));
    if (amountValue == null) {
      failures.add(ImportRowFailure(rowNumber: rowNumber, reason: 'unparseable amount "$amountText"'));
      continue;
    }

    String kind;
    int amountMinor;
    final kindText = valueOf(row, mapping.kindColumn);
    if (kindText != null) {
      if (kindText == mapping.expenseValue) {
        kind = 'expense';
        amountMinor = -amountValue.abs().round();
      } else if (kindText == mapping.incomeValue) {
        kind = 'income';
        amountMinor = amountValue.abs().round();
      } else {
        failures.add(ImportRowFailure(rowNumber: rowNumber, reason: 'unrecognised kind "$kindText"'));
        continue;
      }
    } else {
      amountMinor = amountValue.round();
      kind = amountMinor < 0 ? 'expense' : 'income';
    }

    rows.add(ParsedImportRow(
      rowNumber: rowNumber,
      occurredAtUtcMillis: date.toUtc().millisecondsSinceEpoch,
      amountMinor: amountMinor,
      kind: kind,
      categoryName: valueOf(row, mapping.categoryColumn),
      accountName: valueOf(row, mapping.accountColumn),
      note: valueOf(row, mapping.noteColumn),
    ));
  }

  return ImportParseResult(rows: rows, failures: failures);
}

/// A best-effort default mapping for a Money Manager (Realbyte) CSV
/// export — plan/01-features.md, "CSV import for Money Manager and Ollo
/// exports." **Unverified**: no real Money Manager export was available
/// in this environment to test against (see DECISIONS.md, Sprint 16).
/// The column-mapping screen lets a user correct any of this per-import,
/// so an inaccurate guess here is a worse first screen, not a broken
/// import.
const moneyManagerProfile = ColumnMapping(
  dateColumn: 'Date',
  amountColumn: 'Amount',
  categoryColumn: 'Category',
  accountColumn: 'Account',
  noteColumn: 'Note',
  kindColumn: 'Income/Expense',
  expenseValue: 'Expense',
  incomeValue: 'Income',
  dateFormat: 'yyyy-MM-dd',
);
