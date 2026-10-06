import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:wudget/core/providers.dart';
import 'package:wudget/data/budgets_repository.dart';
import 'package:wudget/data/database.dart';
import 'package:wudget/data/postings_repository.dart';
import 'package:wudget/design/tokens.dart';
import 'package:wudget/features/pantau/pantau_screen.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  Future<void> seedCategory(WudgetDatabase db) {
    return db.into(db.categories).insert(CategoriesCompanion.insert(
          id: 'cat', name: 'Makan', kind: 'expense', iconKey: 'food', hueIndex: 0, sortOrder: 0, updatedAt: 0,
        ));
  }

  Future<void> expense(WudgetDatabase db, String id, DateTime at, int amountMinor) {
    return PostingsRepository(db).insertTransaction(
      transaction: TransactionsCompanion.insert(
        id: id, kind: 'expense', occurredAt: at.toUtc().millisecondsSinceEpoch, tzOffsetMinutes: 0, updatedAt: 0,
      ),
      postings: [
        PostingsCompanion.insert(id: '${id}a', transactionId: id, accountId: const Value('acc'),
            amountMinor: -amountMinor, currency: 'IDR', baseAmountMinor: -amountMinor),
        PostingsCompanion.insert(id: '${id}c', transactionId: id, categoryId: const Value('cat'),
            amountMinor: amountMinor, currency: 'IDR', baseAmountMinor: amountMinor),
      ],
    );
  }

  testWidgets('shows the close summary for the just-ended period, then does not repeat it',
      (tester) async {
    final db = WudgetDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await seedCategory(db);
    final now = DateTime.now();

    await expense(db, 'tx0', DateTime(now.year, now.month - 2, 10), 5000); // clears waiting + gives a baseline
    await expense(db, 'tx1', DateTime(now.year, now.month - 1, 15), 200000); // the closing (just-ended) period

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

    expect(find.text('TUTUP PERIODE'), findsOneWidget);

    await tester.tap(find.text('Lanjut ke periode berikutnya'));
    await tester.pumpAndSettle();
    expect(find.text('TUTUP PERIODE'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));

    // Re-opening Pantau does not show it again — it was acknowledged.
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

    expect(find.text('TUTUP PERIODE'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets('shows nothing when the closing period has no data', (tester) async {
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

    expect(find.text('TUTUP PERIODE'), findsNothing);
    expect(find.text('Sudah beberapa waktu'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets('with a plan, the recap card shows and Bagikan opens the system share sheet',
      (tester) async {
    final db = WudgetDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await seedCategory(db);
    await BudgetsRepository(db).setAmount('cat', 300000);
    final now = DateTime.now();
    await expense(db, 'tx0', DateTime(now.year, now.month - 2, 10), 5000);
    await expense(db, 'tx1', DateTime(now.year, now.month - 1, 15), 200000);

    final shared = <MethodCall>[];
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(const MethodChannel('dev.fluttercommunity.plus/share'), (call) async {
      shared.add(call);
      return 'dev.fluttercommunity.plus/share/unavailable';
    });
    final tmp = Directory.systemTemp.createTempSync('recap');
    addTearDown(() => tmp.deleteSync(recursive: true));
    messenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'), (_) async => tmp.path);

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

    expect(find.text('Terpakai'), findsOneWidget);
    expect(find.text('Sisa Rp 100.000. Semua kantong aman.'), findsOneWidget);
    expect(find.text('Sisa Rp 100.000 ikut ke anggaran periode berikutnya saat gajian.'), findsOneWidget);
    // The leftover joins the next budget; no transfer is offered next to it.
    expect(find.textContaining('Sisihkan'), findsNothing);

    await tester.ensureVisible(find.text('Bagikan'));
    await tester.tap(find.text('Bagikan'));
    // toImage and the temp-file write are real async work, outside fake time.
    for (var i = 0; i < 50 && shared.isEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump();
    }
    expect(shared.single.method, 'share');

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });
}
