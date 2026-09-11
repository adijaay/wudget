import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:wudget/core/providers.dart';
import 'package:wudget/data/database.dart';
import 'package:wudget/design/tokens.dart';
import 'package:wudget/features/pantau/pantau_screen.dart';
import 'package:wudget/features/wallets/wallets_screen.dart';

/// plan/05-sprints.md Sprint 18: "Dark theme complete, golden tests for
/// both themes on the key screens." Deliberately scoped to
/// low-decoration screens (an empty state, a waiting state): these are
/// screens data/06-implications.md's competitors got wrong (see
/// plan/04-ux-design.md's states table), not a chart-heavy render most
/// sensitive to font-hinting differences across machines. Regenerate with
/// `flutter test --update-goldens test/golden/key_screens_theme_test.dart`
/// after any deliberate visual change.
void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  Future<void> pumpThemed(WidgetTester tester, Widget home, Brightness brightness) async {
    final db = WudgetDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: buildWudgetTheme(WudgetTokens.light, Brightness.light),
          darkTheme: buildWudgetTheme(WudgetTokens.dark, Brightness.dark),
          themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
          home: home,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  // Both screens hold StreamBuilders over drift watch queries; unmount
  // under a controlled pump before the test ends, per the house pattern
  // in DECISIONS.md (Sprint 5/6), or drift's stream-query cleanup Timer
  // trips flutter_test's "a Timer is still pending" check.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('Kantong empty state, light theme', (tester) async {
    await pumpThemed(tester, const WalletsScreen(), Brightness.light);
    await expectLater(find.byType(WalletsScreen), matchesGoldenFile('kantong_empty_light.png'));
    await unmount(tester);
  });

  testWidgets('Kantong empty state, dark theme', (tester) async {
    await pumpThemed(tester, const WalletsScreen(), Brightness.dark);
    await expectLater(find.byType(WalletsScreen), matchesGoldenFile('kantong_empty_dark.png'));
    await unmount(tester);
  });

  testWidgets('Pantau waiting state, light theme', (tester) async {
    await pumpThemed(tester, const PantauScreen(), Brightness.light);
    await expectLater(find.byType(PantauScreen), matchesGoldenFile('pantau_waiting_light.png'));
    await unmount(tester);
  });

  testWidgets('Pantau waiting state, dark theme', (tester) async {
    await pumpThemed(tester, const PantauScreen(), Brightness.dark);
    await expectLater(find.byType(PantauScreen), matchesGoldenFile('pantau_waiting_dark.png'));
    await unmount(tester);
  });
}
