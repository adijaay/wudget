/// The one sentence home says each day, picked from what Pola and Aliran
/// already compute. Keys carry the numbers, so an unchanged fact keeps its
/// key and counts as already said.
library;

import '../core/money.dart';
import '../core/money_formatter.dart';
import 'flow.dart';
import 'pola.dart';

const _formatter = MoneyFormatter();
String _rp(int minor) => _formatter.format(Money.fromMinor(minor, 'IDR'));

const _weekdayNames = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

/// How many shown sentences are remembered and skipped.
const insightMemory = 7;

class Insight {
  const Insight({required this.key, required this.text});
  final String key;
  final String text;
}

/// Candidates in preference order: this week's biggest category move,
/// the weekend against workdays, the busiest weekday, last period's flow.
List<Insight> insightCandidates({
  List<CategoryDelta> weekDeltas = const [],
  WeekdayPattern? pattern,
  FlowBreakdown? lastPeriodFlow,
}) {
  final out = <Insight>[];
  for (final d in weekDeltas.where((d) => !d.isFlat).take(1)) {
    final less = d.deltaMinor < 0;
    out.add(Insight(
      key: 'week:${d.name}:${d.deltaMinor}',
      text: '${d.name} minggu ini ${_rp(d.deltaMinor.abs())} '
          '${less ? 'lebih sedikit' : 'lebih banyak'} dari minggu lalu.',
    ));
  }
  final weekend = pattern?.weekendAverageMinor;
  final workday = pattern?.workdayAverageMinor;
  if (weekend != null && workday != null && weekend > 0 && workday > 0 && weekend != workday) {
    out.add(Insight(
      key: 'weekend:$weekend:$workday',
      text: 'Akhir pekan rata-rata ${_rp(weekend)} per hari, hari kerja ${_rp(workday)}.',
    ));
  }
  final peak = pattern?.peakWeekdayIndex;
  if (peak != null) {
    out.add(Insight(
      key: 'peak:$peak',
      text: 'Pengeluaranmu paling besar biasanya di hari ${_weekdayNames[peak]}.',
    ));
  }
  final flow = lastPeriodFlow;
  if (flow != null && !flow.isDeficit && flow.savedMinor > 0) {
    final per100k = flow.savedMinor * 100000 ~/ flow.incomeMinor ~/ 1000 * 1000;
    if (per100k > 0) {
      out.add(Insight(
        key: 'flow:${flow.incomeMinor}:${flow.savedMinor}',
        text: 'Periode lalu, dari tiap ${_rp(100000)} yang masuk, ${_rp(per100k)} tersisa.',
      ));
    }
  }
  return out;
}

/// Today's sentence: the one already shown today if it still holds, else
/// the first candidate not among the last [insightMemory] shown. Null when
/// nothing is new; a stale sentence never wins over silence.
Insight? pickDailyInsight({
  required List<Insight> candidates,
  required List<({int day, String key})> recent,
  required int today,
}) {
  final shownToday = recent.where((r) => r.day == today).map((r) => r.key).toSet();
  for (final c in candidates) {
    if (shownToday.contains(c.key)) return c;
  }
  final seen = recent.take(insightMemory).map((r) => r.key).toSet();
  for (final c in candidates) {
    if (!seen.contains(c.key)) return c;
  }
  return null;
}
