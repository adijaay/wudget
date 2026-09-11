import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:wudget/core/money.dart';
import 'package:wudget/core/money_formatter.dart';
import 'package:wudget/core/providers.dart';
import 'package:wudget/data/database.dart';
import 'package:wudget/design/tokens.dart';
import 'package:wudget/domain/default_categories.dart';
import 'package:wudget/features/capture/capture_sheet.dart';

const _formatter = MoneyFormatter();

/// plan/05-sprints.md Sprint 18: "Semantics labels, screen reader
/// traversal of the capture sheet with amounts announced." A screen
/// reader walks the semantics tree, not the widget tree — this asserts
/// what it would actually find: a labelled amount that updates as digits
/// are entered, and every numpad control carrying a real label rather
/// than a bare glyph.
void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  testWidgets('the amount is announced, and updates as digits are entered', (tester) async {
    // Disposed explicitly at the end of this body, not via addTearDown:
    // WidgetTester's end-of-test semantics-handle check runs inside the
    // testWidgets callback itself, before addTearDown callbacks fire.
    final handle = tester.ensureSemantics();

    final db = WudgetDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await seedDefaultsIfEmpty(db);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: buildWudgetTheme(WudgetTokens.light, Brightness.light),
          home: const Scaffold(body: CaptureSheet()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final amountFinder = find.byKey(const Key('captureAmount'));

    // Rp 0 to start — a screen reader must still hear a real amount, not
    // silence or a raw "0".
    expect(tester.getSemantics(amountFinder).label, 'Jumlah: ${_formatter.format(Money.fromMinor(0, 'IDR'))}');

    await tester.tap(find.text('1'));
    await tester.tap(find.text('5'));
    await tester.tap(find.text('0'));
    await tester.tap(find.text('0'));
    await tester.tap(find.text('0'));
    await tester.pump();

    expect(tester.getSemantics(amountFinder).label, 'Jumlah: ${_formatter.format(Money.fromMinor(15000, 'IDR'))}');

    // The capture sheet holds StreamBuilders over drift watch queries
    // (category/account dropdowns) — unmount under a controlled pump
    // before the test ends, per the house pattern in DECISIONS.md
    // (Sprint 5/6), or drift's stream-query cleanup Timer trips
    // flutter_test's "a Timer is still pending" check.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));

    handle.dispose();
  });

  testWidgets('every numpad control has a real label, not a bare glyph', (tester) async {
    final handle = tester.ensureSemantics();

    final db = WudgetDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await seedDefaultsIfEmpty(db);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: buildWudgetTheme(WudgetTokens.light, Brightness.light),
          home: const Scaffold(body: CaptureSheet()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The glyph-only controls (⌫, ±, ✓) must announce a real word, not the
    // glyph itself — a screen reader user cannot act on "backspace symbol".
    expect(tester.getSemantics(find.text('⌫')).label, 'Hapus');
    expect(tester.getSemantics(find.text('±')).label, 'Kalkulator');
    expect(tester.getSemantics(find.text('✓')).label, 'Simpan');
    final dateSemantics = find.byWidgetPredicate(
      (w) => w is Semantics && (w.properties.label?.startsWith('Tanggal: ') ?? false),
    );
    expect(dateSemantics, findsOneWidget);

    // Digit keys are real Semantics buttons (not just visible text a mouse
    // could hit), so Tab/switch-access and a screen reader can reach them.
    for (final digit in ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0']) {
      final semantics = tester.getSemantics(find.text(digit));
      expect(semantics.hasFlag(SemanticsFlag.isButton), isTrue, reason: 'digit "$digit" is not a Semantics button');
    }

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));

    handle.dispose();
  });
}
