import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:wudget/core/providers.dart';
import 'package:wudget/data/budgets_repository.dart';
import 'package:wudget/data/database.dart';
import 'package:wudget/data/postings_repository.dart';
import 'package:wudget/data/settings_repository.dart';
import 'package:wudget/data/wallets_repository.dart';
import 'package:wudget/design/tokens.dart';
import 'package:wudget/domain/default_categories.dart';
import 'package:wudget/domain/period.dart';
import 'package:wudget/features/budget/budget_screen.dart';
import 'package:wudget/features/payday/budget_review_screen.dart';
import 'package:wudget/features/payday/payday_card.dart';
import 'package:wudget/features/import/import_screen.dart';
import 'package:wudget/features/onboarding/onboarding_screen.dart';
import 'package:wudget/features/recurring/recurring_screen.dart';
import 'package:wudget/features/settings/backup_screen.dart';
import 'package:wudget/features/capture/capture_sheet.dart';
import 'package:wudget/features/ledger/ledger_screen.dart';
import 'package:wudget/domain/period_close.dart';
import 'package:wudget/features/pantau/pantau_screen.dart';
import 'package:wudget/features/pantau/recap_card.dart';
import 'package:wudget/features/settings/saya_screen.dart';
import 'package:wudget/features/wallets/wallets_screen.dart';

import 'accessibility/retention_surfaces.dart';

