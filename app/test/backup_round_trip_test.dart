import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wudget/data/backup_repository.dart';
import 'package:wudget/data/database.dart';

Future<void> _seed(WudgetDatabase db, int transactionCount) async {
  await db.into(db.accounts).insert(AccountsCompanion.insert(
        id: 'acc1',
        name: 'Cash',
        type: 'cash',
        currency: 'IDR',
        updatedAt: 0,
      ));
  await db.into(db.categories).insert(CategoriesCompanion.insert(
        id: 'cat1',
        name: 'Makan',
        kind: 'expense',
        iconKey: 'food',
        hueIndex: 0,
        sortOrder: 0,
        updatedAt: 0,
      ));

  final rng = Random(42);
  for (var i = 0; i < transactionCount; i++) {
    final amount = rng.nextInt(500000) + 1000;
    await db.into(db.transactions).insert(TransactionsCompanion.insert(
          id: 'tx$i',
          kind: 'expense',
          occurredAt: i * 1000,
          tzOffsetMinutes: 420,
          updatedAt: 0,
        ));
    await db.into(db.postings).insert(PostingsCompanion.insert(
          id: 'p$i-a',
          transactionId: 'tx$i',
          amountMinor: -amount,
          currency: 'IDR',
          baseAmountMinor: -amount,
          accountId: const Value('acc1'),
        ));
    await db.into(db.postings).insert(PostingsCompanion.insert(
          id: 'p$i-b',
          transactionId: 'tx$i',
          amountMinor: amount,
          currency: 'IDR',
          baseAmountMinor: amount,
          categoryId: const Value('cat1'),
        ));
  }
}

Future<int> _totalBalance(WudgetDatabase db) async {
  final postings = await db.select(db.postings).get();
  return postings.fold<int>(0, (sum, p) => sum + p.baseAmountMinor);
}

void main() {
  test('5,000 transaction JSON export/import round trip preserves balances', () async {
    final source = WudgetDatabase(NativeDatabase.memory());
    await _seed(source, 5000);
    final sourceBalance = await _totalBalance(source);
    final sourceCounts = await Future.wait([
      source.select(source.accounts).get(),
      source.select(source.categories).get(),
      source.select(source.transactions).get(),
      source.select(source.postings).get(),
    ]);

    final exportRepo = BackupRepository(source, backupDir: Directory.systemTemp);
    final json = await exportRepo.exportJson();
    await source.close();

    final target = WudgetDatabase(NativeDatabase.memory());
    final importRepo = BackupRepository(target, backupDir: Directory.systemTemp);

    final preview = importRepo.previewImport(json);
    expect(preview.transactions, 5000);
    expect(preview.postings, 10000);

    await importRepo.importJson(json);

    final targetBalance = await _totalBalance(target);
    expect(targetBalance, sourceBalance);

    expect((await target.select(target.accounts).get()).length, sourceCounts[0].length);
    expect((await target.select(target.categories).get()).length, sourceCounts[1].length);
    expect((await target.select(target.transactions).get()).length, sourceCounts[2].length);
    expect((await target.select(target.postings).get()).length, sourceCounts[3].length);

    await target.close();
  });

  test('CSV export produces one row per posting', () async {
    final db = WudgetDatabase(NativeDatabase.memory());
    await _seed(db, 10);
    final repo = BackupRepository(db, backupDir: Directory.systemTemp);

    final csv = await repo.exportCsv();
    final lines = csv.trim().split('\n');

    expect(lines.first, 'date,kind,account_id,category_id,amount_minor,currency,note');
    expect(lines.length, 21); // header + 10 transactions * 2 postings

    await db.close();
  });

  test('createBackup keeps only the newest N snapshots and updates lastBackupTime', () async {
    final db = WudgetDatabase(NativeDatabase.memory());
    final dbFile = File('${Directory.systemTemp.path}/wudget_test_${Random().nextInt(1 << 32)}.sqlite')
      ..writeAsStringSync('fake db bytes');
    final backupDir = Directory('${Directory.systemTemp.path}/wudget_backups_${Random().nextInt(1 << 32)}');
    final repo = BackupRepository(db, backupDir: backupDir);

    expect(repo.lastBackupTime(), isNull);

    for (var i = 0; i < 7; i++) {
      await repo.createBackup(dbFile, keep: 5);
      await Future.delayed(const Duration(milliseconds: 2));
    }

    final remaining = backupDir.listSync().whereType<File>().toList();
    expect(remaining.length, 5);
    expect(repo.lastBackupTime(), isNotNull);

    await db.close();
    dbFile.deleteSync();
    backupDir.deleteSync(recursive: true);
  });
}
