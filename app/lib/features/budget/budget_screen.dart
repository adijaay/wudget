import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../core/money_formatter.dart';
import '../../core/providers.dart';
import '../../data/budget_history_queries.dart';
import '../../design/components.dart';
import '../../design/tokens.dart';
import '../../domain/budget_proposal.dart';
import '../payday/budget_review_screen.dart';

const _formatter = MoneyFormatter();
const _lookbackDays = 28;

int _todayDayBucket() {
  final now = DateTime.now();
  return DateTime.utc(now.year, now.month, now.day)
      .difference(DateTime.utc(1970, 1, 1))
      .inDays;
}

class _BudgetRow {
  _BudgetRow({
    required this.key,
    required this.name,
    required this.amountMinor,
    required this.spentMinor,
    required this.lookbackSpendMinor,
    required this.lookbackDays,
    this.iconKey,
    this.hueIndex,
  });
  final String key;
  final String name;
  final int amountMinor;
  final int spentMinor;

  /// What the proposal was derived from, so a row can say where its number
  /// came from instead of presenting it as an opinion.
  final int lookbackSpendMinor;
  final int lookbackDays;
  final String? iconKey;
  final int? hueIndex;

  bool get isIrregular => key == irregularBudgetKey;

  _BudgetRow withAmount(int minor) => _BudgetRow(
        key: key,
        name: name,
        amountMinor: minor,
        spentMinor: spentMinor,
        lookbackSpendMinor: lookbackSpendMinor,
        lookbackDays: lookbackDays,
        iconKey: iconKey,
        hueIndex: hueIndex,
      );
}

