import 'dart:async';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/perf.dart';
import '../../core/currency.dart';
import '../../core/money.dart';
import '../../core/money_formatter.dart';
import '../../core/providers.dart';
import '../../data/database.dart';
import '../../data/payment_log_repository.dart';
import '../../design/components.dart';
import '../../design/tokens.dart';
import '../../domain/period.dart';
import '../categories/category_edit_sheet.dart';

const _uuid = Uuid();

enum CaptureKind { expense, income, transfer }

abstract final class CaptureSource {
  static const nav = 'nav';
  static const widget = 'widget';
  static const chip = 'chip';
  static const launch = 'launch';
  static const home = 'home';
  static const backfill = 'backfill';
  static const payment = 'payment';
}

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
    this.initialSubcategoryId,
    this.initialAccountId,
    this.initialNote,
    this.initialOccurredAt,
    this.initialPhotoPath,
    this.confirmingTransactionId,
    this.editingTransactionId,
    this.paymentLogId,
    this.source = CaptureSource.nav,
  });

  /// The payment-notification log entry this sheet records; a save points the log at the new transaction.
  final String? paymentLogId;

  /// Where the sheet was opened from, logged with the capture timing events.
  final String source;

  /// Lets a caller (e.g. the card "Bayar" button in Kantong) open the sheet
  /// pre-filled as a transfer, rather than every screen needing its own
  /// mini transfer form.
  final CaptureKind initialKind;
  final String? initialToAccountId;
  final int? initialAmountMinor;

  /// Pre-fills the category/account/note — used by a bill reminder
  /// notification's deep link (Sprint 13) to open the sheet already set up
  /// the way the recurring item's template says, rather than empty.
  ///
  /// [initialCategoryId] must be a top-level category, same requirement
  /// the category grid itself has; a transaction actually recorded against
  /// a subcategory passes that subcategory's parent here and the
  /// subcategory itself in [initialSubcategoryId].
  final String? initialCategoryId;
  final String? initialSubcategoryId;
  final String? initialAccountId;
  final String? initialNote;

  /// Prefilling the entry's own date, rather than defaulting to now — a
  /// transaction being edited keeps the moment it actually happened
  /// unless the user deliberately changes it via the date/time field.
  final DateTime? initialOccurredAt;
  final String? initialPhotoPath;

  /// When set, a successful save removes this transaction — the
  /// recurrence engine's projected placeholder this save supersedes, so
  /// confirming a reminder produces one real transaction, not two. See
  /// `RecurrenceRepository` and DECISIONS.md, Sprint 13.
  final String? confirmingTransactionId;

  /// When set, this sheet is editing a real, already-recorded transaction
  /// rather than capturing a new one: a successful save soft-deletes this
  /// transaction (same as the ledger's own delete, so the "Batalkan" undo
  /// on the save snackbar can restore it) and the edited values are saved
  /// as a fresh entry.
  ///
  /// Deliberately not reusing [confirmingTransactionId]: that path hard-
  /// deletes a recurrence engine's projected placeholder, which was never
  /// a real entry and regenerates on its own — soft-deleting a genuine
  /// historical transaction needs the undo-restore path a hard delete
  /// cannot offer back.
  final String? editingTransactionId;

  @override
  ConsumerState<CaptureSheet> createState() => _CaptureSheetState();
}

class _CaptureSheetState extends ConsumerState<CaptureSheet> {
  late CaptureKind _kind = widget.initialKind;
  String _amountBuffer = '';
  late String? _categoryId = widget.initialCategoryId;
  late String? _subcategoryId = widget.initialSubcategoryId;
  late String? _accountId = widget.initialAccountId;
  late String? _toAccountId = widget.initialToAccountId;
  bool _calculatorMode = false;
  bool _saveBlocked = false;
  final _noteController = TextEditingController();
  late DateTime _occurredAt = widget.initialOccurredAt ?? DateTime.now();
  late String? _photoPath = widget.initialPhotoPath;
  List<String> _rankedIds = const [];
  final _sinceOpen = Stopwatch()..start();

  /// Non-null while an expense is being split across categories.
  List<_SplitLine>? _split;

