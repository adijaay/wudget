import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:wudget/core/providers.dart';
import 'package:wudget/data/database.dart';
import 'package:wudget/data/period_aggregate_queries.dart';
import 'package:wudget/design/tokens.dart';
import 'package:wudget/domain/flow.dart';
import 'package:wudget/domain/period.dart';
import 'package:wudget/domain/pola.dart';
import 'package:wudget/features/pantau/aliran_view.dart';
import 'package:wudget/features/pantau/month_compare_chart.dart';
import 'package:wudget/features/pantau/pola_view.dart';

// These cover the branches where the two new views refuse to draw rather
// than drawing something untrue — the failure mode research/07-ui-audit.md
// found in every competitor, and the one a happy-path screenshot hides.

/// Both views embed the shared PeriodSelector, which reads the period out
/// of settings, so they need a scope with a database behind it.
Widget _host(WudgetDatabase db, Widget child) => ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        theme: buildWudgetTheme(WudgetTokens.light, Brightness.light),
        home: Scaffold(body: child),
      ),
    );

const _period = Period(startDay: 20454, endDayExclusive: 20484, monthStartDay: 1);

FlowBreakdown _flow({required int income, required int expense}) => buildFlowBreakdown(
      incomeMinor: income,
      expenseMinor: expense,
      ranks: [(name: 'Makan', amountMinor: expense, hueIndex: 0)],
    )!;

