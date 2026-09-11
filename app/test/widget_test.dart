import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wudget/core/providers.dart';
import 'package:wudget/data/database.dart';
import 'package:wudget/features/wallets/wallets_screen.dart';
import 'package:wudget/main.dart';

void main() {
  testWidgets('app boots to Kantong, with Catat available in the tab bar', (WidgetTester tester) async {
    final db = WudgetDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const WudgetApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(WalletsScreen), findsOneWidget);

    await tester.tap(find.text('Catat'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Belum ada transaksi.'), findsOneWidget);

    // Unmount explicitly, with a pump still under our control, so drift's
    // stream-query cleanup (which schedules its own Timer.run — see
    // stream_queries.dart) fires before flutter_test's end-of-test "no
    // pending timer" check runs. Left mounted, that check runs right after
    // automatic teardown with no pump left to flush it.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });
}