  int get _splitRemainderMinor =>
      _amount.minor - (_split ?? const []).fold(0, (sum, l) => sum + l.minor);

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
    }
    _loadRanking();
    unawaited(ref
        .read(analyticsRepositoryProvider)
        .logEvent('capture_open', props: {'source': widget.source}));
  }

  @override
  void dispose() {
    _noteController.dispose();
    for (final line in _split ?? const <_SplitLine>[]) {
      line.amount.dispose();
    }
    super.dispose();
  }

  /// Orders the category tiles for this hour and picks the likeliest one,
  /// so a repeat expense is amount and save.
  Future<void> _loadRanking() async {
    if (_kind == CaptureKind.transfer) return;
    final kind = _kind;
    final ids = await ref.read(captureQueriesProvider).rankedCategoryIds(
        kind == CaptureKind.expense ? 'expense' : 'income', DateTime.now());
    if (!mounted || kind != _kind) return;
    setState(() {
      _rankedIds = ids;
      if (_categoryId == null && ids.isNotEmpty) _categoryId = ids.first;
    });
  }

  /// The wallet this category was last recorded from, so picking a category
  /// moves the wallet with it (plan/04-ux-design.md: "the wallet defaults to
  /// the last wallet used with the selected category, not to a global
  /// default"). A wallet the user picked by hand wins until the category
  /// changes, which is why this only runs on a category tap.
  Future<void> _adoptLastWalletFor(String categoryId) async {
    final last = await ref
        .read(captureQueriesProvider)
        .lastAccountIdForCategory(categoryId);
    if (!mounted || last == null || _categoryId != categoryId) return;
    setState(() => _accountId = last);
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

  Money get _operandAmount =>
      Money.fromMajor(num.tryParse(_currentOperand) ?? 0, _currency);

  bool get _bufferEndsWithOperator =>
      _amountBuffer.isNotEmpty &&
      '+-×÷'.contains(_amountBuffer[_amountBuffer.length - 1]);

  bool get _bufferHasExpression => _amountBuffer.contains(RegExp(r'[+\-×÷]'));

  /// The number the numpad is typing into: everything after the last
  /// operator. The big slot shows this rather than the running total, so
  /// tapping an operator hands you an empty number to type instead of
  /// appearing to edit the one before it (15.000 becoming 15.005, then
  /// 15.050, as the second operand arrives digit by digit).
  String get _currentOperand => _amountBuffer.split(RegExp(r'[+\-×÷]')).last;

  /// Everything before that, trailing operator included: "15000 +".
  String get _pendingExpression =>
      _amountBuffer.substring(0, _amountBuffer.length - _currentOperand.length);

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
    if (_amountBuffer.isEmpty || _bufferEndsWithOperator || _atDigitLimit())
      return;
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
    setState(() =>
        _amountBuffer = _amountBuffer.substring(0, _amountBuffer.length - 1));
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
      _occurredAt =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
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
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kamera tidak tersedia')));
      }
    }
  }

  /// Why the save key cannot act yet, in the order a person fills the sheet
  /// in. Null means it can. Recomputed on every build rather than latched, so
  /// the reason disappears the moment the missing piece is supplied.
  String? get _blockingSave {
    if (_amount.isZero) return 'Isi jumlahnya dulu.';
    if (_kind == CaptureKind.transfer) {
      if (_accountId == null || _toAccountId == null) {
        return 'Pilih kantong asal dan tujuannya.';
      }
      if (_accountId == _toAccountId) {
        return 'Kantong asal dan tujuan tidak boleh sama.';
      }
      return null;
    }
    if (_split case final split?) {
      if (split.length < 2) return 'Pecah ke minimal dua kategori.';
      if (split.any((l) => l.categoryId == null)) return 'Pilih kategori tiap bagian.';
      if (_splitRemainderMinor != 0) return 'Sisanya harus Rp 0 dulu.';
      return null;
    }
    if (_categoryId == null) return 'Pilih kategorinya dulu.';
    return null;
  }

  Future<void> _save() async {
    // Every bail-out below used to be a bare `return`, so the save key looked
    // lit, did nothing, and said nothing. The sheet covers the snackbar, so
    // the reason has to be drawn inside it.
    if (_blockingSave != null) {
      setState(() => _saveBlocked = true);
      return;
    }
    final saveToDismissed = Stopwatch()..start();
    final db = ref.read(databaseProvider);
    // Captured once, up front: the snackbar's "Batalkan" runs after this
    // sheet has already popped and this State has disposed, so `ref` is no
    // longer safe to read from inside that closure — the repository itself
    // is a plain object and doesn't care about the widget's lifecycle.
    final postings = ref.read(postingsRepositoryProvider);
    final txId = _uuid.v4();
    final now = DateTime.now();

    if (_kind == CaptureKind.transfer) {
      // Transfer: from-account negative, to-account positive, no category
      // leg — that absence is what keeps a transfer (including a card
      // payment) out of spending statistics. See spending_queries.dart.
      await postings.insertTransaction(
        transaction: TransactionsCompanion.insert(
          id: txId,
          kind: 'transfer',
          occurredAt: _occurredAt.toUtc().millisecondsSinceEpoch,
          tzOffsetMinutes: _occurredAt.timeZoneOffset.inMinutes,
          note: _noteController.text.isEmpty
              ? const Value.absent()
              : Value(_noteController.text),
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
      final accountId = _accountId ??
          await ref.read(captureQueriesProvider).defaultAccountId();
      final split = _split;
      final categoryLegs = split == null
          ? [(categoryId: _subcategoryId ?? _categoryId!, minor: _amount.minor)]
          : [for (final l in split) (categoryId: l.categoryId!, minor: l.minor)];

      // Expense: account leg negative, category leg positive.
      // Income: account leg positive, category leg negative.
      final sign = _kind == CaptureKind.expense ? -1 : 1;

      await postings.insertTransaction(
        transaction: TransactionsCompanion.insert(
          id: txId,
          kind: _kind == CaptureKind.expense ? 'expense' : 'income',
          occurredAt: _occurredAt.toUtc().millisecondsSinceEpoch,
          tzOffsetMinutes: _occurredAt.timeZoneOffset.inMinutes,
          note: _noteController.text.isEmpty
              ? const Value.absent()
              : Value(_noteController.text),
          photoPath:
              _photoPath == null ? const Value.absent() : Value(_photoPath),
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
          for (final leg in categoryLegs)
            PostingsCompanion.insert(
              id: _uuid.v4(),
              transactionId: txId,
              categoryId: Value(leg.categoryId),
              amountMinor: -sign * leg.minor,
              currency: _currency,
              baseAmountMinor: -sign * leg.minor,
            ),
        ],
      );
    }

    if (widget.editingTransactionId == null) {
      unawaited(ref.read(analyticsRepositoryProvider).logEvent(
        'capture_save',
        props: {'source': widget.source, 'ms': _sinceOpen.elapsedMilliseconds},
      ));
    }
    if (widget.paymentLogId != null) await PaymentLogRepository.relink(widget.paymentLogId!, txId);

    if (widget.confirmingTransactionId != null) {
      await postings.undoInsert(widget.confirmingTransactionId!);
    }
    if (widget.editingTransactionId != null) {
      // Soft delete, not undoInsert: this is a real historical entry, and
      // the point of soft delete is exactly this — the undo below can
      // bring it back, the same restore path the ledger's own delete uses.
      await postings.deleteTransaction(widget.editingTransactionId!);
    }

    final message = await _savedMessage(db);
    if (!mounted) return;
    unawaited(HapticFeedback.mediumImpact());
    Navigator.of(context).pop();
    perfMark('save_to_dismissed', saveToDismissed);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 5),
        content: Text(message),
        action: SnackBarAction(
          label: 'Batalkan',
          onPressed: () {
            postings.undoInsert(txId);
            final editing = widget.editingTransactionId;
            if (editing != null) postings.restoreTransaction(editing);
          },
        ),
      ),
    );
  }

  /// For an expense in a budgeted kantong, what is left of it this period.
  Future<String> _savedMessage(WudgetDatabase db) async {
    final plain = 'Tersimpan: ${_formatter.format(_amount)}';
    if (_kind != CaptureKind.expense || _split != null) return plain;
    final queries = ref.read(captureQueriesProvider);
    final period = await ref
        .read(settingsRepositoryProvider)
        .effectivePeriodFor(todayDayBucket());
    final remaining = await queries.kantongRemaining(_categoryId!, period);
    if (remaining == null) return plain;
    final category = await (db.select(db.categories)
          ..where((c) => c.id.equals(_categoryId!)))
        .getSingle();
    return 'Tersimpan. Kantong ${category.name} sisa '
        '${_formatter.format(Money.fromMinor(remaining, _currency))} '
        'sampai ${_dateFormat.format(period.lastDate)}.';
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final db = ref.watch(databaseProvider);

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                  top: WudgetTokens.space2, bottom: WudgetTokens.space3),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: WudgetTokens.space4),
                      child: Row(
                        children: [
                          Expanded(
                            child: SegmentedTray<CaptureKind>(
                              // Transfer only for a sheet opened as one (Kantong's
                              // Bayar, or editing a transfer): wallets are out of capture.
                              segments: {
                                CaptureKind.expense: 'Pengeluaran',
                                CaptureKind.income: 'Pemasukan',
                                if (widget.initialKind == CaptureKind.transfer)
                                  CaptureKind.transfer: 'Transfer',
                              },
                              value: _kind,
                              onChanged: (k) {
                                setState(() {
                                  _kind = k;
                                  _categoryId = null;
                                  _subcategoryId = null;
                                  _rankedIds = const [];
                                });
                                _loadRanking();
                              },
                            ),
                          ),
                          const SizedBox(width: WudgetTokens.space2),
                          _SquareIconButton(
                            icon: _photoPath == null
                                ? Icons.photo_camera_outlined
                                : Icons.photo_camera,
                            tooltip: 'Kamera struk',
                            active: _photoPath != null,
                            onPressed: _pickReceiptPhoto,
                          ),
                        ],
                      ),
                    ),
                    if (_kind == CaptureKind.transfer) _transferAccounts(db),
                    if (_kind != CaptureKind.transfer)
                      _walletSelector(db, tokens),
                    _amountDisplay(tokens),
                    _noteLine(),
                    if (_kind != CaptureKind.transfer)
                      _frequentTemplates(db, tokens),
                    if (_split != null)
                      _splitSection(db, tokens)
                    else ...[
                      if (_kind != CaptureKind.transfer) _categories(db, tokens),
                      if (_categoryId != null) _subcategories(db, tokens),
                      if (_kind == CaptureKind.expense &&
                          widget.editingTransactionId == null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            key: const Key('captureSplitStart'),
                            icon: const Icon(Icons.call_split, size: 18),
                            label: const Text('Pecah ke beberapa kategori'),
                            onPressed: () => setState(() => _split = [
                                  _SplitLine(_categoryId, _amount.minor),
                                  _SplitLine(null, 0),
                                ]),
                          ),
                        ),
                    ],
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
              onToggleCalculator: () => setState(() {
                _calculatorMode = !_calculatorMode;
                if (!_calculatorMode) _settleBuffer();
              }),
              onPickDate: _pickDateTime,
            ),
            _saveButton(db),
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
        _toAccountId ??= accounts
            .firstWhere(
              (a) => a.id != _accountId,
              orElse: () => accounts.last,
            )
            .id;
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
                    for (final a in accounts)
                      DropdownMenuItem(value: a.id, child: Text(a.name)),
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
                    for (final a in accounts)
                      DropdownMenuItem(value: a.id, child: Text(a.name)),
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

  /// Where the entry goes, drawn as the mockup's `[GoPay v]` chip. The sheet
  /// used to pick the oldest wallet silently and offer no way to change it,
  /// which made Sprint 4's "allow override of auto-selection" unbuilt. One
  /// wallet is a plain label, since there is nothing to choose between.
  Widget _walletSelector(WudgetDatabase db, WudgetTokens tokens) {
    return StreamBuilder<List<Account>>(
      stream: (db.select(db.accounts)
            ..where((a) => a.archivedAt.isNull() & a.deletedAt.isNull())
            ..orderBy([(a) => OrderingTerm.asc(a.rowId)]))
          .watch(),
      builder: (context, snapshot) {
        final accounts = snapshot.data ?? const <Account>[];
        if (accounts.isEmpty) return const SizedBox.shrink();

        final selected = accounts.firstWhere(
          (a) => a.id == _accountId,
          orElse: () => accounts.first,
        );
        final text = Theme.of(context).textTheme;
        final label = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(walletTypeIcon(selected.type), size: 14, color: tokens.ink2),
            const SizedBox(width: 4),
            Text(selected.name,
                style: text.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
            if (accounts.length > 1) ...[
              const SizedBox(width: 2),
              Icon(Icons.arrow_drop_down, size: 16, color: tokens.ink2),
            ],
          ],
        );

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: WudgetTokens.space4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: accounts.length == 1
                ? Padding(
                    padding: const EdgeInsets.only(bottom: WudgetTokens.space2),
                    child: label,
                  )
                : PopupMenuButton<Account>(
                    tooltip: 'Ganti kantong',
                    position: PopupMenuPosition.under,
                    onSelected: (a) => setState(() => _accountId = a.id),
                    itemBuilder: (_) => [
                      for (final a in accounts)
                        PopupMenuItem(
                          value: a,
                          child: Row(
                            children: [
                              Icon(walletTypeIcon(a.type),
                                  size: 16, color: tokens.ink2),
                              const SizedBox(width: WudgetTokens.space2),
                              Text(a.name),
                              if (a.id == selected.id) ...[
                                const Spacer(),
                                Icon(Icons.check,
                                    size: 16, color: tokens.accent),
                              ],
                            ],
                          ),
                        ),
                    ],
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: WudgetTokens.space3),
                      child: label,
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _frequentTemplates(WudgetDatabase db, WudgetTokens tokens) {
    return FutureBuilder<
        List<({String categoryId, int amountMinor, String? note})>>(
      future: _loadFrequentTemplates(db),
      builder: (context, snapshot) {
        final templates = snapshot.data ?? [];
        if (templates.isEmpty) return const SizedBox.shrink();

        return SizedBox(
          height: 60,
          child: StreamBuilder<List<Category>>(
            stream: db.select(db.categories).watch(),
            builder: (context, catSnapshot) {
              final categories = {
                for (final c in catSnapshot.data ?? <Category>[]) c.id: c
              };
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: WudgetTokens.space4),
                itemCount: templates.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: WudgetTokens.space2),
                itemBuilder: (context, index) {
                  final template = templates[index];
                  final category = categories[template.categoryId];
                  if (category == null) return const SizedBox.shrink();

                  return ActionChip(
                    label: Text(
                      '${category.name} ${_formatter.format(Money.fromMinor(template.amountMinor, _currency))}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    onPressed: () {
                      setState(() {
                        _categoryId = template.categoryId;
                        _subcategoryId = null;
                        final info = CurrencyInfo.of(_currency);
                        _amountBuffer = info.exponent == 0
                            ? template.amountMinor.toString()
                            : (template.amountMinor / info.minorUnitsPerMajor)
                                .toString();
                        if (template.note != null) {
                          _noteController.text = template.note!;
                        }
                      });
                    },
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Future<List<({String categoryId, int amountMinor, String? note})>>
      _loadFrequentTemplates(
    WudgetDatabase db,
  ) async {
    final kind = _kind == CaptureKind.expense ? 'expense' : 'income';
    final query = '''
      SELECT p.category_id, p.amount_minor, t.note, COUNT(*) as cnt
      FROM transactions t
      JOIN postings p ON t.id = p.transaction_id
      WHERE t.kind = ? AND t.deleted_at IS NULL AND p.category_id IS NOT NULL
      GROUP BY p.category_id, p.amount_minor, t.note
      ORDER BY cnt DESC, MAX(t.occurred_at) DESC
      LIMIT 5
    ''';
    final result =
        await db.customSelect(query, variables: [Variable<String>(kind)]).get();
    return result
        .map((row) => (
              categoryId: row.read<String>('category_id'),
              amountMinor: row.read<int>('amount_minor'),
              note: row.read<String?>('note'),
            ))
        .toList();
  }

  Widget _categories(WudgetDatabase db, WudgetTokens tokens) {
    return StreamBuilder<List<Category>>(
      stream: (db.select(db.categories)
            ..where((c) => c.kind
                .equals(_kind == CaptureKind.expense ? 'expense' : 'income'))
            ..where((c) => c.parentId.isNull())
            ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
          .watch(),
      builder: (context, snapshot) {
        final rank = {
          for (var i = 0; i < _rankedIds.length; i++) _rankedIds[i]: i
        };
        final categories = [...?snapshot.data]..sort((a, b) =>
            (rank[a.id] ?? rank.length).compareTo(rank[b.id] ?? rank.length));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_rankedIds.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    WudgetTokens.space4,
                    WudgetTokens.space3,
                    WudgetTokens.space4,
                    WudgetTokens.space2),
                child: Text('Kategori, diurutkan dari kebiasaanmu jam segini',
                    style: Theme.of(context).textTheme.labelMedium),
              ),
            _CategoryRow(
              categories: categories,
              tokens: tokens,
              selectedId: _categoryId,
              onCreate: () => _createCategory(categories),
              onSelected: (id) {
                HapticFeedback.selectionClick();
                setState(() {
                  _categoryId = id;
                  _subcategoryId = null;
                });
                _adoptLastWalletFor(id);
              },
            ),
          ],
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
      stream: (db.select(db.categories)
            ..where((c) => c.parentId.equals(_categoryId!)))
          .watch(),
      builder: (context, snapshot) {
        final subcategories = snapshot.data ?? const [];
        if (subcategories.isEmpty) return const SizedBox.shrink();
        return _SubcategoryChips(
          subcategories: subcategories,
          selectedId: _subcategoryId,
          hueIndex: subcategories.first.hueIndex,
          tokens: tokens,
          onSelected: (id) =>
              setState(() => _subcategoryId = _subcategoryId == id ? null : id),
        );
      },
    );
  }

  Widget _amountDisplay(WudgetTokens tokens) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(
          top: WudgetTokens.space4, bottom: WudgetTokens.space2),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                CurrencyInfo.of(_currency).symbol,
                style:
                    text.titleLarge?.copyWith(fontSize: 20, color: tokens.ink2),
              ),
              const SizedBox(width: WudgetTokens.space2),
              // The operand being typed, with what is waiting for it on the
              // line below. Saving mid-expression still writes the total,
              // which the undo snackbar names, and leaving calculator mode
              // brings the total up here.
              Text(
                key: const Key('captureAmount'),
                _formatter.format(_operandAmount, showSymbol: false),
                semanticsLabel: 'Jumlah: ${_formatter.format(_operandAmount)}',
                style: text.headlineMedium?.copyWith(
                  fontSize: 40,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: WudgetTokens.space1),
              Container(width: 2, height: 34, color: tokens.accent),
            ],
          ),
          if (_saveBlocked && _blockingSave != null) ...[
            const SizedBox(height: WudgetTokens.space1),
            Text(
              _blockingSave!,
              style: text.bodySmall?.copyWith(color: tokens.warning),
            ),
          ],
          if (_pendingExpression.isNotEmpty) ...[
            const SizedBox(height: WudgetTokens.space1),
            Text(
              _pendingExpression.replaceAllMapped(
                  RegExp(r'[+\-×÷]'), (m) => ' ${m[0]} '),
              style: text.bodySmall?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _noteExpanded = false;
  bool _noteManuallyExpanded = false;

  Widget _noteLine() {
    if (!_noteExpanded) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: WudgetTokens.space4),
        child: InkWell(
          onTap: () => setState(() => _noteExpanded = true),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: WudgetTokens.space2),
            child: Row(
              children: [
                Icon(Icons.add,
                    size: 16, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: WudgetTokens.space2),
                Text(
                  'Tambah catatan',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: WudgetTokens.space4),
      child: TextField(
        key: const Key('captureNote'),
        controller: _noteController,
        textCapitalization: TextCapitalization.sentences,
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          hintText: 'Catatan, boleh kosong',
          suffixIcon: IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: () {
              _noteController.clear();
              setState(() => _noteExpanded = false);
            },
          ),
        ),
      ),
    );
  }

  Widget _splitSection(WudgetDatabase db, WudgetTokens tokens) {
    final split = _split!;
    final remainder = _splitRemainderMinor;
    return StreamBuilder<List<Category>>(
      stream: (db.select(db.categories)
            ..where((c) => c.kind.equals('expense'))
            ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
          .watch(),
      builder: (context, snapshot) {
        final categories = snapshot.data ?? const <Category>[];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: WudgetTokens.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Pecah ke kategori',
                        style: Theme.of(context).textTheme.labelMedium),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      for (final l in split) {
                        l.amount.dispose();
                      }
                      _split = null;
                    }),
                    child: const Text('Batal pecah'),
                  ),
                ],
              ),
              for (final (i, line) in split.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: WudgetTokens.space2),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<String>(
                          key: Key('splitCategory_$i'),
                          value: line.categoryId,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Kategori'),
                          items: [
                            for (final c in categories)
                              DropdownMenuItem(value: c.id, child: Text(c.name)),
                          ],
                          onChanged: (id) => setState(() => line.categoryId = id),
                        ),
                      ),
                      const SizedBox(width: WudgetTokens.space2),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          key: Key('splitAmount_$i'),
                          controller: line.amount,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Rp'),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        tooltip: 'Hapus bagian',
                        onPressed: () => setState(() => split.removeAt(i).amount.dispose()),
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  TextButton.icon(
                    key: const Key('splitAdd'),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Tambah kategori'),
                    onPressed: () => setState(() => split.add(_SplitLine(null, 0))),
                  ),
                  const Spacer(),
                  Text(
                    'Sisa ${_formatter.format(Money.fromMinor(remainder, _currency))}',
                    key: const Key('splitRemainder'),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: remainder == 0 ? tokens.ink2 : tokens.warning,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Says what the tap will do: "Simpan Rp 18.000 ke Makan".
  Widget _saveButton(WudgetDatabase db) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    return StreamBuilder<List<Category>>(
      stream: db.select(db.categories).watch(),
      builder: (context, snapshot) {
        final names = {
          for (final c in snapshot.data ?? const <Category>[]) c.id: c.name
        };
        final amount = _amount.isZero ? '' : ' ${_formatter.format(_amount)}';
        final category =
            _split != null ? null : names[_subcategoryId ?? _categoryId ?? ''];
        final label = switch (_kind) {
          // Income on a normal day; the gajian split arrives with payday (R3).
          CaptureKind.income => 'Simpan saja',
          CaptureKind.transfer => 'Simpan$amount',
          CaptureKind.expense => category == null || amount.isEmpty
              ? 'Simpan$amount'
              : 'Simpan$amount ke $category',
        };
        final canSave = _blockingSave == null;
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            WudgetTokens.space3,
            0,
            WudgetTokens.space3,
            WudgetTokens.space2,
          ),
          child: Semantics(
            button: true,
            label: canSave ? label : '$label, belum bisa',
            excludeSemantics: true,
            child: FilledButton(
              key: const Key('numpadKey_save'),
              onPressed: _save,
              // Recessed rather than disabled: the tap still answers by naming
              // what the sheet is waiting for.
              style: canSave
                  ? null
                  : FilledButton.styleFrom(
                      backgroundColor: tokens.surfaceMuted,
                      foregroundColor: tokens.ink2,
                    ),
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
        );
      },
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
                border: Border.all(
                    color: active ? tokens.accent : tokens.borderStrong),
              ),
              child: Icon(icon,
                  size: 20, color: active ? tokens.inkOnAccent : tokens.ink1),
            ),
          ),
        ),
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
                  color: selected
                      ? tokens.tintFor(c.hueIndex)
                      : tokens.surfaceMuted,
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
              _subcategoryChip(
                  subcategories[i], subcategories[i].id == selectedId),
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
      side:
          BorderSide(color: selected ? tokens.hueFor(hueIndex) : tokens.border),
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
  final VoidCallback onToggleCalculator;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    final rows = <List<Widget>>[
      [
        _digit('1'),
        _digit('2'),
        _digit('3'),
        _NumpadKey(
          key: const Key('numpadKey_backspace'),
          icon: Icons.backspace_outlined,
          semanticLabel: 'Hapus',
          onTap: onBackspace,
          tone: _KeyTone.action,
        ),
      ],
      [
        _digit('4'),
        _digit('5'),
        _digit('6'),
        _NumpadKey(
          key: const Key('numpadKey_calculator'),
          icon: Icons.calculate_outlined,
          semanticLabel: 'Kalkulator',
          onTap: onToggleCalculator,
          tone: calculatorMode ? _KeyTone.activeAction : _KeyTone.action,
        ),
      ],
      [
        _digit('7'),
        _digit('8'),
        _digit('9'),
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
            ? _NumpadKey(
                key: const Key('numpadKey_000'), label: '000', onTap: onZeros)
            : const SizedBox.shrink(),
        const SizedBox.shrink(),
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

enum _KeyTone { digit, action, activeAction }

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
                          fontSize: caption != null
                              ? 12.5
                              : (label!.length > 2 ? 16 : 21),
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

class _SplitLine {
  _SplitLine(this.categoryId, int minor)
      : amount = TextEditingController(text: minor == 0 ? '' : '$minor');
  String? categoryId;
  final TextEditingController amount;

  int get minor => int.tryParse(amount.text.replaceAll('.', '')) ?? 0;
}
