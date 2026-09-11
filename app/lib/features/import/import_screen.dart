import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/csv_import_repository.dart';
import '../../design/tokens.dart';
import '../../domain/csv_import.dart';
import '../../domain/csv_parser.dart';

/// CSV import from a competitor export, with a column-mapping step and a
/// partial import that keeps valid rows and reports failed ones by row
/// number — plan/05-sprints.md Sprint 16. Only the Money Manager default
/// mapping ships; Ollo's is cut per the plan's own cut list ("ship the
/// Money Manager one, since it has the larger installed base"). The
/// column mapping is editable regardless of profile, so any CSV export
/// can be imported by mapping its own columns by hand.
class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key, this.debugInitialCsvContent, this.debugInitialFileName});

  /// Test-only seam: pre-loads CSV content without going through
  /// `FilePicker`'s platform channel, which isn't available in
  /// `flutter_test`. Never set outside a test.
  @visibleForTesting
  final String? debugInitialCsvContent;
  @visibleForTesting
  final String? debugInitialFileName;

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  List<String>? _headers;
  List<List<String>>? _dataRows;
  String? _fileName;

  String? _dateColumn;
  String? _amountColumn;
  String? _categoryColumn;
  String? _accountColumn;
  String? _noteColumn;
  String? _kindColumn;

  ImportWriteResult? _writeResult;
  List<ImportRowFailure> _parseFailures = const [];
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    if (widget.debugInitialCsvContent != null) {
      _applyCsv(widget.debugInitialCsvContent!, widget.debugInitialFileName ?? 'test.csv');
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv']);
    final path = result?.files.single.path;
    if (path == null) return;

    final content = await File(path).readAsString();
    setState(() => _applyCsv(content, result!.files.single.name));
  }

  /// Sets every CSV-derived field directly — the caller wraps this in
  /// `setState` when it runs after the first build (`_pickFile`); `initState`
  /// calls it unwrapped, since setState isn't legal before a first build exists.
  void _applyCsv(String content, String fileName) {
    final rows = parseCsv(content);
    if (rows.isEmpty) return;
    _fileName = fileName;
    _headers = rows.first;
    _dataRows = rows.skip(1).toList();
    _writeResult = null;
    _parseFailures = const [];

    // Prefill from the Money Manager profile when the headers match it
    // exactly; otherwise leave the mapping for the user to set by hand.
    final headerSet = _headers!.toSet();
    if ({
      moneyManagerProfile.dateColumn,
      moneyManagerProfile.amountColumn,
    }.every(headerSet.contains)) {
      _dateColumn = moneyManagerProfile.dateColumn;
      _amountColumn = moneyManagerProfile.amountColumn;
      _categoryColumn = headerSet.contains(moneyManagerProfile.categoryColumn) ? moneyManagerProfile.categoryColumn : null;
      _accountColumn = headerSet.contains(moneyManagerProfile.accountColumn) ? moneyManagerProfile.accountColumn : null;
      _noteColumn = headerSet.contains(moneyManagerProfile.noteColumn) ? moneyManagerProfile.noteColumn : null;
      _kindColumn = headerSet.contains(moneyManagerProfile.kindColumn) ? moneyManagerProfile.kindColumn : null;
    }
  }

  Future<void> _import() async {
    if (_dateColumn == null || _amountColumn == null) return;
    setState(() => _importing = true);

    final mapping = ColumnMapping(
      dateColumn: _dateColumn!,
      amountColumn: _amountColumn!,
      categoryColumn: _categoryColumn,
      accountColumn: _accountColumn,
      noteColumn: _noteColumn,
      kindColumn: _kindColumn,
    );
    final parsed = parseImportRows(headers: _headers!, dataRows: _dataRows!, mapping: mapping);
    final result = await CsvImportRepository(ref.read(databaseProvider)).importRows(parsed.rows, currency: 'IDR');

    if (!mounted) return;
    setState(() {
      _parseFailures = parsed.failures;
      _writeResult = result;
      _importing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Impor dari CSV')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(WudgetTokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.upload_file),
              label: Text(_fileName ?? 'Pilih file CSV'),
            ),
            const SizedBox(height: WudgetTokens.space4),
            if (_headers != null) ...[
              Text('${_dataRows!.length} baris ditemukan.', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: WudgetTokens.space3),
              _ColumnPicker(label: 'Tanggal', headers: _headers!, value: _dateColumn,
                  onChanged: (v) => setState(() => _dateColumn = v), required_: true),
              _ColumnPicker(label: 'Jumlah', headers: _headers!, value: _amountColumn,
                  onChanged: (v) => setState(() => _amountColumn = v), required_: true),
              _ColumnPicker(label: 'Kategori', headers: _headers!, value: _categoryColumn,
                  onChanged: (v) => setState(() => _categoryColumn = v)),
              _ColumnPicker(label: 'Dompet', headers: _headers!, value: _accountColumn,
                  onChanged: (v) => setState(() => _accountColumn = v)),
              _ColumnPicker(label: 'Catatan', headers: _headers!, value: _noteColumn,
                  onChanged: (v) => setState(() => _noteColumn = v)),
              _ColumnPicker(label: 'Jenis (masuk/keluar)', headers: _headers!, value: _kindColumn,
                  onChanged: (v) => setState(() => _kindColumn = v)),
              const SizedBox(height: WudgetTokens.space4),
              FilledButton(
                onPressed: _dateColumn == null || _amountColumn == null || _importing ? null : _import,
                child: _importing ? const CircularProgressIndicator() : const Text('Impor'),
              ),
            ],
            if (_writeResult != null) ...[
              const SizedBox(height: WudgetTokens.space5),
              Text('${_writeResult!.importedCount} baris berhasil diimpor.',
                  style: Theme.of(context).textTheme.titleMedium),
              if (_parseFailures.isNotEmpty || _writeResult!.failures.isNotEmpty) ...[
                const SizedBox(height: WudgetTokens.space2),
                Text('Gagal:', style: Theme.of(context).textTheme.bodyMedium),
                for (final f in [..._parseFailures, ..._writeResult!.failures])
                  Text('Baris ${f.rowNumber}: ${f.reason}'),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _ColumnPicker extends StatelessWidget {
  const _ColumnPicker({
    required this.label,
    required this.headers,
    required this.value,
    required this.onChanged,
    this.required_ = false,
  });
  final String label;
  final List<String> headers;
  final String? value;
  final ValueChanged<String?> onChanged;
  final bool required_;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: WudgetTokens.space1),
      child: DropdownButtonFormField<String?>(
        value: value,
        decoration: InputDecoration(labelText: required_ ? '$label *' : label),
        items: [
          if (!required_) const DropdownMenuItem(value: null, child: Text('(tidak dipetakan)')),
          for (final h in headers) DropdownMenuItem(value: h, child: Text(h)),
        ],
        onChanged: onChanged,
      ),
    );
  }
}
