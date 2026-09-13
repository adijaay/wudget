import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/perf.dart';
import '../../core/currency.dart';
import '../../core/money.dart';
import '../../core/money_formatter.dart';
import '../../core/providers.dart';
import '../../data/capture_queries.dart';
import '../../data/database.dart';
import '../../design/components.dart';
import '../../design/tokens.dart';
import '../categories/category_edit_sheet.dart';

const _uuid = Uuid();

enum CaptureKind { expense, income, transfer }

/// The capture sheet: the one screen the product lives or dies on. See
/// plan/04-ux-design.md "The capture sheet, specified", and
/// design/Main.dc.html for the layout. Three taps to a saved expense:
/// pick the category, type the amount, save.
class CaptureSheet extends ConsumerStatefulWidget {
  const CaptureSheet({
    super.key,
    this.initialKind = CaptureKind.expense,
    this.initialToAccountId,
    this.initialAmountMinor,
    this.initialCategoryId,
    this.initialAccountId,
    this.initialNote,
    this.confirmingTransactionId,
  });

  /// Lets a caller (e.g. the card "Bayar" button in Kantong) open the sheet
  /// pre-filled as a transfer, rather than every screen needing its own
  /// mini transfer form.
  final CaptureKind initialKind;
  final String? initialToAccountId;
  final int? initialAmountMinor;

  /// Pre-fills the category/account/note — used by a bill reminder
  /// notification's deep link (Sprint 13) to open the sheet already set up
  /// the way the recurring item's template says, rather than empty.
  final String? initialCategoryId;
  final String? initialAccountId;
  final String? initialNote;

  /// When set, a successful save removes this transaction — the
  /// recurrence engine's projected placeholder this save supersedes, so
  /// confirming a reminder produces one real transaction, not two. See
  /// `RecurrenceRepository` and DECISIONS.md, Sprint 13.
  final String? confirmingTransactionId;

  @override
  ConsumerState<CaptureSheet> createState() => _CaptureSheetState();
}

class _CaptureSheetState extends ConsumerState<CaptureSheet> {
  late CaptureKind _kind = widget.initialKind;
  String _amountBuffer = '';
  late String? _categoryId = widget.initialCategoryId;
  String? _subcategoryId;
  late String? _accountId = widget.initialAccountId;
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
  static final _timeFormat = DateFormat('HH:mm');

