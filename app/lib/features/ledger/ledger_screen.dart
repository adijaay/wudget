import 'dart:async';

import 'package:drift/drift.dart' show TableUpdateQuery, Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/perf.dart';
import '../../core/money_formatter.dart';
import '../../core/providers.dart';
import '../../data/daily_totals_repository.dart';
import '../../data/database.dart';
import '../../data/ledger_queries.dart';
import '../../design/components.dart';
import '../../design/tokens.dart';
import '../capture/capture_sheet.dart';

const _pageSize = 50;

/// Catat: the ledger, grouped by day. Built to design/Catat.dc.html: each
/// day is one card with its own header and net total, and each row carries
/// the category's chip, the wallet and the time it happened, because "Makan"
/// and an amount alone is not enough to recognise an entry you made
/// yesterday. Editing an existing amount is still out of scope (see
/// DECISIONS.md); the note is editable, delete is a soft delete with undo.
class LedgerScreen extends ConsumerStatefulWidget {
  const LedgerScreen({super.key});

  @override
  ConsumerState<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends ConsumerState<LedgerScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final _entries = <LedgerEntry>[];
  final _dayTotals = <int, int>{};
  String? _categoryId;
  String? _categoryName;
  String? _accountId;
  String? _accountName;
  String _noteQuery = '';
  int? _minAmountMinor;
  int? _maxAmountMinor;
  bool _loading = false;
  bool _hasMore = true;
  bool _searchOpen = false;
  StreamSubscription<void>? _txChangesSubscription;
  // Bumped by every _loadFirstPage call so a reload triggered by the table
  // listener and one triggered explicitly can race without both appending
  // to _entries: a page fetch started under an older generation is
  // discarded once a newer one has started.
  int _loadGeneration = 0;

  LedgerFilter get _filter => LedgerFilter(
        categoryId: _categoryId,
        categoryName: _categoryName,
        accountId: _accountId,
        accountName: _accountName,
        noteQuery: _noteQuery.isEmpty ? null : _noteQuery,
        minAmountMinor: _minAmountMinor,
        maxAmountMinor: _maxAmountMinor,
      );

  bool get _hasActiveFilter =>
      _categoryId != null ||
      _accountId != null ||
      _noteQuery.isNotEmpty ||
      _minAmountMinor != null ||
      _maxAmountMinor != null;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadFirstPage();

