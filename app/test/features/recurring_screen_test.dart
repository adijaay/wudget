import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' show Value;
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
    expect(find.text('Tidak ada tagihan yang menunggu dikonfirmasi.'), findsOneWidget);

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
    expect(find.textContaining('Berikutnya '), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets('the empty state names what a recurring item is, with an action to add one',
      (tester) async {
    final db = WudgetDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await seedDefaultsIfEmpty(db);

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

    expect(find.textContaining('Item berulang adalah'), findsOneWidget);
    expect(find.text('Tambah item berulang'), findsWidgets); // the empty-state button and the app bar action

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets('creating a recurring item from the sheet adds it to the active list', (tester) async {
    final db = WudgetDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await seedDefaultsIfEmpty(db);

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

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Nama (mis. Listrik)'), 'Internet');
    await tester.enterText(find.widgetWithText(TextField, 'Jumlah (Rp)'), '300000');
    await tester.enterText(find.widgetWithText(TextField, 'Tanggal tiap bulan (1-31)'), '10');

    await tester.tap(find.widgetWithText(DropdownButtonFormField<String?>, 'Kategori'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tagihan').last);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(DropdownButtonFormField<String?>, 'Dompet'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tunai').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(find.text('Internet'), findsOneWidget);

    final recurrences = await db.select(db.recurrences).get();
    expect(recurrences, hasLength(1));
    expect(recurrences.single.byMonthDay, 10);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets('a rule with a recorded generation error shows the reason on its row', (tester) async {
    final db = WudgetDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await seedDefaultsIfEmpty(db);

    final id = await RecurrenceRepository(db).create(
      template: const RecurrenceTemplate(
        kind: 'expense', accountId: 'acc_cash', categoryId: 'cat_tagihan', currency: 'IDR',
        fixedAmountMinor: 150000, note: 'Air',
      ),
      rule: RecurrenceRule(freq: RecurrenceFreq.monthly, byMonthDay: 1, startsOn: _day(2026, 3, 1)),
    );
    await (db.update(db.recurrences)..where((r) => r.id.equals(id)))
        .write(const RecurrencesCompanion(lastGenerationError: Value('contoh kesalahan')));

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

    expect(find.textContaining('Gagal membuat: contoh kesalahan'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });
}
