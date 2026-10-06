import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:wudget/core/providers.dart';
import 'package:wudget/data/budgets_repository.dart';
import 'package:wudget/data/database.dart';
import 'package:wudget/data/postings_repository.dart';
import 'package:wudget/design/tokens.dart';
import 'package:wudget/domain/default_categories.dart';
import 'package:wudget/domain/insight.dart';
import 'package:wudget/domain/pola.dart';
import 'package:wudget/features/ledger/ledger_screen.dart';
import 'package:wudget/features/ledger/today_header.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  Widget themed(Widget child, {Brightness brightness = Brightness.light}) => MaterialApp(
        theme: buildWudgetTheme(
            brightness == Brightness.dark ? WudgetTokens.dark : WudgetTokens.light, brightness),
        home: Scaffold(body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: child)),
      );

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  }

  Future<void> pumpLedger(WidgetTester tester, WudgetDatabase db, VoidCallback onOpenKantong) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        theme: buildWudgetTheme(WudgetTokens.light, Brightness.light),
        home: Scaffold(body: LedgerScreen(onOpenKantong: onOpenKantong)),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('first run, no entries and no budget: jatah explains itself, one task', (tester) async {
    final db = WudgetDatabase(NativeDatabase.memory());
    await seedDefaultsIfEmpty(db);
    addTearDown(db.close);
    var opened = 0;

    await pumpLedger(tester, db, () => opened++);

    expect(find.text('Jatah hari ini'), findsOneWidget);
    expect(find.text('Jatah muncul setelah kamu isi gaji atau anggaran per kategori.'), findsOneWidget);
    expect(find.text('Catat satu pengeluaran hari ini'), findsOneWidget);
    expect(find.text('Catat pengeluaran'), findsOneWidget);
    expect(find.text('Hari tercatat periode ini'), findsNothing);

    await tester.tap(find.text('Atur anggaran sekarang'));
    expect(opened, 1);
    await unmount(tester);
  });

  testWidgets('with a budget, the period remainder is a link that opens Kantong', (tester) async {
    final db = WudgetDatabase(NativeDatabase.memory());
    await seedDefaultsIfEmpty(db);
    addTearDown(db.close);
    await BudgetsRepository(db).setAmount('cat_makan', 3000000);
    final now = DateTime.now();
    await PostingsRepository(db).insertTransaction(
      transaction: TransactionsCompanion.insert(
        id: 'tx1',
        kind: 'expense',
        occurredAt: now.toUtc().millisecondsSinceEpoch,
        tzOffsetMinutes: now.timeZoneOffset.inMinutes,
        updatedAt: 0,
      ),
      postings: [
        PostingsCompanion.insert(id: 'p1a', transactionId: 'tx1', accountId: const Value('acc_cash'),
            amountMinor: -15000, currency: 'IDR', baseAmountMinor: -15000),
        PostingsCompanion.insert(id: 'p1c', transactionId: 'tx1', categoryId: const Value('cat_makan'),
            amountMinor: 15000, currency: 'IDR', baseAmountMinor: 15000),
      ],
    );
    var opened = 0;

    await pumpLedger(tester, db, () => opened++);

    expect(find.text('Sudah keluar'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^1 dari \d+ hari tercatat$')), findsOneWidget);
    await tester.tap(find.textContaining('Sisa periode Rp\u00a02.985.000 untuk'));
    expect(opened, 1);
    await unmount(tester);
  });

  testWidgets('each block fails and loads on its own without blanking home', (tester) async {
    const strip = LoggedStripData(startDay: 100, endDayExclusive: 118, todayDay: 112, entryDays: {100, 101});
    await tester.pumpWidget(themed(TodayHeader(
      todayDay: 112,
      jatah: AsyncError(Exception('db'), StackTrace.empty),
      strip: const AsyncData(strip),
      insight: const AsyncData(null),
      onRetry: () {},
    )));
    expect(find.text('Jatah hari ini belum bisa dihitung.'), findsOneWidget);
    expect(find.text('Muat ulang'), findsOneWidget);
    expect(find.text('Hari tercatat periode ini'), findsOneWidget);

    await tester.pumpWidget(themed(TodayHeader(
      todayDay: 112,
      jatah: AsyncData(TodayHeaderData(
        todayDay: 112,
        todaySpendMinor: 63000,
        allowance: computeDailyAllowance(budgetTotalMinor: 4500000, spentMinor: 2106000, daysRemaining: 18),
      )),
      strip: AsyncError(Exception('db'), StackTrace.empty),
      insight: const AsyncData(Insight(key: 'k', text: 'Satu hal baru.')),
    )));
    expect(find.text('Rp\u00a0133.000'), findsOneWidget);
    expect(find.text('Sisa periode Rp\u00a02.394.000 untuk 18 hari'), findsOneWidget);
    expect(find.text('Hari tercatat belum bisa dimuat.'), findsOneWidget);
    expect(find.text('Satu hal baru.'), findsOneWidget);

    await tester.pumpWidget(themed(const TodayHeader(
      todayDay: 112,
      jatah: AsyncLoading(),
      strip: AsyncLoading(),
      insight: AsyncData(null),
    )));
    expect(find.bySemanticsLabel('Menghitung jatah hari ini'), findsOneWidget);
    expect(find.bySemanticsLabel('Memuat hari tercatat'), findsOneWidget);
    await unmount(tester);
  });

  // 13 days so far with two missed, as on screen 1 of design/Retention.html.
  const mockupStrip = LoggedStripData(
    startDay: 100,
    endDayExclusive: 118,
    todayDay: 112,
    entryDays: {100, 101, 102, 103, 105, 106, 107, 109, 110, 111, 112},
  );

  for (final brightness in Brightness.values) {
    testWidgets('logged-days strip, ${brightness.name}', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(themed(const LoggedDaysStrip(data: mockupStrip), brightness: brightness));
      expect(find.bySemanticsLabel('11 dari 13 hari tercatat'), findsOneWidget);
      await expectLater(
        find.byType(LoggedDaysStrip),
        matchesGoldenFile('../golden/logged_days_strip_${brightness.name}.png'),
      );
    });
  }
}
