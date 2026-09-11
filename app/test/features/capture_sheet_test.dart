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
import 'package:wudget/features/capture/capture_sheet.dart';

Future<void> _openSheet(WidgetTester tester, WudgetDatabase db) async {
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
                builder: (_) => const CaptureSheet(),
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
    await tester.tap(find.text('1'));
    await tester.tap(find.text('5'));
    await tester.tap(find.text('000'));
    await tester.pump();

    expect(_amountText(tester), contains('15.000'));

    await tester.tap(find.text('Makan'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('✓'));
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

    await tester.tap(find.bySemanticsLabel('Kalkulator'));
    await tester.pump();

    // 10000 + 5000
    for (final d in ['1', '0', '0', '0', '0']) {
      await tester.tap(find.text(d));
    }
    await tester.tap(find.text('+'));
    for (final d in ['5', '0', '0', '0']) {
      await tester.tap(find.text(d));
    }
    await tester.pump();

    await tester.tap(find.text('Makan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('✓'));
    await tester.pumpAndSettle();

    final postings = await db.select(db.postings).get();
    final accountLeg = postings.firstWhere((p) => p.accountId != null);
    expect(accountLeg.amountMinor, -15000); // 10000 + 5000
  });

  testWidgets('a saved expense becomes a one-tap template on the next open', (tester) async {
    final db = WudgetDatabase(NativeDatabase.memory());
    await seedDefaultsIfEmpty(db);
    addTearDown(db.close);

    await _openSheet(tester, db);
    await tester.tap(find.text('2'));
    await tester.tap(find.text('0'));
    await tester.tap(find.text('000'));
    await tester.tap(find.text('Makan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('✓'));
    await tester.pumpAndSettle();

    // Reopen: the template row should now offer "Makan" as a one-tap chip.
    await _openSheet(tester, db);
    await tester.pumpAndSettle();

    final templateChip = find.widgetWithText(ActionChip, 'Makan');
    expect(templateChip, findsOneWidget);
    await tester.tap(templateChip);
    await tester.pump();

    expect(_amountText(tester), contains('20.000'));

    await tester.tap(find.text('✓'));
    await tester.pumpAndSettle();

    final transactions = await db.select(db.transactions).get();
    expect(transactions.length, 2);
  });

  testWidgets('a transfer moves money between two wallets with no category leg', (tester) async {
    final db = WudgetDatabase(NativeDatabase.memory());
    await seedDefaultsIfEmpty(db); // seeds acc_cash
    await db.into(db.accounts).insert(AccountsCompanion.insert(
          id: 'acc_bank', name: 'Bank', type: 'bank', currency: 'IDR', updatedAt: 0,
        ));
    addTearDown(db.close);

    await _openSheet(tester, db);
    await tester.tap(find.text('Transfer'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('1'));
    await tester.tap(find.text('0'));
    await tester.tap(find.text('000'));
    await tester.pump();

    await tester.tap(find.text('✓'));
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

    await tester.tap(find.text('✓'));
    await tester.pumpAndSettle();

    final transactions = await db.select(db.transactions).get();
    expect(transactions, hasLength(1)); // the placeholder is gone
    expect(transactions.single.id, isNot('placeholder'));
    expect(transactions.single.isProjected, isFalse);
  });
}
