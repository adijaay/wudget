import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:wudget/core/providers.dart';
import 'package:wudget/data/database.dart';
import 'package:wudget/data/feature_flags_repository.dart';
import 'package:wudget/data/postings_repository.dart';
import 'package:wudget/design/tokens.dart';
import 'package:wudget/features/pantau/pantau_screen.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  testWidgets('shows the waiting state with no history', (tester) async {
    final db = WudgetDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: buildWudgetTheme(WudgetTokens.light, Brightness.light),
          home: const PantauScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Catat dulu'), findsOneWidget);
    expect(find.text('Pengeluaran'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets('shows totals once 14 days of history exist', (tester) async {
    final db = WudgetDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final postings = PostingsRepository(db);

    final firstDay = DateTime.now().subtract(const Duration(days: 14));
    await postings.insertTransaction(
      transaction: TransactionsCompanion.insert(
        id: 'tx1',
        kind: 'expense',
        occurredAt: firstDay.toUtc().millisecondsSinceEpoch,
        tzOffsetMinutes: 0,
        updatedAt: 0,
      ),
      postings: [
        PostingsCompanion.insert(id: 'p1a', transactionId: 'tx1', accountId: const Value('acc'),
            amountMinor: -12000, currency: 'IDR', baseAmountMinor: -12000),
        PostingsCompanion.insert(id: 'p1c', transactionId: 'tx1', categoryId: const Value('cat'),
            amountMinor: 12000, currency: 'IDR', baseAmountMinor: 12000),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: buildWudgetTheme(WudgetTokens.light, Brightness.light),
          home: const PantauScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // No previous period has any real history, so the pace card names the
    // reason instead of fabricating a comparison (chart rule 8).
    expect(find.text('Belum ada periode sebelumnya untuk dibandingkan.'), findsOneWidget);

    await tester.ensureVisible(find.text('Lihat sisa saldo periode ini'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lihat sisa saldo periode ini'));
    await tester.pumpAndSettle();
    expect(find.text('Sisa periode ini'), findsOneWidget);
    await tester.tapAt(const Offset(20, 20)); // dismiss the sheet
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets('states a pace sentence once a full previous period exists to compare against',
      (tester) async {
    final db = WudgetDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final postings = PostingsRepository(db);

    Future<void> expense(String id, DateTime at, int amountMinor) {
      return postings.insertTransaction(
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
          PostingsCompanion.insert(id: '${id}c', transactionId: id, categoryId: const Value('cat'),
              amountMinor: amountMinor, currency: 'IDR', baseAmountMinor: amountMinor),
        ],
      );
    }

    // First ever transaction over a year ago guarantees the entire previous
    // calendar month is "full" history, whatever today's date happens to
    // be — a relative "60 days ago" would sometimes land inside the same
    // calendar month as today, making the test's outcome date-dependent.
    final now = DateTime.now();
    await expense('tx0', now.subtract(const Duration(days: 400)), 5000);
    await expense('tx1', DateTime(now.year, now.month - 1, 15), 300000);
    await expense('tx2', now, 10000);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: buildWudgetTheme(WudgetTokens.light, Brightness.light),
          home: const PantauScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Belum ada periode sebelumnya untuk dibandingkan.'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets('the remaining-first flag leads with the remaining balance, pace one tap away',
      (tester) async {
    final db = WudgetDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await FeatureFlagsRepository(db).setBool(paceFirstFlagKey, false);

    final postings = PostingsRepository(db);
    await postings.insertTransaction(
      transaction: TransactionsCompanion.insert(
        id: 'tx1',
        kind: 'expense',
        occurredAt: DateTime.now().subtract(const Duration(days: 14)).toUtc().millisecondsSinceEpoch,
        tzOffsetMinutes: 0,
        updatedAt: 0,
      ),
      postings: [
        PostingsCompanion.insert(id: 'p1a', transactionId: 'tx1', accountId: const Value('acc'),
            amountMinor: -12000, currency: 'IDR', baseAmountMinor: -12000),
        PostingsCompanion.insert(id: 'p1c', transactionId: 'tx1', categoryId: const Value('cat'),
            amountMinor: 12000, currency: 'IDR', baseAmountMinor: 12000),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: buildWudgetTheme(WudgetTokens.light, Brightness.light),
          home: const PantauScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sisa periode ini'), findsOneWidget);
    expect(find.text('Lihat laju & perkiraan'), findsOneWidget);
    expect(find.text('Lihat sisa saldo periode ini'), findsNothing);

    await tester.ensureVisible(find.text('Lihat laju & perkiraan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lihat laju & perkiraan'));
    await tester.pumpAndSettle();
    expect(find.byType(PantauScreen), findsOneWidget); // sheet is up, screen still behind it

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets('logs a pantau_viewed analytics event with the active variant', (tester) async {
    final db = WudgetDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final postings = PostingsRepository(db);
    await postings.insertTransaction(
      transaction: TransactionsCompanion.insert(
        id: 'tx1',
        kind: 'expense',
        occurredAt: DateTime.now().subtract(const Duration(days: 14)).toUtc().millisecondsSinceEpoch,
        tzOffsetMinutes: 0,
        updatedAt: 0,
      ),
      postings: [
        PostingsCompanion.insert(id: 'p1a', transactionId: 'tx1', accountId: const Value('acc'),
            amountMinor: -12000, currency: 'IDR', baseAmountMinor: -12000),
        PostingsCompanion.insert(id: 'p1c', transactionId: 'tx1', categoryId: const Value('cat'),
            amountMinor: 12000, currency: 'IDR', baseAmountMinor: 12000),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: buildWudgetTheme(WudgetTokens.light, Brightness.light),
          home: const PantauScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final events = await (db.select(db.analyticsEvents)..where((e) => e.name.equals('pantau_viewed'))).get();
    expect(events, hasLength(1));
    expect(events.single.propsJson, contains('pace_first'));

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });
}