  @override
  void initState() {
    super.initState();
    if (widget.initialAmountMinor != null) {
      final info = CurrencyInfo.of(_currency);
      _amountBuffer = info.exponent == 0
          ? widget.initialAmountMinor!.toString()
          : (widget.initialAmountMinor! / info.minorUnitsPerMajor).toString();
    }
    if (widget.initialNote != null) {
      _noteController.text = widget.initialNote!;
      _noteExpanded = true;
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

  bool get _bufferHasExpression => _amountBuffer.contains(RegExp(r'[+\-×÷]'));

  /// Rp 999.999.999.999 and change. Without a ceiling the numpad will keep
  /// taking digits, `num.tryParse` stops being exact past 2^53, and the
  /// rounded minor units reach the database as a number no arithmetic can
  /// survive: one such row made SQLite's SUM over an account's postings
  /// fail with "integer overflow", which took the whole Kantong tab down.
  static const _maxAmountDigits = 12;

  bool _atDigitLimit() {
    final current = _amountBuffer.split(RegExp(r'[+\-×÷]')).last;
    return current.replaceAll('.', '').length >= _maxAmountDigits;
  }

  void _appendDigit(String d) {
    if (_atDigitLimit()) return;
    setState(() => _amountBuffer += d);
  }

  void _appendZeros() {
    if (_amountBuffer.isEmpty || _bufferEndsWithOperator || _atDigitLimit()) return;
    setState(() => _amountBuffer += '000');
  }

  /// Leaving calculator mode is this numpad's "=": the expression collapses
  /// to what it evaluated to, so the next digit starts a new number instead
  /// of extending the last operand. Without it, turning the calculator off
  /// left an expression on screen that could no longer be edited, since the
  /// operator row goes with the mode.
  void _settleBuffer() {
    if (!_bufferHasExpression) return;
    final info = CurrencyInfo.of(_currency);
    final minor = _amount.minor;
    _amountBuffer = info.exponent == 0
        ? minor.toString()
        : (minor / info.minorUnitsPerMajor).toString();
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
    final saveToDismissed = Stopwatch()..start();
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

    if (widget.confirmingTransactionId != null) {
      await ref.read(postingsRepositoryProvider).undoInsert(widget.confirmingTransactionId!);
    }

    if (!mounted) return;
    Navigator.of(context).pop();
    perfMark('save_to_dismissed', saveToDismissed);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tersimpan: ${_formatter.format(_amount)}'),
        action: SnackBarAction(
          label: 'Batalkan',
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
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: WudgetTokens.space2, bottom: WudgetTokens.space3),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: tokens.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Everything above the numpad scrolls, so the amount and the
            // save key stay reachable at any text scale or screen height
            // (R-03, R-35).
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: WudgetTokens.space4),
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
                          const SizedBox(width: WudgetTokens.space2),
                          _SquareIconButton(
                            icon: _photoPath == null ? Icons.photo_camera_outlined : Icons.photo_camera,
                            tooltip: 'Kamera struk',
                            active: _photoPath != null,
                            onPressed: _pickReceiptPhoto,
                          ),
                        ],
                      ),
                    ),
                    if (_kind == CaptureKind.transfer) _transferAccounts(db),
                    if (_kind != CaptureKind.transfer) _templates(db),
                    if (_kind != CaptureKind.transfer) _categories(db, tokens),
                    if (_categoryId != null) _subcategories(db, tokens),
                    _amountDisplay(tokens),
                    _noteAndWallet(db, tokens),
                  ],
                ),
              ),
            ),
            if (_calculatorMode) _OperatorRow(onOperator: _appendOperator),
            _Numpad(
              showDecimal: CurrencyInfo.of(_currency).exponent > 0,
              showZeros: CurrencyInfo.of(_currency).exponent == 0,
              calculatorMode: _calculatorMode,
              dateLabel: _dateFormat.format(_occurredAt),
              timeLabel: _timeFormat.format(_occurredAt),
              onDigit: _appendDigit,
              onZeros: _appendZeros,
              onBackspace: _backspace,
              onSave: _save,
              onToggleCalculator: () => setState(() {
                _calculatorMode = !_calculatorMode;
                if (!_calculatorMode) _settleBuffer();
              }),
              onPickDate: _pickDateTime,
            ),
          ],
        ),
      ),
    );
  }

  Widget _transferAccounts(WudgetDatabase db) {
    return StreamBuilder<List<Account>>(
      stream: db.select(db.accounts).watch(),
      builder: (context, snapshot) {
        final accounts = snapshot.data ?? const [];
        if (accounts.length < 2) {
          return const Padding(
            padding: EdgeInsets.all(WudgetTokens.space4),
            child: Text('Butuh minimal dua kantong untuk transfer.'),
          );
        }
        _accountId ??= accounts.first.id;
        _toAccountId ??= accounts.firstWhere(
          (a) => a.id != _accountId,
          orElse: () => accounts.last,
        ).id;
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            WudgetTokens.space4,
            WudgetTokens.space3,
            WudgetTokens.space4,
            0,
          ),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _accountId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Dari'),
                  items: [
                    for (final a in accounts) DropdownMenuItem(value: a.id, child: Text(a.name)),
                  ],
                  onChanged: (id) => setState(() => _accountId = id),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: WudgetTokens.space2),
                child: Icon(Icons.arrow_forward, size: 18),
              ),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _toAccountId,
                  isExpanded: true,
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
    );
  }

  Widget _templates(WudgetDatabase db) {
    return FutureBuilder<List<CaptureTemplate>>(
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
            return Padding(
              padding: const EdgeInsets.only(top: WudgetTokens.space3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: WudgetTokens.space4),
                    child: SectionLabel('Sering'),
                  ),
                  _TemplatesRow(
                    templates: templates,
                    categoriesById: categoriesById,
                    onTap: _applyTemplate,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _categories(WudgetDatabase db, WudgetTokens tokens) {
    return StreamBuilder<List<Category>>(
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
          onCreate: () => _createCategory(categories),
          onSelected: (id) async {
            // The wallet this category was last paid from, so the common
            // case needs no wallet tap at all (Sprint 4).
            final lastAccount = await ref.read(captureQueriesProvider).lastAccountIdForCategory(id);
            setState(() {
              _categoryId = id;
              _subcategoryId = null;
              if (lastAccount != null) _accountId = lastAccount;
            });
          },
        );
      },
    );
  }

  /// Opens the category editor and selects whatever comes back, so adding a
  /// category mid-capture does not cost the user their place: they came here
  /// to record something, not to do admin.
  Future<void> _createCategory(List<Category> siblings) async {
    final selected = _categoryId == null
        ? null
        : siblings.where((c) => c.id == _categoryId).firstOrNull;
    final createdId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CategoryEditSheet(
        kind: _kind == CaptureKind.expense ? 'expense' : 'income',
        parent: selected,
      ),
    );
    if (createdId == null || !mounted) return;
    setState(() {
      // A new subcategory leaves its parent selected and selects itself
      // underneath; a new top-level category becomes the selection.
      if (selected != null && _categoryId == selected.id) {
        _subcategoryId = createdId;
      } else {
        _categoryId = createdId;
        _subcategoryId = null;
      }
    });
  }

  Widget _subcategories(WudgetDatabase db, WudgetTokens tokens) {
    return StreamBuilder<List<Category>>(
      stream: (db.select(db.categories)..where((c) => c.parentId.equals(_categoryId!))).watch(),
      builder: (context, snapshot) {
        final subcategories = snapshot.data ?? const [];
        if (subcategories.isEmpty) return const SizedBox.shrink();
        return _SubcategoryChips(
          subcategories: subcategories,
          selectedId: _subcategoryId,
          hueIndex: subcategories.first.hueIndex,
          tokens: tokens,
          onSelected: (id) => setState(() => _subcategoryId = _subcategoryId == id ? null : id),
        );
      },
    );
  }

  Widget _amountDisplay(WudgetTokens tokens) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: WudgetTokens.space4, bottom: WudgetTokens.space2),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                CurrencyInfo.of(_currency).symbol,
                style: text.titleLarge?.copyWith(fontSize: 20, color: tokens.ink2),
              ),
              const SizedBox(width: WudgetTokens.space2),
              // Always the evaluated total, never the raw expression: the
              // number shown is the number that will be saved. The
              // expression itself goes on the line below.
              Text(
                key: const Key('captureAmount'),
                _formatter.format(_amount, showSymbol: false),
                semanticsLabel: 'Jumlah: ${_formatter.format(_amount)}',
                style: text.headlineMedium?.copyWith(
                  fontSize: 40,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: WudgetTokens.space1),
              Container(width: 2, height: 34, color: tokens.accent),
            ],
          ),
          if (_bufferHasExpression) ...[
            const SizedBox(height: WudgetTokens.space1),
            Text(
              _amountBuffer.replaceAllMapped(RegExp(r'[+\-×÷]'), (m) => ' ${m[0]} '),
              style: text.bodySmall?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _noteAndWallet(WudgetDatabase db, WudgetTokens tokens) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: WudgetTokens.space4),
      child: Row(
        children: [
          Expanded(
            child: _noteExpanded
                ? TextField(
                    controller: _noteController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(hintText: 'Catatan'),
                  )
                : _NoteButton(onPressed: () => setState(() => _noteExpanded = true)),
          ),
          if (_kind != CaptureKind.transfer)
            StreamBuilder<List<Account>>(
              stream: db.select(db.accounts).watch(),
              builder: (context, snapshot) {
                final accounts = snapshot.data ?? const [];
                if (accounts.isEmpty) return const SizedBox.shrink();
                final selected = _accountId ?? accounts.first.id;
                final account = accounts.firstWhere(
                  (a) => a.id == selected,
                  orElse: () => accounts.first,
                );
                return Padding(
                  padding: const EdgeInsets.only(left: WudgetTokens.space2),
                  child: _WalletPicker(
                    account: account,
                    accounts: accounts,
                    onSelected: (id) => setState(() => _accountId = id),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// The type control: a tray with the selected segment filled, from
/// design/Main.dc.html. Built rather than taken from Material's
/// SegmentedButton, whose selected-state checkmark and minimum widths were
/// what pushed "Pengeluaran" onto two lines on a real device.
class _TypeSegments extends StatelessWidget {
  const _TypeSegments({required this.kind, required this.onChanged});
  final CaptureKind kind;
  final ValueChanged<CaptureKind> onChanged;

  static const _labels = {
    CaptureKind.expense: 'Pengeluaran',
    CaptureKind.income: 'Pemasukan',
    CaptureKind.transfer: 'Transfer',
  };

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(WudgetTokens.radiusControl),
      ),
      child: Row(
        children: [
          for (final entry in _labels.entries)
            Expanded(
              child: Semantics(
                selected: kind == entry.key,
                button: true,
                label: entry.value,
                excludeSemantics: true,
                child: Material(
                  color: kind == entry.key ? tokens.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: () => onChanged(entry.key),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: WudgetTokens.space2),
                      child: Text(
                        entry.value,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: WudgetTokens.fontFamily,
                          fontSize: 13,
                          fontWeight: kind == entry.key ? FontWeight.w600 : FontWeight.w500,
                          color: kind == entry.key ? tokens.inkOnAccent : tokens.ink2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SquareIconButton extends StatelessWidget {
  const _SquareIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.active = false,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        excludeSemantics: true,
        child: Material(
          color: active ? tokens.accent : tokens.surfaceCard,
          borderRadius: BorderRadius.circular(WudgetTokens.radiusControl),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(WudgetTokens.radiusControl),
            child: Container(
              width: WudgetTokens.minTapTarget,
              height: WudgetTokens.minTapTarget,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(WudgetTokens.radiusControl),
                border: Border.all(color: active ? tokens.accent : tokens.borderStrong),
              ),
              child: Icon(icon, size: 20, color: active ? tokens.inkOnAccent : tokens.ink1),
            ),
          ),
        ),
      ),
    );
  }
}

class _TemplatesRow extends StatelessWidget {
  const _TemplatesRow({
    required this.templates,
    required this.categoriesById,
    required this.onTap,
  });
  final List<CaptureTemplate> templates;
  final Map<String, Category> categoriesById;
  final ValueChanged<CaptureTemplate> onTap;

  @override
  Widget build(BuildContext context) {
    // A scrolling Row, not a fixed-height ListView: the row then takes its
    // height from the chips themselves, so a chip that grows at 200% text
    // scale is not clipped by a hardcoded height (R-03, R-35).
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: WudgetTokens.space4),
      child: Row(
        children: [
          for (var i = 0; i < templates.length; i++) ...[
            if (i > 0) const SizedBox(width: WudgetTokens.space2),
            ActionChip(
              label: Text(categoriesById[templates[i].categoryId]?.name ?? templates[i].categoryId),
              onPressed: () => onTap(templates[i]),
            ),
          ],
        ],
      ),
    );
  }
}

/// Categories as tiles rather than chips: the icon is what makes the common
/// four recognisable at a glance without reading, which is the difference
/// between a three-tap capture and a five-tap one.
class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.categories,
    required this.tokens,
    required this.selectedId,
    required this.onSelected,
    required this.onCreate,
  });
  final List<Category> categories;
  final WudgetTokens tokens;
  final String? selectedId;
  final ValueChanged<String> onSelected;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: WudgetTokens.space3),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: WudgetTokens.space4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < categories.length; i++) ...[
              if (i > 0) const SizedBox(width: WudgetTokens.space3),
              _CategoryTile(
                category: categories[i],
                tokens: tokens,
                selected: categories[i].id == selectedId,
                onTap: () => onSelected(categories[i].id),
              ),
            ],
            // Last, not first: the eight seeded categories cover most days,
            // and the one you reach for should not have moved along by one.
            const SizedBox(width: WudgetTokens.space3),
            _AddCategoryTile(onTap: onCreate),
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.tokens,
    required this.selected,
    required this.onTap,
  });
  final Category category;
  final WudgetTokens tokens;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
            final c = category;
            final hue = tokens.hueFor(c.hueIndex);
            return Semantics(
              selected: selected,
              button: true,
              label: c.name,
              excludeSemantics: true,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(WudgetTokens.radiusTile),
                child: SizedBox(
                  width: 58,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: WudgetTokens.categoryTile,
                        height: WudgetTokens.categoryTile,
                        decoration: BoxDecoration(
                          color: selected ? tokens.tintFor(c.hueIndex) : tokens.surfaceMuted,
                          borderRadius: BorderRadius.circular(WudgetTokens.radiusTile),
                          // The selected tile carries a border as well as a
                          // fill, so selection survives not seeing hue.
                          border: Border.all(
                            color: selected ? hue : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          categoryIcon(c.iconKey),
                          size: 22,
                          color: selected ? tokens.inkFor(c.hueIndex) : tokens.ink2,
                        ),
                      ),
                      const SizedBox(height: WudgetTokens.space1),
                      Text(
                        c.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: WudgetTokens.fontFamily,
                          fontSize: 11,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? tokens.ink1 : tokens.ink2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
  }
}

/// The same shape as a category tile, drawn as an outline so it reads as an
/// action rather than a category you could pick by mistake.
class _AddCategoryTile extends StatelessWidget {
  const _AddCategoryTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    return Semantics(
      button: true,
      label: 'Kategori baru',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(WudgetTokens.radiusTile),
        child: SizedBox(
          width: 58,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: WudgetTokens.categoryTile,
                height: WudgetTokens.categoryTile,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(WudgetTokens.radiusTile),
                  border: Border.all(color: tokens.borderStrong),
                ),
                child: Icon(Icons.add, size: 22, color: tokens.ink2),
              ),
              const SizedBox(height: WudgetTokens.space1),
              Text(
                'Baru',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: WudgetTokens.fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: tokens.ink2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubcategoryChips extends StatelessWidget {
  const _SubcategoryChips({
    required this.subcategories,
    required this.selectedId,
    required this.hueIndex,
    required this.tokens,
    required this.onSelected,
  });
  final List<Category> subcategories;
  final String? selectedId;
  final int hueIndex;
  final WudgetTokens tokens;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: WudgetTokens.space2),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: WudgetTokens.space4),
        child: Row(
          children: [
            for (var i = 0; i < subcategories.length; i++) ...[
              if (i > 0) const SizedBox(width: WudgetTokens.space2),
              _subcategoryChip(subcategories[i], subcategories[i].id == selectedId),
            ],
          ],
        ),
      ),
    );
  }

  Widget _subcategoryChip(Category s, bool selected) {
            return ChoiceChip(
              label: Text(s.name),
              selected: selected,
              // The same treatment as a selected category tile: the hue's
              // tint as the ground and its darker ink as the label, plus a
              // hue border. Filling with the hue itself and writing white on
              // it measured 3.56:1 on the lightest hue, below the 4.5 a
              // label needs (test/domain/contrast_test.dart).
              selectedColor: tokens.tintFor(hueIndex),
              side: BorderSide(color: selected ? tokens.hueFor(hueIndex) : tokens.border),
              labelStyle: TextStyle(
                fontFamily: WudgetTokens.fontFamily,
                fontSize: 12.5,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? tokens.inkFor(hueIndex) : tokens.ink1,
              ),
              onSelected: (_) => onSelected(s.id),
            );
  }
}

