import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/currency.dart';
import '../../core/money.dart';
import '../../core/money_formatter.dart';
import '../../core/providers.dart';
import '../../data/capture_queries.dart';
import '../../data/database.dart';
import '../../design/tokens.dart';

const _uuid = Uuid();

enum CaptureKind { expense, income, transfer }

/// The capture sheet: the one screen the product lives or dies on. See
/// plan/04-ux-design.md "The capture sheet, specified" for the full spec.
/// Sprint 3 built structure and a real save; this (Sprint 4) adds the
/// three-tap path: frequency templates, per-category wallet default, the
/// calculator toggle, an in-sheet date/time button, a collapsed note field
/// and a receipt photo.
class CaptureSheet extends ConsumerStatefulWidget {
  const CaptureSheet({
    super.key,
    this.initialKind = CaptureKind.expense,
    this.initialToAccountId,
    this.initialAmountMinor,
  });

  /// Lets a caller (e.g. the card "Bayar" button in Kantong) open the sheet
  /// pre-filled as a transfer, rather than every screen needing its own
  /// mini transfer form.
  final CaptureKind initialKind;
  final String? initialToAccountId;
  final int? initialAmountMinor;

  @override
  ConsumerState<CaptureSheet> createState() => _CaptureSheetState();
}

class _CaptureSheetState extends ConsumerState<CaptureSheet> {
  late CaptureKind _kind = widget.initialKind;
  String _amountBuffer = '';
  String? _categoryId;
  String? _subcategoryId;
  String? _accountId;
  late String? _toAccountId = widget.initialToAccountId;
  bool _calculatorMode = false;
  bool _noteExpanded = false;
  final _noteController = TextEditingController();
  DateTime _occurredAt = DateTime.now();
  String? _photoPath;
  late Future<List<CaptureTemplate>> _templatesFuture;

  static const _formatter = MoneyFormatter();
  static const _currency = 'IDR'; // only currency seeded so far; see Sprint 5
  static final _dateFormat = DateFormat('d MMM', 'id_ID');

