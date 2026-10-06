import 'package:drift/drift.dart' show Value, BooleanExpressionOperators;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:wudget/core/providers.dart';
import 'package:wudget/data/budgets_repository.dart';
import 'package:wudget/data/daily_totals_repository.dart';
import 'package:wudget/data/database.dart';
import 'package:wudget/data/feature_flags_repository.dart';
import 'package:wudget/data/postings_repository.dart';
import 'package:wudget/data/settings_repository.dart';
import 'package:wudget/domain/default_categories.dart';
import 'package:wudget/domain/payday.dart';
import 'package:wudget/domain/period.dart';
import 'package:wudget/features/pantau/kantong_pace_list.dart';
import 'package:wudget/features/pantau/pantau_screen.dart';
import 'package:wudget/features/shell/nav_bar.dart';
import 'package:wudget/features/wallets/wallets_screen.dart';
import 'package:wudget/main.dart';

// Run: flutter test integration_test/retention_e2e_test.dart -d <device>
// No injectable clock: every seed is relative to DateTime.now().
// Any FlutterError (overflow included) fails the test through the binding.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => initializeDateFormatting('id_ID'));

  final now = DateTime.now();
  final today = todayDayBucket();
  DateTime daysAgo(int n, [int hour = 12]) => DateTime(now.year, now.month, now.day - n, hour);
  final period = Period.containing(today, monthStartDay: defaultPeriodStartDay);
  final lastPeriod = period.previous;
  DateTime dateOf(int day) {
    final d = DateTime.utc(1970).add(Duration(days: day));
    return DateTime(d.year, d.month, d.day, 12);
  }

  var seq = 0;
  Future<void> tx(WudgetDatabase db, DateTime at, int amount,
      {String cat = 'cat_makan', String kind = 'expense', String? note}) {
    final id = 'seed${seq++}';
    final sign = kind == 'income' ? 1 : -1;
    return PostingsRepository(db).insertTransaction(
      transaction: TransactionsCompanion.insert(
        id: id, kind: kind, occurredAt: at.toUtc().millisecondsSinceEpoch,
        tzOffsetMinutes: at.timeZoneOffset.inMinutes, note: Value(note), updatedAt: 0,
      ),
      postings: [
        PostingsCompanion.insert(id: '${id}a', transactionId: id, accountId: const Value('acc_cash'),
            amountMinor: sign * amount, currency: 'IDR', baseAmountMinor: sign * amount),
        PostingsCompanion.insert(id: '${id}c', transactionId: id, categoryId: Value(cat),
            amountMinor: -sign * amount, currency: 'IDR', baseAmountMinor: -sign * amount),
      ],
    );
  }

  Future<WudgetDatabase> freshDb() async {
    final db = WudgetDatabase(NativeDatabase.memory());
    await seedDefaultsIfEmpty(db);
    addTearDown(db.close);
    return db;
  }

  Future<void> boot(WidgetTester tester, WudgetDatabase db) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const WudgetApp(),
    ));
    await tester.pumpAndSettle();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    });
  }

  Future<int> liveTxCount(WudgetDatabase db, String kind) async =>
      (await (db.select(db.transactions)..where((t) => t.kind.equals(kind) & t.deletedAt.isNull())).get())
          .length;

  Future<void> tapNav(WidgetTester tester, String label) async {
    await tester.tap(find.descendant(of: find.byType(WudgetNavBar), matching: find.text(label)));
    await tester.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  Future<void> typeAmount(WidgetTester tester, List<String> keys) async {
    for (final k in keys) {
      await tester.tap(find.byKey(Key('numpadKey_$k')));
    }
    await tester.pumpAndSettle();
  }

  testWidgets('a. cold launch opens capture, toast names the kantong, undo, save again', (tester) async {
    final db = await freshDb();
    await BudgetsRepository(db).setAmount('cat_makan', 1000000);
    await boot(tester, db);

    await showLaunchSurface(db);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('numpadKey_save')), findsOneWidget);

    await typeAmount(tester, ['2', '5', '000']);
    await tester.tap(find.text('Makan').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('captureNote')), 'Kopi');
    await tester.tap(find.byKey(const Key('numpadKey_save')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Tersimpan. Kantong Makan sisa'), findsOneWidget);
    expect(find.textContaining('Makan sisa Rp 975.000'), findsOneWidget);
    expect(await liveTxCount(db, 'expense'), 1);

    await tester.tap(find.text('Batalkan'));
    await tester.pumpAndSettle();
    expect(await liveTxCount(db, 'expense'), 0);

    await tester.tap(find.byType(CaptureButton));
    await tester.pumpAndSettle();
    await typeAmount(tester, ['2', '5', '000']);
    await tester.tap(find.text('Makan').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('numpadKey_save')));
    await tester.pumpAndSettle();
    expect(await liveTxCount(db, 'expense'), 1);
  });

  testWidgets('b. home: jatah, logged days, insight, quick chip saves pre-filled', (tester) async {
    final db = await freshDb();
    await BudgetsRepository(db).setAmount('cat_makan', 3000000);
    // Already paid this period, so the payday card stays out of the way.
    await SettingsRepository(db).confirmPayday(period.startDay, 5000000);
    for (var i = 1; i <= 20; i++) {
      await tx(db, daysAgo(i, now.hour), i <= 6 ? 18000 : 30000, note: 'Kopi');
    }
    await boot(tester, db);

    expect(find.text('Jatah hari ini'), findsOneWidget);
    expect(find.text('Sudah keluar'), findsOneWidget);
    expect(find.text('Hari tercatat periode ini'), findsOneWidget);
    expect(find.textContaining(RegExp('minggu ini|Akhir pekan|paling besar|Periode lalu')), findsOneWidget);

    final chip = find.byKey(const Key('quickChip_Kopi_cat_makan_18000'));
    expect(chip, findsOneWidget);
    await tapVisible(tester, chip);
    expect(find.textContaining('ke Makan'), findsOneWidget);
    await tester.tap(find.byKey(const Key('numpadKey_save')));
    await tester.pumpAndSettle();
    expect(await liveTxCount(db, 'expense'), 21);
  });

  testWidgets('c. income through the Pemasukan switch, Simpan saja', (tester) async {
    final db = await freshDb();
    await boot(tester, db);

    await tester.tap(find.byType(CaptureButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pemasukan'));
    await tester.pumpAndSettle();
    await typeAmount(tester, ['5', '000', '000']);
    await tester.tap(find.text('Gaji').last);
    await tester.pumpAndSettle();
    expect(find.text('Simpan saja'), findsOneWidget);
    await tester.tap(find.text('Simpan saja'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Tersimpan: Rp'), findsOneWidget);
    expect(await liveTxCount(db, 'income'), 1);
  });

  testWidgets('d. first run: explainer, Atur anggaran sekarang, review, home shows a jatah', (tester) async {
    final db = await freshDb();
    await boot(tester, db);

    expect(find.text('Jatah muncul setelah kamu isi gaji atau anggaran per kategori.'), findsOneWidget);
    await tester.tap(find.text('Atur anggaran sekarang'));
    await tester.pumpAndSettle();

    final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip)).toList();
    expect(chips, hasLength(2));
    expect(chips.where((c) => c.selected), hasLength(1));

    for (final k in ['3', '000', '000']) {
      await tester.tap(find.byKey(Key('amountKey_$k')));
    }
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lanjut bagi ke kantong'));
    await tester.pumpAndSettle();

    expect(find.text('Pakai anggaran ini'), findsOneWidget);
    await tapVisible(tester, find.text('Pakai anggaran ini'));

    expect(find.text('Jatah muncul setelah kamu isi gaji atau anggaran per kategori.'), findsNothing);
    expect(find.text('Sudah keluar'), findsOneWidget);
    expect((await BudgetsRepository(db).getAll()).values.fold<int>(0, (a, b) => a + b), 3000000);
  });

  testWidgets('e. payday: Sudah masuk, review totals salary plus leftover, Tabungan holds it', (tester) async {
    final db = await freshDb();
    final settings = SettingsRepository(db);
    await settings.confirmPayday(lastPeriod.startDay, 7500000);
    await settings.setLastAcknowledgedPeriodClose(lastPeriod.startDay);
    await BudgetsRepository(db).setAmount('cat_makan', 2000000);
    await tx(db, dateOf(lastPeriod.startDay), 5000000, cat: 'cat_gaji', kind: 'income');
    await tx(db, dateOf(lastPeriod.startDay + 3), 4000000);
    await tx(db, daysAgo(0), 20000);
    await boot(tester, db);

    expect(find.textContaining('7.500.000 sudah masuk?'), findsOneWidget);
    await tester.tap(find.text('Sudah masuk'));
    await tester.pumpAndSettle();

    expect(find.textContaining('8.500.000'), findsWidgets);
    expect(find.textContaining(RegExp(r'^Gaji Rp.7\.500\.000 dan sisa periode lalu Rp.1\.000\.000$')),
        findsOneWidget);
    expect(find.textContaining(RegExp(r'^termasuk sisa Rp.1\.000\.000$')), findsOneWidget);

    await tapVisible(tester, find.text('Pakai anggaran ini'));
    final saved = await BudgetsRepository(db).getAll();
    expect(saved.values.fold<int>(0, (a, b) => a + b), 8500000);
    expect(saved[tabunganCategoryId], greaterThanOrEqualTo(1000000));
    expect(find.text('Sudah masuk'), findsNothing);
  });

  testWidgets('g. Pantau: pace sentence, sorted kantong, Pola and Aliran', (tester) async {
    final db = await freshDb();
    await SettingsRepository(db).setLastAcknowledgedPeriodClose(lastPeriod.startDay);
    await BudgetsRepository(db).setAmount('cat_transport', 1000000);
    await BudgetsRepository(db).setAmount('cat_makan', 500000);
    await tx(db, dateOf(lastPeriod.startDay + 2), 600000);
    await tx(db, daysAgo(0), 450000);
    await tx(db, daysAgo(0), 50000, cat: 'cat_transport');
    await boot(tester, db);

    await tapNav(tester, 'Pantau');
    expect(find.textContaining('Makan sudah'), findsOneWidget);
    final list = find.byType(KantongPaceList);
    expect(list, findsOneWidget);
    final makanY = tester.getTopLeft(find.descendant(of: list, matching: find.text('Makan'))).dy;
    final transportY = tester.getTopLeft(find.descendant(of: list, matching: find.text('Transport'))).dy;
    expect(makanY, lessThan(transportY));

    await tester.scrollUntilVisible(find.text('Lihat pola dan aliran'), 300,
        scrollable: find.descendant(of: find.byType(PantauScreen), matching: find.byType(Scrollable)).first);
    await tapVisible(tester, find.text('Lihat pola dan aliran'));
    expect(find.text('Pola'), findsWidgets);
    await tester.tap(find.text('Aliran').first);
    await tester.pumpAndSettle();
    expect(find.text('Pola dan aliran belum bisa dimuat. Coba buka lagi.'), findsNothing);
  });

  testWidgets('h. comeback after a gap, backfill one day', (tester) async {
    final db = await freshDb();
    await tx(db, daysAgo(10), 10000);
    await tx(db, daysAgo(4), 10000);
    await boot(tester, db);

    await showLaunchSurface(db);
    await tester.pumpAndSettle();
    expect(find.text('Lanjut lagi'), findsOneWidget);

    await tester.tap(find.text('Isi 3 hari yang lewat'));
    await tester.pumpAndSettle();
    expect(find.text('Hari 1 dari 3'), findsOneWidget);
    await tester.tap(find.byType(FilledButton).first);
    await tester.pumpAndSettle();
    await typeAmount(tester, ['5', '000']);
    await tester.ensureVisible(find.text('Makan').last);
    await tester.tap(find.text('Makan').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('numpadKey_save')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();

    expect(await DailyTotalsRepository(db).entryDays(today - 3, today - 2), {today - 3});
  });

  testWidgets('i. Saya: reminder switches persist, Dompet opens wallets', (tester) async {
    final db = await freshDb();
    await boot(tester, db);

    await tapNav(tester, 'Saya');
    final switches = find.byType(Switch);
    expect(switches, findsNWidgets(3));
    await tapVisible(tester, switches.first);
    expect(await FeatureFlagsRepository(db).getBool(eveningReminderKey, defaultValue: true), isFalse);

    await boot(tester, db);
    await tapNav(tester, 'Saya');
    expect(tester.widget<Switch>(find.byType(Switch).first).value, isFalse);

    await tapVisible(tester, find.text('Dompet'));
    expect(find.byType(WalletsScreen), findsOneWidget);
  });

  testWidgets('j. dark mode: home and Pantau render clean', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    final db = await freshDb();
    await SettingsRepository(db).setLastAcknowledgedPeriodClose(lastPeriod.startDay);
    await BudgetsRepository(db).setAmount('cat_makan', 1500000);
    for (var i = 0; i < 20; i++) {
      await tx(db, daysAgo(i), 25000 + i * 1000, note: 'Makan siang');
    }
    await boot(tester, db);

    expect(Theme.of(tester.element(find.text('Jatah hari ini'))).brightness, Brightness.dark);
    await tapNav(tester, 'Pantau');
    expect(find.byType(KantongPaceList), findsOneWidget);
  });

  // Last on purpose: the real share sheet covers the app and nothing here can dismiss it.
  testWidgets('f. period close recap with the plan snapshot, Bagikan', (tester) async {
    final db = await freshDb();
    await BudgetsRepository(db).setAmount('cat_makan', 1000000);
    await tx(db, dateOf(lastPeriod.previous.startDay + 2), 5000);
    await tx(db, dateOf(lastPeriod.startDay + 2), 600000);
    await tx(db, daysAgo(0), 10000);
    await boot(tester, db);

    await tapNav(tester, 'Pantau');
    expect(find.text('TUTUP PERIODE'), findsOneWidget);
    expect(find.text('Terpakai'), findsOneWidget);
    expect(find.textContaining('400.000'), findsWidgets);

    await tester.ensureVisible(find.text('Bagikan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bagikan'));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Gambar belum bisa dibagikan. Coba lagi.'), findsNothing);
  });
}