class _NoteButton extends StatelessWidget {
  const _NoteButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    return Material(
      color: tokens.surfaceMuted,
      borderRadius: BorderRadius.circular(WudgetTokens.radiusControl),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(WudgetTokens.radiusControl),
        child: Container(
          height: WudgetTokens.minTapTarget,
          padding: const EdgeInsets.symmetric(horizontal: WudgetTokens.space3),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Icon(Icons.add, size: 16, color: tokens.ink2),
              const SizedBox(width: WudgetTokens.space2),
              Text('Catatan', style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _WalletPicker extends StatelessWidget {
  const _WalletPicker({
    required this.account,
    required this.accounts,
    required this.onSelected,
  });
  final Account account;
  final List<Account> accounts;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    return PopupMenuButton<String>(
      tooltip: 'Pilih kantong',
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final a in accounts)
          PopupMenuItem(
            value: a.id,
            child: Row(
              children: [
                Icon(walletTypeIcon(a.type), size: 18, color: tokens.ink2),
                const SizedBox(width: WudgetTokens.space3),
                Text(a.name),
              ],
            ),
          ),
      ],
      child: Container(
        height: WudgetTokens.minTapTarget,
        padding: const EdgeInsets.symmetric(horizontal: WudgetTokens.space3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(WudgetTokens.radiusControl),
          border: Border.all(color: tokens.borderStrong),
        ),
        child: Row(
          children: [
            Icon(walletTypeIcon(account.type), size: 16, color: tokens.ink2),
            const SizedBox(width: WudgetTokens.space2),
            Text(
              account.name,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 13),
            ),
            Icon(Icons.expand_more, size: 16, color: tokens.ink2),
          ],
        ),
      ),
    );
  }
}

