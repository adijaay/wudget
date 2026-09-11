import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/providers.dart';
import '../../data/backup_repository.dart';
import '../../design/tokens.dart';

final _dateTimeFormat = DateFormat('d MMM yyyy, HH:mm', 'id_ID');

/// Data, backup, export and restore — plan/03-architecture.md's backup
/// engine (Sprint 2) never had a screen until this sprint's states pass
/// asked for one directly: "Catat, new user error: corrupt database
/// routes to restore" needs somewhere for that route to land.
class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key, this.debugDocumentsDir});

  /// Test-only seam: `getApplicationDocumentsDirectory` needs a platform
  /// channel `flutter_test` can't provide. Never set outside a test.
  @visibleForTesting
  final Directory? debugDocumentsDir;

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  Future<Directory> get _documentsDir async =>
      widget.debugDocumentsDir ?? getApplicationDocumentsDirectory();

  Future<BackupRepository> _repository() async {
    final documents = await _documentsDir;
    return BackupRepository(
      ref.read(databaseProvider),
      backupDir: Directory(p.join(documents.path, 'backups')),
    );
  }

  Future<File> _databaseFile() async {
    final documents = await _documentsDir;
    return File(p.join(documents.path, 'wudget.sqlite'));
  }

  DateTime? _lastBackup;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refreshLastBackup();
  }

  Future<void> _refreshLastBackup() async {
    final repo = await _repository();
    if (!mounted) return;
    setState(() => _lastBackup = repo.lastBackupTime());
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _createBackup() async {
    await _run(() async {
      final repo = await _repository();
      await repo.createBackup(await _databaseFile());
      await _refreshLastBackup();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cadangan dibuat')));
    });
  }

  Future<void> _exportJson() async {
    await _run(() async {
      final repo = await _repository();
      final json = await repo.exportJson();
      final documents = await _documentsDir;
      final file = File(p.join(documents.path, 'wudget-export-${DateTime.now().millisecondsSinceEpoch}.json'));
      await file.writeAsString(backupJsonCodec.encode(json));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tersimpan: ${file.path}')));
    });
  }

  Future<void> _exportCsv() async {
    await _run(() async {
      final repo = await _repository();
      final csv = await repo.exportCsv();
      final documents = await _documentsDir;
      final file = File(p.join(documents.path, 'wudget-export-${DateTime.now().millisecondsSinceEpoch}.csv'));
      await file.writeAsString(csv);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tersimpan: ${file.path}')));
    });
  }

  Future<void> _restore() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
    final path = result?.files.single.path;
    if (path == null) return;

    await _run(() async {
      final repo = await _repository();
      final json = jsonDecode(await File(path).readAsString()) as Map<String, dynamic>;
      final preview = repo.previewImport(json);

      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Pulihkan cadangan?'),
          content: Text(
            'Akan mengganti seluruh data saat ini dengan:\n'
            '${preview.accounts} dompet, ${preview.categories} kategori, '
            '${preview.transactions} transaksi, ${preview.postings} posting.\n\n'
            'Tidak bisa dibatalkan.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Pulihkan')),
          ],
        ),
      );
      if (confirmed != true) return;

      await repo.importJson(json);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data dipulihkan')));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data & Cadangan')),
      body: Padding(
        padding: const EdgeInsets.all(WudgetTokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _lastBackup == null ? 'Belum ada cadangan.' : 'Cadangan terakhir: ${_dateTimeFormat.format(_lastBackup!)}',
            ),
            const SizedBox(height: WudgetTokens.space4),
            FilledButton(onPressed: _busy ? null : _createBackup, child: const Text('Buat cadangan sekarang')),
            const SizedBox(height: WudgetTokens.space2),
            OutlinedButton(onPressed: _busy ? null : _exportJson, child: const Text('Ekspor JSON (lengkap)')),
            const SizedBox(height: WudgetTokens.space2),
            OutlinedButton(onPressed: _busy ? null : _exportCsv, child: const Text('Ekspor CSV (spreadsheet)')),
            const SizedBox(height: WudgetTokens.space5),
            OutlinedButton(onPressed: _busy ? null : _restore, child: const Text('Pulihkan dari file JSON...')),
            if (_busy) const Padding(
              padding: EdgeInsets.only(top: WudgetTokens.space4),
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      ),
    );
  }
}
