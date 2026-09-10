import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wudget/core/providers.dart';
import 'package:wudget/data/database.dart';
import 'package:wudget/design/tokens.dart';
import 'package:wudget/domain/default_categories.dart';
import 'package:wudget/features/capture/capture_sheet.dart';

void main() {
  testWidgets('an expense is saved end to end: amount, category, save writes balanced postings',
      (tester) async {
    final db = WudgetDatabase(NativeDatabase.memory());
    await seedDefaultsIfEmpty(db);
    addTearDown(db.close);

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

    // Type Rp 15.000.
    await tester.tap(find.text('1'));
    await tester.tap(find.text('5'));
    await tester.tap(find.text('000'));
    await tester.pump();

    expect(find.textContaining('15.000'), findsOneWidget);

    // Pick the "Makan" category.
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
}