/// Calculator mode's operators, as a row that appears above the numpad.
/// They are not swapped into the right-hand column: doing that took the
/// toggle key itself away, so there was no way back out of calculator mode,
/// and it hid the date key while it was on.
class _OperatorRow extends StatelessWidget {
  const _OperatorRow({required this.onOperator});
  final void Function(String) onOperator;

  @override
  Widget build(BuildContext context) {
    const operators = [('+', '+'), ('−', '-'), ('×', '×'), ('÷', '÷')];
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        WudgetTokens.space2,
        WudgetTokens.space1,
        WudgetTokens.space2,
        0,
      ),
      child: Row(
        children: [
          for (final (label, op) in operators)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3.5),
                child: _NumpadKey(
                  key: Key('numpadOp_$op'),
                  label: label,
                  semanticLabel: switch (op) {
                    '+' => 'Tambah',
                    '-' => 'Kurang',
                    '×' => 'Kali',
                    _ => 'Bagi',
                  },
                  onTap: () => onOperator(op),
                  tone: _KeyTone.action,
                ),
              ),
            ),
        ],
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
    required this.timeLabel,
    required this.onDigit,
    required this.onZeros,
    required this.onBackspace,
    required this.onSave,
    required this.onToggleCalculator,
    required this.onPickDate,
  });
  final bool showDecimal;
  final bool showZeros;
  final bool calculatorMode;
  final String dateLabel;
  final String timeLabel;
  final void Function(String) onDigit;
  final VoidCallback onZeros;
  final VoidCallback onBackspace;
  final VoidCallback onSave;
  final VoidCallback onToggleCalculator;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    final rows = <List<Widget>>[
      [
        _digit('1'), _digit('2'), _digit('3'),
        _NumpadKey(
          key: const Key('numpadKey_backspace'),
          icon: Icons.backspace_outlined,
          semanticLabel: 'Hapus',
          onTap: onBackspace,
          tone: _KeyTone.action,
        ),
      ],
      [
        _digit('4'), _digit('5'), _digit('6'),
        _NumpadKey(
          key: const Key('numpadKey_calculator'),
          icon: Icons.calculate_outlined,
          semanticLabel: 'Kalkulator',
          onTap: onToggleCalculator,
          tone: calculatorMode ? _KeyTone.activeAction : _KeyTone.action,
        ),
      ],
      [
        _digit('7'), _digit('8'), _digit('9'),
        _NumpadKey(
          key: const Key('numpadKey_date'),
          label: dateLabel,
          caption: timeLabel,
          semanticLabel: 'Tanggal: $dateLabel',
          onTap: onPickDate,
          tone: _KeyTone.action,
        ),
      ],
      [
        showDecimal ? _digit('.') : const SizedBox.shrink(),
        _digit('0'),
        showZeros
            ? _NumpadKey(key: const Key('numpadKey_000'), label: '000', onTap: onZeros)
            : const SizedBox.shrink(),
        _NumpadKey(
          key: const Key('numpadKey_save'),
          icon: Icons.check,
          semanticLabel: 'Simpan',
          onTap: onSave,
          tone: _KeyTone.save,
        ),
      ],
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        WudgetTokens.space2,
        WudgetTokens.space2,
        WudgetTokens.space2,
        WudgetTokens.space2,
      ),
      child: Column(
        children: [
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3.5),
              child: Row(
                children: [
                  for (final key in row)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3.5),
                        child: key,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Keyed so a test can tap one key without colliding with the same glyph
  /// rendered in the amount display above.
  Widget _digit(String d) => _NumpadKey(
        key: Key('numpadKey_$d'),
        label: d,
        onTap: () => onDigit(d),
      );
}

enum _KeyTone { digit, action, activeAction, save }

class _NumpadKey extends StatelessWidget {
  const _NumpadKey({
    super.key,
    this.label,
    this.icon,
    this.caption,
    this.semanticLabel,
    required this.onTap,
    this.tone = _KeyTone.digit,
  });
  final String? label;
  final IconData? icon;
  final String? caption;
  final String? semanticLabel;
  final VoidCallback onTap;
  final _KeyTone tone;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final (background, foreground) = switch (tone) {
      _KeyTone.digit => (tokens.surfaceMuted, tokens.ink1),
      _KeyTone.action => (tokens.surfaceCard, tokens.ink1),
      _KeyTone.activeAction => (tokens.accent, tokens.inkOnAccent),
      _KeyTone.save => (tokens.accent, tokens.inkOnAccent),
    };

    return Semantics(
      label: semanticLabel ?? label ?? '',
      button: true,
      // Without this, a screen reader merges the glyph's own default
      // reading ("chevron left equals sign" for "±", say) in with the
      // explicit label instead of replacing it — see DECISIONS.md,
      // Sprint 18.
      excludeSemantics: true,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(WudgetTokens.radiusCard),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(WudgetTokens.radiusCard),
          child: Container(
            // A minimum, not a fixed height: at 200% text scale a 21px glyph
            // is 42px and overflowed a hard 52px key (R-03, R-35).
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(vertical: WudgetTokens.space1),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(WudgetTokens.radiusCard),
              border: tone == _KeyTone.action
                  ? Border.all(color: tokens.border)
                  : null,
            ),
            alignment: Alignment.center,
            child: icon != null
                ? Icon(icon, size: 22, color: foreground)
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label!,
                        maxLines: 1,
                        style: TextStyle(
                          fontFamily: WudgetTokens.fontFamily,
                          fontSize: caption != null ? 12.5 : (label!.length > 2 ? 16 : 21),
                          fontWeight: FontWeight.w600,
                          color: foreground,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      if (caption != null)
                        Text(
                          caption!,
                          maxLines: 1,
                          style: TextStyle(
                            fontFamily: WudgetTokens.fontFamily,
                            fontSize: 10,
                            color: tokens.ink2,
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
