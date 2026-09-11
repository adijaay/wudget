/// A minimal RFC-4180-ish CSV parser: quoted fields (with embedded commas,
/// newlines, and `""` as an escaped quote), unquoted fields split on
/// commas. No dependency added for this — the format this sprint needs is
/// small and well-scoped, and a competitor export is not going to exercise
/// exotic CSV dialects (BOM aside, stripped separately).
List<List<String>> parseCsv(String content) {
  final rows = <List<String>>[];
  var row = <String>[];
  final field = StringBuffer();
  var inQuotes = false;
  var i = 0;
  final text = content.startsWith('﻿') ? content.substring(1) : content;

  void endField() {
    row.add(field.toString());
    field.clear();
  }

  void endRow() {
    endField();
    rows.add(row);
    row = [];
  }

  while (i < text.length) {
    final c = text[i];
    if (inQuotes) {
      if (c == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          field.write('"');
          i += 2;
          continue;
        }
        inQuotes = false;
        i++;
        continue;
      }
      field.write(c);
      i++;
      continue;
    }

    switch (c) {
      case '"':
        inQuotes = true;
        i++;
      case ',':
        endField();
        i++;
      case '\r':
        i++;
      case '\n':
        endRow();
        i++;
      default:
        field.write(c);
        i++;
    }
  }
  if (field.isNotEmpty || row.isNotEmpty) endRow();

  return rows;
}
