import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:wudget/core/providers.dart';
import 'package:wudget/data/budgets_repository.dart';
import 'package:wudget/data/database.dart';
import 'package:wudget/data/postings_repository.dart';
import 'package:wudget/design/tokens.dart';
import 'package:wudget/domain/contrast.dart';
import 'package:wudget/features/budget/budget_screen.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  testWidgets('undoing a budget save puts every previous amount back', (tester) async {
    final db = WudgetDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db.into(db.categories).insert(CategoriesCompanion.insert(
          id: 'cat_makan',
          name: 'Makan',
          kind: 'expense',
          iconKey: 'food',
          hueIndex: 0,
          sortOrder: 0,
          updatedAt: 0,
        ));
    await db.into(db.categories).insert(CategoriesCompanion.insert(
          id: 'cat_transport',
          name: 'Transport',
          kind: 'expense',
          iconKey: 'car',
          hueIndex: 1,
          sortOrder: 1,
          updatedAt: 0,
        ));

    final repo = BudgetsRepository(db);
    await repo.setAmount('cat_makan', 200000);
    await repo.setAmount('cat_transport', 100000);

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

    await tester.enterText(find.byType(TextField).first, '999000');
    await tester.pump();
    await tester.tap(find.text('Simpan perubahan'));
    await tester.pumpAndSettle();

    final saved = await repo.getAll();
    expect(saved['cat_makan'], 999000);

    await tester.tap(find.text('Batalkan'));
    await tester.pumpAndSettle();

    expect(await repo.getAll(), {'cat_makan': 200000, 'cat_transport': 100000});

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets('undoing a first save clears the keys it created, not zeroes them', (tester) async {
    // A budget row saved as Rp 0 is still a saved budget, so an undo back to
    // "nothing was ever saved" has to delete the row rather than set 0.
    final db = WudgetDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db.into(db.categories).insert(CategoriesCompanion.insert(
          id: 'cat_makan',
          name: 'Makan',
          kind: 'expense',
          iconKey: 'food',
          hueIndex: 0,
          sortOrder: 0,
          updatedAt: 0,
        ));
    await PostingsRepository(db).insertTransaction(
      transaction: TransactionsCompanion.insert(
        id: 'tx1',
        kind: 'expense',
        occurredAt: DateTime.now().subtract(const Duration(days: 5)).toUtc().millisecondsSinceEpoch,
        tzOffsetMinutes: 0,
        updatedAt: 0,
      ),
      postings: [
        PostingsCompanion.insert(
            id: 'tx1a',
            transactionId: 'tx1',
            accountId: const Value('acc_cash'),
            amountMinor: -70000,
            currency: 'IDR',
            baseAmountMinor: -70000),
        PostingsCompanion.insert(
            id: 'tx1c',
            transactionId: 'tx1',
            categoryId: const Value('cat_makan'),
            amountMinor: 70000,
            currency: 'IDR',
            baseAmountMinor: 70000),
      ],
    );

    final repo = BudgetsRepository(db);
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

    expect(await repo.getAll(), isEmpty);
    await tester.tap(find.text('Pakai anggaran ini'));
    await tester.pumpAndSettle();
    expect(await repo.getAll(), isNotEmpty);

    await tester.tap(find.text('Batalkan'));
    await tester.pumpAndSettle();

    expect(await repo.getAll(), isEmpty);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets('the period-close figures use the inverse palette, not a literal theme',
      (tester) async {
    // The sheet is dark whatever the app theme is, so its figures come from
    // the inverse tokens. This pins the contrast the tokens were chosen for.
    expect(contrastRatio(WudgetTokens.onInversePositive, WudgetTokens.light.surfaceInverse),
        greaterThanOrEqualTo(4.5));
    expect(contrastRatio(WudgetTokens.onInverseNegative, WudgetTokens.light.surfaceInverse),
        greaterThanOrEqualTo(4.5));
    expect(contrastRatio(WudgetTokens.onInversePositive, WudgetTokens.dark.surfaceInverse),
        greaterThanOrEqualTo(4.5));
    expect(contrastRatio(WudgetTokens.onInverseNegative, WudgetTokens.dark.surfaceInverse),
        greaterThanOrEqualTo(4.5));
  });
}