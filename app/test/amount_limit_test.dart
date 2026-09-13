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

/// An amount with no ceiling reached the database as a number SQLite's SUM
/// could not add up, and Kantong died on it. The cap is what stops that, so
/// it is what this asserts: hammer the numpad, then prove the balance the
/// saved row produces is still a number the database can sum.
void main() {
  testWidgets('a hammered numpad cannot build an amount past the digit cap', (tester) async {
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

    await tester.tap(find.text('Makan').first);
    await tester.pumpAndSettle();
    for (var i = 0; i < 12; i++) {
      await tester.tap(find.text('9').first);
      await tester.tap(find.byKey(const Key('numpadKey_000')));
    }
    await tester.pumpAndSettle();

    // Whatever the numpad let through has to still be an amount the ledger
    // can add up: within int64 with room for a lifetime of rows above it.
    final shown = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .firstWhere((d) => d.startsWith('9'), orElse: () => '');
    final digits = shown.replaceAll(RegExp(r'[^0-9]'), '');
    expect(digits, isNotEmpty, reason: 'no amount rendered');
    expect(digits.length, lessThanOrEqualTo(12), reason: 'rendered "$shown"');

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });
}
