import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncData;
import 'package:wudget/domain/insight.dart';
import 'package:wudget/domain/pace.dart';
import 'package:wudget/domain/period.dart';
import 'package:wudget/domain/period_close.dart';
import 'package:wudget/domain/pola.dart';
import 'package:wudget/features/comeback/comeback_screen.dart';
import 'package:wudget/features/ledger/today_header.dart';
import 'package:wudget/features/pantau/kantong_pace_list.dart';
import 'package:wudget/features/pantau/recap_card.dart';
import 'package:wudget/features/payday/budget_review_screen.dart';
import 'package:wudget/features/payday/payday_card.dart';

/// The R1 to R5 surfaces with the mockup's numbers, shared by the 200% text
/// and screen reader tests so both walk the same list.
final _today = todayDayBucket();
final _period = Period.containing(_today, monthStartDay: 25);

LoggedStripData stripFixture() => LoggedStripData(
      startDay: _today - 12,
      endDayExclusive: _today + 18,
      todayDay: _today,
      entryDays: {for (var d = _today - 12; d <= _today; d++) if (d != _today - 4 && d != _today - 8) d},
    );

Widget _padded(Widget child) => Scaffold(
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: child),
    );

Map<String, Widget Function()> retentionSurfaces() => {
      'home jatah, strip and insight': () => _padded(TodayHeader(
            todayDay: _today,
            jatah: AsyncData(TodayHeaderData(
              todayDay: _today,
              todaySpendMinor: 48000,
              allowance: const DailyAllowance(remainingMinor: 2394000, daysRemaining: 18, perDayMinor: 133000),
            )),
            strip: AsyncData(stripFixture()),
            insight: const AsyncData(Insight(
              key: 'week_makan',
              text: 'Makan minggu ini Rp 84.000 lebih sedikit dari minggu lalu.',
            )),
          )),
      'payday card': () => _padded(PaydayCard(
            data: PaydayCardData(period: _period, lastSalaryMinor: 7500000, leftoverMinor: 420000),
            todayDay: _period.startDay,
            onChanged: () {},
          )),
      'budget review': () => BudgetReviewScreen(period: _period, newMoneyMinor: 7500000, leftoverMinor: 420000),
      'set-now sheet': () => Scaffold(
            body: AmountSheet(
              title: 'Atur anggaran sekarang',
              subtitle: 'Uang yang kamu pegang untuk dipakai sampai gajian berikutnya.',
              buttonLabel: 'Lanjut bagi ke kantong',
              initialMinor: 3000000,
              endChoices: setNowEndChoices(_today, monthStartDay: 25),
            ),
          ),
      'recap card': () => _padded(const RecapShare(
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
          )),
      'pantau kantong list': () => _padded(KantongPaceList(
            sorted: sortKantongByPace(const [
              (key: 'cat_belanja', name: 'Belanja', planMinor: 800000, spentMinor: 688000, hueIndex: 3),
              (key: 'cat_makan', name: 'Makan', planMinor: 1560000, spentMinor: 610000, hueIndex: 0),
              (key: 'cat_tagihan', name: 'Tagihan', planMinor: 900000, spentMinor: 900000, hueIndex: 5),
            ], 0.43),
          )),
      'comeback screen': () => ComebackScreen(
            data: ComebackData(lastEntryDay: _today - 5, todayDay: _today, strip: stripFixture()),
          ),
      'backfill screen': () => BackfillScreen(days: [_today - 4, _today - 3, _today - 2, _today - 1]),
    };
