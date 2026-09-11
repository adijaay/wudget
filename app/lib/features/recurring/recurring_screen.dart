import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/money.dart';
import '../../core/money_formatter.dart';
import '../../core/providers.dart';
import '../../data/database.dart';
import '../../data/recurrence_repository.dart';
import '../../data/recurring_queries.dart';
import '../../design/tokens.dart';
import '../../domain/recurrence.dart';
import '../capture/capture_sheet.dart';

const _formatter = MoneyFormatter();
final _dateFormat = DateFormat('d MMM', 'id_ID');

int _todayDayBucket() {
  final now = DateTime.now();
  return DateTime.utc(now.year, now.month, now.day).difference(DateTime.utc(1970, 1, 1)).inDays;
}

DateTime _dateForDay(int day) => DateTime.utc(1970, 1, 1).add(Duration(days: day));

/// Recurring items and bills, split into what's already materialised and
/// waiting for confirmation ("Akan datang") and the rules that produce
/// them ("Aktif") — plan/05-sprints.md Sprint 13.
class RecurringScreen extends ConsumerStatefulWidget {
  const RecurringScreen({super.key});

  @override
  ConsumerState<RecurringScreen> createState() => _RecurringScreenState();
}

class _RecurringScreenState extends ConsumerState<RecurringScreen> {
  List<UpcomingInstance>? _upcoming;
  List<Recurrence>? _active;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final queries = RecurringQueries(ref.read(databaseProvider));
    final upcoming = await queries.upcoming();
    final active = await queries.activeRules();
    if (!mounted) return;
    setState(() {
      _upcoming = upcoming;
      _active = active;
    });
  }

  Future<void> _skip(UpcomingInstance instance) async {
    await ref.read(postingsRepositoryProvider).undoInsert(instance.transactionId);
    await _load();
  }

  void _confirm(UpcomingInstance instance) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => CaptureSheet(
        initialCategoryId: instance.categoryId,
        initialAccountId: instance.accountId,
        initialAmountMinor: instance.amountMinor,
        initialNote: instance.note,
        confirmingTransactionId: instance.transactionId,
      ),
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final upcoming = _upcoming;
    final active = _active;
    if (upcoming == null || active == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final today = _todayDayBucket();

    return Scaffold(
      appBar: AppBar(title: const Text('Berulang & Tagihan')),
      body: ListView(
        padding: const EdgeInsets.all(WudgetTokens.space4),
        children: [
          Text('Akan datang', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: WudgetTokens.space2),
          if (upcoming.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: WudgetTokens.space3),
              child: Text('Tidak ada yang akan datang.'),
            )
          else
            for (final instance in upcoming)
              _UpcomingTile(
                instance: instance,
                onConfirm: () => _confirm(instance),
                onSkip: () => _skip(instance),
              ),
          const SizedBox(height: WudgetTokens.space5),
          Text('Aktif', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: WudgetTokens.space2),
          if (active.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: WudgetTokens.space3),
              child: Text('Belum ada item berulang.'),
            )
          else
            for (final row in active) _ActiveTile(row: row, today: today),
        ],
      ),
    );
  }
}

class _UpcomingTile extends StatelessWidget {
  const _UpcomingTile({required this.instance, required this.onConfirm, required this.onSkip});
  final UpcomingInstance instance;
  final VoidCallback onConfirm;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: WudgetTokens.space2),
      child: ListTile(
        title: Text(instance.note?.isNotEmpty == true ? instance.note! : 'Tagihan'),
        subtitle: Text(_dateFormat.format(_dateForDay(instance.dueDay))),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_formatter.format(Money.fromMinor(instance.amountMinor, 'IDR'))),
            IconButton(icon: const Icon(Icons.close), tooltip: 'Lewati', onPressed: onSkip),
            IconButton(icon: const Icon(Icons.check), tooltip: 'Konfirmasi', onPressed: onConfirm),
          ],
        ),
      ),
    );
  }
}

class _ActiveTile extends StatelessWidget {
  const _ActiveTile({required this.row, required this.today});
  final Recurrence row;
  final int today;

  @override
  Widget build(BuildContext context) {
    final rule = RecurrenceRule(
      freq: RecurrenceFreq.values.byName(row.freq),
      intervalN: row.intervalN,
      byMonthDay: row.byMonthDay,
      byWeekday: row.byWeekday,
      weekendRule: WeekendRule.values.byName(row.weekendRule),
      startsOn: row.startsOn,
      endsOn: row.endsOn,
    );
    final template = RecurrenceTemplate.fromJson(jsonDecode(row.templateJson) as Map<String, Object?>);
    final nextDue = rule.nextOccurrenceOnOrAfter(today);
    final amountLabel = row.amountMode == 'varies'
        ? '${_formatter.format(Money.fromMinor(row.expectedMinMinor ?? 0, 'IDR'))} - '
            '${_formatter.format(Money.fromMinor(row.expectedMaxMinor ?? 0, 'IDR'))}'
        : _formatter.format(Money.fromMinor(template.fixedAmountMinor ?? 0, 'IDR'));

    return Card(
      margin: const EdgeInsets.only(bottom: WudgetTokens.space2),
      child: ListTile(
        title: Text(template.note?.isNotEmpty == true ? template.note! : 'Item berulang'),
        subtitle: Text('Berikutnya: ${_dateFormat.format(_dateForDay(nextDue))}'),
        trailing: Text(amountLabel),
      ),
    );
  }
}
