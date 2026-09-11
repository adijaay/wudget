import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:wudget/core/providers.dart';
import 'package:wudget/data/database.dart';
import 'package:wudget/data/postings_repository.dart';
import 'package:wudget/design/tokens.dart';
import 'package:wudget/domain/default_categories.dart';
import 'package:wudget/features/ledger/ledger_screen.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  testWidgets('lists a saved expense under its day, and delete offers undo', (tester) async {
    final db = WudgetDatabase(NativeDatabase.memory());
    await seedDefaultsIfEmpty(db);
    addTearDown(db.close);

    await PostingsRepository(db).insertTransaction(
      transaction: TransactionsCompanion.insert(
        id: 'tx1',
        kind: 'expense',
        occurredAt: DateTime.utc(2024, 6, 1, 8).millisecondsSinceEpoch,
        tzOffsetMinutes: 0,
        note: const Value('sarapan'),
        updatedAt: 0,
      ),
      postings: [
        PostingsCompanion.insert(id: 'p1a', transactionId: 'tx1', accountId: const Value('acc_cash'),
            amountMinor: -15000, currency: 'IDR', baseAmountMinor: -15000),
        PostingsCompanion.insert(id: 'p1c', transactionId: 'tx1', categoryId: const Value('cat_makan'),
            amountMinor: 15000, currency: 'IDR', baseAmountMinor: 15000),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: buildWudgetTheme(WudgetTokens.light, Brightness.light),
          home: const LedgerScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Makan'), findsOneWidget);
    expect(find.textContaining('sarapan'), findsOneWidget); // note sits in the detail line now
    expect(find.textContaining('1 Jun 2024'), findsOneWidget);

    // Swipe to delete, then undo.
    await tester.drag(find.text('Makan'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Makan'), findsNothing);
    expect(find.text('Catat pengeluaran pertama'), findsOneWidget); // first-run state

    await tester.tap(find.text('Batalkan'));
    await tester.pumpAndSettle();
    expect(find.text('Makan'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets('picks up a transaction written elsewhere while this screen stays mounted', (tester) async {
    // HomeShell holds Kantong, Catat and Pantau in an IndexedStack, so this
    // screen's initState only ever runs once per app session, never again
    // on a tab switch. A transaction saved from another tab's capture sheet
    // has to reach this list through a real change notification, not
    // through this screen re-loading itself.
    final db = WudgetDatabase(NativeDatabase.memory());
    await seedDefaultsIfEmpty(db);
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: buildWudgetTheme(WudgetTokens.light, Brightness.light),
          home: const LedgerScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Catat pengeluaran pertama'), findsOneWidget); // first-run state

    await PostingsRepository(db).insertTransaction(
      transaction: TransactionsCompanion.insert(
        id: 'tx1',
        kind: 'expense',
        occurredAt: DateTime.utc(2024, 6, 1, 8).millisecondsSinceEpoch,
        tzOffsetMinutes: 0,
        note: const Value('sarapan'),
        updatedAt: 0,
      ),
      postings: [
        PostingsCompanion.insert(id: 'p1a', transactionId: 'tx1', accountId: const Value('acc_cash'),
            amountMinor: -15000, currency: 'IDR', baseAmountMinor: -15000),
        PostingsCompanion.insert(id: 'p1c', transactionId: 'tx1', categoryId: const Value('cat_makan'),
            amountMinor: 15000, currency: 'IDR', baseAmountMinor: 15000),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text('Makan'), findsOneWidget);
    expect(find.text('Catat pengeluaran pertama'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });
}
