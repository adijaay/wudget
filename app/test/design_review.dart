import 'dart:io';

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
import 'package:wudget/features/budget/budget_screen.dart';
import 'package:wudget/features/capture/capture_sheet.dart';
import 'package:wudget/features/ledger/ledger_screen.dart';
import 'package:wudget/features/pantau/pantau_screen.dart';
import 'package:wudget/features/settings/saya_screen.dart';
import 'package:wudget/features/wallets/wallets_screen.dart';

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
  }) async {
    final database = db ?? await seeded();
    addTearDown(database.close);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
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
}
