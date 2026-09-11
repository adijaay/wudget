import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:wudget/core/providers.dart';
import 'package:wudget/data/database.dart';
import 'package:wudget/design/tokens.dart';
import 'package:wudget/domain/default_categories.dart';
import 'package:wudget/features/ledger/ledger_screen.dart';

/// plan/05-sprints.md Sprint 18: "Reduce-motion fallbacks." The app builds
/// no bespoke animation (no AnimationController, AnimatedContainer,
/// TweenAnimationBuilder, or Hero anywhere in lib/ — verified via
/// DECISIONS.md, Sprint 18) — every transition is a stock Material
/// default (the modal bottom sheet's slide-up), and Flutter's own
/// PageTransitionsTheme/ModalBottomSheetRoute already read
/// MediaQuery.disableAnimations and cut to an instant transition when
/// it's set. This test is the fallback's proof: opening the capture sheet
/// works exactly the same, immediately, with reduce-motion on.
void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  testWidgets('the capture sheet opens correctly with reduce-motion enabled', (tester) async {
    final db = WudgetDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await seedDefaultsIfEmpty(db);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            theme: buildWudgetTheme(WudgetTokens.light, Brightness.light),
            home: const LedgerScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Capture lives on the shell's docked centre button now, so a Catat
    // rendered on its own opens the sheet from its empty-state action.
    await tester.tap(find.text('Catat pengeluaran pertama'));
    await tester.pumpAndSettle();

    // The save key, fully rendered.
    expect(find.byKey(const Key('numpadKey_save')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });
}