    // HomeShell keeps every tab alive in an IndexedStack, so this screen's
    // one-shot page load never re-runs on its own when a transaction is
    // added from the capture button or another tab — only a real change
    // notification catches that.
    final db = ref.read(databaseProvider);
    _txChangesSubscription = db
        .tableUpdates(TableUpdateQuery.onTable(db.transactions))
        .listen((_) => _loadFirstPage());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _txChangesSubscription?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _loading) return;
    if (_scrollController.position.pixels > _scrollController.position.maxScrollExtent - 200) {
      _loadNextPage();
    }
  }

  Future<void> _loadFirstPage() async {
    final render = Stopwatch()..start();
    final generation = ++_loadGeneration;
    setState(() {
      _entries.clear();
      _dayTotals.clear();
      _hasMore = true;
    });
    await _loadNextPage(generation);
    if (mounted) perfMark('catat_render', render);
  }

  Future<void> _loadNextPage([int? generation]) async {
    generation ??= _loadGeneration;
    setState(() => _loading = true);
    final page = await ref
        .read(ledgerQueriesProvider)
        .page(limit: _pageSize, offset: _entries.length, filter: _filter);

    final days = {
      for (final e in page) dayBucketFor(e.occurredAtUtcMillis, e.tzOffsetMinutes),
    };
    final db = ref.read(databaseProvider);
    for (final day in days.difference(_dayTotals.keys.toSet())) {
      final row =
          await (db.select(db.dailyTotals)..where((t) => t.day.equals(day))).getSingleOrNull();
      _dayTotals[day] = row?.netMinor ?? 0;
    }

    if (!mounted || generation != _loadGeneration) return;
    setState(() {
      _entries.addAll(page);
      _hasMore = page.length == _pageSize;
      _loading = false;
    });
  }

  Future<void> _deleteEntry(LedgerEntry entry) async {
    await ref.read(postingsRepositoryProvider).deleteTransaction(entry.transactionId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Transaksi dihapus'),
        action: SnackBarAction(
          label: 'Batalkan',
          onPressed: () =>
              ref.read(postingsRepositoryProvider).restoreTransaction(entry.transactionId),
        ),
      ),
    );
  }

  Future<void> _editNote(LedgerEntry entry) async {
    final db = ref.read(databaseProvider);
    final controller = TextEditingController(text: entry.note ?? '');
    final newNote = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah catatan'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (newNote == null) return;
    await (db.update(db.transactions)..where((t) => t.id.equals(entry.transactionId))).write(
      TransactionsCompanion(
        note: Value(newNote.isEmpty ? null : newNote),
        updatedAt: Value(DateTime.now().toUtc().millisecondsSinceEpoch),
      ),
    );
  }

  void _openCaptureSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const CaptureSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catat'),
        actions: [
          IconButton(
            tooltip: 'Cari catatan',
            icon: Icon(_searchOpen ? Icons.search_off : Icons.search),
            onPressed: () => setState(() {
              _searchOpen = !_searchOpen;
              if (!_searchOpen && _noteQuery.isNotEmpty) {
                _searchController.clear();
                _noteQuery = '';
                _loadFirstPage();
              }
            }),
          ),
          IconButton(
            tooltip: 'Filter',
            icon: Badge(
              isLabelVisible: _hasActiveFilter,
              backgroundColor: tokens.accent,
              child: const Icon(Icons.filter_list),
            ),
            onPressed: () => _showFilterSheet(context),
          ),
          const SizedBox(width: WudgetTokens.space1),
        ],
      ),
      body: Column(
        children: [
          if (_searchOpen)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                WudgetTokens.space4,
                0,
                WudgetTokens.space4,
                WudgetTokens.space3,
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  hintText: 'Cari catatan',
                  prefixIcon: Icon(Icons.search),
                ),
                onSubmitted: (v) {
                  _noteQuery = v;
                  _loadFirstPage();
                },
              ),
            ),
          if (_hasActiveFilter) _ActiveFilterChips(
            categoryName: _categoryName,
            accountName: _accountName,
            noteQuery: _noteQuery,
            hasAmountFilter: _minAmountMinor != null || _maxAmountMinor != null,
            onClearCategory: () => setState(() {
              _categoryId = null;
              _categoryName = null;
              _loadFirstPage();
            }),
            onClearAccount: () => setState(() {
              _accountId = null;
              _accountName = null;
              _loadFirstPage();
            }),
            onClearNote: () => setState(() {
              _noteQuery = '';
              _searchController.clear();
              _loadFirstPage();
            }),
            onClearAmount: () => setState(() {
              _minAmountMinor = null;
              _maxAmountMinor = null;
              _loadFirstPage();
            }),
          ),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_entries.isEmpty && _loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_entries.isEmpty) {
      return _hasActiveFilter
          ? _FilteredEmpty(
              description: _filter.describe(),
              onClearAll: () => setState(() {
                _categoryId = null;
                _categoryName = null;
                _accountId = null;
                _accountName = null;
                _noteQuery = '';
                _searchController.clear();
                _minAmountMinor = null;
                _maxAmountMinor = null;
                _loadFirstPage();
              }),
            )
          : _FirstRunEmpty(onCreate: _openCaptureSheet);
    }

    // One card per day, so the day header and its net total belong to the
    // rows underneath rather than floating above a continuous list.
    final groups = <int, List<LedgerEntry>>{};
    for (final e in _entries) {
      groups.putIfAbsent(dayBucketFor(e.occurredAtUtcMillis, e.tzOffsetMinutes), () => []).add(e);
    }
    final days = groups.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(
        WudgetTokens.space4,
        0,
        WudgetTokens.space4,
        WudgetTokens.space6,
      ),
      itemCount: days.length + 1,
      itemBuilder: (context, index) {
        if (index == days.length) {
          return _loading
              ? const Padding(
                  padding: EdgeInsets.all(WudgetTokens.space4),
                  child: Center(child: CircularProgressIndicator()),
                )
              : const SizedBox(height: WudgetTokens.space4);
        }
        final day = days[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: WudgetTokens.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DayHeader(day: day, netMinor: _dayTotals[day] ?? 0),
              CardGroup(
                children: [
                  for (final entry in groups[day]!)
                    _EntryRow(
                      entry: entry,
                      onDelete: () => _deleteEntry(entry),
                      onEditNote: () => _editNote(entry),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFilterSheet(BuildContext context) {
    final db = ref.read(databaseProvider);
    var category = _categoryId;
    var categoryName = _categoryName;
    var account = _accountId;
    var accountName = _accountName;
    var minAmount = _minAmountMinor;
    var maxAmount = _maxAmountMinor;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + WudgetTokens.space4,
          left: WudgetTokens.space4,
          right: WudgetTokens.space4,
          top: WudgetTokens.space4,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Filter', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: WudgetTokens.space4),
              StreamBuilder<List<Category>>(
                stream: db.select(db.categories).watch(),
                builder: (context, snapshot) {
                  final categories = snapshot.data ?? const [];
                  return DropdownButtonFormField<String?>(
                    value: category,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Kategori'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Semua kategori')),
                      for (final c in categories) DropdownMenuItem(value: c.id, child: Text(c.name)),
                    ],
                    onChanged: (id) {
                      category = id;
                      categoryName =
                          categories.where((c) => c.id == id).map((c) => c.name).firstOrNull;
                    },
                  );
                },
              ),
              const SizedBox(height: WudgetTokens.space3),
              StreamBuilder<List<Account>>(
                stream: db.select(db.accounts).watch(),
                builder: (context, snapshot) {
                  final accounts = snapshot.data ?? const [];
                  return DropdownButtonFormField<String?>(
                    value: account,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Kantong'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Semua kantong')),
                      for (final a in accounts) DropdownMenuItem(value: a.id, child: Text(a.name)),
                    ],
                    onChanged: (id) {
                      account = id;
                      accountName = accounts.where((a) => a.id == id).map((a) => a.name).firstOrNull;
                    },
                  );
                },
              ),
              const SizedBox(height: WudgetTokens.space3),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(labelText: 'Minimal (Rp)'),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => minAmount = int.tryParse(v),
                    ),
                  ),
                  const SizedBox(width: WudgetTokens.space3),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(labelText: 'Maksimal (Rp)'),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => maxAmount = int.tryParse(v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: WudgetTokens.space4),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _categoryId = category;
                    _categoryName = categoryName;
                    _accountId = account;
                    _accountName = accountName;
                    _minAmountMinor = minAmount;
                    _maxAmountMinor = maxAmount;
                  });
                  _loadFirstPage();
                },
                child: const Text('Terapkan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day, required this.netMinor});
  final int day;
  final int netMinor;

  @override
  Widget build(BuildContext context) {
    final date = DateTime.fromMillisecondsSinceEpoch(day * 86400000, isUtc: true);
    final today = DateTime.now();
    final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
    // The year only appears once the date is not in this one: printing it on
    // every header is noise while scrolling this month, and dropping it
    // entirely makes a row from a previous year unreadable.
    final pattern = date.year == today.year ? 'EEEE, d MMM' : 'EEEE, d MMM yyyy';
    final label = isToday
        ? 'Hari ini, ${DateFormat('d MMM', 'id_ID').format(date)}'
        : DateFormat(pattern, 'id_ID').format(date);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        WudgetTokens.space1,
        0,
        WudgetTokens.space1,
        WudgetTokens.space2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 13),
            ),
          ),
          AmountText(
            minor: netMinor,
            sign: MoneySign.explicit,
            colorBySign: true,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.entry, required this.onDelete, required this.onEditNote});
  final LedgerEntry entry;
  final VoidCallback onDelete;
  final VoidCallback onEditNote;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final time = DateFormat('HH:mm').format(
      DateTime.fromMillisecondsSinceEpoch(entry.occurredAtUtcMillis, isUtc: true)
          .add(Duration(minutes: entry.tzOffsetMinutes)),
    );
    final hue = entry.categoryHueIndex;

    return Dismissible(
      key: ValueKey(entry.transactionId),
      direction: DismissDirection.endToStart,
      // A fixed strong red, not tokens.negative: that token is tuned as a
      // *text* colour against each theme's surface, so in dark theme it is
      // too light to hold a white icon at AA contrast — see DECISIONS.md,
      // Sprint 18. A delete backdrop needs its own guarantee.
      background: Container(
        color: Colors.red.shade700,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: WudgetTokens.space4),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: CardRow(
        leading: IconChip(
          // A transfer has no category leg, so it gets the movement icon on
          // a neutral ground rather than a borrowed category hue.
          icon: hue == null
              ? Icons.swap_horiz
              : categoryIcon(entry.categoryIconKey ?? 'category'),
          background: hue == null ? tokens.surfaceMuted : tokens.tintFor(hue),
          foreground: hue == null ? tokens.ink2 : tokens.inkFor(hue),
        ),
        // The category leads, as in the mockup: it is what the eye scans a
        // day's rows for. A transfer has no category, so it leads with the
        // two wallets it moved between.
        title: entry.categoryName ?? entry.accountName,
        // "GoPay, 12:24": which wallet it came out of and when, which is how
        // you recognise an entry you made yesterday. The note joins the
        // front of that line when there is one.
        subtitle: [
          if (entry.note?.isNotEmpty == true) entry.note!,
          if (entry.categoryName != null) entry.accountName,
          time,
        ].join(' · '),
        trailing: AmountText(
          minor: entry.amountMinor,
          sign: MoneySign.explicit,
          showSymbol: false,
          colorBySign: true,
        ),
        onTap: onEditNote,
      ),
    );
  }
}

