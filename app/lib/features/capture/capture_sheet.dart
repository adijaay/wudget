import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/currency.dart';
import '../../core/money.dart';
import '../../core/money_formatter.dart';
import '../../core/providers.dart';
import '../../data/database.dart';
import '../../design/tokens.dart';

const _uuid = Uuid();

enum _Kind { expense, income, transfer }

/// The capture sheet: the one screen the product lives or dies on. See
/// plan/04-ux-design.md "The capture sheet, specified" for the full spec —
/// this sprint (3) covers structure and a real save; templates, calculator
/// toggle and receipt photo are Sprint 4.
class CaptureSheet extends ConsumerStatefulWidget {
  const CaptureSheet({super.key});

  @override
  ConsumerState<CaptureSheet> createState() => _CaptureSheetState();
}

class _CaptureSheetState extends ConsumerState<CaptureSheet> {
  _Kind _kind = _Kind.expense;
  String _amountBuffer = '';
  String? _categoryId;
  String? _subcategoryId;

  static const _formatter = MoneyFormatter();
  static const _currency = 'IDR'; // only currency seeded so far; see Sprint 5

  Money get _amount {
    final major = _amountBuffer.isEmpty ? 0 : num.parse(_amountBuffer);
    return Money.fromMajor(major, _currency);
  }

  void _appendDigit(String d) {
    setState(() => _amountBuffer += d);
  }

  void _appendZeros() {
    if (_amountBuffer.isEmpty) return; // "000" on nothing does nothing
    setState(() => _amountBuffer += '000');
  }

  void _backspace() {
    if (_amountBuffer.isEmpty) return;
    setState(() => _amountBuffer = _amountBuffer.substring(0, _amountBuffer.length - 1));
  }

  Future<void> _save() async {
    if (_kind == _Kind.transfer) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transfer belum tersedia — datang di Sprint 5')),
      );
      return;
    }
    if (_amount.isZero || _categoryId == null) return;

    final db = ref.read(databaseProvider);
    final account = await db.select(db.accounts).getSingle();
    final categoryLeg = _subcategoryId ?? _categoryId!;
    final txId = _uuid.v4();
    final now = DateTime.now();

    // Expense: account leg negative, category leg positive.
    // Income: account leg positive, category leg negative.
    final sign = _kind == _Kind.expense ? -1 : 1;

    await ref.read(postingsRepositoryProvider).insertTransaction(
      transaction: TransactionsCompanion.insert(
        id: txId,
        kind: _kind == _Kind.expense ? 'expense' : 'income',
        occurredAt: now.toUtc().millisecondsSinceEpoch,
        tzOffsetMinutes: now.timeZoneOffset.inMinutes,
        updatedAt: now.toUtc().millisecondsSinceEpoch,
      ),
      postings: [
        PostingsCompanion.insert(
          id: _uuid.v4(),
          transactionId: txId,
          accountId: Value(account.id),
          amountMinor: sign * _amount.minor,
          currency: _currency,
          baseAmountMinor: sign * _amount.minor,
        ),
        PostingsCompanion.insert(
          id: _uuid.v4(),
          transactionId: txId,
          categoryId: Value(categoryLeg),
          amountMinor: -sign * _amount.minor,
          currency: _currency,
          baseAmountMinor: -sign * _amount.minor,
        ),
      ],
    );

    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tersimpan: ${_formatter.format(_amount)}'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => db.transaction(() async {
            await (db.delete(db.postings)..where((p) => p.transactionId.equals(txId))).go();
            await (db.delete(db.transactions)..where((t) => t.id.equals(txId))).go();
          }),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final db = ref.watch(databaseProvider);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(WudgetTokens.radiusSheet)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  WudgetTokens.space4,
                  WudgetTokens.space3,
                  WudgetTokens.space4,
                  0,
                ),
                child: _TypeSegments(
                  kind: _kind,
                  onChanged: (k) => setState(() {
                    _kind = k;
                    _categoryId = null;
                    _subcategoryId = null;
                  }),
                ),
              ),
              if (_kind != _Kind.transfer)
                StreamBuilder<List<Category>>(
                  stream: (db.select(db.categories)
                        ..where((c) => c.kind.equals(_kind == _Kind.expense ? 'expense' : 'income'))
                        ..where((c) => c.parentId.isNull())
                        ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
                      .watch(),
                  builder: (context, snapshot) {
                    final categories = snapshot.data ?? const [];
                    return _CategoryRow(
                      categories: categories,
                      tokens: tokens,
                      selectedId: _categoryId,
                      onSelected: (id) => setState(() {
                        _categoryId = id;
                        _subcategoryId = null;
                      }),
                    );
                  },
                ),
              if (_categoryId != null)
                StreamBuilder<List<Category>>(
                  stream: (db.select(db.categories)..where((c) => c.parentId.equals(_categoryId!)))
                      .watch(),
                  builder: (context, snapshot) {
                    final subcategories = snapshot.data ?? const [];
                    if (subcategories.isEmpty) return const SizedBox.shrink();
                    return _SubcategoryChips(
                      subcategories: subcategories,
                      selectedId: _subcategoryId,
                      onSelected: (id) => setState(() => _subcategoryId = id),
                    );
                  },
                ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: WudgetTokens.space5),
                child: Text(
                  _formatter.format(_amount),
                  semanticsLabel: 'Jumlah: ${_formatter.format(_amount)}',
                  style: Theme.of(context)
                      .textTheme
                      .displaySmall
                      ?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                ),
              ),
              _Numpad(
                showDecimal: CurrencyInfo.of(_currency).exponent > 0,
                showZeros: CurrencyInfo.of(_currency).exponent == 0,
                onDigit: _appendDigit,
                onZeros: _appendZeros,
                onBackspace: _backspace,
                onSave: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeSegments extends StatelessWidget {
  const _TypeSegments({required this.kind, required this.onChanged});
  final _Kind kind;
  final ValueChanged<_Kind> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<_Kind>(
      segments: const [
        ButtonSegment(value: _Kind.expense, label: Text('Pengeluaran')),
        ButtonSegment(value: _Kind.income, label: Text('Pemasukan')),
        ButtonSegment(value: _Kind.transfer, label: Text('Transfer')),
      ],
      selected: {kind},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.categories,
    required this.tokens,
    required this.selectedId,
    required this.onSelected,
  });
  final List<Category> categories;
  final WudgetTokens tokens;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: WudgetTokens.space4, vertical: WudgetTokens.space2),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: WudgetTokens.space2),
        itemBuilder: (context, i) {
          final c = categories[i];
          final selected = c.id == selectedId;
          return ChoiceChip(
            label: Text(c.name),
            selected: selected,
            avatar: CircleAvatar(
              radius: 8,
              backgroundColor: tokens.categoryHues[c.hueIndex % tokens.categoryHues.length],
            ),
            onSelected: (_) => onSelected(c.id),
          );
        },
      ),
    );
  }
}

