import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:wudget/core/providers.dart';
import 'package:wudget/data/categories_repository.dart';
import 'package:wudget/data/database.dart';
import 'package:wudget/design/tokens.dart';
import 'package:wudget/domain/default_categories.dart';
import 'package:wudget/features/capture/capture_sheet.dart';
import 'package:wudget/features/categories/categories_screen.dart';

Widget _wrap(WudgetDatabase db, Widget home) {
  return ProviderScope(
    overrides: [databaseProvider.overrideWithValue(db)],
    child: MaterialApp(
      theme: buildWudgetTheme(WudgetTokens.light, Brightness.light),
      home: home,
    ),
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  group('CategoriesRepository', () {
    test('a new category sorts after every existing one', () async {
      final db = WudgetDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await seedDefaultsIfEmpty(db);
      final repo = CategoriesRepository(db);

      final before = await db.select(db.categories).get();
      final maxBefore = before.map((c) => c.sortOrder).reduce((a, b) => a > b ? a : b);

      await repo.create(
        id: 'cat_kos', name: 'Kos', kind: 'expense', iconKey: 'home', hueIndex: 3,
      );

      final created = await (db.select(db.categories)..where((c) => c.id.equals('cat_kos'))).getSingle();
      expect(created.sortOrder, greaterThan(maxBefore));
      expect(created.parentId, isNull);
      expect(created.kind, 'expense');
    });

    test('a subcategory keeps its parent, so spend still rolls up', () async {
      final db = WudgetDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await seedDefaultsIfEmpty(db);

      await CategoriesRepository(db).create(
        id: 'cat_makan_gorengan',
        name: 'Gorengan',
        kind: 'expense',
        iconKey: 'restaurant',
        hueIndex: 0,
        parentId: 'cat_makan',
      );

      final created =
          await (db.select(db.categories)..where((c) => c.id.equals('cat_makan_gorengan'))).getSingle();
      expect(created.parentId, 'cat_makan');
    });

    test('rename changes the name everywhere, because rows store the id', () async {
      final db = WudgetDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await seedDefaultsIfEmpty(db);

      await CategoriesRepository(db).rename('cat_makan', 'Makan & minum');

      final renamed = await (db.select(db.categories)..where((c) => c.id.equals('cat_makan'))).getSingle();
      expect(renamed.name, 'Makan & minum');
      expect(renamed.id, 'cat_makan', reason: 'renaming must not re-key the category');
    });

    test('setAppearance updates the icon and hue without touching the name', () async {
      final db = WudgetDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await seedDefaultsIfEmpty(db);

      await CategoriesRepository(db).setAppearance('cat_lainnya', iconKey: 'pets', hueIndex: 5);

      final updated =
          await (db.select(db.categories)..where((c) => c.id.equals('cat_lainnya'))).getSingle();
      expect(updated.iconKey, 'pets');
      expect(updated.hueIndex, 5);
      expect(updated.name, 'Lainnya');
    });
  });

  testWidgets('the capture sheet creates a category and selects it straight away',
      (tester) async {
    final db = WudgetDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await seedDefaultsIfEmpty(db);

    await tester.pumpWidget(_wrap(db, const Scaffold(body: CaptureSheet())));
    await tester.pumpAndSettle();

    // The "+ Baru" tile sits at the end of the category row.
    await tester.ensureVisible(find.text('Baru'));
    await tester.tap(find.text('Baru'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, 'Kos');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tambah kategori'));
    await tester.pumpAndSettle();

    final created = await (db.select(db.categories)..where((c) => c.name.equals('Kos'))).getSingle();
    expect(created.kind, 'expense');

    // Selected, so the amount can be saved against it without hunting for it.
    expect(find.text('Kos'), findsWidgets);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets('the category screen renames an existing category', (tester) async {
    final db = WudgetDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await seedDefaultsIfEmpty(db);

    await tester.pumpWidget(_wrap(db, const CategoriesScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Makan'), findsOneWidget);
    await tester.tap(find.text('Makan'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Makan & minum');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    final renamed = await (db.select(db.categories)..where((c) => c.id.equals('cat_makan'))).getSingle();
    expect(renamed.name, 'Makan & minum');

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets('a category created for income does not appear under expenses', (tester) async {
    final db = WudgetDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await seedDefaultsIfEmpty(db);
    await CategoriesRepository(db).create(
      id: 'cat_bonus', name: 'Bonus', kind: 'income', iconKey: 'work', hueIndex: 2,
    );

    await tester.pumpWidget(_wrap(db, const Scaffold(body: CaptureSheet())));
    await tester.pumpAndSettle();

    expect(find.text('Bonus'), findsNothing, reason: 'expense capture must not offer an income category');

    await tester.tap(find.text('Pemasukan'));
    await tester.pumpAndSettle();
    expect(find.text('Bonus'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });

  test('a renamed category keeps the postings already written against it', () async {
    final db = WudgetDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await seedDefaultsIfEmpty(db);

    await db.into(db.transactions).insert(TransactionsCompanion.insert(
          id: 'tx1', kind: 'expense', occurredAt: 0, tzOffsetMinutes: 0, updatedAt: 0,
        ));
    await db.into(db.postings).insert(PostingsCompanion.insert(
          id: 'p1', transactionId: 'tx1', categoryId: const Value('cat_makan'),
          amountMinor: 15000, currency: 'IDR', baseAmountMinor: 15000,
        ));

    await CategoriesRepository(db).rename('cat_makan', 'Jajan');

    final posting = await (db.select(db.postings)..where((p) => p.id.equals('p1'))).getSingle();
    expect(posting.categoryId, 'cat_makan', reason: 'the posting points at the id, not the name');
  });
}
