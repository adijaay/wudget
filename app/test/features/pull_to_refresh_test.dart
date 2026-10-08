import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:wudget/core/providers.dart';
import 'package:wudget/data/analytics_repository.dart';
import 'package:wudget/data/database.dart';
import 'package:wudget/data/postings_repository.dart';
import 'package:wudget/design/tokens.dart';
import 'package:wudget/domain/default_categories.dart';
import 'package:wudget/features/budget/budget_screen.dart';
import 'package:wudget/features/ledger/ledger_screen.dart';
import 'package:wudget/features/pantau/pantau_screen.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  Widget host(WudgetDatabase db, Widget screen) => ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: buildWudgetTheme(WudgetTokens.light, Brightness.light),
          home: screen,
        ),
      );

  Future<void> expense(WudgetDatabase db, String id, DateTime at, int amountMinor) {
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
            accountId: const Value('acc_cash'),
            amountMinor: -amountMinor,
            currency: 'IDR',
            baseAmountMinor: -amountMinor),
        PostingsCompanion.insert(
            id: '${id}c',
            transactionId: id,
            categoryId: const Value('cat_makan'),
            amountMinor: amountMinor,
            currency: 'IDR',
            baseAmountMinor: amountMinor),
      ],
    );
  }

  Future<void> pull(WidgetTester tester) async {
    await tester.drag(find.byType(RefreshIndicator).first, const Offset(0, 400),
        warnIfMissed: false);
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }

  Future<void> expectPulled(WudgetDatabase db, String screen) async {
    final events = await AnalyticsRepository(db).all();
    expect(
      events.where((e) => e.name == 'pull_to_refresh' && e.propsJson!.contains('"$screen"')),
      isNotEmpty,
    );
  }

  testWidgets('Catat: pulling down is wired to a reload, and the ledger survives it',
      (tester) async {
    final db = WudgetDatabase(NativeDatabase.memory());
    await seedDefaultsIfEmpty(db);
    addTearDown(db.close);

    await tester.pumpWidget(host(db, const LedgerScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Catat satu pengeluaran hari ini'), findsOneWidget);

    await expense(db, 'tx1', DateTime.now(), 15000);
    await tester.pumpAndSettle();

    await pull(tester);
    await expectPulled(db, 'catat');
    // Reloaded, not blanked: the row the reload produced is on screen.
    expect(find.text('Makan'), findsOneWidget);
    expect(find.text('Catat satu pengeluaran hari ini'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets('Pantau: pulling down is wired to a reload, and the period survives it',
      (tester) async {
    final db = WudgetDatabase(NativeDatabase.memory());
    await seedDefaultsIfEmpty(db);
    addTearDown(db.close);

    await tester.pumpWidget(host(db, const PantauScreen()));
    await tester.pumpAndSettle();
    expect(find.text('0'), findsOneWidget); // 0 of 14 days collected

    await expense(db, 'tx1', DateTime.now(), 15000);
    await tester.pumpAndSettle();

    await pull(tester);
    await expectPulled(db, 'pantau');
    // Reloaded, not reset: the transaction the reload read is on screen.
    expect(find.textContaining('15.000'), findsWidgets);
    expect(find.textContaining('dari 14 hari'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets('Anggaran: pulling down is the only way it can see history written since it loaded',
      (tester) async {
    // BudgetScreen is the one of the three with no table listener: it reads
    // once in initState, so a pull is genuinely the only path to fresh data.
    final db = WudgetDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(host(db, const BudgetScreen()));
    await tester.pumpAndSettle();
    expect(find.textContaining('Belum ada yang bisa diusulkan'), findsOneWidget);

    await db.into(db.categories).insert(CategoriesCompanion.insert(
          id: 'cat_makan',
          name: 'Makan',
          kind: 'expense',
          iconKey: 'food',
          hueIndex: 0,
          sortOrder: 0,
          updatedAt: 0,
        ));
    await expense(db, 'tx1', DateTime.now().subtract(const Duration(days: 5)), 70000);
    await tester.pumpAndSettle();
    expect(find.textContaining('Belum ada yang bisa diusulkan'), findsOneWidget);

    await pull(tester);
    await expectPulled(db, 'kantong');
    expect(find.text('Makan'), findsOneWidget);
    expect(find.textContaining('Belum ada yang bisa diusulkan'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });
}