/// Active filters as dismissible chips, so what is excluding rows is visible
/// on the list itself and not only inside the filter sheet
/// (design/States.dc.html, "kosong, kena filter").
class _ActiveFilterChips extends StatelessWidget {
  const _ActiveFilterChips({
    required this.categoryName,
    required this.accountName,
    required this.noteQuery,
    required this.hasAmountFilter,
    required this.onClearCategory,
    required this.onClearAccount,
    required this.onClearNote,
    required this.onClearAmount,
  });
  final String? categoryName;
  final String? accountName;
  final String noteQuery;
  final bool hasAmountFilter;
  final VoidCallback onClearCategory;
  final VoidCallback onClearAccount;
  final VoidCallback onClearNote;
  final VoidCallback onClearAmount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        WudgetTokens.space4,
        0,
        WudgetTokens.space4,
        WudgetTokens.space3,
      ),
      child: Wrap(
        spacing: WudgetTokens.space2,
        runSpacing: WudgetTokens.space2,
        children: [
          if (categoryName != null)
            InputChip(label: Text(categoryName!), onDeleted: onClearCategory),
          if (accountName != null)
            InputChip(label: Text(accountName!), onDeleted: onClearAccount),
          if (noteQuery.isNotEmpty)
            InputChip(label: Text('"$noteQuery"'), onDeleted: onClearNote),
          if (hasAmountFilter)
            InputChip(label: const Text('rentang nominal'), onDeleted: onClearAmount),
        ],
      ),
    );
  }
}

