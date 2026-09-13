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

/// Turning the calculator off used to leave the expression in the buffer with
/// no operator row left to edit it, so the next digit extended the last
/// operand: 15000 + 5000 then 1 became 15000 + 50001. Leaving the mode is the
/// "=" this numpad has no key for.
void main() {
  testWidgets('leaving calculator mode collapses the expression to its result', (tester) async {
    await initializeDateFormatting('id_ID');
    final db = WudgetDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await seedDefaultsIfEmpty(db);

    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        theme: buildWudgetTheme(WudgetTokens.light, Brightness.light),
        home: const Scaffold(body: CaptureSheet()),
      ),
    ));
    await tester.pumpAndSettle();

    Future<void> tap(String label) async {
      await tester.tap(find.text(label).first);
      await tester.pump();
    }

    String amount() =>
        tester.widget<Text>(find.byKey(const Key('captureAmount'))).data!;

    await tester.tap(find.byKey(const Key('numpadKey_calculator')));
    await tester.pumpAndSettle();
    for (final key in ['1', '5']) {
      await tap(key);
    }
    await tester.tap(find.byKey(const Key('numpadKey_000')));
    await tap('+');
    expect(amount(), '0', reason: 'an operator hands you an empty number');
    await tap('5');
    await tester.tap(find.byKey(const Key('numpadKey_000')));
    await tester.pumpAndSettle();
    // The big slot is the operand being typed, not the running total, so
    // tapping + does not appear to edit the number before it.
    expect(amount(), '5.000');
    expect(find.text('15000 + '), findsOneWidget);

    await tester.tap(find.byKey(const Key('numpadKey_calculator')));
    await tester.pumpAndSettle();
    expect(amount(), '20.000', reason: 'leaving the mode is the "=" that totals it');
    expect(find.text('15000 + '), findsNothing);

    await tap('1');
    await tester.pumpAndSettle();
    expect(amount(), '200.001', reason: 'the next digit continues the result, not the last operand');

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });
}