class _SubcategoryChips extends StatelessWidget {
  const _SubcategoryChips({
    required this.subcategories,
    required this.selectedId,
    required this.onSelected,
  });
  final List<Category> subcategories;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: WudgetTokens.space4),
        itemCount: subcategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: WudgetTokens.space2),
        itemBuilder: (context, i) {
          final s = subcategories[i];
          return ChoiceChip(
            label: Text(s.name),
            selected: s.id == selectedId,
            onSelected: (_) => onSelected(s.id),
          );
        },
      ),
    );
  }
}

class _Numpad extends StatelessWidget {
  const _Numpad({
    required this.showDecimal,
    required this.showZeros,
    required this.onDigit,
    required this.onZeros,
    required this.onBackspace,
    required this.onSave,
  });
  final bool showDecimal;
  final bool showZeros;
  final void Function(String) onDigit;
  final VoidCallback onZeros;
  final VoidCallback onBackspace;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final rows = <List<Widget>>[
      [_key('1', () => onDigit('1')), _key('2', () => onDigit('2')), _key('3', () => onDigit('3')),
       _key('⌫', onBackspace, semanticLabel: 'Hapus')],
      [_key('4', () => onDigit('4')), _key('5', () => onDigit('5')), _key('6', () => onDigit('6')),
       const SizedBox.shrink()],
      [_key('7', () => onDigit('7')), _key('8', () => onDigit('8')), _key('9', () => onDigit('9')),
       const SizedBox.shrink()],
      [
        showDecimal ? _key('.', () => onDigit('.')) : const SizedBox.shrink(),
        _key('0', () => onDigit('0')),
        showZeros ? _key('000', onZeros) : const SizedBox.shrink(),
        _key('✓', onSave, semanticLabel: 'Simpan'),
      ],
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: WudgetTokens.space2, vertical: WudgetTokens.space2),
      child: Column(
        children: [for (final row in rows) Row(children: [for (final k in row) Expanded(child: k)])],
      ),
    );
  }

  Widget _key(String label, VoidCallback onTap, {String? semanticLabel}) {
    return Semantics(
      label: semanticLabel ?? label,
      button: true,
      child: SizedBox(
        height: 56,
        child: TextButton(
          onPressed: onTap,
          child: Text(label, style: const TextStyle(fontSize: 20)),
        ),
      ),
    );
  }
}
