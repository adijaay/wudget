import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:wudget/core/providers.dart';
import 'package:wudget/data/analytics_repository.dart';
import 'package:wudget/data/database.dart';
import 'package:wudget/domain/default_categories.dart';
import 'package:wudget/features/shell/nav_bar.dart';
import 'package:wudget/main.dart';

// Run: flutter test integration_test/capture_timing_test.dart -d <device>
// Taps are machine speed, so this measures the app's own open-to-save cost, not a person's.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('20 repeat captures, median open-to-save', (tester) async {
    await initializeDateFormatting('id_ID');
    final db = WudgetDatabase(NativeDatabase.memory());
    await seedDefaultsIfEmpty(db);
    addTearDown(db.close);

    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const WudgetApp(),
    ));
    await tester.pumpAndSettle();

    Future<void> capture() async {
      await tester.tap(find.byType(CaptureButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('numpadKey_2')));
      await tester.tap(find.byKey(const Key('numpadKey_5')));
      await tester.tap(find.byKey(const Key('numpadKey_000')));
      await tester.tap(find.text('Makan').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('numpadKey_save')));
      await tester.pumpAndSettle();
    }

    await capture();
    for (var i = 0; i < 20; i++) {
      await capture();
    }

    final ms = await AnalyticsRepository(db).recentCaptureSaveMs();
    expect(ms, hasLength(20));
    // ignore: avoid_print
    print('CAPTURE_MEDIAN_MS=${medianMs(ms)}');
  });
}