/// Not a test: a design-review harness. Renders each screen at phone size
/// with the bundled typeface actually loaded and realistic seeded data, and
/// writes the images to `test/design_review/`, so the rebuilt UI can be
/// looked at without a device attached.
///
/// Deliberately named without the `_test` suffix so `flutter test` skips it.
/// Run it on purpose:
///   flutter test --update-goldens test/design_review.dart
///
/// The golden tests in test/golden/ are the regression guard; this is for
/// looking, which the goldens cannot be (they render text as boxes, because
/// the default test font has no glyphs).
void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      final loader = FontLoader(WudgetTokens.fontFamily)
        ..addFont(
          File('assets/fonts/PlusJakartaSans-$weight.ttf')
              .readAsBytes()
              .then((bytes) => ByteData.view(Uint8List.fromList(bytes).buffer)),
        );
      await loader.load();
    }
    // Without this every Icon in the gallery draws as a hollow box, which is
    // what made an earlier review miss a wrong glyph. The file ships with the
    // Flutter SDK; skipped rather than failed if the path moves.
    final icons = File('${Platform.environment['FLUTTER_ROOT'] ?? p.dirname(p.dirname(Platform.resolvedExecutable))}'
        '/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
    if (icons.existsSync()) {
      final loader = FontLoader('MaterialIcons')
        ..addFont(icons.readAsBytes().then((b) => ByteData.view(Uint8List.fromList(b).buffer)));
      await loader.load();
    }
  });

  /// A month of plausible history: three wallets including a credit card,
  /// spread across categories, so every surface has something real to draw.
  Future<WudgetDatabase> seeded() async {
    final db = WudgetDatabase(NativeDatabase.memory());
    await seedDefaultsIfEmpty(db);
    final wallets = WalletsRepository(db);
    await wallets.create(
      id: 'acc_gopay', name: 'GoPay', type: 'ewallet', currency: 'IDR', openingMinor: 185000,
    );
    await wallets.create(
      id: 'acc_bca', name: 'BCA', type: 'bank', currency: 'IDR', openingMinor: 4210000,
    );
    await wallets.create(
      id: 'acc_darurat', name: 'Dana darurat', type: 'savings', currency: 'IDR',
      openingMinor: 11800000,
    );
    await wallets.create(
      id: 'acc_kartu', name: 'Kartu kredit BCA', type: 'card', currency: 'IDR',
      statementDay: 25, dueDay: 18, creditLimitMinor: 10000000,
    );
    await (db.update(db.accounts)..where((a) => a.id.equals('acc_cash')))
        .write(const AccountsCompanion(openingMinor: Value(320000)));

    final postings = PostingsRepository(db);
    final now = DateTime.now();
    var n = 0;

    Future<void> tx({
      required String category,
      required String account,
      required int amountMinor,
      required DateTime at,
      String? note,
      String kind = 'expense',
    }) async {
      final id = 'tx${n++}';
      final sign = kind == 'expense' ? -1 : 1;
      await postings.insertTransaction(
        transaction: TransactionsCompanion.insert(
          id: id,
          kind: kind,
          occurredAt: at.toUtc().millisecondsSinceEpoch,
          tzOffsetMinutes: at.timeZoneOffset.inMinutes,
          note: note == null ? const Value.absent() : Value(note),
          updatedAt: 0,
        ),
        postings: [
          PostingsCompanion.insert(
            id: '${id}a', transactionId: id, accountId: Value(account),
            amountMinor: sign * amountMinor, currency: 'IDR', baseAmountMinor: sign * amountMinor,
          ),
          PostingsCompanion.insert(
            id: '${id}c', transactionId: id, categoryId: Value(category),
            amountMinor: -sign * amountMinor, currency: 'IDR', baseAmountMinor: -sign * amountMinor,
          ),
        ],
      );
    }

    // Salary at the start of the period, then a month of spending, including
    // a couple of days' worth of entries for today so Catat has a full day.
    await tx(category: 'cat_gaji', account: 'acc_bca', amountMinor: 8500000, kind: 'income',
        at: DateTime(now.year, now.month, 1, 9), note: 'Gaji');
    await tx(category: 'cat_makan_siang', account: 'acc_gopay', amountMinor: 15000, at: now.copyWith(hour: 12, minute: 24));
    await tx(category: 'cat_transport', account: 'acc_gopay', amountMinor: 23000, at: now.copyWith(hour: 8, minute: 10));
    await tx(category: 'cat_makan', account: 'acc_cash', amountMinor: 25000, at: now.copyWith(hour: 16, minute: 40), note: 'Ngopi');
    await tx(category: 'cat_belanja', account: 'acc_bca', amountMinor: 120000, at: now.subtract(const Duration(days: 1)), note: 'Belanja bulanan');
    await tx(category: 'cat_tagihan', account: 'acc_gopay', amountMinor: 28000, at: now.subtract(const Duration(days: 1)), note: 'Pulsa & data');
    await tx(category: 'cat_kartu_x', account: 'acc_kartu', amountMinor: 0, at: now); // placeholder replaced below
    await (db.delete(db.transactions)..where((t) => t.id.equals('tx6'))).go();

    for (var day = 2; day < 26; day++) {
      final at = DateTime(now.year, now.month, day, 13);
      if (at.isAfter(now)) break;
      await tx(category: 'cat_makan', account: 'acc_gopay', amountMinor: 32000 + (day % 5) * 7000, at: at);
      if (day % 3 == 0) {
        await tx(category: 'cat_transport', account: 'acc_gopay', amountMinor: 18000, at: at);
      }
      if (day % 7 == 0) {
        await tx(category: 'cat_hiburan', account: 'acc_kartu', amountMinor: 95000, at: at, note: 'Bioskop');
      }
      if (day % 11 == 0) {
        await tx(category: 'cat_kesehatan', account: 'acc_bca', amountMinor: 150000, at: at, note: 'Obat');
      }
    }
    // Two prior months, so the previous period counts as a full period of
    // real history and Pantau actually has a baseline to compare against.
    for (final monthsBack in [1, 2]) {
      for (var day = 1; day <= 28; day++) {
        await tx(
          category: 'cat_makan',
          account: 'acc_gopay',
          amountMinor: 40000 + (day % 4) * 9000,
          at: DateTime(now.year, now.month - monthsBack, day, 13),
        );
      }
    }

    // The close ritual fires on entering Pantau at a period boundary, which
    // would sit over every Pantau shot. Acknowledge it here so the review
    // images show the screen; the sheet gets a shot of its own below.
    await SettingsRepository(db).setLastAcknowledgedPeriodClose(
      DateTime(now.year, now.month, 1).difference(DateTime(1970, 1, 1)).inDays,
    );

    final budgets = BudgetsRepository(db);
    await budgets.setAmount('cat_makan', 1560000);
    await budgets.setAmount('cat_transport', 920000);
    await budgets.setAmount('cat_belanja', 780000);
    await budgets.setAmount('irregular', 400000);
    return db;
  }

  Future<void> shoot(
    WidgetTester tester,
    String name,
    Widget home, {
    Brightness brightness = Brightness.light,
    WudgetDatabase? db,
    List<Override> overrides = const [],
    Future<void> Function(WidgetTester)? drive,
  }) async {
    final database = db ?? await seeded();
    addTearDown(database.close);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database), ...overrides],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildWudgetTheme(WudgetTokens.light, Brightness.light),
          darkTheme: buildWudgetTheme(WudgetTokens.dark, Brightness.dark),
          themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
          home: home,
        ),
      ),
    );
    await tester.pumpAndSettle();
    if (drive != null) {
      await drive(tester);
      await tester.pumpAndSettle();
    }
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('design_review/$name.png'));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('kantong', (t) => shoot(t, 'kantong', const WalletsScreen()));
  testWidgets('kantong dark',
      (t) => shoot(t, 'kantong_dark', const WalletsScreen(), brightness: Brightness.dark));
  testWidgets('catat', (t) => shoot(t, 'catat', const LedgerScreen()));
  testWidgets('catat dark',
      (t) => shoot(t, 'catat_dark', const LedgerScreen(), brightness: Brightness.dark));
  testWidgets('pantau', (t) => shoot(t, 'pantau', const PantauScreen()));
  testWidgets('pantau dark',
      (t) => shoot(t, 'pantau_dark', const PantauScreen(), brightness: Brightness.dark));
  testWidgets('anggaran', (t) => shoot(t, 'anggaran', const BudgetScreen()));
  testWidgets('saya', (t) => shoot(t, 'saya', const SayaScreen()));
  testWidgets('capture', (t) => shoot(t, 'capture', const Scaffold(body: CaptureSheet())));
  testWidgets('capture dark',
      (t) => shoot(t, 'capture_dark', const Scaffold(body: CaptureSheet()), brightness: Brightness.dark));

  // R3: screens 4a, 4b, 4c.
  final payPeriod = Period.containing(todayDayBucket(), monthStartDay: 25);
  Widget review() => BudgetReviewScreen(period: payPeriod, newMoneyMinor: 7500000, leftoverMinor: 420000);
  Widget card() => Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: PaydayCard(
            data: PaydayCardData(period: payPeriod, lastSalaryMinor: 7500000, leftoverMinor: 420000),
            todayDay: payPeriod.startDay,
            onChanged: () {},
          ),
        ),
      );
  Widget setNow() => Scaffold(
        body: AmountSheet(
          title: 'Atur anggaran sekarang',
          subtitle: 'Uang yang kamu pegang untuk dipakai sampai gajian berikutnya.',
          buttonLabel: 'Lanjut bagi ke kantong',
          initialMinor: 3000000,
          endChoices: setNowEndChoices(todayDayBucket(), monthStartDay: 25),
        ),
      );
  testWidgets('payday card', (t) => shoot(t, 'payday_card', card()));
  testWidgets('payday card dark', (t) => shoot(t, 'payday_card_dark', card(), brightness: Brightness.dark));
  testWidgets('payday review', (t) => shoot(t, 'payday_review', review()));
  testWidgets('payday review dark', (t) => shoot(t, 'payday_review_dark', review(), brightness: Brightness.dark));
  // R4: screen 5, the recap card that gets shared as an image.
  Widget recap() => const Scaffold(
        body: Padding(
          padding: EdgeInsets.all(16),
          child: RecapShare(
            rangeLabel: '25 Agustus sampai 24 September',
            recap: PeriodRecap(
              planMinor: 6500000,
              spentMinor: 6120000,
              bestHeldName: 'Transport',
              bestHeldPercent: 79,
              overName: 'Hiburan',
              overMinor: 70000,
              overCount: 1,
            ),
          ),
        ),
      );
  testWidgets('recap', (t) => shoot(t, 'recap', recap()));
  testWidgets('recap dark', (t) => shoot(t, 'recap_dark', recap(), brightness: Brightness.dark));
  // R5: screen 6, the comeback after a gap, and its backfill step.
  final surfaces = retentionSurfaces();
  testWidgets('comeback', (t) => shoot(t, 'comeback', surfaces['comeback screen']!()));
  testWidgets('comeback dark',
      (t) => shoot(t, 'comeback_dark', surfaces['comeback screen']!(), brightness: Brightness.dark));
  testWidgets('backfill', (t) => shoot(t, 'backfill', surfaces['backfill screen']!()));
  testWidgets('backfill dark',
      (t) => shoot(t, 'backfill_dark', surfaces['backfill screen']!(), brightness: Brightness.dark));
  testWidgets('saya dark', (t) => shoot(t, 'saya_dark', const SayaScreen(), brightness: Brightness.dark));
  testWidgets('set now', (t) => shoot(t, 'set_now', setNow()));
  testWidgets('set now dark', (t) => shoot(t, 'set_now_dark', setNow(), brightness: Brightness.dark));

  /// A database with nothing in it but the seeded categories, which is what
  /// every first-run empty state actually renders against.
  Future<WudgetDatabase> empty() async {
    final db = WudgetDatabase(NativeDatabase.memory());
    await seedDefaultsIfEmpty(db);
    return db;
  }

  // The states table in plan/04-ux-design.md, one shot per row that exists.
  // Sprint 17 implemented these; this is its second ticket, the gallery.
  testWidgets('catat empty', (t) async => shoot(t, 'catat_empty', const LedgerScreen(), db: await empty()));

  testWidgets('catat filtered empty', (t) => shoot(
        t,
        'catat_filtered_empty',
        const LedgerScreen(),
        drive: (tester) async {
          await tester.tap(find.byTooltip('Cari catatan'));
          await tester.pumpAndSettle();
          await tester.enterText(find.byType(TextField).first, 'kondangan');
          await tester.testTextInput.receiveAction(TextInputAction.search);
        },
      ));

  // main.dart routes a database that cannot be opened here, so this is the
  // "corrupt database routes to restore" cell, not a settings screen shot.
  testWidgets('catat error, routed to restore', (t) async => shoot(
        t,
        'catat_error_restore',
        BackupScreen(debugDocumentsDir: Directory.systemTemp.createTempSync('wudget_review')),
        db: await empty(),
      ));

  testWidgets('pantau waiting', (t) async {
    final db = await empty();
    final postings = PostingsRepository(db);
    final now = DateTime.now();
    await WalletsRepository(db).create(
        id: 'acc_gopay', name: 'GoPay', type: 'ewallet', currency: 'IDR', openingMinor: 185000);
    for (var day = 0; day < 3; day++) {
      final at = now.subtract(Duration(days: day));
      final id = 'tx$day';
      await postings.insertTransaction(
        transaction: TransactionsCompanion.insert(
          id: id, kind: 'expense', occurredAt: at.toUtc().millisecondsSinceEpoch,
          tzOffsetMinutes: at.timeZoneOffset.inMinutes, updatedAt: 0,
        ),
        postings: [
          PostingsCompanion.insert(id: '${id}a', transactionId: id, accountId: const Value('acc_gopay'),
              amountMinor: -35000, currency: 'IDR', baseAmountMinor: -35000),
          PostingsCompanion.insert(id: '${id}c', transactionId: id, categoryId: const Value('cat_makan'),
              amountMinor: 35000, currency: 'IDR', baseAmountMinor: 35000),
        ],
      );
    }
    await shoot(t, 'pantau_waiting', const PantauScreen(), db: db);
  });

  // Six periods back, which the seeded three months of history do not reach.
  testWidgets('pantau empty period', (t) => shoot(
        t,
        'pantau_empty_period',
        const PantauScreen(),
        overrides: [periodOffsetProvider.overrideWith((ref) => -6)],
      ));

  testWidgets('kantong empty', (t) async => shoot(t, 'kantong_empty', const WalletsScreen(), db: await empty()));

  // Sprint 10's tour. Screen 1 is the shot: the later three share its layout,
  // so only the first plus its dark pair is worth a file.
  testWidgets('onboarding', (t) => shoot(t, 'onboarding', const OnboardingScreen()));
  testWidgets('onboarding dark',
      (t) => shoot(t, 'onboarding_dark', const OnboardingScreen(), brightness: Brightness.dark));

  testWidgets('recurring empty', (t) async => shoot(t, 'recurring_empty', const RecurringScreen(), db: await empty()));

  const goodCsv = 'Date,Amount,Category,Account,Note\n'
      '2026-09-01,-35000,Makan,GoPay,Sarapan\n'
      '2026-09-02,-23000,Transport,GoPay,Ojek\n'
      '2026-09-03,-120000,Belanja,BCA,Belanja bulanan\n';

  // Rows 3 and 5 fail, on a bad amount and a bad date: the cell asks for the
  // row number and the reason, with the two valid rows still imported.
  const mixedCsv = 'Date,Amount,Category,Account,Note\n'
      '2026-09-01,-35000,Makan,GoPay,Sarapan\n'
      '2026-09-02,tigapuluh ribu,Transport,GoPay,Ojek\n'
      '2026-09-03,-120000,Belanja,BCA,Belanja bulanan\n'
      'kemarin,-15000,Makan,GoPay,Kopi\n';

  testWidgets('import mapping', (t) async => shoot(
        t,
        'import_mapping',
        const ImportScreen(debugInitialCsvContent: goodCsv, debugInitialFileName: 'moneymanager.csv'),
        db: await empty(),
      ));

  testWidgets('import failures', (t) async => shoot(
        t,
        'import_failures',
        const ImportScreen(debugInitialCsvContent: mixedCsv, debugInitialFileName: 'moneymanager.csv'),
        db: await empty(),
        drive: (tester) async {
          await tester.tap(find.byType(FilledButton));
        },
      ));
}
