import 'package:drift/drift.dart' show Value;
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
import 'package:wudget/data/capture_queries.dart';
import 'package:wudget/domain/period.dart';
import 'package:wudget/features/capture/capture_sheet.dart';
import 'package:wudget/features/widget/capture_deeplink.dart';

Future<void> _openSheet(WidgetTester tester, WudgetDatabase db,
    [CaptureSheet sheet = const CaptureSheet()]) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        theme: buildWudgetTheme(WudgetTokens.light, Brightness.light),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => sheet,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

String _amountText(WidgetTester tester) =>
    (tester.widget(find.byKey(const Key('captureAmount'))) as Text).data!;

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  testWidgets('an expense is saved end to end: amount, category, save writes balanced postings',
      (tester) async {
    final db = WudgetDatabase(NativeDatabase.memory());
    await seedDefaultsIfEmpty(db);
    addTearDown(db.close);

    await _openSheet(tester, db);

    // Type Rp 15.000.
    await tester.tap(find.byKey(const Key('numpadKey_1')));
    await tester.tap(find.byKey(const Key('numpadKey_5')));
    await tester.tap(find.byKey(const Key('numpadKey_000')));
    await tester.pump();

    expect(_amountText(tester), contains('15.000'));

    await tester.ensureVisible(find.text('Makan'));
    await tester.tap(find.text('Makan'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('numpadKey_save')));
    await tester.pumpAndSettle();

    final transactions = await db.select(db.transactions).get();
    expect(transactions.length, 1);
    expect(transactions.single.kind, 'expense');

    final postings = await db.select(db.postings).get();
    expect(postings.length, 2);
    final sum = postings.fold<int>(0, (acc, p) => acc + p.baseAmountMinor);
    expect(sum, 0);

    final accountLeg = postings.firstWhere((p) => p.accountId != null);
    expect(accountLeg.amountMinor, -15000);
    final categoryLeg = postings.firstWhere((p) => p.categoryId != null);
    expect(categoryLeg.amountMinor, 15000);
    expect(categoryLeg.categoryId, 'cat_makan');
  });

  testWidgets('calculator mode evaluates a left-to-right expression before saving', (tester) async {
    final db = WudgetDatabase(NativeDatabase.memory());
    await seedDefaultsIfEmpty(db);
    addTearDown(db.close);

    await _openSheet(tester, db);

    await tester.tap(find.byKey(const Key('numpadKey_calculator')));
    await tester.pump();

    // 10000 + 5000
    // Keys, not glyphs: the amount display renders digits too, so
    // find.text('0') would match the display as well as the key.
    for (final d in ['1', '0', '0', '0', '0']) {
      await tester.tap(find.byKey(Key('numpadKey_$d')));
    }
    await tester.tap(find.byKey(const Key('numpadOp_+')));
    for (final d in ['5', '0', '0', '0']) {
      await tester.tap(find.byKey(Key('numpadKey_$d')));
    }
    await tester.pump();

    await tester.ensureVisible(find.text('Makan'));
    await tester.tap(find.text('Makan'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('numpadKey_save')));
    await tester.pumpAndSettle();

    final postings = await db.select(db.postings).get();
    final accountLeg = postings.firstWhere((p) => p.accountId != null);
    expect(accountLeg.amountMinor, -15000); // 10000 + 5000
  });

  testWidgets('no wallet picker; typing needs no tap first; the save button says what it will do',
      (tester) async {
    final db = WudgetDatabase(NativeDatabase.memory());
    await seedDefaultsIfEmpty(db);
    addTearDown(db.close);

    await _openSheet(tester, db);
    expect(find.byType(PopupMenuButton<String>), findsNothing);
    expect(find.byTooltip('Pilih kantong'), findsNothing);
    expect(find.text('Transfer'), findsNothing);

    await tester.tap(find.byKey(const Key('numpadKey_2')));
    await tester.tap(find.byKey(const Key('numpadKey_000')));
    await tester.ensureVisible(find.text('Makan'));
    await tester.tap(find.text('Makan'));
    await tester.pumpAndSettle();
    expect(find.textContaining('2.000 ke Makan'), findsOneWidget);

    // The note is left empty.
    await tester.tap(find.byKey(const Key('numpadKey_save')));
    await tester.pumpAndSettle();
    final tx = (await db.select(db.transactions).get()).single;
    expect(tx.note, isNull);
    expect((await db.select(db.postings).get()).firstWhere((p) => p.accountId != null).accountId, 'acc_cash');
  });

  testWidgets('income on a normal day saves with "Simpan saja"', (tester) async {
    final db = WudgetDatabase(NativeDatabase.memory());
    await seedDefaultsIfEmpty(db);
    addTearDown(db.close);

    await _openSheet(tester, db);
    await tester.tap(find.text('Pemasukan'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('numpadKey_5')));
    await tester.tap(find.byKey(const Key('numpadKey_000')));
    final incomeCategory = (await (db.select(db.categories)
              ..where((c) => c.kind.equals('income'))
              ..where((c) => c.parentId.isNull()))
            .get())
        .first;
    await tester.ensureVisible(find.text(incomeCategory.name));
    await tester.tap(find.text(incomeCategory.name));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Tambah catatan'));
    await tester.tap(find.text('Tambah catatan'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('captureNote')), 'Refund');

    expect(find.text('Simpan saja'), findsOneWidget);
    await tester.tap(find.byKey(const Key('numpadKey_save')));
    await tester.pumpAndSettle();
    final tx = (await db.select(db.transactions).get()).single;
    expect(tx.kind, 'income');
    expect(tx.note, 'Refund');
  });

  testWidgets('the toast names what is left in the kantong, and undo removes the entry and postings',
      (tester) async {
    final db = WudgetDatabase(NativeDatabase.memory());
    await seedDefaultsIfEmpty(db);
    addTearDown(db.close);
    await db.into(db.budgets).insert(BudgetsCompanion.insert(key: 'cat_makan', amountMinor: 500000, updatedAt: 0));

    await _openSheet(tester, db);
    await tester.tap(find.byKey(const Key('numpadKey_1')));
    await tester.tap(find.byKey(const Key('numpadKey_8')));
    await tester.tap(find.byKey(const Key('numpadKey_000')));
    await tester.ensureVisible(find.text('Makan'));
    await tester.tap(find.text('Makan'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('numpadKey_save')));
    await tester.pumpAndSettle();

    final period = Period.containing(todayDayBucket(), monthStartDay: 1);
    final remaining = await tester.runAsync(() => CaptureQueries(db).kantongRemaining('cat_makan', period));
    expect(remaining, 500000 - 18000);
    expect(find.textContaining(RegExp(r'Kantong Makan sisa Rp.482.000')), findsOneWidget);

    await tester.tap(find.text('Batalkan'));
    await tester.pumpAndSettle();
    expect(await db.select(db.transactions).get(), isEmpty);
    expect(await db.select(db.postings).get(), isEmpty);
  });

  testWidgets('a home chip opens the sheet pre-filled with note, category and amount', (tester) async {
    final db = WudgetDatabase(NativeDatabase.memory());
    await seedDefaultsIfEmpty(db);
    addTearDown(db.close);

    const launch = CaptureLaunch(kind: CaptureKind.expense, categoryId: 'cat_makan', amountMinor: 18000, note: 'Warung');
    await _openSheet(
      tester,
      db,
      CaptureSheet(
        initialCategoryId: launch.categoryId,
        initialAmountMinor: launch.amountMinor,
        initialNote: launch.note,
        source: CaptureSource.chip,
      ),
    );
    expect(find.textContaining('18.000 ke Makan'), findsOneWidget);
    await tester.tap(find.byKey(const Key('numpadKey_save')));
    await tester.pumpAndSettle();
    final tx = (await db.select(db.transactions).get()).single;
    expect(tx.note, 'Warung');
    final events = await db.select(db.analyticsEvents).get();
    expect(events.map((e) => e.propsJson).join(), contains('chip'));
  });

  testWidgets('a transfer moves money between two wallets with no category leg', (tester) async {
    final db = WudgetDatabase(NativeDatabase.memory());
    await seedDefaultsIfEmpty(db); // seeds acc_cash
    await db.into(db.accounts).insert(AccountsCompanion.insert(
          id: 'acc_bank', name: 'Bank', type: 'bank', currency: 'IDR', updatedAt: 0,
        ));
    addTearDown(db.close);

    await _openSheet(tester, db, const CaptureSheet(initialKind: CaptureKind.transfer));

    await tester.tap(find.byKey(const Key('numpadKey_1')));
    await tester.tap(find.byKey(const Key('numpadKey_0')));
    await tester.tap(find.byKey(const Key('numpadKey_000')));
    await tester.pump();

    await tester.tap(find.byKey(const Key('numpadKey_save')));
    await tester.pumpAndSettle();

    final transactions = await db.select(db.transactions).get();
    expect(transactions.single.kind, 'transfer');

    final postings = await db.select(db.postings).get();
    expect(postings.length, 2);
    expect(postings.every((p) => p.categoryId == null), isTrue); // no category leg
    final sum = postings.fold<int>(0, (acc, p) => acc + p.baseAmountMinor);
    expect(sum, 0);
  });

  testWidgets('confirming a recurrence placeholder removes it, leaving one real transaction',
      (tester) async {
    final db = WudgetDatabase(NativeDatabase.memory());
    await seedDefaultsIfEmpty(db);
    addTearDown(db.close);

    await PostingsRepository(db).insertTransaction(
      transaction: TransactionsCompanion.insert(
        id: 'placeholder',
        kind: 'expense',
        occurredAt: 0,
        tzOffsetMinutes: 0,
        recurrenceId: const Value('rec1'),
        isProjected: const Value(true),
        updatedAt: 0,
      ),
      postings: [
        PostingsCompanion.insert(id: 'p1a', transactionId: 'placeholder', accountId: const Value('acc_cash'),
            amountMinor: -150000, currency: 'IDR', baseAmountMinor: -150000),
        PostingsCompanion.insert(id: 'p1c', transactionId: 'placeholder', categoryId: const Value('cat_tagihan'),
            amountMinor: 150000, currency: 'IDR', baseAmountMinor: 150000),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: buildWudgetTheme(WudgetTokens.light, Brightness.light),
          home: const Scaffold(
            body: CaptureSheet(
              initialCategoryId: 'cat_tagihan',
              initialAccountId: 'acc_cash',
              initialAmountMinor: 150000,
              confirmingTransactionId: 'placeholder',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('numpadKey_save')));
    await tester.pumpAndSettle();

    final transactions = await db.select(db.transactions).get();
    expect(transactions, hasLength(1)); // the placeholder is gone
    expect(transactions.single.id, isNot('placeholder'));
    expect(transactions.single.isProjected, isFalse);
  });
}
