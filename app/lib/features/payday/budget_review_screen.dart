import 'package:drift/drift.dart' show InsertMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/money.dart';
import '../../core/money_formatter.dart';
import '../../core/providers.dart';
import '../../data/database.dart';
import '../../design/components.dart';
import '../../design/tokens.dart';
import '../../domain/budget_proposal.dart';
import '../../domain/payday.dart';
import '../../domain/period.dart';

const _formatter = MoneyFormatter();
final _shortDate = DateFormat('d MMM', 'id_ID');
String _rp(int minor) => _formatter.format(Money.fromMinor(minor, 'IDR'));
const _lookbackDays = 28;

/// "Atur sekarang" (screen 4c): money on hand and an end date, then the review.
Future<void> startSetNow(BuildContext context, WidgetRef ref) async {
  final analytics = ref.read(analyticsRepositoryProvider);
  await analytics.logEvent('set_now_open');
  final today = todayDayBucket();
  final monthStartDay = (await ref.read(settingsRepositoryProvider).getRow())?.periodStartDay ?? defaultPeriodStartDay;
  if (!context.mounted) return;
  final result = await showAmountSheet(
    context,
    title: 'Atur anggaran sekarang',
    subtitle: 'Uang yang kamu pegang untuk dipakai sampai gajian berikutnya.',
    buttonLabel: 'Lanjut bagi ke kantong',
    endChoices: setNowEndChoices(today, monthStartDay: monthStartDay),
  );
  if (result == null || !context.mounted) return;
  await Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => BudgetReviewScreen(
      period: Period(startDay: today, endDayExclusive: result.endDayExclusive!, monthStartDay: monthStartDay),
      newMoneyMinor: result.amountMinor,
      leftoverMinor: 0,
      customPeriod: true,
    ),
  ));
}

/// The keypad sheet for "Atur sekarang" and "Beda jumlah". With
/// [endChoices] it also asks until when; the result then carries the end.
Future<({int amountMinor, int? endDayExclusive})?> showAmountSheet(
  BuildContext context, {
  required String title,
  required String subtitle,
  required String buttonLabel,
  int initialMinor = 0,
  ({int coming, int later, bool laterIsDefault})? endChoices,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => AmountSheet(
      title: title,
      subtitle: subtitle,
      buttonLabel: buttonLabel,
      initialMinor: initialMinor,
      endChoices: endChoices,
    ),
  );
}

class AmountSheet extends StatefulWidget {
  const AmountSheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    this.initialMinor = 0,
    this.endChoices,
  });
  final String title;
  final String subtitle;
  final String buttonLabel;
  final int initialMinor;
  final ({int coming, int later, bool laterIsDefault})? endChoices;

  @override
  State<AmountSheet> createState() => _AmountSheetState();
}

class _AmountSheetState extends State<AmountSheet> {
  // Twelve digits of rupiah is far past any salary; it stops an overflow.
  static const _maxMinor = 999999999999;
  late int _amount = widget.initialMinor;
  late int? _end = widget.endChoices == null
      ? null
      : (widget.endChoices!.laterIsDefault ? widget.endChoices!.later : widget.endChoices!.coming);

  void _type(int Function(int) f) {
    final next = f(_amount);
    if (next <= _maxMinor) setState(() => _amount = next);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final text = Theme.of(context).textTheme;
    final choices = widget.endChoices;
    String endLabel(int endExclusive) => _shortDate.format(DateTime.utc(1970).add(Duration(days: endExclusive - 1)));

    Widget key(String label, VoidCallback onTap, {String? semantics, IconData? icon}) => Expanded(
          child: Padding(
            padding: const EdgeInsets.all(3.5),
            child: Semantics(
              label: semantics ?? label,
              button: true,
              excludeSemantics: true,
              child: Material(
                color: tokens.surfaceMuted,
                borderRadius: BorderRadius.circular(WudgetTokens.radiusCard),
                child: InkWell(
                  key: Key('amountKey_$label'),
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(WudgetTokens.radiusCard),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 52),
                    alignment: Alignment.center,
                    child: icon == null ? Text(label, style: text.titleLarge) : Icon(icon),
                  ),
                ),
              ),
            ),
          ),
        );
    Widget digit(int d) => key('$d', () => _type((a) => a * 10 + d));

    // Scrolls only when it has to: at 200% text the keypad outgrows a phone.
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(WudgetTokens.space4, WudgetTokens.space4, WudgetTokens.space4, WudgetTokens.space3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title, style: text.labelMedium?.copyWith(color: tokens.ink2)),
            const SizedBox(height: WudgetTokens.space1),
            Text(widget.subtitle, style: text.bodyMedium?.copyWith(color: tokens.ink2)),
            const SizedBox(height: WudgetTokens.space2),
            AmountText(minor: _amount, style: text.headlineMedium?.copyWith(fontSize: 40)),
            if (choices != null) ...[
              const SizedBox(height: WudgetTokens.space3),
              Text('Berlaku', style: text.labelMedium?.copyWith(color: tokens.ink2)),
              const SizedBox(height: WudgetTokens.space2),
              Wrap(
                spacing: WudgetTokens.space2,
                runSpacing: WudgetTokens.space2,
                children: [
                  ChoiceChip(
                    label: Text('Hari ini sampai ${endLabel(choices.coming)}'),
                    selected: _end == choices.coming,
                    onSelected: (_) => setState(() => _end = choices.coming),
                  ),
                  ChoiceChip(
                    label: Text('Sampai ${endLabel(choices.later)}'),
                    selected: _end == choices.later,
                    onSelected: (_) => setState(() => _end = choices.later),
                  ),
                ],
              ),
            ],
            const SizedBox(height: WudgetTokens.space3),
            for (final row in const [[1, 2, 3], [4, 5, 6], [7, 8, 9]]) Row(children: [for (final d in row) digit(d)]),
            Row(children: [
              key('000', () => _type((a) => a * 1000)),
              digit(0),
              key('⌫', () => setState(() => _amount ~/= 10), semantics: 'Hapus', icon: Icons.backspace_outlined),
            ]),
            const SizedBox(height: WudgetTokens.space3),
            FilledButton(
              onPressed: _amount <= 0
                  ? null
                  : () => Navigator.of(context).pop((amountMinor: _amount, endDayExclusive: _end)),
              child: Text(widget.buttonLabel),
            ),
          ],
        ),
      ),
    );
  }
}

