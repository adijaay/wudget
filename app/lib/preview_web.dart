// A browser entrypoint for looking at the new Pantau and Catat surfaces
// with the real bundled typeface, which the widget-test harness cannot
// give (flutter_test renders with a blank font, so every label comes out
// as a box).
//
// Deliberately not the app: wudget's persistence is drift over a native
// sqlite file and its startup path imports dart:io, so running the real
// app in a browser means porting the database to wasm and guarding the
// notification, home-widget and timezone plugins. This entrypoint skips
// all of that by feeding the views fixture data and overriding the two
// providers PeriodSelector reads, so no database is ever opened.
//
//   flutter run -d web-server --target=lib/preview_web.dart
//
// The numbers below are fixtures for looking at layout. They are not a
// user's data and nothing here is wired to the real database.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/providers.dart';
import 'data/period_aggregate_queries.dart';
import 'design/components.dart';
import 'design/tokens.dart';
import 'domain/flow.dart';
import 'domain/period.dart';
import 'domain/pola.dart';
import 'features/ledger/today_header.dart';
import 'features/pantau/aliran_view.dart';
import 'features/pantau/month_compare_chart.dart';
import 'features/pantau/pola_view.dart';

final _sep1 = DateTime.utc(2026, 9, 1).difference(DateTime.utc(1970, 1, 1)).inDays;
final _today = _sep1 + 10;

final _daily = <int, int>{
  _sep1 + 0: 950000,
  _sep1 + 1: 88000,
  _sep1 + 3: 212000,
  _sep1 + 4: 410000,
  _sep1 + 5: 318000,
  _sep1 + 6: 145000,
  _sep1 + 8: 196000,
  _sep1 + 9: 48000,
  _sep1 + 10: 63000,
};

/// A 90-day window for the weekday averages, so the bars are not all the
/// same height from one month of data.
final _ninetyDays = <int, int>{
  for (var day = _sep1 - 79; day <= _today; day++)
    if (_daily.containsKey(day))
      day: _daily[day]!
    else if (weekdayIndexOf(day) >= 5)
      day: 180000 + (day % 7) * 22000
    else if (day % 5 != 0)
      day: 90000 + (day % 11) * 9000,
};

final _polaData = PolaData(
  period: Period(startDay: _sep1, endDayExclusive: _sep1 + 30, monthStartDay: 1),
  todayDay: _today,
  dailyExpense: _daily,
  transactionCount: 34,
  expenseMinor: _daily.values.fold(0, (a, b) => a + b),
  weekdayPattern: computeWeekdayPattern(
    dailyExpenseMinor: _ninetyDays,
    sinceDayInclusive: _sep1 - 79,
    untilDayExclusive: _today + 1,
  ),
  weekdayWindowDays: 90,
  months: const [
    MonthTotal(label: 'Jul 2026', totalMinor: 5890000),
    MonthTotal(label: 'Agu 2026', totalMinor: 6210000),
    MonthTotal(label: 'Sep 2026', totalMinor: 4980000, isForecast: true),
  ],
  largestExpenses: [
    LargeExpense(
      transactionId: 't1',
      day: _sep1,
      amountMinor: 780000,
      note: 'Kos bulanan',
      categoryName: 'Rumah',
      hueIndex: 3,
    ),
    LargeExpense(
      transactionId: 't2',
      day: _sep1 + 4,
      amountMinor: 320000,
      note: 'Sepatu kerja',
      categoryName: 'Belanja',
      hueIndex: 2,
    ),
    LargeExpense(
      transactionId: 't3',
      day: _sep1,
      amountMinor: 170000,
      note: null,
      categoryName: 'Rumah',
      hueIndex: 3,
    ),
  ],
);

final _surplus = buildFlowBreakdown(
  incomeMinor: 8500000,
  expenseMinor: 6210000,
  ranks: const [
    (name: 'Rumah', amountMinor: 2100000, hueIndex: 3),
    (name: 'Makan & minum', amountMinor: 1780000, hueIndex: 0),
    (name: 'Transport', amountMinor: 1030000, hueIndex: 1),
    (name: 'Hiburan', amountMinor: 830000, hueIndex: 4),
    (name: 'Belanja', amountMinor: 470000, hueIndex: 2),
  ],
)!;

