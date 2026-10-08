import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wudget/core/providers.dart';
import 'package:wudget/data/analytics_repository.dart';
import 'package:wudget/data/database.dart';
import 'package:wudget/design/tokens.dart';
import 'package:wudget/features/settings/household_screen.dart';

void main() {
  testWidgets('a valid email logs household_interest locally; a bad one is refused', (tester) async {
    final db = WudgetDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        theme: buildWudgetTheme(WudgetTokens.light, Brightness.light),
        home: const HouseholdScreen(),
      ),
    ));

    await tester.enterText(find.byKey(const Key('householdEmail')), 'bukan-email');
    await tester.tap(find.text('Saya tertarik'));
    await tester.pumpAndSettle();
    expect(find.text('Alamat email belum lengkap.'), findsOneWidget);
    expect(await AnalyticsRepository(db).all(), isEmpty);

    await tester.enterText(find.byKey(const Key('householdEmail')), 'sari@contoh.id');
    await tester.tap(find.text('Saya tertarik'));
    await tester.pumpAndSettle();
    final events = await AnalyticsRepository(db).all();
    expect(events.single.name, 'household_interest');
    expect(events.single.propsJson, contains('sari@contoh.id'));
    expect(find.textContaining('Tercatat'), findsOneWidget);
  });
}
