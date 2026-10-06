import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:wudget/core/providers.dart';
import 'package:wudget/data/database.dart';
import 'package:wudget/features/shell/nav_bar.dart';
import 'package:wudget/features/budget/budget_screen.dart';
import 'package:wudget/features/settings/saya_screen.dart';
import 'package:wudget/features/wallets/wallets_screen.dart';
import 'package:wudget/main.dart';

void main() {
  // main() initialises this before runApp; a test that pumps the whole
  // shell has to do the same, because every tab is built at once by the
  // IndexedStack and Pantau formats dates as it builds.
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  testWidgets('app boots to Catat, wallets live in Saya, with the four tabs and the capture button', (WidgetTester tester) async {
    final db = WudgetDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const WudgetApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(WalletsScreen, skipOffstage: false), findsNothing);
    expect(find.byType(BudgetScreen, skipOffstage: false), findsOneWidget); // the Kantong tab
    // Catat's first-run state shows the shape of the row that will exist,
    // and the one action that creates it.
    expect(find.text('Catat pengeluaran pertama'), findsOneWidget);

    // The capture button is docked in the middle of the bar, reachable from
    // every tab rather than living in one screen's corner.
    expect(find.byType(CaptureButton), findsOneWidget);
    await tester.tap(find.byKey(const Key('navTab_Saya')));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(SayaScreen), matching: find.text('Dompet')));
    await tester.pumpAndSettle();
    expect(find.byType(WalletsScreen), findsOneWidget);

    // Unmount explicitly, with a pump still under our control, so drift's
    // stream-query cleanup (which schedules its own Timer.run — see
    // stream_queries.dart) fires before flutter_test's end-of-test "no
    // pending timer" check runs. Left mounted, that check runs right after
    // automatic teardown with no pump left to flush it.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });
}
