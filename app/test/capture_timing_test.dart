import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:wudget/core/providers.dart';
import 'package:wudget/data/analytics_repository.dart';
import 'package:wudget/data/database.dart';
import 'package:wudget/design/tokens.dart';
import 'package:wudget/domain/default_categories.dart';
import 'package:wudget/features/capture/capture_sheet.dart';
import 'package:wudget/features/settings/capture_debug_screen.dart';

Widget _app(WudgetDatabase db, Widget home) => ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: MaterialApp(theme: buildWudgetTheme(WudgetTokens.light, Brightness.light), home: home),
    );

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  testWidgets('opening and saving logs capture_open and capture_save with source and ms', (tester) async {
    final db = WudgetDatabase(NativeDatabase.memory());
    await seedDefaultsIfEmpty(db);
    addTearDown(db.close);

    await tester.pumpWidget(_app(
      db,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => const CaptureSheet(source: CaptureSource.widget),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('numpadKey_5')));
    await tester.tap(find.byKey(const Key('numpadKey_000')));
    await tester.tap(find.text('Makan'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('numpadKey_save')));
    await tester.pumpAndSettle();

    final events = await AnalyticsRepository(db).all();
    expect(events.map((e) => e.name), ['capture_open', 'capture_save']);
    final save = jsonDecode(events.last.propsJson!) as Map;
    expect(save['source'], 'widget');
    expect(save['ms'], isA<int>());

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });

  test('median of the last 20 saves only', () async {
    final db = WudgetDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = AnalyticsRepository(db);
    for (var i = 0; i < 25; i++) {
      // Distinct timestamps so "last 20" is well defined.
      await db.into(db.analyticsEvents).insert(AnalyticsEventsCompanion.insert(
            id: '$i',
            name: 'capture_save',
            propsJson: Value(jsonEncode({'source': 'nav', 'ms': i < 5 ? 99999 : 1000 + i})),
            occurredAt: i,
          ));
    }
    final ms = await repo.recentCaptureSaveMs();
    expect(ms, hasLength(20));
    expect(medianMs(ms), (1014 + 1015) ~/ 2);
    expect(medianMs(const []), isNull);
  });

  testWidgets('debug screen shows the median and logged days', (tester) async {
    final db = WudgetDatabase(NativeDatabase.memory());
    await seedDefaultsIfEmpty(db);
    addTearDown(db.close);
    await AnalyticsRepository(db).logEvent('capture_save', props: {'source': 'nav', 'ms': 2400});

    await tester.pumpWidget(_app(db, const CaptureDebugScreen()));
    await tester.pumpAndSettle();

    expect(find.textContaining('2400 ms, dari 1 simpanan terakhir'), findsOneWidget);
    expect(find.textContaining('0 dari'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });
}
