import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:wudget/core/providers.dart';
import 'package:wudget/data/database.dart';
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
}
