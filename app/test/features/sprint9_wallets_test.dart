import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:wudget/core/providers.dart';
import 'package:wudget/data/capture_queries.dart';
import 'package:wudget/data/database.dart';
import 'package:wudget/data/postings_repository.dart';
import 'package:wudget/design/tokens.dart';
import 'package:wudget/domain/default_categories.dart';
import 'package:wudget/features/capture/capture_sheet.dart';
import 'package:wudget/features/wallets/wallets_screen.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  Future<void> expense(
    WudgetDatabase db,
    String id,
    String accountId,
    String categoryId,
    DateTime at,
    int amountMinor,
  ) {
    return PostingsRepository(db).insertTransaction(
      transaction: TransactionsCompanion.insert(
        id: id,
        kind: 'expense',
        occurredAt: at.toUtc().millisecondsSinceEpoch,
        tzOffsetMinutes: 0,
        updatedAt: 0,
      ),
      postings: [
        PostingsCompanion.insert(
            id: '${id}a',
            transactionId: id,
            accountId: Value(accountId),
            amountMinor: -amountMinor,
            currency: 'IDR',
            baseAmountMinor: -amountMinor),
        PostingsCompanion.insert(
            id: '${id}c',
            transactionId: id,
            categoryId: Value(categoryId),
            amountMinor: amountMinor,
            currency: 'IDR',
            baseAmountMinor: amountMinor),
      ],
    );
  }

  testWidgets('Kantong: each group ends in its own total row', (tester) async {
    final db = WudgetDatabase(NativeDatabase.memory());
    await seedDefaultsIfEmpty(db);
    addTearDown(db.close);

    await (db.update(db.accounts)..where((a) => a.id.equals('acc_cash')))
        .write(const AccountsCompanion(openingMinor: Value(50000)));
    await db.into(db.accounts).insert(AccountsCompanion.insert(
        id: 'acc_bank', name: 'BCA', type: 'bank', currency: 'IDR', openingMinor: const Value(500000), updatedAt: 0));
    await expense(db, 'tx1', 'acc_cash', 'cat_makan', DateTime.now(), 20000);

    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        theme: buildWudgetTheme(WudgetTokens.light, Brightness.light),
        home: const WalletsScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    // 50.000 - 20.000 + 500.000 = 530.000 for the Harian group.
    expect(find.text('Total Harian'), findsOneWidget);
    expect(find.textContaining('530.000'), findsWidgets);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets('Kantong: a group holding two currencies prints no total', (tester) async {
    final db = WudgetDatabase(NativeDatabase.memory());
    await seedDefaultsIfEmpty(db);
    addTearDown(db.close);

    await (db.update(db.accounts)..where((a) => a.id.equals('acc_cash')))
        .write(const AccountsCompanion(openingMinor: Value(50000)));
    await db.into(db.accounts).insert(AccountsCompanion.insert(
        id: 'acc_usd', name: 'USD tunai', type: 'cash', currency: 'USD', openingMinor: const Value(10000), updatedAt: 0));

    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        theme: buildWudgetTheme(WudgetTokens.light, Brightness.light),
        home: const WalletsScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Total Harian'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets('Kantong: the first-wallet CTA is on screen without scrolling', (tester) async {
    final db = WudgetDatabase(NativeDatabase.memory());
    await seedDefaultsIfEmpty(db);
    await db.delete(db.accounts).go();
    addTearDown(db.close);

    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        theme: buildWudgetTheme(WudgetTokens.light, Brightness.light),
        home: const WalletsScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    final cta = find.text('Tambah kantong pertama');
    expect(cta, findsOneWidget);
    // Visible in the first viewport, not merely present in the tree.
    final rect = tester.getRect(cta);
    expect(rect.bottom, lessThan(tester.view.physicalSize.height / tester.view.devicePixelRatio));

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets('capture: the wallet control lets you change where it goes', (tester) async {
    final db = WudgetDatabase(NativeDatabase.memory());
    await seedDefaultsIfEmpty(db);
    addTearDown(db.close);
    await db.into(db.accounts).insert(AccountsCompanion.insert(
        id: 'acc_bank', name: 'BCA', type: 'bank', currency: 'IDR', openingMinor: const Value(0), updatedAt: 0));

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        theme: buildWudgetTheme(WudgetTokens.light, Brightness.light),
        home: Scaffold(body: CaptureSheet(initialKind: CaptureKind.expense)),
      ),
    ));
    await tester.pumpAndSettle();

    // Opens on the oldest wallet, which is the seeded Tunai.
    expect(find.text('Tunai'), findsOneWidget);

    await tester.tap(find.text('Tunai'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('BCA').last); // the menu entry, not the chip
    await tester.pumpAndSettle();

    expect(find.text('BCA'), findsOneWidget);
    expect(find.text('Tunai'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets('capture: the wallet follows the category last recorded from', (tester) async {
    final db = WudgetDatabase(NativeDatabase.memory());
    await seedDefaultsIfEmpty(db);
    addTearDown(db.close);
    await db.into(db.accounts).insert(AccountsCompanion.insert(
        id: 'acc_bank', name: 'BCA', type: 'bank', currency: 'IDR', openingMinor: const Value(0), updatedAt: 0));
    // Makan was last paid from the bank, Transport has no history at all.
    await expense(db, 'tx1', 'acc_bank', 'cat_makan', DateTime.now(), 20000);

    expect(
      await CaptureQueries(db).lastAccountIdForCategory('cat_makan'),
      'acc_bank',
    );
    expect(
      await CaptureQueries(db).lastAccountIdForCategory('cat_transport'),
      null,
    );

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        theme: buildWudgetTheme(WudgetTokens.light, Brightness.light),
        home: Scaffold(body: CaptureSheet(initialKind: CaptureKind.expense)),
      ),
    ));
    await tester.pumpAndSettle();

    // Opens on the oldest wallet (Tunai); picking Makan moves it to BCA.
    expect(find.text('Tunai'), findsOneWidget);
    await tester.tap(find.text('Makan').last, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('BCA'), findsOneWidget);
    expect(find.text('Tunai'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });
}