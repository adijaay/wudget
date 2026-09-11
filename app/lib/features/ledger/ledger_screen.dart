import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/money.dart';
import '../../core/money_formatter.dart';
import '../../core/providers.dart';
import '../../data/daily_totals_repository.dart';
import '../../data/database.dart';
import '../../data/ledger_queries.dart';
import '../../design/tokens.dart';
import '../capture/capture_sheet.dart';

const _formatter = MoneyFormatter();
const _pageSize = 50;

/// Catat: the date-grouped transaction list. See plan/05-sprints.md
/// Sprint 6. Editing an existing transaction's amount/category is out of
/// scope this sprint — see DECISIONS.md; only its note is editable here.
/// Deleting is a soft delete with undo.
class LedgerScreen extends ConsumerStatefulWidget {
  const LedgerScreen({super.key});

  @override
  ConsumerState<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends ConsumerState<LedgerScreen> {
  final _scrollController = ScrollController();
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

  LedgerFilter get _filter => LedgerFilter(
        categoryId: _categoryId,
        categoryName: _categoryName,
        accountId: _accountId,
        accountName: _accountName,
        noteQuery: _noteQuery.isEmpty ? null : _noteQuery,
        minAmountMinor: _minAmountMinor,
        maxAmountMinor: _maxAmountMinor,
      );

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadFirstPage();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _loading) return;
    if (_scrollController.position.pixels > _scrollController.position.maxScrollExtent - 200) {
      _loadNextPage();
    }
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _entries.clear();
      _dayTotals.clear();
      _hasMore = true;
    });
    await _loadNextPage();
  }

  Future<void> _loadNextPage() async {
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

    if (!mounted) return;
    setState(() {
      _entries.addAll(page);
      _hasMore = page.length == _pageSize;
      _loading = false;
    });
  }

  Future<void> _deleteEntry(LedgerEntry entry) async {
    await ref.read(postingsRepositoryProvider).deleteTransaction(entry.transactionId);
    await _loadFirstPage();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Transaksi dihapus'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            await ref.read(postingsRepositoryProvider).restoreTransaction(entry.transactionId);
            await _loadFirstPage();
          },
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
    await _loadFirstPage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catat'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: WudgetTokens.space4, vertical: WudgetTokens.space2),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Cari catatan...',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onSubmitted: (v) {
                _noteQuery = v;
                _loadFirstPage();
              },
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSheet(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => const CaptureSheet(),
        ).then((_) => _loadFirstPage()),
        child: const Icon(Icons.add),
      ),
      body: _entries.isEmpty && !_loading
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(WudgetTokens.space5),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _filter.describe().isEmpty
                          ? 'Belum ada transaksi. Setiap catatan muncul di sini, dikelompokkan per hari.'
                          : 'Tidak ada transaksi untuk ${_filter.describe()}.',
                      textAlign: TextAlign.center,
                    ),
                    if (_filter.describe().isEmpty) ...[
                      const SizedBox(height: WudgetTokens.space3),
                      FilledButton(
                        onPressed: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => const CaptureSheet(),
                        ).then((_) => _loadFirstPage()),
                        child: const Text('Catat transaksi pertama'),
                      ),
                    ],
                  ],
                ),
              ),
            )
          : ListView.builder(
              controller: _scrollController,
              itemCount: _entries.length + 1,
              itemBuilder: (context, index) {
                if (index == _entries.length) {
                  return _loading
                      ? const Padding(
                          padding: EdgeInsets.all(WudgetTokens.space4),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : const SizedBox.shrink();
                }

                final entry = _entries[index];
                final day = dayBucketFor(entry.occurredAtUtcMillis, entry.tzOffsetMinutes);
                final showHeader =
                    index == 0 || dayBucketFor(_entries[index - 1].occurredAtUtcMillis, _entries[index - 1].tzOffsetMinutes) != day;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showHeader) _DayHeader(day: day, netMinor: _dayTotals[day] ?? 0),
                    _EntryTile(entry: entry, onDelete: () => _deleteEntry(entry), onEditNote: () => _editNote(entry)),
                  ],
                );
              },
            ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    final db = ref.read(databaseProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: WudgetTokens.space4,
          right: WudgetTokens.space4,
          top: WudgetTokens.space4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StreamBuilder<List<Category>>(
              stream: db.select(db.categories).watch(),
              builder: (context, snapshot) {
                final categories = snapshot.data ?? const [];
                return DropdownButtonFormField<String?>(
                  value: _categoryId,
                  decoration: const InputDecoration(labelText: 'Kategori'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Semua kategori')),
                    for (final c in categories) DropdownMenuItem(value: c.id, child: Text(c.name)),
                  ],
                  onChanged: (id) {
                    _categoryId = id;
                    _categoryName = categories.where((c) => c.id == id).map((c) => c.name).firstOrNull;
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
                  value: _accountId,
                  decoration: const InputDecoration(labelText: 'Dompet'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Semua dompet')),
                    for (final a in accounts) DropdownMenuItem(value: a.id, child: Text(a.name)),
                  ],
                  onChanged: (id) {
                    _accountId = id;
                    _accountName = accounts.where((a) => a.id == id).map((a) => a.name).firstOrNull;
                  },
                );
              },
            ),
            const SizedBox(height: WudgetTokens.space3),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'Min (Rp)'),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => _minAmountMinor = int.tryParse(v),
                  ),
                ),
                const SizedBox(width: WudgetTokens.space3),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'Maks (Rp)'),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => _maxAmountMinor = int.tryParse(v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: WudgetTokens.space4),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _loadFirstPage();
              },
              child: const Text('Terapkan'),
            ),
            const SizedBox(height: WudgetTokens.space4),
          ],
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
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: WudgetTokens.space4, vertical: WudgetTokens.space2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(DateFormat('d MMM yyyy', 'id_ID').format(date)),
          Text(_formatter.format(Money.fromMinor(netMinor, 'IDR'), sign: MoneySign.explicit)),
        ],
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry, required this.onDelete, required this.onEditNote});
  final LedgerEntry entry;
  final VoidCallback onDelete;
  final VoidCallback onEditNote;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final money = Money.fromMinor(entry.amountMinor, 'IDR');
    return Dismissible(
      key: ValueKey(entry.transactionId),
      direction: DismissDirection.endToStart,
      // A fixed strong red, not tokens.negative: that token is tuned as a
      // *text* color against each theme's surface (light red on dark
      // surface, dark red on light surface), so in dark theme it's too
      // light to hold a white icon at AA contrast — see DECISIONS.md,
      // Sprint 18. A delete-swipe backdrop needs its own guarantee, not a
      // theme-adaptive text color repurposed as a background.
      background: Container(color: Colors.red.shade700, alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: WudgetTokens.space4),
          child: const Icon(Icons.delete, color: Colors.white)),
      onDismissed: (_) => onDelete(),
      child: ListTile(
        title: Text(entry.categoryName ?? entry.accountName),
        subtitle: entry.note != null && entry.note!.isNotEmpty ? Text(entry.note!) : null,
        trailing: Text(
          _formatter.format(money, sign: MoneySign.explicit),
          style: TextStyle(color: money.isNegative ? tokens.negative : tokens.positive),
        ),
        onTap: onEditNote,
      ),
    );
  }
}