/// Screen 4b. "Uang periode ini" is one number; the kantong are filled from
/// the last budget (or the proposal) and the rest goes to Tabungan, so there
/// is nothing left to divide. A row opens an editor only when tapped.
class BudgetReviewScreen extends ConsumerStatefulWidget {
  const BudgetReviewScreen({
    super.key,
    required this.period,
    required this.newMoneyMinor,
    required this.leftoverMinor,
    this.customPeriod = false,
  });

  final Period period;
  final int newMoneyMinor;
  final int leftoverMinor;

  /// "Atur sekarang": accepting also stores this period as the custom one.
  final bool customPeriod;

  @override
  ConsumerState<BudgetReviewScreen> createState() => _BudgetReviewScreenState();
}

class _ReviewRow {
  const _ReviewRow(this.name, this.hueIndex);
  final String name;
  final int? hueIndex;
}

class _BudgetReviewScreenState extends ConsumerState<BudgetReviewScreen> {
  AsyncValue<({Map<String, int> kantong, Map<String, _ReviewRow> rows, bool fromLastBudget})> _data =
      const AsyncLoading();
  bool _edited = false;
  bool _saving = false;

  int get _total => widget.newMoneyMinor + widget.leftoverMinor;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _data = const AsyncLoading());
    final data = await AsyncValue.guard(() async {
      final history = ref.read(budgetHistoryQueriesProvider);
      final saved = {...await ref.read(budgetsRepositoryProvider).getAll()}..remove(tabunganCategoryId);
      final fromLastBudget = saved.values.any((v) => v > 0);
      final kantong = fromLastBudget ? saved : await _proposal();
      final db = ref.read(databaseProvider);
      final categories = {for (final c in await db.select(db.categories).get()) c.id: c};
      final rows = {
        for (final key in kantong.keys)
          key: _ReviewRow(await history.displayNameFor(key), categories[key]?.hueIndex),
      };
      return (kantong: kantong, rows: rows, fromLastBudget: fromLastBudget);
    });
    if (mounted) setState(() => _data = data);
  }

  /// Same proposal BudgetScreen opens with, sized to this period's length.
  Future<Map<String, int>> _proposal() async {
    final today = todayDayBucket();
    final firstDay = await ref.read(periodAggregateQueriesProvider).firstTransactionDay();
    if (firstDay == null) return {};
    final since = firstDay > today - _lookbackDays + 1 ? firstDay : today - _lookbackDays + 1;
    return proposeBudgets(
      spendByKey: await ref.read(budgetHistoryQueriesProvider).categorySpendByKey(since, today + 1),
      historyWindowDays: today - since + 1,
      periodLengthDays: widget.period.endDayExclusive - widget.period.startDay,
    );
  }

  Future<void> _editRow(String key, String name, int current) async {
    final result = await showAmountSheet(
      context,
      title: name,
      subtitle: 'Sisanya otomatis masuk Tabungan.',
      buttonLabel: 'Pakai jumlah ini',
      initialMinor: current,
    );
    if (result == null || !mounted) return;
    final data = _data.valueOrNull!;
    setState(() {
      data.kantong[key] = result.amountMinor;
      _edited = true;
    });
  }

  Future<void> _accept() async {
    setState(() => _saving = true);
    final db = ref.read(databaseProvider);
    final placed = placeEveryRupiah(_total, _data.valueOrNull!.kantong);
    await db.into(db.categories).insert(
          CategoriesCompanion.insert(
            id: tabunganCategoryId,
            name: 'Tabungan',
            kind: 'expense',
            iconKey: 'savings',
            hueIndex: 1,
            sortOrder: 99,
            updatedAt: DateTime.now().toUtc().millisecondsSinceEpoch,
          ),
          mode: InsertMode.insertOrIgnore,
        );
    final budgets = ref.read(budgetsRepositoryProvider);
    final closing = await ref.read(settingsRepositoryProvider).effectivePeriodFor(widget.period.startDay - 1);
    await budgets.snapshotFor(closing.startDay);
    for (final e in placed.entries) {
      await budgets.setAmount(e.key, e.value);
    }
    if (widget.customPeriod) {
      await ref.read(settingsRepositoryProvider).setCustomPeriod(widget.period.startDay, widget.period.endDayExclusive, widget.newMoneyMinor);
    }
    await ref.read(analyticsRepositoryProvider).logEvent('budget_review_accept', props: {
      'source': widget.customPeriod ? 'set_now' : 'payday',
      'totalMinor': _total,
      'edited': _edited,
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Anggaran baru dipakai')));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final text = Theme.of(context).textTheme;
    final p = widget.period;

    return Scaffold(
      appBar: AppBar(title: const Text('Anggaran baru')),
      body: switch (_data) {
        AsyncData(:final value) => Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(WudgetTokens.space4, 0, WudgetTokens.space4, WudgetTokens.space4),
                  children: [
                    Text('${_shortDate.format(p.startDate)} sampai ${_shortDate.format(p.lastDate)}',
                        style: text.bodyMedium?.copyWith(color: tokens.ink2)),
                    const SizedBox(height: WudgetTokens.space3),
                    WudgetCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Uang periode ini', style: text.labelMedium?.copyWith(color: tokens.ink2)),
                          const SizedBox(height: WudgetTokens.space1),
                          AmountText(minor: _total, style: text.headlineMedium?.copyWith(fontSize: 34)),
                          if (widget.leftoverMinor > 0) ...[
                            const SizedBox(height: WudgetTokens.space1),
                            Text(
                              'Gaji ${_rp(widget.newMoneyMinor)} dan sisa periode lalu ${_rp(widget.leftoverMinor)}',
                              style: text.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: WudgetTokens.space4),
                    Padding(
                      padding: const EdgeInsets.only(left: WudgetTokens.space1, bottom: WudgetTokens.space2),
                      child: Text(
                        value.fromLastBudget
                            ? 'Sama seperti periode lalu. Ketuk untuk ubah.'
                            : 'Dari pengeluaranmu sendiri. Ketuk untuk ubah.',
                        style: text.labelMedium?.copyWith(color: tokens.ink2),
                      ),
                    ),
                    CardGroup(children: _rowsFor(value.kantong, value.rows, tokens, text)),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(WudgetTokens.space4, 0, WudgetTokens.space4, WudgetTokens.space4),
                  child: Row(children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: _saving ? null : _accept,
                        child: const Text('Pakai anggaran ini'),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        AsyncError() => Center(
            child: Padding(
              padding: const EdgeInsets.all(WudgetTokens.space4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Anggaran belum bisa dimuat.', style: text.bodyLarge),
                  TextButton(onPressed: _load, child: const Text('Coba lagi')),
                ],
              ),
            ),
          ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }

  List<Widget> _rowsFor(Map<String, int> kantong, Map<String, _ReviewRow> rows, WudgetTokens tokens, TextTheme text) {
    final placed = placeEveryRupiah(_total, kantong);
    final keys = placed.keys.where((k) => k != tabunganCategoryId && placed[k]! > 0).toList()
      ..sort((a, b) => placed[b]!.compareTo(placed[a]!));

    Widget row(String name, int amount, int? hue, {String? note, VoidCallback? onTap}) => InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: WudgetTokens.space4, vertical: WudgetTokens.space3),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: hue == null ? tokens.surfaceMuted : tokens.inkFor(hue),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: WudgetTokens.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: text.titleSmall?.copyWith(fontSize: 14)),
                        if (note != null) Text(note, style: text.bodySmall),
                      ],
                    ),
                  ),
                  AmountText(minor: amount, showSymbol: false, style: text.titleSmall?.copyWith(fontSize: 14)),
                ],
              ),
            ),
          ),
        );

    return [
      for (final k in keys)
        row(rows[k]?.name ?? k, placed[k]!, rows[k]?.hueIndex,
            onTap: () => _editRow(k, rows[k]?.name ?? k, placed[k]!)),
      row('Tabungan', placed[tabunganCategoryId]!, 1,
          note: widget.leftoverMinor > 0 ? 'termasuk sisa ${_rp(widget.leftoverMinor)}' : 'sisa yang belum dipakai'),
    ];
  }
}
