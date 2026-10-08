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


void main() {
  setUpAll(() async => initializeDateFormatting('id_ID'));

  testWidgets('a split expense saves one category leg per part, balanced, once the remainder is zero',
      (tester) async {
    final db = WudgetDatabase(NativeDatabase.memory());
    await seedDefaultsIfEmpty(db);
    addTearDown(db.close);
    await _openSheet(tester, db);

    for (final k in ['1', '5', '000']) {
      await tester.tap(find.byKey(Key('numpadKey_$k')));
    }
    await tester.pump();
    await tester.ensureVisible(find.text('Makan'));
    await tester.tap(find.text('Makan'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('captureSplitStart')));
    await tester.tap(find.byKey(const Key('captureSplitStart')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('splitAmount_0')), '10000');
    await tester.pump();
    expect(find.textContaining('5.000'), findsWidgets);

    await tester.ensureVisible(find.byKey(const Key('splitCategory_1')));
    await tester.tap(find.byKey(const Key('splitCategory_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Transport').last);
    await tester.pumpAndSettle();

    // Remainder still Rp 5.000: save is blocked.
    await tester.tap(find.byKey(const Key('numpadKey_save')));
    await tester.pumpAndSettle();
    expect(await db.select(db.transactions).get(), isEmpty);

    await tester.enterText(find.byKey(const Key('splitAmount_1')), '5000');
    await tester.pump();
    await tester.tap(find.byKey(const Key('numpadKey_save')));
    await tester.pumpAndSettle();

    final postings = await db.select(db.postings).get();
    expect(postings.length, 3);
    expect(postings.fold<int>(0, (a, p) => a + p.baseAmountMinor), 0);
    final legs = {for (final p in postings) if (p.categoryId != null) p.categoryId: p.amountMinor};
    expect(legs, {'cat_makan': 10000, 'cat_transport': 5000});
  });
}
