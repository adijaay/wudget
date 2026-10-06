import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:wudget/core/providers.dart';
import 'package:wudget/data/budgets_repository.dart';
import 'package:wudget/data/database.dart';
import 'package:wudget/data/period_aggregate_queries.dart';
import 'package:wudget/data/postings_repository.dart';
import 'package:wudget/data/settings_repository.dart';
import 'package:wudget/design/tokens.dart';
import 'package:wudget/domain/default_categories.dart';
import 'package:wudget/domain/payday.dart';
import 'package:wudget/domain/period.dart';
import 'package:wudget/features/payday/budget_review_screen.dart';
import 'package:wudget/features/payday/payday_card.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  Future<void> pump(WidgetTester tester, WudgetDatabase db, Widget home) async {
    await tester.binding.setSurfaceSize(const Size(390, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: MaterialApp(theme: buildWudgetTheme(WudgetTokens.light, Brightness.light), home: home),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('review: the mockup numbers, every rupiah placed, one tap saves', (tester) async {
    final db = WudgetDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await seedDefaultsIfEmpty(db);
    final budgets = BudgetsRepository(db);
    for (final e in {
      'cat_makan': 2400000,
      'cat_tagihan': 1650000,
      'cat_transport': 900000,
      'cat_belanja': 800000,
      'cat_hiburan': 450000,
      'cat_kesehatan': 300000,
      tabunganCategoryId: 1000000,
    }.entries) {
      await budgets.setAmount(e.key, e.value);
    }
    final period = Period.containing(todayDayBucket(), monthStartDay: 25);

    await pump(tester, db, BudgetReviewScreen(period: period, newMoneyMinor: 7500000, leftoverMinor: 420000));

    expect(find.textContaining('7.920.000'), findsOneWidget);
    expect(find.textContaining(RegExp(r'^Gaji Rp.7\.500\.000 dan sisa periode lalu Rp.420\.000$')), findsOneWidget);
    expect(find.text('Sama seperti periode lalu. Ketuk untuk ubah.'), findsOneWidget);
    expect(find.text('1.420.000'), findsOneWidget);
    expect(find.textContaining(RegExp(r'^termasuk sisa Rp.420\.000$')), findsOneWidget);

    await tester.tap(find.text('Pakai anggaran ini'));
    await tester.pumpAndSettle();

    final saved = await budgets.getAll();
    expect(saved[tabunganCategoryId], 1420000);
    expect(saved.values.fold<int>(0, (a, b) => a + b), 7920000);
    final tabungan = await (db.select(db.categories)..where((c) => c.id.equals(tabunganCategoryId))).getSingle();
    expect(tabungan.name, 'Tabungan');
    expect(await SettingsRepository(db).getRow(), isNull); // payday: no custom period stored
  });

  testWidgets('review: a tapped row edits, Tabungan takes the difference', (tester) async {
    final db = WudgetDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await seedDefaultsIfEmpty(db);
    await BudgetsRepository(db).setAmount('cat_makan', 1000000);
    final period = Period.containing(todayDayBucket(), monthStartDay: 25);

    await pump(tester, db, BudgetReviewScreen(period: period, newMoneyMinor: 3000000, leftoverMinor: 0, customPeriod: true));
    expect(find.text('2.000.000'), findsOneWidget);

    await tester.tap(find.text('Makan'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('amountKey_⌫')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pakai jumlah ini'));
    await tester.pumpAndSettle();
    expect(find.text('2.900.000'), findsOneWidget);

    await tester.tap(find.text('Pakai anggaran ini'));
    await tester.pumpAndSettle();
    final row = await SettingsRepository(db).getRow();
    expect(row!.customPeriodStart, period.startDay);
    expect((await BudgetsRepository(db).getAll())[tabunganCategoryId], 2900000);
  });

  testWidgets('Atur sekarang sheet: chips show both ends, one pre-selected', (tester) async {
    final today = DateTime.utc(2026, 10, 15).difference(DateTime.utc(1970)).inDays;
    final db = WudgetDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await pump(
      tester,
      db,
      Scaffold(
        body: AmountSheet(
          title: 'Atur anggaran sekarang',
          subtitle: 's',
          buttonLabel: 'Lanjut bagi ke kantong',
          endChoices: setNowEndChoices(today, monthStartDay: 25),
        ),
      ),
    );
    expect(find.text('Hari ini sampai 24 Okt'), findsOneWidget);
    final later = tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Sampai 24 Nov'));
    expect(later.selected, isTrue);
  });

  test('set now 3.000.000 on 7 Oct, spend 2.580.000, payday 25 Oct with 7.500.000: 7.920.000', () async {
    final db = WudgetDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await seedDefaultsIfEmpty(db);
    int day(int m, int d) => DateTime.utc(2026, m, d).difference(DateTime.utc(1970)).inDays;
    final settings = SettingsRepository(db);
    await settings.setPeriodStartDay(25);
    await settings.setCustomPeriod(day(10, 7), day(10, 25), 3000000);
    final at = DateTime.utc(2026, 10, 10, 5).millisecondsSinceEpoch;
    await PostingsRepository(db).insertTransaction(
      transaction: TransactionsCompanion.insert(id: 't', kind: 'expense', occurredAt: at, tzOffsetMinutes: 0, updatedAt: 0),
      postings: [
        PostingsCompanion.insert(id: 'a', transactionId: 't', accountId: const Value('acc_cash'),
            amountMinor: -2580000, currency: 'IDR', baseAmountMinor: -2580000),
        PostingsCompanion.insert(id: 'c', transactionId: 't', categoryId: const Value('cat_makan'),
            amountMinor: 2580000, currency: 'IDR', baseAmountMinor: 2580000),
      ],
    );
    final payday = await settings.effectivePeriodFor(day(10, 25));
    expect(payday.startDay, day(10, 25));
    final leftover = await lastPeriodLeftoverFor(settings, PeriodAggregateQueries(db), payday);
    expect(leftover, 420000);
    expect(7500000 + leftover, 7920000);
  });
}
