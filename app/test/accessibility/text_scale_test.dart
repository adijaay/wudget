import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:wudget/core/providers.dart';
import 'package:wudget/data/database.dart';
import 'package:wudget/data/postings_repository.dart';
import 'package:wudget/design/tokens.dart';
import 'package:wudget/domain/default_categories.dart';
import 'package:wudget/features/capture/capture_sheet.dart';
import 'package:wudget/features/ledger/ledger_screen.dart';
import 'package:wudget/features/pantau/pantau_screen.dart';

import 'retention_surfaces.dart';

/// plan/05-sprints.md Sprint 18: "200 per cent text scale on the capture
/// sheet, the ledger row, the pace card." A test here means what
/// R-3/antislop-human means by resizable text: the layout must hold at
/// 200% without clipping or an overflow error, not just look plausible at
/// the default scale.
Widget _at200Percent(Widget child) {
  return MediaQuery(
    data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
    child: child,
  );
}

Future<void> _seedFullPeriodHistory(WudgetDatabase db) async {
  await seedDefaultsIfEmpty(db);
  final postings = PostingsRepository(db);
  final now = DateTime.now();

  Future<void> expense(String id, DateTime at, int amountMinor) {
    return postings.insertTransaction(
      transaction: TransactionsCompanion.insert(
        id: id, kind: 'expense', occurredAt: at.toUtc().millisecondsSinceEpoch, tzOffsetMinutes: 0, updatedAt: 0,
      ),
      postings: [
        PostingsCompanion.insert(id: '${id}a', transactionId: id, accountId: const Value('acc_cash'),
            amountMinor: -amountMinor, currency: 'IDR', baseAmountMinor: -amountMinor),
        PostingsCompanion.insert(id: '${id}c', transactionId: id, categoryId: const Value('cat_makan'),
            amountMinor: amountMinor, currency: 'IDR', baseAmountMinor: amountMinor),
      ],
    );
  }

  await expense('tx0', now.subtract(const Duration(days: 60)), 15000);
  await expense('tx1', DateTime(now.year, now.month - 1, 15), 300000);
  await expense('tx2', now, 20000);
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  testWidgets('capture sheet holds together at 200% text scale', (tester) async {
    final db = WudgetDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await seedDefaultsIfEmpty(db);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: buildWudgetTheme(WudgetTokens.light, Brightness.light),
          builder: (context, child) => _at200Percent(child!),
          home: const Scaffold(body: CaptureSheet()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets('a Catat (ledger) row holds together at 200% text scale', (tester) async {
    final db = WudgetDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await seedDefaultsIfEmpty(db);
    await PostingsRepository(db).insertTransaction(
      transaction: TransactionsCompanion.insert(
        id: 'tx1', kind: 'expense', occurredAt: DateTime.utc(2026, 6, 1, 8).millisecondsSinceEpoch,
        tzOffsetMinutes: 0, note: const Value('Sarapan nasi uduk dengan lauk lengkap'), updatedAt: 0,
      ),
      postings: [
        PostingsCompanion.insert(id: 'p1a', transactionId: 'tx1', accountId: const Value('acc_cash'),
            amountMinor: -1500000, currency: 'IDR', baseAmountMinor: -1500000),
        PostingsCompanion.insert(id: 'p1c', transactionId: 'tx1', categoryId: const Value('cat_makan'),
            amountMinor: 1500000, currency: 'IDR', baseAmountMinor: 1500000),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: buildWudgetTheme(WudgetTokens.light, Brightness.light),
          builder: (context, child) => _at200Percent(child!),
          home: const LedgerScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    // Catat now opens on the day header (jatah harian and the week bars),
    // which at 200% is most of a viewport on its own, so the first ledger
    // row starts below the fold. Scroll to it: what this test guards is
    // that the row holds together at that scale, not where it sits.
    await tester.scrollUntilVisible(find.text('Makan'), 200, maxScrolls: 30);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Makan'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets('the Pantau pace card holds together at 200% text scale', (tester) async {
    final db = WudgetDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await _seedFullPeriodHistory(db);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: buildWudgetTheme(WudgetTokens.light, Brightness.light),
          builder: (context, child) => _at200Percent(child!),
          home: const PantauScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });

  // R5.5: every surface the retention round added, at 200%.
  for (final MapEntry(key: name, value: build) in retentionSurfaces().entries) {
    for (final brightness in Brightness.values) {
      testWidgets('$name holds together at 200% text scale (${brightness.name})', (tester) async {
        final db = WudgetDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        await seedDefaultsIfEmpty(db);
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          ProviderScope(
            overrides: [databaseProvider.overrideWithValue(db)],
            child: MaterialApp(
              theme: buildWudgetTheme(
                  brightness == Brightness.dark ? WudgetTokens.dark : WudgetTokens.light, brightness),
              builder: (context, child) => _at200Percent(child!),
              home: build(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(milliseconds: 50));
      });
    }
  }
}
