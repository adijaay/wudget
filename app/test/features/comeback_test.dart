import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:wudget/core/providers.dart';
import 'package:wudget/data/analytics_repository.dart';
import 'package:wudget/data/daily_totals_repository.dart';
import 'package:wudget/data/database.dart';
import 'package:wudget/data/postings_repository.dart';
import 'package:wudget/design/tokens.dart';
import 'package:wudget/domain/default_categories.dart';
import 'package:wudget/domain/period.dart';
import 'package:wudget/features/comeback/comeback_screen.dart';

Future<void> _expenseOn(WudgetDatabase db, int day) async {
  final d = DateTime.utc(1970, 1, 1).add(Duration(days: day));
  final at = DateTime(d.year, d.month, d.day, 12);
  final id = 'tx$day';
  await PostingsRepository(db).insertTransaction(
    transaction: TransactionsCompanion.insert(
      id: id, kind: 'expense', occurredAt: at.toUtc().millisecondsSinceEpoch,
      tzOffsetMinutes: at.timeZoneOffset.inMinutes, updatedAt: 0,
    ),
    postings: [
      PostingsCompanion.insert(id: '${id}a', transactionId: id, accountId: const Value('acc_cash'),
          amountMinor: -10000, currency: 'IDR', baseAmountMinor: -10000),
      PostingsCompanion.insert(id: '${id}c', transactionId: id, categoryId: const Value('cat_makan'),
          amountMinor: 10000, currency: 'IDR', baseAmountMinor: 10000),
    ],
  );
}

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  late WudgetDatabase db;
  setUp(() async {
    db = WudgetDatabase(NativeDatabase.memory());
    await seedDefaultsIfEmpty(db);
  });
  tearDown(() => db.close());

  final today = todayDayBucket();

  test('no comeback for a new user or a gap under three days', () async {
    expect(await loadComeback(db, today), isNull);
    await _expenseOn(db, today - 3); // two days missed
    expect(await loadComeback(db, today), isNull);
  });

  test('shows once per gap and keeps the count', () async {
    await _expenseOn(db, today - 6);
    await _expenseOn(db, today - 5); // four days missed

    final data = (await loadComeback(db, today))!;
    expect(data.missedDays, 4);
    expect(data.backfillDays, [today - 4, today - 3, today - 2, today - 1]);
    expect(data.strip.entryDays, containsAll([today - 6, today - 5].where((d) => d >= data.strip.startDay)));

    await AnalyticsRepository(db).logEvent('comeback_shown', props: {'lastEntryDay': data.lastEntryDay});
    expect(await loadComeback(db, today), isNull);
    // Entries are untouched by the comeback.
    expect(await DailyTotalsRepository(db).lastEntryDayOnOrBefore(today), today - 5);
  });

  test('a long gap offers only the last seven days to fill', () async {
    await _expenseOn(db, today - 30);
    final data = (await loadComeback(db, today))!;
    expect(data.missedDays, 29);
    expect(data.backfillDays, hasLength(backfillMaxDays));
    expect(data.backfillDays.last, today - 1);
  });

  testWidgets('backfill walks one day at a time, skip allowed', (tester) async {
    final days = [today - 2, today - 1];
    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        theme: buildWudgetTheme(WudgetTokens.light, Brightness.light),
        home: BackfillScreen(days: days),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Hari 1 dari 2'), findsOneWidget);
    await tester.tap(find.text('Lewati hari itu'));
    await tester.pumpAndSettle();
    expect(find.text('Hari 2 dari 2'), findsOneWidget);
    expect(find.text('Selesai'), findsOneWidget);

    final events = await AnalyticsRepository(db).all();
    expect(events.where((e) => e.name == 'backfill_skip'), hasLength(1));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets('backfill entries are dated to the chosen day', (tester) async {
    final day = today - 3;
    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        theme: buildWudgetTheme(WudgetTokens.light, Brightness.light),
        home: BackfillScreen(days: [day]),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('numpadKey_5')));
    await tester.tap(find.byKey(const Key('numpadKey_000')));
    await tester.ensureVisible(find.text('Makan'));
    await tester.tap(find.text('Makan'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('numpadKey_save')));
    await tester.pumpAndSettle();
    // Let the undo toast time out so the sheet's timers settle.
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();

    expect(await DailyTotalsRepository(db).entryDays(day, day + 1), {day});
    expect(find.textContaining('Sudah ada catatan'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });
}