/// Budget review and edit: every row starts pre-filled from
/// [proposeBudgets], the user edits rather than authors — plan/05-sprints.md
/// Sprint 10, laid out to design/BudgetProposal.dc.html. A category with no
/// spend history in the lookback window (and no budget already saved) has
/// nothing honest to propose, so it simply isn't a row — "no user is ever
/// shown a blank budget field" means never shown blank, not shown
/// blank-then-filled.
class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  List<_BudgetRow>? _rows;
  int _incomeMinor = 0;
  bool _anySaved = false;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// The manual fallback for a change the load missed. Logged so a dogfooding
  /// pass can tell whether the automatic path ever needs it.
  Future<void> _refresh() {
    ref
        .read(analyticsRepositoryProvider)
        .logEvent('pull_to_refresh', props: {'screen': 'kantong'});
    return _load();
  }

  Future<void> _load() async {
    final period = ref.read(currentPeriodProvider);
    final periodLengthDays = period.endDayExclusive - period.startDay;
    final today = _todayDayBucket();

    final aggregateQueries = ref.read(periodAggregateQueriesProvider);
    final historyQueries = ref.read(budgetHistoryQueriesProvider);
    final budgetsRepo = ref.read(budgetsRepositoryProvider);
    final db = ref.read(databaseProvider);

    final firstDay = await aggregateQueries.firstTransactionDay();
    final sinceDay = firstDay == null
        ? today + 1
        : (firstDay > today - _lookbackDays + 1
            ? firstDay
            : today - _lookbackDays + 1);
    final historyWindowDays = firstDay == null ? 0 : today - sinceDay + 1;

    final lookbackSpend = firstDay == null
        ? <String, int>{}
        : await historyQueries.categorySpendByKey(sinceDay, today + 1);
    final proposals = proposeBudgets(
      spendByKey: lookbackSpend,
      historyWindowDays: historyWindowDays,
      periodLengthDays: periodLengthDays,
    );
    final saved = await budgetsRepo.getAll();
    final currentSpend = await historyQueries.categorySpendByKey(
        period.startDay, period.endDayExclusive);
    final totals = await aggregateQueries.totalsFor(period);
    final categories = {
      for (final c in await db.select(db.categories).get()) c.id: c
    };

    // Every top-level expense category gets a row, not just the ones with
    // spend history or a saved amount. A category with no history still
    // gets no *proposed* number (proposeBudgets rightly refuses to guess
    // one — see its own doc comment), but it does get a listing and an
    // honest Rp 0 the user can type over themselves. Those are different
    // things: the app never invents a number, but the user setting one for
    // a category they haven't used yet is their input, not a guess.
    final allExpenseKeys = {
      for (final c in categories.values)
        if (c.kind == 'expense' && c.parentId == null && !c.isIrregular) c.id,
    };

    final keys = {...allExpenseKeys, ...proposals.keys, ...saved.keys}.toList()
      ..sort((a, b) {
        if (a == irregularBudgetKey) return 1;
        if (b == irregularBudgetKey) return -1;
        return 0;
      });

    final rows = <_BudgetRow>[];
    for (final key in keys) {
      final category = categories[key];
      rows.add(_BudgetRow(
        key: key,
        name: await historyQueries.displayNameFor(key),
        amountMinor: saved[key] ?? proposals[key] ?? 0,
        spentMinor: currentSpend[key] ?? 0,
        lookbackSpendMinor: lookbackSpend[key] ?? 0,
        lookbackDays: historyWindowDays,
        iconKey: category?.iconKey,
        hueIndex: category?.hueIndex,
      ));
    }

    if (!mounted) return;
    setState(() {
      _rows = rows;
      _incomeMinor = totals.incomeMinor;
      _anySaved = saved.isNotEmpty;
    });
  }

  void _edit(String key, int amountMinor) {
    setState(() {
      _rows = [
        for (final r in _rows!) r.key == key ? r.withAmount(amountMinor) : r
      ];
      _dirty = true;
    });
  }

  /// Saved as one action rather than field by field: the proposal is a set
  /// of numbers that only makes sense together, and its total is what the
  /// footer is asking the user to accept. The whole previous set is kept so
  /// one tap can put it back, since a save overwrites every row at once.
  Future<void> _saveAll() async {
    final repo = ref.read(budgetsRepositoryProvider);
    final previous = await repo.getAll();
    for (final row in _rows!) {
      await repo.setAmount(row.key, row.amountMinor);
    }
    if (!mounted) return;
    setState(() {
      _anySaved = true;
      _dirty = false;
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: const Text('Anggaran disimpan'),
        action: SnackBarAction(
          label: 'Batalkan',
          onPressed: () async {
            for (final entry in previous.entries) {
              await repo.setAmount(entry.key, entry.value);
            }
            // A key that did not exist before the save has nothing to go
            // back to, so it is one the undo has to clear rather than set.
            final added =
                _rows!.map((r) => r.key).where((k) => !previous.containsKey(k));
            for (final key in added) {
              await repo.clearAmount(key);
            }
            if (!mounted) return;
            setState(() {
              _anySaved = previous.isNotEmpty;
              _dirty = false;
            });
            _load();
          },
        ),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Anggaran'),
        actions: [
          TextButton(
            onPressed: () async {
              await startSetNow(context, ref);
              if (mounted) _load();
            },
            child: const Text('Atur anggaran sekarang'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: switch (rows) {
          null => const Center(child: CircularProgressIndicator()),
          [] => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(WudgetTokens.space4),
              children: [
                WudgetCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Belum ada yang bisa diusulkan',
                          style: text.titleLarge),
                      const SizedBox(height: WudgetTokens.space2),
                      Text(
                        'Anggaran di sini diambil dari pengeluaranmu sendiri, jadi '
                        'catat dulu beberapa hari. Tidak ada angka tebakan.',
                        style: text.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          final filled => _ProposalBody(
              rows: filled,
              incomeMinor: _incomeMinor,
              anySaved: _anySaved,
              dirty: _dirty,
              onEdit: _edit,
              onSave: _saveAll,
            ),
        },
      ),
    );
  }
}

class _ProposalBody extends StatelessWidget {
  const _ProposalBody({
    required this.rows,
    required this.incomeMinor,
    required this.anySaved,
    required this.dirty,
    required this.onEdit,
    required this.onSave,
  });
  final List<_BudgetRow> rows;
  final int incomeMinor;
  final bool anySaved;
  final bool dirty;
  final void Function(String key, int amountMinor) onEdit;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final text = Theme.of(context).textTheme;
    final regular = rows.where((r) => !r.isIrregular).toList();
    final irregular = rows.where((r) => r.isIrregular).toList();
    final total = rows.fold<int>(0, (a, r) => a + r.amountMinor);
    final lookbackTotal = rows.fold<int>(0, (a, r) => a + r.lookbackSpendMinor);
    final lookbackDays = rows.isEmpty ? 0 : rows.first.lookbackDays;

    return Column(
      children: [
        Expanded(
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              WudgetTokens.space4,
              0,
              WudgetTokens.space4,
              WudgetTokens.space4,
            ),
            children: [
              if (!anySaved) ...[
                // The first time, this screen is a proposal to accept, so it
                // opens by saying where the numbers came from.
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: WudgetTokens.space3,
                    vertical: WudgetTokens.space2,
                  ),
                  decoration: BoxDecoration(
                    color: tokens.accent.withOpacity(0.12),
                    borderRadius:
                        BorderRadius.circular(WudgetTokens.radiusPill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome_motion_outlined,
                          size: 14, color: tokens.accent),
                      const SizedBox(width: WudgetTokens.space2),
                      Text(
                        'DARI RIWAYATMU',
                        style: text.labelMedium?.copyWith(color: tokens.accent),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: WudgetTokens.space3),
                Text('Ini anggaran dari kebiasaanmu sendiri',
                    style: text.headlineMedium),
                const SizedBox(height: WudgetTokens.space2),
                Text(
                  lookbackDays > 0
                      ? '$lookbackDays hari terakhir kamu keluar '
                          '${_formatter.format(Money.fromMinor(lookbackTotal, 'IDR'))}. Angka di bawah '
                          'diambil dari situ, bukan tebakan. Ubah yang kerasa kurang pas.'
                      : 'Angka di bawah diambil dari pengeluaranmu sendiri. Ubah yang kerasa kurang pas.',
                  style: text.bodyMedium,
                ),
                const SizedBox(height: WudgetTokens.space4),
              ],
              CardGroup(
                dividerIndent: 58,
                children: [
                  for (final row in regular)
                    _BudgetRowTile(row: row, onEdit: onEdit),
                ],
              ),
              for (final row in irregular) ...[
                const SizedBox(height: WudgetTokens.space3),
                // The exceptional bucket, proposed by default: one pot so the
                // wedding invitations and the bike service stop being
                // surprises every single month.
                WudgetCard(
                  dashed: true,
                  padding: const EdgeInsets.all(WudgetTokens.space3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _BudgetRowTile(row: row, onEdit: onEdit, padded: false),
                      const SizedBox(height: WudgetTokens.space2),
                      Text(
                        'Kondangan, servis motor, kado, obat. Yang begini selalu '
                        'kerasa dadakan, padahal tiap bulan ada. Satu pos biar tidak ngagetin.',
                        style: text.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        // The total and the action stay pinned: the number being accepted is
        // the sum, not any one row.
        Container(
          decoration: BoxDecoration(
            color: tokens.surfaceCard,
            border: Border(top: BorderSide(color: tokens.border)),
          ),
          padding: EdgeInsets.fromLTRB(
            WudgetTokens.space4,
            WudgetTokens.space3,
            WudgetTokens.space4,
            // As the Kantong tab, the docked capture button overhangs this bar.
            WudgetTokens.space3 + (Navigator.of(context).canPop() ? 0 : 40),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Total anggaran periode ini', style: text.titleMedium),
                    AmountText(
                        minor: total,
                        style: text.titleLarge?.copyWith(fontSize: 18)),
                  ],
                ),
                // Only stated when income for this period is actually
                // recorded: "sisa buat ditabung" against an unknown income
                // would be an invented number (R-17).
                if (incomeMinor > 0) ...[
                  const SizedBox(height: WudgetTokens.space1),
                  Text(
                    'Dari pemasukan ${_formatter.format(Money.fromMinor(incomeMinor, 'IDR'))}, '
                    'sisa ${_formatter.format(Money.fromMinor(incomeMinor - total, 'IDR'))} buat ditabung.',
                    style: text.bodySmall,
                  ),
                ],
                const SizedBox(height: WudgetTokens.space3),
                Row(
                  children: [
                    if (!anySaved && Navigator.of(context).canPop()) ...[
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        child: const Text('Nanti saja'),
                      ),
                      const SizedBox(width: WudgetTokens.space2),
                    ],
                    Expanded(
                      child: FilledButton(
                        onPressed: anySaved && !dirty ? null : onSave,
                        child: Text(anySaved
                            ? 'Simpan perubahan'
                            : 'Pakai anggaran ini'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BudgetRowTile extends StatefulWidget {
  const _BudgetRowTile(
      {required this.row, required this.onEdit, this.padded = true});
  final _BudgetRow row;
  final void Function(String key, int amountMinor) onEdit;
  final bool padded;

  @override
  State<_BudgetRowTile> createState() => _BudgetRowTileState();
}

class _BudgetRowTileState extends State<_BudgetRowTile> {
  late final TextEditingController _controller =
      TextEditingController(text: _grouped(widget.row.amountMinor));

  /// Grouped as the user types, so a budget field reads like every other
  /// amount in the app rather than as a raw run of digits. The symbol is the
  /// field's own prefix, so only the digits are formatted here.
  static String _grouped(int minor) =>
      _formatter.format(Money.fromMinor(minor, 'IDR'), showSymbol: false);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final text = Theme.of(context).textTheme;
    final row = widget.row;
    final over = row.amountMinor > 0 && row.spentMinor > row.amountMinor;
    final hue = row.hueIndex;
    final perDay =
        row.lookbackDays <= 0 ? 0 : row.lookbackSpendMinor ~/ row.lookbackDays;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconChip(
              size: 30,
              icon: row.isIrregular
                  ? Icons.auto_awesome_outlined
                  : categoryIcon(row.iconKey ?? 'category'),
              background:
                  hue == null ? tokens.surfaceMuted : tokens.tintFor(hue),
              foreground: hue == null ? tokens.ink2 : tokens.inkFor(hue),
            ),
            const SizedBox(width: WudgetTokens.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(row.name,
                      style: text.titleSmall?.copyWith(fontSize: 14)),
                  if (perDay > 0) ...[
                    const SizedBox(height: 1),
                    Text(
                      'rata-rata ${_formatter.format(Money.fromMinor(perDay, 'IDR'))} per hari',
                      style: text.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: WudgetTokens.space2),
            SizedBox(
              width: 116,
              child: TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                  prefixText: 'Rp ',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: WudgetTokens.space2,
                    vertical: WudgetTokens.space2,
                  ),
                ),
                style: text.titleSmall?.copyWith(
                  fontSize: 14,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                onChanged: (v) {
                  final minor =
                      int.tryParse(v.replaceAll(RegExp(r'[^0-9]'), ''));
                  if (minor == null) return;
                  widget.onEdit(row.key, minor);
                  final formatted = _grouped(minor);
                  if (formatted != v) {
                    // Re-group as they type, keeping the caret at the end
                    // (money is typed left to right, never inserted into).
                    _controller.value = TextEditingValue(
                      text: formatted,
                      selection:
                          TextSelection.collapsed(offset: formatted.length),
                    );
                  }
                },
              ),
            ),
          ],
        ),
        // Progress against this period's actual spend, with the overspend
        // named in words as well as coloured (chart rule 7).
        if (row.spentMinor > 0) ...[
          const SizedBox(height: WudgetTokens.space2),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: row.amountMinor <= 0
                  ? 0
                  : (row.spentMinor / row.amountMinor).clamp(0.0, 1.0),
              minHeight: 6,
              color: over ? tokens.warning : tokens.accent,
              backgroundColor: tokens.surfaceMuted,
            ),
          ),
          const SizedBox(height: WudgetTokens.space1),
          Row(
            children: [
              if (over) ...[
                Icon(Icons.priority_high, size: 14, color: tokens.warning),
                const SizedBox(width: 2),
              ],
              Text(
                over
                    ? 'lewat ${_formatter.format(Money.fromMinor(row.spentMinor - row.amountMinor, 'IDR'))} dari anggaran'
                    : '${_formatter.format(Money.fromMinor(row.spentMinor, 'IDR'))} terpakai periode ini',
                style: text.bodySmall
                    ?.copyWith(color: over ? tokens.warning : tokens.ink2),
              ),
            ],
          ),
        ],
      ],
    );

    if (!widget.padded) return content;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: WudgetTokens.space3,
        vertical: WudgetTokens.space3,
      ),
      child: content,
    );
  }
}
