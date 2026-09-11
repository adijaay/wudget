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
import '../../design/components.dart';
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
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Cadangan & pulihkan')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          WudgetTokens.space4,
          0,
          WudgetTokens.space4,
          WudgetTokens.space6,
        ),
        children: [
          // The state of the thing this screen is about, first: whether a
          // copy exists at all is the only fact that matters here.
          WudgetCard(
            child: Row(
              children: [
                IconChip(
                  icon: _lastBackup == null ? Icons.shield_outlined : Icons.verified_outlined,
                  background: _lastBackup == null ? tokens.surfaceMuted : tokens.accent,
                  foreground: _lastBackup == null ? tokens.ink2 : tokens.inkOnAccent,
                ),
                const SizedBox(width: WudgetTokens.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _lastBackup == null ? 'Belum ada cadangan' : 'Cadangan terakhir',
                        style: text.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _lastBackup == null
                            ? 'Catatanmu cuma ada di HP ini. Kalau HP-nya hilang, hilang juga.'
                            // toLocal: the repository returns the instant in
                            // UTC, so formatting it raw printed 16:09 for a
                            // backup the user made at 23:09.
                            : _dateTimeFormat.format(_lastBackup!.toLocal()),
                        style: text.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: WudgetTokens.space4),
          FilledButton(
            onPressed: _busy ? null : _createBackup,
            child: const Text('Buat cadangan sekarang'),
          ),
          if (_busy) ...[
            const SizedBox(height: WudgetTokens.space4),
            const Center(child: CircularProgressIndicator()),
          ],
          const SizedBox(height: WudgetTokens.space5),
          const SectionLabel('Ekspor'),
          CardGroup(
            dividerIndent: WudgetTokens.space3,
            children: [
              CardRow(
                title: 'Ekspor JSON',
                subtitle: 'Lengkap, termasuk semua kantong dan kategori',
                trailing: Icon(Icons.file_download_outlined, color: tokens.ink2),
                onTap: _busy ? null : _exportJson,
              ),
              CardRow(
                title: 'Ekspor CSV',
                subtitle: 'Buat dibuka di spreadsheet',
                trailing: Icon(Icons.file_download_outlined, color: tokens.ink2),
                onTap: _busy ? null : _exportCsv,
              ),
            ],
          ),
          const SizedBox(height: WudgetTokens.space5),
          const SectionLabel('Pulihkan'),
          CardGroup(
            dividerIndent: WudgetTokens.space3,
            children: [
              CardRow(
                title: 'Pulihkan dari file JSON',
                // Says what it will do before it is tapped, because the
                // action itself cannot be undone.
                subtitle: 'Mengganti seluruh data saat ini, tidak bisa dibatalkan',
                trailing: Icon(Icons.chevron_right, color: tokens.ink2),
                onTap: _busy ? null : _restore,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