final _deficit = buildFlowBreakdown(
  incomeMinor: 4200000,
  expenseMinor: 5080000,
  ranks: const [
    (name: 'Rumah', amountMinor: 2100000, hueIndex: 3),
    (name: 'Makan & minum', amountMinor: 1780000, hueIndex: 0),
    (name: 'Transport', amountMinor: 1200000, hueIndex: 1),
  ],
)!;

AliranData _aliran(FlowBreakdown flow) => AliranData(
      isPeriodRunning: false,
      flow: flow,
      deltas: const [
        CategoryDelta(name: 'Belanja', deltaMinor: 120000, hueIndex: 2),
        CategoryDelta(name: 'Makan & minum', deltaMinor: 90000, hueIndex: 0),
        CategoryDelta(name: 'Transport', deltaMinor: -50000, hueIndex: 1),
        CategoryDelta(name: 'Rumah', deltaMinor: 0, hueIndex: 3),
      ],
      previousLabel: 'Jul 2026',
    );

final _header = TodayHeaderData(
  todayDay: _today,
  todaySpendMinor: 63000,
  allowance: computeDailyAllowance(
    budgetTotalMinor: 4500000,
    spentMinor: 2430000,
    daysRemaining: 19,
  ),
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  runApp(
    ProviderScope(
      // The only provider the embedded PeriodSelector needs. Overridden
      // with a literal so nothing reaches for settings, and therefore
      // nothing reaches for a database.
      overrides: [
        periodStartDayProvider.overrideWith((ref) => Stream.value(1)),
      ],
      child: const _PreviewApp(),
    ),
  );
}

class _PreviewApp extends StatefulWidget {
  const _PreviewApp();

  @override
  State<_PreviewApp> createState() => _PreviewAppState();
}

class _PreviewAppState extends State<_PreviewApp> {
  ThemeMode _mode = ThemeMode.light;
  int _screen = 0;

  static const _screens = ['Pola', 'Aliran', 'Aliran (defisit)', 'Catat, kepala hari ini'];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'wudget preview',
      debugShowCheckedModeBanner: false,
      theme: buildWudgetTheme(WudgetTokens.light, Brightness.light),
      darkTheme: buildWudgetTheme(WudgetTokens.dark, Brightness.dark),
      themeMode: _mode,
      home: Builder(
        builder: (context) {
          final tokens = Theme.of(context).extension<WudgetTokens>()!;
          return Scaffold(
            appBar: AppBar(
              title: Text(_screens[_screen]),
              actions: [
                IconButton(
                  tooltip: _mode == ThemeMode.light ? 'Ke tema gelap' : 'Ke tema terang',
                  icon: Icon(_mode == ThemeMode.light
                      ? Icons.dark_mode_outlined
                      : Icons.light_mode_outlined),
                  onPressed: () => setState(() =>
                      _mode = _mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light),
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    WudgetTokens.space4,
                    0,
                    WudgetTokens.space4,
                    WudgetTokens.space2,
                  ),
                  child: SegmentedTray<int>(
                    segments: {for (var i = 0; i < _screens.length; i++) i: _screens[i]},
                    value: _screen,
                    onChanged: (i) => setState(() => _screen = i),
                  ),
                ),
              ),
            ),
            // Held to a phone width, because that is the only width these
            // screens are designed for.
            body: Center(
              child: Container(
                width: 390,
                decoration: BoxDecoration(
                  border: Border.symmetric(vertical: BorderSide(color: tokens.border)),
                ),
                child: switch (_screen) {
                  0 => PolaView(data: _polaData),
                  1 => AliranView(data: _aliran(_surplus)),
                  2 => AliranView(data: _aliran(_deficit)),
                  _ => ListView(
                      padding: const EdgeInsets.all(WudgetTokens.space4),
                      children: [
                        TodayHeader(
                          todayDay: _today,
                          jatah: AsyncData(_header),
                          strip: const AsyncLoading(),
                          insight: const AsyncData(null),
                        ),
                      ],
                    ),
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
