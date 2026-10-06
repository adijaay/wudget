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

/// The save key used to return silently when the sheet was incomplete: fully
/// lit, tapped, nothing happened, nothing said. It has to name what is
/// missing, and stop saying it once that is supplied.
void main() {
  testWidgets('a blocked save says what is missing, and stops once it is given', (tester) async {
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

    Future<void> save() async {
      await tester.tap(find.byKey(const Key('numpadKey_save')));
      await tester.pumpAndSettle();
    }

    // Dimmed before the tap, so the state is visible without trying it, and a
    // screen reader hears the same thing the colour says.
    expect(find.bySemanticsLabel('Simpan, belum bisa'), findsOneWidget);

    await save();
    expect(find.text('Isi jumlahnya dulu.'), findsOneWidget);

    await tester.tap(find.text('1').first);
    await tester.tap(find.byKey(const Key('numpadKey_000')));
    await tester.pumpAndSettle();
    expect(find.text('Isi jumlahnya dulu.'), findsNothing);

    await save();
    expect(find.text('Pilih kategorinya dulu.'), findsOneWidget,
        reason: 'an amount with no category is the next thing missing');

    await tester.tap(find.text('Makan').first);
    await tester.pumpAndSettle();
    expect(find.text('Pilih kategorinya dulu.'), findsNothing);
    expect(find.bySemanticsLabel(RegExp(r'^Simpan Rp.1.000 ke Makan$')), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });
}