void main() {
  setUpAll(() async => initializeDateFormatting('id_ID'));

  late WudgetDatabase db;
  setUp(() {
    db = WudgetDatabase(NativeDatabase.memory());
    addTearDown(db.close);
  });

  group('AliranView', () {
    testWidgets('a period still running gets the reason, not a half-drawn flow', (tester) async {
      await tester.pumpWidget(_host(db, const AliranView(
        data: AliranData(
          isPeriodRunning: true,
          flow: null,
          deltas: [],
          previousLabel: 'Agu 2026',
        ),
      )));
      await tester.pumpAndSettle();

      expect(find.text('Periode ini masih jalan'), findsOneWidget);
      expect(find.textContaining('sudah tutup'), findsOneWidget);
      // Unmount inside the test so drift's stream-query timer drains before
      // the binding checks for pending timers — same teardown as the other
      // feature tests in this directory.
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    });

    testWidgets('a closed period with no income says so instead of hanging a flow off zero',
        (tester) async {
      await tester.pumpWidget(_host(db, const AliranView(
        data: AliranData(
          isPeriodRunning: false,
          flow: null,
          deltas: [],
          previousLabel: 'Agu 2026',
        ),
      )));
      await tester.pumpAndSettle();

      expect(find.text('Belum ada pemasukan di periode ini'), findsOneWidget);
      // Unmount inside the test so drift's stream-query timer drains before
      // the binding checks for pending timers — same teardown as the other
      // feature tests in this directory.
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    });

    testWidgets('a deficit period draws no DITABUNG band and names the shortfall',
        (tester) async {
      final flow = _flow(income: 100000, expense: 150000);
      expect(flow.isDeficit, isTrue);

      await tester.pumpWidget(_host(db, AliranView(
        data: AliranData(
          isPeriodRunning: false,
          flow: flow,
          deltas: const [],
          previousLabel: 'Agu 2026',
        ),
      )));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('DITABUNG'), findsNothing);
      expect(find.text('Tidak terpakai'), findsNothing);
      expect(find.textContaining('keluar lebih banyak dari yang masuk'), findsOneWidget);
      // Unmount inside the test so drift's stream-query timer drains before
      // the binding checks for pending timers — same teardown as the other
      // feature tests in this directory.
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    });

    testWidgets('a surplus period does draw the saved band', (tester) async {
      await tester.pumpWidget(_host(db, AliranView(
        data: AliranData(
          isPeriodRunning: false,
          flow: _flow(income: 850000000, expense: 621000000),
          deltas: const [],
          previousLabel: 'Agu 2026',
        ),
      )));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('DITABUNG'), findsOneWidget);
      expect(find.text('Tidak terpakai'), findsOneWidget);
      expect(find.textContaining('Dari tiap Rp 100.000'), findsOneWidget);
      // Unmount inside the test so drift's stream-query timer drains before
      // the binding checks for pending timers — same teardown as the other
      // feature tests in this directory.
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    });
  });

  group('PolaView', () {
    PolaData data({
      required int expenseMinor,
      Map<int, int> daily = const {},
      List<MonthTotal> months = const [],
      List<LargeExpense> largest = const [],
    }) =>
        PolaData(
          period: _period,
          todayDay: _period.startDay + 10,
          dailyExpense: daily,
          transactionCount: daily.length,
          expenseMinor: expenseMinor,
          weekdayPattern: computeWeekdayPattern(
            dailyExpenseMinor: daily,
            sinceDayInclusive: _period.startDay,
            untilDayExclusive: _period.startDay + 11,
          ),
          weekdayWindowDays: 11,
          months: months,
          largestExpenses: largest,
        );

    testWidgets('no spend in the period names the reason rather than an empty chart',
        (tester) async {
      await tester.pumpWidget(_host(db, PolaView(data: data(expenseMinor: 0))));
      await tester.pumpAndSettle();

      expect(find.text('Polanya belum kelihatan'), findsOneWidget);
      // Unmount inside the test so drift's stream-query timer drains before
      // the binding checks for pending timers — same teardown as the other
      // feature tests in this directory.
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    });

    testWidgets('the forecast caveat appears only when a bar is actually a forecast',
        (tester) async {
      final closed = [
        const MonthTotal(label: 'Jul 2026', totalMinor: 589000000),
        const MonthTotal(label: 'Agu 2026', totalMinor: 621000000),
      ];
      await tester.pumpWidget(_host(db, PolaView(
        data: data(
          expenseMinor: 243000000,
          daily: {_period.startDay: 243000000},
          months: closed,
        ),
      )));
      await tester.pumpAndSettle();

      // The months card sits below the calendar and the weekday chart, so
      // it has to be scrolled to before it exists in the tree at all.
      await tester.scrollUntilVisible(find.byType(MonthCompareChart), 200, maxScrolls: 30);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Perkiraan periode ini dihitung dari'), findsNothing);
      expect(find.text('Perkiraan, belum terjadi'), findsNothing);

      await tester.pumpWidget(_host(db, PolaView(
        data: data(
          expenseMinor: 243000000,
          daily: {_period.startDay: 243000000},
          months: [...closed, const MonthTotal(label: 'Sep 2026', totalMinor: 498000000, isForecast: true)],
        ),
      )));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.byType(MonthCompareChart), 200, maxScrolls: 30);
      await tester.pumpAndSettle();

      expect(find.textContaining('Perkiraan periode ini dihitung dari'), findsOneWidget);
      expect(find.text('Perkiraan, belum terjadi'), findsOneWidget);
      // Unmount inside the test so drift's stream-query timer drains before
      // the binding checks for pending timers — same teardown as the other
      // feature tests in this directory.
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    });

    testWidgets('a window too short to compare weekends says so instead of guessing',
        (tester) async {
      // One day of history: there are weekdays in the window but no
      // weekend, so no honest ratio exists yet.
      final oneDay = PolaData(
        period: _period,
        todayDay: _period.startDay,
        dailyExpense: {_period.startDay: 5000000},
        transactionCount: 1,
        expenseMinor: 5000000,
        weekdayPattern: computeWeekdayPattern(
          dailyExpenseMinor: {_period.startDay: 5000000},
          sinceDayInclusive: _period.startDay,
          untilDayExclusive: _period.startDay + 1,
        ),
        weekdayWindowDays: 1,
        months: const [],
        largestExpenses: const [],
      );

      await tester.pumpWidget(_host(db, PolaView(data: oneDay)));
      await tester.pumpAndSettle();

      expect(
        find.text('Belum cukup hari untuk membandingkan akhir pekan dengan hari kerja.'),
        findsOneWidget,
      );
      // Unmount inside the test so drift's stream-query timer drains before
      // the binding checks for pending timers — same teardown as the other
      // feature tests in this directory.
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    });
  });
}
