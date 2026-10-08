import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:wudget/core/providers.dart';
import 'package:wudget/data/analytics_repository.dart';
import 'package:wudget/data/database.dart';
import 'package:wudget/data/feature_flags_repository.dart';
import 'package:wudget/data/postings_repository.dart';
import 'package:wudget/design/tokens.dart';
import 'package:wudget/domain/default_categories.dart';
import 'package:wudget/domain/period.dart';
import 'package:wudget/features/capture/capture_sheet.dart';
import 'package:wudget/features/onboarding/onboarding_screen.dart';
import 'package:wudget/main.dart';

/// The tour is pushed onto `navigatorKey`'s navigator, which only exists
/// once the real app tree is up, so these tests mount the app's own
/// MaterialApp around a key the same way `main()` does.
Future<void> _launch(WidgetTester tester, WudgetDatabase db, {required bool push}) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [databaseProvider.overrideWithValue(db)],
    child: MaterialApp(
      navigatorKey: navigatorKey,
      theme: buildWudgetTheme(WudgetTokens.light, Brightness.light),
      home: const Scaffold(body: SizedBox.shrink()),
    ),
  ));
  if (push) await showLaunchSurface(db);
  await tester.pumpAndSettle();
}

Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 50));
}

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

  testWidgets('a fresh install opens the tour, not the capture sheet', (tester) async {
    await _launch(tester, db, push: true);

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.byType(CaptureSheet), findsNothing);
    expect(find.text('Catat dalam tiga ketukan'), findsOneWidget);
    await _unmount(tester);
  });

  testWidgets('the tour runs to "Mulai catat" and does not come back', (tester) async {
    await _launch(tester, db, push: true);

    for (final title in [
      'Empat tab, satu alur',
      'Satu periode, bukan satu bulan',
      'Catatanmu tinggal di HP ini',
    ]) {
      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();
      expect(find.text(title), findsOneWidget);
    }
    // No skip on the last screen: the only way out is finishing.
    expect(find.text('Lewati'), findsNothing);
    await tester.tap(find.text('Mulai catat'));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsNothing);
    expect(await FeatureFlagsRepository(db).getBool(onboardingCompletedKey, defaultValue: false), isTrue);
    final events = await AnalyticsRepository(db).all();
    expect(events.where((e) => e.name == 'onboarding_finished'), hasLength(1));

    // Second launch: the tour stays away, so the capture sheet is the surface.
    await showLaunchSurface(db);
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.byType(CaptureSheet), findsOneWidget);
    await _unmount(tester);
  });

  testWidgets('"Lewati" counts as done and records which screen it left from', (tester) async {
    await _launch(tester, db, push: true);

    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lewati'));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsNothing);
    expect(await FeatureFlagsRepository(db).getBool(onboardingCompletedKey, defaultValue: false), isTrue);
    final events = await AnalyticsRepository(db).all();
    final skipped = events.singleWhere((e) => e.name == 'onboarding_skipped');
    expect(skipped.propsJson, contains('"screen":2'));

    await _unmount(tester);
  });

  testWidgets('a returning user goes straight to the comeback', (tester) async {
    await FeatureFlagsRepository(db).setBool(onboardingCompletedKey, true);
    await _expenseOn(db, todayDayBucket() - 6); // four days missed

    await _launch(tester, db, push: true);

    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.text('Lanjut lagi'), findsOneWidget);
    await _unmount(tester);
  });
}