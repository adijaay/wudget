import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'daily_totals_repository.dart';
import 'database.dart';

/// Counts of what a JSON import will do, computed without writing anything —
/// the dry-run preview the restore screen shows before the user confirms.
class RestorePreview {
  const RestorePreview({
    required this.accounts,
    required this.categories,
    required this.transactions,
    required this.postings,
  });
  final int accounts;
  final int categories;
  final int transactions;
  final int postings;
}

/// Lossless JSON export/import (accounts, categories, transactions,
/// postings), CSV export for spreadsheets, and local file backups. See
/// plan/03-architecture.md "Backup, restore, import".
class BackupRepository {
  BackupRepository(this._db, {required Directory backupDir}) : _backupDir = backupDir;

  final WudgetDatabase _db;
  final Directory _backupDir;

  static const _formatVersion = 1;

  Future<Map<String, dynamic>> exportJson() async {
    final accounts = await _db.select(_db.accounts).get();
    final categories = await _db.select(_db.categories).get();
    final transactions = await _db.select(_db.transactions).get();
    final postings = await _db.select(_db.postings).get();
    final budgets = await _db.select(_db.budgets).get();
    final recurrences = await _db.select(_db.recurrences).get();
    final recurrenceOverrides = await _db.select(_db.recurrenceOverrides).get();
    final appSettings = await _db.select(_db.appSettings).get();
    final featureFlags = await _db.select(_db.featureFlags).get();
    final goals = await _db.select(_db.goals).get();
    final analyticsEvents = await _db.select(_db.analyticsEvents).get();

    return {
      'formatVersion': _formatVersion,
      'exportedAt': DateTime.now().toUtc().millisecondsSinceEpoch,
      'accounts': accounts.map((a) => a.toJson()).toList(),
      'categories': categories.map((c) => c.toJson()).toList(),
      'transactions': transactions.map((t) => t.toJson()).toList(),
      'postings': postings.map((p) => p.toJson()).toList(),
      'budgets': budgets.map((b) => b.toJson()).toList(),
      'recurrences': recurrences.map((r) => r.toJson()).toList(),
      'recurrenceOverrides': recurrenceOverrides.map((o) => o.toJson()).toList(),
      'appSettings': appSettings.map((s) => s.toJson()).toList(),
      'featureFlags': featureFlags.map((f) => f.toJson()).toList(),
      'goals': goals.map((g) => g.toJson()).toList(),
      // Exported so a beta tester can send the event log back; restore
      // ignores it, the log belongs to the device that wrote it.
      'analyticsEvents': analyticsEvents.map((e) => e.toJson()).toList(),
    };
  }

  RestorePreview previewImport(Map<String, dynamic> json) {
    return RestorePreview(
      accounts: (json['accounts'] as List).length,
      categories: (json['categories'] as List).length,
      transactions: (json['transactions'] as List).length,
      postings: (json['postings'] as List).length,
    );
  }

