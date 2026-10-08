import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:wudget/core/providers.dart';
import 'package:wudget/data/backup_repository.dart';
import 'package:wudget/data/database.dart';
import 'package:wudget/data/goals_repository.dart';
import 'package:wudget/data/postings_repository.dart';
import 'package:wudget/data/wallets_repository.dart';
import 'package:wudget/design/tokens.dart';
import 'package:wudget/domain/period_close.dart';
import 'package:wudget/features/pantau/period_close_sheet.dart';
import 'package:wudget/features/wallets/wallets_screen.dart';

Future<void> _transfer(WudgetDatabase db, String id, int minor) {
  return PostingsRepository(db).insertTransaction(
    transaction: TransactionsCompanion.insert(
        id: id, kind: 'transfer', occurredAt: 0, tzOffsetMinutes: 0, updatedAt: 0),
    postings: [
      PostingsCompanion.insert(id: '${id}a', transactionId: id, accountId: const Value('cash'),
          amountMinor: -minor, currency: 'IDR', baseAmountMinor: -minor),
      PostingsCompanion.insert(id: '${id}b', transactionId: id, accountId: const Value('save'),
          amountMinor: minor, currency: 'IDR', baseAmountMinor: minor),
    ],
  );
}

Future<WudgetDatabase> _seed() async {
  final db = WudgetDatabase(NativeDatabase.memory());
  final wallets = WalletsRepository(db);
  await wallets.create(id: 'cash', name: 'Tunai', type: 'cash', currency: 'IDR', openingMinor: 1000000);
  await wallets.create(id: 'save', name: 'Tabungan', type: 'savings', currency: 'IDR');
  return db;
}

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  test('a milestone is announced once, then again only for the next one', () async {
    final db = await _seed();
    addTearDown(db.close);
    final goals = GoalsRepository(db);
    await goals.create(id: 'g', name: 'Dana darurat', targetMinor: 100000, accountId: 'save');
    final sent = <String>[];
    Future<void> notify(int _, String body) async => sent.add(body);

    await goals.announceMilestones(notify);
    expect(sent, isEmpty);

    await _transfer(db, 't1', 60000);
    await goals.announceMilestones(notify);
    await goals.announceMilestones(notify);
    expect(sent, ['Terkumpul 50 persen dari Dana darurat.']);

    await _transfer(db, 't2', 40000);
    await goals.announceMilestones(notify);
    expect(sent.last, 'Dana darurat sudah penuh.');
    expect(sent, hasLength(2));
  });

  test('goals survive a backup round trip', () async {
    final db = await _seed();
    addTearDown(db.close);
    await GoalsRepository(db).create(id: 'g', name: 'Liburan', targetMinor: 500, accountId: 'save');
    final json = await BackupRepository(db, backupDir: Directory.systemTemp).exportJson();
    await BackupRepository(db, backupDir: Directory.systemTemp).importJson(json);
    expect((await db.select(db.goals).getSingle()).name, 'Liburan');
  });

  testWidgets('Kantong creates a goal and shows its milestone chips', (tester) async {
    final db = await _seed();
    addTearDown(db.close);
    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: MaterialApp(
          theme: buildWudgetTheme(WudgetTokens.light, Brightness.light), home: const WalletsScreen()),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Target baru'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Nama target, misal Dana darurat'), 'Motor');
    await tester.enterText(find.widgetWithText(TextField, 'Jumlah target'), '1000');
    await tester.tap(find.text('Buat target'));
    await tester.pumpAndSettle();

    final goal = await db.select(db.goals).getSingle();
    expect(goal.accountId, 'save'); // the savings wallet is preselected
    expect(find.text('Motor'), findsOneWidget);
    expect(find.text('25%'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets('period close offers the surplus to the goal', (tester) async {
    final db = await _seed();
    addTearDown(db.close);
    await GoalsRepository(db).create(id: 'g', name: 'Motor', targetMinor: 1000, accountId: 'save');
    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        theme: buildWudgetTheme(WudgetTokens.dark, Brightness.dark),
        home: Scaffold(
          body: PeriodCloseSheet(
            onClose: () {},
            summary: const PeriodCloseSummary(
              incomeMinor: 300000,
              expenseMinor: 100000,
              largestCategoryName: 'Makan',
              largestCategoryAmountMinor: 100000,
              mostChangedCategoryName: null,
              mostChangedCategoryDeltaMinor: 0,
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Motor'), findsOneWidget);
    expect(find.textContaining('Sisihkan'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });
}
