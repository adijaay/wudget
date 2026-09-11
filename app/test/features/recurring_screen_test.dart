import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:wudget/core/providers.dart';
import 'package:wudget/data/database.dart';
import 'package:wudget/data/recurrence_repository.dart';
import 'package:wudget/design/tokens.dart';
import 'package:wudget/domain/default_categories.dart';
import 'package:wudget/domain/recurrence.dart';
import 'package:wudget/features/recurring/recurring_screen.dart';

int _day(int year, int month, int day) =>
    DateTime.utc(year, month, day).difference(DateTime.utc(1970, 1, 1)).inDays;

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  testWidgets('lists an upcoming instance, and skip removes it', (tester) async {
    final db = WudgetDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await seedDefaultsIfEmpty(db);

    final recurrences = RecurrenceRepository(db);
    await recurrences.create(
      template: const RecurrenceTemplate(
        kind: 'expense', accountId: 'acc_cash', categoryId: 'cat_tagihan', currency: 'IDR',
        fixedAmountMinor: 150000, note: 'Listrik',
      ),
      rule: RecurrenceRule(freq: RecurrenceFreq.monthly, byMonthDay: 1, startsOn: _day(2026, 3, 1)),
    );
    await recurrences.materializeAll(toDayInclusive: _day(2026, 3, 1));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: buildWudgetTheme(WudgetTokens.light, Brightness.light),
          home: const RecurringScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Appears twice: once as the upcoming (materialised) instance, once as
    // the active rule that produced it — the two sections answer different
    // questions ("what's due" vs. "what rule exists").
    expect(find.text('Listrik'), findsNWidgets(2));

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    // Only the active-rule listing remains; the upcoming instance is gone.
    expect(find.text('Listrik'), findsOneWidget);
    expect(find.text('Tidak ada yang akan datang.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets('confirm opens the capture sheet prefilled from the instance', (tester) async {
    final db = WudgetDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await seedDefaultsIfEmpty(db);

    final recurrences = RecurrenceRepository(db);
    await recurrences.create(
      template: const RecurrenceTemplate(
        kind: 'expense', accountId: 'acc_cash', categoryId: 'cat_tagihan', currency: 'IDR', fixedAmountMinor: 150000,
      ),
      rule: RecurrenceRule(freq: RecurrenceFreq.monthly, byMonthDay: 1, startsOn: _day(2026, 3, 1)),
    );
    await recurrences.materializeAll(toDayInclusive: _day(2026, 3, 1));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: buildWudgetTheme(WudgetTokens.light, Brightness.light),
          home: const RecurringScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    expect(find.textContaining('150.000'), findsWidgets); // the amount, prefilled

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets('lists an active rule with its next due date', (tester) async {
    final db = WudgetDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await seedDefaultsIfEmpty(db);

    await RecurrenceRepository(db).create(
      template: const RecurrenceTemplate(
        kind: 'expense', accountId: 'acc_cash', categoryId: 'cat_tagihan', currency: 'IDR',
        fixedAmountMinor: 150000, note: 'Listrik',
      ),
      rule: RecurrenceRule(freq: RecurrenceFreq.monthly, byMonthDay: 1, startsOn: _day(2026, 3, 1)),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: buildWudgetTheme(WudgetTokens.light, Brightness.light),
          home: const RecurringScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Listrik'), findsOneWidget);
    expect(find.textContaining('Berikutnya:'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });
}