  /// Replaces every row of every table with the rows in [json]. Call
  /// [previewImport] first and confirm with the user — this has no undo.
  Future<void> importJson(Map<String, dynamic> json) async {
    await _db.transaction(() async {
      await _db.delete(_db.goals).go();
      await _db.delete(_db.postings).go();
      await _db.delete(_db.transactions).go();
      await _db.delete(_db.categories).go();
      await _db.delete(_db.accounts).go();
      await _db.delete(_db.budgets).go();
      await _db.delete(_db.recurrenceOverrides).go();
      await _db.delete(_db.recurrences).go();
      await _db.delete(_db.featureFlags).go();
      await _db.delete(_db.appSettings).go();

      for (final row in json['accounts'] as List) {
        await _db.into(_db.accounts).insert(Account.fromJson(row as Map<String, dynamic>));
      }
      for (final row in json['categories'] as List) {
        await _db.into(_db.categories).insert(Category.fromJson(row as Map<String, dynamic>));
      }
      for (final row in json['transactions'] as List) {
        await _db
            .into(_db.transactions)
            .insert(Transaction.fromJson(row as Map<String, dynamic>));
      }
      for (final row in json['postings'] as List) {
        await _db.into(_db.postings).insert(Posting.fromJson(row as Map<String, dynamic>));
      }
      
      if (json.containsKey('budgets')) {
        for (final row in json['budgets'] as List) {
          await _db.into(_db.budgets).insert(Budget.fromJson(row as Map<String, dynamic>));
        }
      }
      // Older backups predate goals; absent means none, not an error.
      if (json.containsKey('goals')) {
        for (final row in json['goals'] as List) {
          await _db.into(_db.goals).insert(Goal.fromJson(row as Map<String, dynamic>));
        }
      }
      if (json.containsKey('recurrences')) {
        for (final row in json['recurrences'] as List) {
          await _db.into(_db.recurrences).insert(Recurrence.fromJson({'isSubscription': false, ...row as Map<String, dynamic>}));
        }
      }
      if (json.containsKey('recurrenceOverrides')) {
        for (final row in json['recurrenceOverrides'] as List) {
          await _db.into(_db.recurrenceOverrides).insert(RecurrenceOverride.fromJson(row as Map<String, dynamic>));
        }
      }
      if (json.containsKey('appSettings')) {
        for (final row in json['appSettings'] as List) {
          await _db.into(_db.appSettings).insert(AppSetting.fromJson(row as Map<String, dynamic>));
        }
      }
      if (json.containsKey('featureFlags')) {
        for (final row in json['featureFlags'] as List) {
          await _db.into(_db.featureFlags).insert(FeatureFlag.fromJson(row as Map<String, dynamic>));
        }
      }
    });
    await DailyTotalsRepository(_db).recomputeAll();
  }

  /// One row per posting, joined to its transaction — a spreadsheet-ready
  /// export. Not lossless (no round-trip guarantee), for humans not for
  /// restore.
  Future<String> exportCsv() async {
    final transactions = {for (final t in await _db.select(_db.transactions).get()) t.id: t};
    final postings = await _db.select(_db.postings).get();

    final buffer = StringBuffer()
      ..writeln('date,kind,account_id,category_id,amount_minor,currency,note');
    for (final posting in postings) {
      final tx = transactions[posting.transactionId];
      if (tx == null) continue;
      final date = DateTime.fromMillisecondsSinceEpoch(tx.occurredAt, isUtc: true)
          .toIso8601String();
      final note = (tx.note ?? '').replaceAll(',', ';').replaceAll('\n', ' ');
      buffer.writeln(
        '$date,${tx.kind},${posting.accountId ?? ''},${posting.categoryId ?? ''},'
        '${posting.amountMinor},${posting.currency},$note',
      );
    }
    return buffer.toString();
  }

  /// Copies the live database file into the backup directory with a
  /// timestamped name, then deletes all but the newest [keep].
  Future<File> createBackup(File databaseFile, {int keep = 5}) async {
    if (!_backupDir.existsSync()) _backupDir.createSync(recursive: true);
    final stamp = DateTime.now().toUtc().millisecondsSinceEpoch;
    final target = File(p.join(_backupDir.path, 'wudget-$stamp.sqlite'));
    await databaseFile.copy(target.path);

    final backups = _backupDir
        .listSync()
        .whereType<File>()
        .where((f) => p.basename(f.path).startsWith('wudget-'))
        .toList()
      ..sort((a, b) => b.path.compareTo(a.path)); // newest first, timestamp sorts lexically
    for (final old in backups.skip(keep)) {
      old.deleteSync();
    }
    return target;
  }

  DateTime? lastBackupTime() {
    if (!_backupDir.existsSync()) return null;
    final backups = _backupDir
        .listSync()
        .whereType<File>()
        .where((f) => p.basename(f.path).startsWith('wudget-'))
        .toList();
    if (backups.isEmpty) return null;
    final newestStamp = backups
        .map((f) => int.tryParse(
              p.basenameWithoutExtension(f.path).replaceFirst('wudget-', ''),
            ) ??
            0)
        .reduce((a, b) => a > b ? a : b);
    return DateTime.fromMillisecondsSinceEpoch(newestStamp, isUtc: true);
  }
}

/// json helper kept here rather than a dependency: [exportJson] already
/// returns a plain Map, so `jsonEncode`/`jsonDecode` from dart:convert is
/// all a caller needs.
const backupJsonCodec = JsonCodec();
