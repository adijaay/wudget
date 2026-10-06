import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../../data/analytics_repository.dart';
import '../../data/daily_totals_repository.dart';
import '../../data/database.dart';
import '../../data/settings_repository.dart';
import '../../design/components.dart';
import '../../design/tokens.dart';
import '../capture/capture_sheet.dart';
import '../ledger/today_header.dart';

final _dayLabel = DateFormat('EEEE, d MMMM', 'id_ID');
DateTime _dateOf(int day) => DateTime.utc(1970, 1, 1).add(Duration(days: day));

/// Gaps shorter than this are an ordinary missed day or two.
const comebackGapDays = 3;

/// Backfill offers at most this many recent days; past a week, memory of
/// small spending is gone anyway.
const backfillMaxDays = 7;

class ComebackData {
  const ComebackData({required this.lastEntryDay, required this.todayDay, required this.strip});
  final int lastEntryDay;
  final int todayDay;
  final LoggedStripData strip;

  int get missedDays => todayDay - lastEntryDay - 1;

  /// Oldest first, so backfill walks forward through the gap.
  List<int> get backfillDays => [
        for (var d = todayDay - (missedDays < backfillMaxDays ? missedDays : backfillMaxDays); d < todayDay; d++) d,
      ];
}

/// Null unless the last entry is [comebackGapDays] or more days back and
/// this gap has not been welcomed yet. Nothing is reset either way.
Future<ComebackData?> loadComeback(WudgetDatabase db, int today) async {
  final last = await DailyTotalsRepository(db).lastEntryDayOnOrBefore(today);
  if (last == null || today - last - 1 < comebackGapDays) return null;
  if (await AnalyticsRepository(db).comebackShownFor(last)) return null;
  final period = await SettingsRepository(db).effectivePeriodFor(today);
  return ComebackData(
    lastEntryDay: last,
    todayDay: today,
    strip: LoggedStripData(
      startDay: period.startDay,
      endDayExclusive: period.endDayExclusive,
      todayDay: today,
      entryDays: await DailyTotalsRepository(db).entryDays(period.startDay, period.endDayExclusive),
    ),
  );
}

/// Screen 6 in design/Retention.html: a welcome back after a gap, with the
/// count kept. Pops true for "start from today" so the caller opens capture.
class ComebackScreen extends ConsumerWidget {
  const ComebackScreen({super.key, required this.data});
  final ComebackData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final text = Theme.of(context).textTheme;
    final analytics = ref.read(analyticsRepositoryProvider);
    final backfill = data.backfillDays;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(WudgetTokens.space4),
          children: [
            Text('Lanjut lagi', style: text.headlineSmall),
            const SizedBox(height: WudgetTokens.space1),
            Text(_dayLabel.format(_dateOf(data.todayDay)), style: text.bodyMedium?.copyWith(color: tokens.ink2)),
            const SizedBox(height: WudgetTokens.space4),
            WudgetCard(
              child: Text(
                '${data.missedDays} hari belum tercatat. Isi yang kamu ingat, atau mulai saja dari hari ini. '
                'Dua-duanya oke.',
                style: text.bodyLarge,
              ),
            ),
            const SizedBox(height: WudgetTokens.space3),
            LoggedDaysStrip(data: data.strip),
            const SizedBox(height: WudgetTokens.space2),
            Text('Tidak ada yang hilang. Hitungannya tetap.', style: text.bodyMedium?.copyWith(color: tokens.ink2)),
            const SizedBox(height: WudgetTokens.space5),
            FilledButton(
              onPressed: () {
                analytics.logEvent('comeback_start_today');
                Navigator.of(context).pop(true);
              },
              child: const Text('Mulai dari hari ini'),
            ),
            const SizedBox(height: WudgetTokens.space2),
            OutlinedButton(
              onPressed: () {
                analytics.logEvent('comeback_backfill', props: {'days': backfill.length});
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => BackfillScreen(days: backfill)),
                );
              },
              child: Text('Isi ${backfill.length} hari yang lewat'),
            ),
          ],
        ),
      ),
    );
  }
}

/// One missed day at a time; each can be filled or skipped.
class BackfillScreen extends ConsumerStatefulWidget {
  const BackfillScreen({super.key, required this.days});
  final List<int> days;

  @override
  ConsumerState<BackfillScreen> createState() => _BackfillScreenState();
}

class _BackfillScreenState extends ConsumerState<BackfillScreen> {
  int _index = 0;
  bool _hasEntry = false;

  int get _day => widget.days[_index];
  bool get _last => _index == widget.days.length - 1;

  Future<void> _capture() async {
    final date = _dateOf(_day);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => CaptureSheet(
        initialOccurredAt: DateTime(date.year, date.month, date.day, 12),
        source: CaptureSource.backfill,
      ),
    );
    final days = await DailyTotalsRepository(ref.read(databaseProvider)).entryDays(_day, _day + 1);
    if (mounted) setState(() => _hasEntry = days.isNotEmpty);
  }

  void _next() {
    if (!_hasEntry) ref.read(analyticsRepositoryProvider).logEvent('backfill_skip', props: {'day': _day});
    if (_last) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _index++;
      _hasEntry = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final text = Theme.of(context).textTheme;
    final label = _dayLabel.format(_dateOf(_day));

    return Scaffold(
      appBar: AppBar(title: const Text('Isi hari yang lewat')),
      body: ListView(
        padding: const EdgeInsets.all(WudgetTokens.space4),
        children: [
          Text('Hari ${_index + 1} dari ${widget.days.length}', style: text.labelMedium?.copyWith(color: tokens.ink2)),
          const SizedBox(height: WudgetTokens.space1),
          Text(label, style: text.headlineSmall),
          const SizedBox(height: WudgetTokens.space3),
          WudgetCard(
            child: Text(
              _hasEntry
                  ? 'Sudah ada catatan di hari ini. Tambah lagi kalau ada yang terlewat.'
                  : 'Ada pengeluaran hari itu? Catat yang kamu ingat saja.',
              style: text.bodyLarge,
            ),
          ),
          const SizedBox(height: WudgetTokens.space5),
          FilledButton(onPressed: _capture, child: Text('Catat untuk $label')),
          const SizedBox(height: WudgetTokens.space2),
          OutlinedButton(
            onPressed: _next,
            child: Text(_last ? 'Selesai' : (_hasEntry ? 'Hari berikutnya' : 'Lewati hari itu')),
          ),
        ],
      ),
    );
  }
}