class _FirstRunEmpty extends StatelessWidget {
  const _FirstRunEmpty({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        WudgetTokens.space4,
        0,
        WudgetTokens.space4,
        WudgetTokens.space6,
      ),
      children: [
        WudgetCard(
          dashed: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Opacity(
                opacity: 0.45,
                child: Row(
                  children: [
                    IconChip(
                      icon: Icons.restaurant_outlined,
                      background: tokens.tintFor(0),
                      foreground: tokens.inkFor(0),
                    ),
                    const SizedBox(width: WudgetTokens.space3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(height: 11, width: 96, color: tokens.surfaceMuted),
                          const SizedBox(height: 6),
                          Container(height: 8, width: 62, color: tokens.surfaceMuted),
                        ],
                      ),
                    ),
                    Container(height: 11, width: 58, color: tokens.surfaceMuted),
                  ],
                ),
              ),
              const SizedBox(height: WudgetTokens.space4),
              Text(
                'Nanti tiap yang kamu catat muncul begini: kategorinya, '
                'kantongnya, jamnya, dan nominalnya. Total per hari ada di '
                'atas tiap kelompok.',
                style: text.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: WudgetTokens.space5),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: WudgetTokens.space1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mulai dari satu saja', style: text.titleLarge),
              const SizedBox(height: WudgetTokens.space2),
              Text(
                'Kopi tadi pagi juga boleh. Yang penting jalan dulu, anggaran belakangan.',
                style: text.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: WudgetTokens.space4),
        FilledButton(onPressed: onCreate, child: const Text('Catat pengeluaran pertama')),
      ],
    );
  }
}

/// Filtered to nothing is a different screen from "nothing recorded yet": it
/// names what is excluding everything and offers the way out.
class _FilteredEmpty extends StatelessWidget {
  const _FilteredEmpty({required this.description, required this.onClearAll});
  final String description;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        WudgetTokens.space4,
        0,
        WudgetTokens.space4,
        WudgetTokens.space6,
      ),
      children: [
        WudgetCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.filter_list_off, size: 26, color: tokens.ink2),
              const SizedBox(height: WudgetTokens.space3),
              Text('Tidak ada transaksi untuk $description.', style: text.titleLarge),
              const SizedBox(height: WudgetTokens.space2),
              Text(
                'Filternya menyaring semua catatan yang ada. Lepas satu filter '
                'lewat tandanya di atas, atau hapus semuanya.',
                style: text.bodyMedium,
              ),
              const SizedBox(height: WudgetTokens.space4),
              FilledButton(onPressed: onClearAll, child: const Text('Hapus semua filter')),
            ],
          ),
        ),
      ],
    );
  }
}