  @override
  void initState() {
    super.initState();
    if (widget.initialAmountMinor != null) {
      final info = CurrencyInfo.of(_currency);
      _amountBuffer = info.exponent == 0
          ? widget.initialAmountMinor!.toString()
          : (widget.initialAmountMinor! / info.minorUnitsPerMajor).toString();
    }
    _loadTemplates();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _loadTemplates() {
    _templatesFuture = ref
        .read(captureQueriesProvider)
        .topTemplates(_kind == CaptureKind.expense ? 'expense' : 'income');
  }

  /// The buffer may hold a calculator expression like "15000+5000". Left to
  /// right, no operator precedence — a plain-calculator rule, not a
  /// scientific one. ponytail: revisit if users ask for precedence.
  num _evaluateBuffer() {
    if (_amountBuffer.isEmpty) return 0;
    final tokens = _amountBuffer.split(RegExp(r'(?<=[+\-×÷])|(?=[+\-×÷])'));
    num result = num.tryParse(tokens.first) ?? 0;
    for (var i = 1; i < tokens.length - 1; i += 2) {
      final op = tokens[i];
      final operand = num.tryParse(tokens[i + 1]) ?? 0;
      result = switch (op) {
        '+' => result + operand,
        '-' => result - operand,
        '×' => result * operand,
        '÷' => operand == 0 ? result : result / operand,
        _ => result,
      };
    }
    return result;
  }

  Money get _amount => Money.fromMajor(_evaluateBuffer(), _currency);

  bool get _bufferEndsWithOperator =>
      _amountBuffer.isNotEmpty && '+-×÷'.contains(_amountBuffer[_amountBuffer.length - 1]);

  void _appendDigit(String d) => setState(() => _amountBuffer += d);

  void _appendZeros() {
    if (_amountBuffer.isEmpty || _bufferEndsWithOperator) return;
    setState(() => _amountBuffer += '000');
  }

  void _appendOperator(String op) {
    if (_amountBuffer.isEmpty || _bufferEndsWithOperator) return;
    setState(() => _amountBuffer += op);
  }

  void _backspace() {
    if (_amountBuffer.isEmpty) return;
    setState(() => _amountBuffer = _amountBuffer.substring(0, _amountBuffer.length - 1));
  }

  Future<void> _applyTemplate(CaptureTemplate template) async {
    setState(() {
      _categoryId = template.categoryId;
      _accountId = template.accountId;
      _amountBuffer = template.lastAmountMinor.toString();
    });
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _occurredAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_occurredAt),
    );
    if (time == null) return;
    setState(() {
      _occurredAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _pickReceiptPhoto() async {
    try {
      final photo = await ImagePicker().pickImage(source: ImageSource.camera);
      if (photo != null) setState(() => _photoPath = photo.path);
    } catch (_) {
      // No camera available (emulator, denied permission, desktop test) —
      // the photo is optional, so failing quietly is correct here.
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Kamera tidak tersedia')));
      }
    }
  }

  Future<void> _save() async {
    final db = ref.read(databaseProvider);
    final txId = _uuid.v4();
    final now = DateTime.now();

    if (_kind == CaptureKind.transfer) {
      if (_amount.isZero || _accountId == null || _toAccountId == null || _accountId == _toAccountId) {
        return;
      }
      // Transfer: from-account negative, to-account positive, no category
      // leg — that absence is what keeps a transfer (including a card
      // payment) out of spending statistics. See spending_queries.dart.
      await ref.read(postingsRepositoryProvider).insertTransaction(
        transaction: TransactionsCompanion.insert(
          id: txId,
          kind: 'transfer',
          occurredAt: _occurredAt.toUtc().millisecondsSinceEpoch,
          tzOffsetMinutes: _occurredAt.timeZoneOffset.inMinutes,
          note: _noteController.text.isEmpty ? const Value.absent() : Value(_noteController.text),
          updatedAt: now.toUtc().millisecondsSinceEpoch,
        ),
        postings: [
          PostingsCompanion.insert(
            id: _uuid.v4(),
            transactionId: txId,
            accountId: Value(_accountId!),
            amountMinor: -_amount.minor,
            currency: _currency,
            baseAmountMinor: -_amount.minor,
          ),
          PostingsCompanion.insert(
            id: _uuid.v4(),
            transactionId: txId,
            accountId: Value(_toAccountId!),
            amountMinor: _amount.minor,
            currency: _currency,
            baseAmountMinor: _amount.minor,
          ),
        ],
      );
    } else {
      if (_amount.isZero || _categoryId == null) return;
      final accountId = _accountId ?? (await db.select(db.accounts).getSingle()).id;
      final categoryLeg = _subcategoryId ?? _categoryId!;

      // Expense: account leg negative, category leg positive.
      // Income: account leg positive, category leg negative.
      final sign = _kind == CaptureKind.expense ? -1 : 1;

      await ref.read(postingsRepositoryProvider).insertTransaction(
        transaction: TransactionsCompanion.insert(
          id: txId,
          kind: _kind == CaptureKind.expense ? 'expense' : 'income',
          occurredAt: _occurredAt.toUtc().millisecondsSinceEpoch,
          tzOffsetMinutes: _occurredAt.timeZoneOffset.inMinutes,
          note: _noteController.text.isEmpty ? const Value.absent() : Value(_noteController.text),
          photoPath: _photoPath == null ? const Value.absent() : Value(_photoPath),
          updatedAt: now.toUtc().millisecondsSinceEpoch,
        ),
        postings: [
          PostingsCompanion.insert(
            id: _uuid.v4(),
            transactionId: txId,
            accountId: Value(accountId),
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
    }

    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tersimpan: ${_formatter.format(_amount)}'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => ref.read(postingsRepositoryProvider).undoInsert(txId),
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
                child: Row(
                  children: [
                    Expanded(
                      child: _TypeSegments(
                        kind: _kind,
                        onChanged: (k) => setState(() {
                          _kind = k;
                          _categoryId = null;
                          _subcategoryId = null;
                          _loadTemplates();
                        }),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Kamera struk',
                      onPressed: _pickReceiptPhoto,
                      icon: Icon(_photoPath == null ? Icons.camera_alt_outlined : Icons.camera_alt),
                    ),
                  ],
                ),
              ),
              if (_kind == CaptureKind.transfer)
                StreamBuilder<List<Account>>(
                  stream: db.select(db.accounts).watch(),
                  builder: (context, snapshot) {
                    final accounts = snapshot.data ?? const [];
                    if (accounts.length < 2) {
                      return const Padding(
                        padding: EdgeInsets.all(WudgetTokens.space4),
                        child: Text('Butuh minimal dua dompet untuk transfer.'),
                      );
                    }
                    _accountId ??= accounts.first.id;
                    _toAccountId ??= accounts.firstWhere(
                      (a) => a.id != _accountId,
                      orElse: () => accounts.last,
                    ).id;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: WudgetTokens.space4),
                      child: Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _accountId,
                              decoration: const InputDecoration(labelText: 'Dari'),
                              items: [
                                for (final a in accounts) DropdownMenuItem(value: a.id, child: Text(a.name)),
                              ],
                              onChanged: (id) => setState(() => _accountId = id),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: WudgetTokens.space2),
                            child: Icon(Icons.arrow_forward),
                          ),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _toAccountId,
                              decoration: const InputDecoration(labelText: 'Ke'),
                              items: [
                                for (final a in accounts) DropdownMenuItem(value: a.id, child: Text(a.name)),
                              ],
                              onChanged: (id) => setState(() => _toAccountId = id),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              if (_kind != CaptureKind.transfer)
                FutureBuilder<List<CaptureTemplate>>(
                  future: _templatesFuture,
                  builder: (context, snapshot) {
                    final templates = snapshot.data ?? const [];
                    if (templates.isEmpty) return const SizedBox.shrink();
                    return StreamBuilder<List<Category>>(
                      stream: db.select(db.categories).watch(),
                      builder: (context, categorySnapshot) {
                        final categoriesById = {
                          for (final c in categorySnapshot.data ?? const <Category>[]) c.id: c,
                        };
                        return _TemplatesRow(
                          templates: templates,
                          categoriesById: categoriesById,
                          formatter: _formatter,
                          currency: _currency,
                          onTap: _applyTemplate,
                        );
                      },
                    );
                  },
                ),
              if (_kind != CaptureKind.transfer)
                StreamBuilder<List<Category>>(
                  stream: (db.select(db.categories)
                        ..where((c) => c.kind.equals(_kind == CaptureKind.expense ? 'expense' : 'income'))
                        ..where((c) => c.parentId.isNull())
                        ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
                      .watch(),
                  builder: (context, snapshot) {
                    final categories = snapshot.data ?? const [];
                    return _CategoryRow(
                      categories: categories,
                      tokens: tokens,
                      selectedId: _categoryId,
                      onSelected: (id) async {
                        final lastAccount =
                            await ref.read(captureQueriesProvider).lastAccountIdForCategory(id);
                        setState(() {
                          _categoryId = id;
                          _subcategoryId = null;
                          if (lastAccount != null) _accountId = lastAccount;
                        });
                      },
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
                  key: const Key('captureAmount'),
                  // A live expression ("15.000+5.000") can't run through the
                  // money formatter mid-entry, so it renders raw while typed.
                  _bufferEndsWithOperator || _amountBuffer.contains(RegExp(r'[+\-×÷]'))
                      ? '${CurrencyInfo.of(_currency).symbol} $_amountBuffer'
                      : _formatter.format(_amount),
                  semanticsLabel: 'Jumlah: ${_formatter.format(_amount)}',
                  style: Theme.of(context)
                      .textTheme
                      .displaySmall
                      ?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: WudgetTokens.space4),
                child: Row(
                  children: [
                    Expanded(
                      child: _noteExpanded
                          ? TextField(
                              controller: _noteController,
                              autofocus: true,
                              decoration: const InputDecoration(hintText: 'Catatan'),
                            )
                          : TextButton(
                              onPressed: () => setState(() => _noteExpanded = true),
                              child: const Text('+ Catatan'),
                            ),
                    ),
                    if (_kind != CaptureKind.transfer)
                      StreamBuilder<List<Account>>(
                        stream: db.select(db.accounts).watch(),
                        builder: (context, snapshot) {
                          final accounts = snapshot.data ?? const [];
                          if (accounts.isEmpty) return const SizedBox.shrink();
                          final selected = _accountId ?? accounts.first.id;
                          return DropdownButton<String>(
                            value: selected,
                            items: [
                              for (final a in accounts) DropdownMenuItem(value: a.id, child: Text(a.name)),
                            ],
                            onChanged: (id) => setState(() => _accountId = id),
                          );
                        },
                      ),
                  ],
                ),
              ),
              _Numpad(
                showDecimal: CurrencyInfo.of(_currency).exponent > 0,
                showZeros: CurrencyInfo.of(_currency).exponent == 0,
                calculatorMode: _calculatorMode,
                dateLabel: _dateFormat.format(_occurredAt),
                onDigit: _appendDigit,
                onZeros: _appendZeros,
                onOperator: _appendOperator,
                onBackspace: _backspace,
                onSave: _save,
                onToggleCalculator: () => setState(() => _calculatorMode = !_calculatorMode),
                onPickDate: _pickDateTime,
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
  final CaptureKind kind;
  final ValueChanged<CaptureKind> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<CaptureKind>(
      segments: const [
        ButtonSegment(value: CaptureKind.expense, label: Text('Pengeluaran')),
        ButtonSegment(value: CaptureKind.income, label: Text('Pemasukan')),
        ButtonSegment(value: CaptureKind.transfer, label: Text('Transfer')),
      ],
      selected: {kind},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

class _TemplatesRow extends StatelessWidget {
  const _TemplatesRow({
    required this.templates,
    required this.categoriesById,
    required this.formatter,
    required this.currency,
    required this.onTap,
  });
  final List<CaptureTemplate> templates;
  final Map<String, Category> categoriesById;
  final MoneyFormatter formatter;
  final String currency;
  final ValueChanged<CaptureTemplate> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: WudgetTokens.space4, vertical: WudgetTokens.space1),
        itemCount: templates.length,
        separatorBuilder: (_, __) => const SizedBox(width: WudgetTokens.space2),
        itemBuilder: (context, i) {
          final t = templates[i];
          final name = categoriesById[t.categoryId]?.name ?? t.categoryId;
          return ActionChip(
            label: Text(name),
            onPressed: () => onTap(t),
          );
        },
      ),
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
    required this.calculatorMode,
    required this.dateLabel,
    required this.onDigit,
    required this.onZeros,
    required this.onOperator,
    required this.onBackspace,
    required this.onSave,
    required this.onToggleCalculator,
    required this.onPickDate,
  });
  final bool showDecimal;
  final bool showZeros;
  final bool calculatorMode;
  final String dateLabel;
  final void Function(String) onDigit;
  final VoidCallback onZeros;
  final void Function(String) onOperator;
  final VoidCallback onBackspace;
  final VoidCallback onSave;
  final VoidCallback onToggleCalculator;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    final rows = <List<Widget>>[
      [
        _key('1', () => onDigit('1')), _key('2', () => onDigit('2')), _key('3', () => onDigit('3')),
        _key('⌫', onBackspace, semanticLabel: 'Hapus'),
      ],
      [
        _key('4', () => onDigit('4')), _key('5', () => onDigit('5')), _key('6', () => onDigit('6')),
        calculatorMode ? _key('+', () => onOperator('+')) : _toggleKey(),
      ],
      [
        _key('7', () => onDigit('7')), _key('8', () => onDigit('8')), _key('9', () => onDigit('9')),
        calculatorMode ? _key('−', () => onOperator('-')) : _dateKey(),
      ],
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

  Widget _toggleKey() => _key(
        '±',
        onToggleCalculator,
        semanticLabel: 'Kalkulator',
      );

  Widget _dateKey() => _key(dateLabel, onPickDate, semanticLabel: 'Tanggal: $dateLabel');

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
