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
import 'package:wudget/features/budget/budget_screen.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  Future<void> expense(WudgetDatabase db, String id, String categoryId, DateTime at, int amountMinor) {
    return PostingsRepository(db).insertTransaction(
      transaction: TransactionsCompanion.insert(
        id: id,
        kind: 'expense',
        occurredAt: at.toUtc().millisecondsSinceEpoch,
        tzOffsetMinutes: 0,
        updatedAt: 0,
      ),
      postings: [
        PostingsCompanion.insert(id: '${id}a', transactionId: id, accountId: const Value('acc'),
            amountMinor: -amountMinor, currency: 'IDR', baseAmountMinor: -amountMinor),
        PostingsCompanion.insert(id: '${id}c', transactionId: id, categoryId: Value(categoryId),
            amountMinor: amountMinor, currency: 'IDR', baseAmountMinor: amountMinor),
      ],
    );
  }

  testWidgets('proposes a budget row from history, with no field left blank', (tester) async {
    final db = WudgetDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db.into(db.categories).insert(CategoriesCompanion.insert(
          id: 'cat_makan', name: 'Makan', kind: 'expense', iconKey: 'food', hueIndex: 0, sortOrder: 0, updatedAt: 0,
        ));

    final now = DateTime.now();
    await expense(db, 'tx1', 'cat_makan', now.subtract(const Duration(days: 5)), 70000);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: buildWudgetTheme(WudgetTokens.light, Brightness.light),
          home: const BudgetScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Makan'), findsOneWidget);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, isNotEmpty);
    expect(field.controller!.text, isNot('0'));

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets('editing the amount persists through BudgetsRepository', (tester) async {
    final db = WudgetDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db.into(db.categories).insert(CategoriesCompanion.insert(
          id: 'cat_makan', name: 'Makan', kind: 'expense', iconKey: 'food', hueIndex: 0, sortOrder: 0, updatedAt: 0,
        ));
    await expense(db, 'tx1', 'cat_makan', DateTime.now().subtract(const Duration(days: 5)), 70000);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: buildWudgetTheme(WudgetTokens.light, Brightness.light),
          home: const BudgetScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '999000');
    await tester.pump();
    // The proposal is accepted as one set, not field by field: its total is
    // what the footer asks the user to agree to (design/BudgetProposal.dc.html).
    await tester.tap(find.text('Pakai anggaran ini'));
    await tester.pumpAndSettle();

    final saved = await (db.select(db.budgets)..where((b) => b.key.equals('cat_makan'))).getSingle();
    expect(saved.amountMinor, 999000);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets('no history and no saved budget shows the empty state, not a blank row', (tester) async {
    final db = WudgetDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: buildWudgetTheme(WudgetTokens.light, Brightness.light),
          home: const BudgetScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Belum ada yang bisa diusulkan'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });
}
