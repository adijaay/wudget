import 'dart:async';

import 'package:drift/drift.dart' show TableUpdateQuery;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/perf.dart';
import '../../core/money_formatter.dart';
import '../../core/providers.dart';
import '../../core/money.dart';
import '../../data/capture_queries.dart';
import '../../data/daily_totals_repository.dart';
import '../../data/database.dart';
import '../../data/ledger_queries.dart';
import '../../design/components.dart';
import '../../design/tokens.dart';
import '../../domain/period.dart';
import '../../data/category_rank_queries.dart';
import '../../domain/flow.dart';
import '../../domain/insight.dart';
import '../../domain/pola.dart';
import '../capture/capture_sheet.dart';
import '../widget/capture_deeplink.dart';
import 'today_header.dart';

const _pageSize = 50;

/// Catat: the ledger, grouped by day. Built to design/Catat.dc.html: each
/// day is one card with its own header and net total, and each row carries
/// the category's chip, the wallet and the time it happened, because "Makan"
/// and an amount alone is not enough to recognise an entry you made
/// yesterday. Tapping a row reopens the capture sheet prefilled from it —
/// editing is a full recapture, not a one-field dialog. Delete is a soft
/// delete with undo.
class LedgerScreen extends ConsumerStatefulWidget {
  const LedgerScreen({super.key, this.onOpenKantong});

  /// Switches the shell to Kantong; null where there is no shell (tests).
  final VoidCallback? onOpenKantong;

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
  int _today = todayDayBucket();
  AsyncValue<TodayHeaderData> _jatah = const AsyncLoading();
  AsyncValue<LoggedStripData> _strip = const AsyncLoading();
  AsyncValue<Insight?> _insight = const AsyncLoading();
  List<QuickChip> _quickChips = const [];

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
    // The mark stops here on purpose: `catat_render` measures time to the
    // ledger being on screen, and the header fills in after it rather than
    // holding the rows back. Folding the header into the mark would have
    // changed what the number means mid-history.
    if (mounted) perfMark('catat_render', render);
    await _loadTodayHeader(generation);
  }

  /// Home's three blocks, loaded alongside the first page so the header and
  /// the rows agree about today. Each block is guarded on its own (R2.6).
  Future<void> _loadTodayHeader(int generation) async {
    final today = todayDayBucket();
    final period = ref.read(currentPeriodProvider);
    final queries = ref.read(periodAggregateQueriesProvider);
    bool stale() => !mounted || generation != _loadGeneration;

    final chips = await ref.read(captureQueriesProvider).quickChips(DateTime.now());
    if (stale()) return;
    setState(() {
      _today = today;
      _quickChips = chips;
    });

    final jatah = await AsyncValue.guard(() async {
      final budgets = await ref.read(budgetsRepositoryProvider).getAll();
      final budgetTotal = budgets.values.fold<int>(0, (sum, amount) => sum + amount);
      final totals = await queries.totalsFor(period);
      final todaySpend = await queries.dailyExpenseMinorInRange(today, today + 1);
      return TodayHeaderData(
        todayDay: today,
        todaySpendMinor: todaySpend[today] ?? 0,
        // Today counts as a day left: its jatah is what today may still spend.
        allowance: computeDailyAllowance(
          budgetTotalMinor: budgetTotal,
          spentMinor: totals.expenseMinor,
          daysRemaining: period.endDayExclusive - today,
        ),
      );
    });
    if (stale()) return;
    setState(() => _jatah = jatah);

    final strip = await AsyncValue.guard(() async => LoggedStripData(
          startDay: period.startDay,
          endDayExclusive: period.endDayExclusive,
          todayDay: today,
          entryDays: await DailyTotalsRepository(ref.read(databaseProvider))
              .entryDays(period.startDay, period.endDayExclusive),
        ));
    if (stale()) return;
    setState(() => _strip = strip);

    final insight = await AsyncValue.guard(() => _pickInsight(today, period));
    if (stale()) return;
    setState(() => _insight = insight);
  }

  Future<Insight?> _pickInsight(int today, Period period) async {
    final queries = ref.read(periodAggregateQueriesProvider);
    final ranks = ref.read(categoryRankQueriesProvider);
    final analytics = ref.read(analyticsRepositoryProvider);

    List<({String key, String name, int amountMinor, int hueIndex})> rows(List<CategoryRank> r) => [
          for (final c in r) (key: c.key, name: c.name, amountMinor: c.amountMinor, hueIndex: c.hueIndex)
        ];
    final thisWeek = await ranks.rankedSpend(today - 6, today + 1);
    final lastWeek = await ranks.rankedSpend(today - 13, today - 6);
    final patternStart = today - 55;
    final last = period.previous;
    final lastTotals = await queries.totalsFor(last);
    final lastRanks = await ranks.rankedSpend(last.startDay, last.endDayExclusive);

    final candidates = insightCandidates(
      weekDeltas: lastWeek.isEmpty ? const [] : buildCategoryDeltas(current: rows(thisWeek), previous: rows(lastWeek)),
      pattern: computeWeekdayPattern(
        dailyExpenseMinor: await queries.dailyExpenseMinorInRange(patternStart, today + 1),
        sinceDayInclusive: patternStart,
        untilDayExclusive: today + 1,
      ),
      lastPeriodFlow: buildFlowBreakdown(
        incomeMinor: lastTotals.incomeMinor,
        expenseMinor: lastTotals.expenseMinor,
        ranks: [for (final r in lastRanks) (name: r.name, amountMinor: r.amountMinor, hueIndex: r.hueIndex)],
      ),
    );
    final recent = await analytics.recentInsights();
    final picked = pickDailyInsight(candidates: candidates, recent: recent, today: today);
    if (picked != null && !recent.any((r) => r.day == today && r.key == picked.key)) {
      await analytics.logEvent('insight_shown', props: {'day': today, 'key': picked.key});
    }
    return picked;
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

  /// Editing an entry opens the same capture sheet a new transaction does,
  /// prefilled from what's already recorded — calculator, categories,
  /// wallet, date, photo, all of it — rather than a one-field dialog that
  /// could only ever touch the note. See CaptureSheet.editingTransactionId.
  void _editEntry(LedgerEntry entry) {
    final occurredAt =
        DateTime.fromMillisecondsSinceEpoch(entry.occurredAtUtcMillis, isUtc: true)
            .add(Duration(minutes: entry.tzOffsetMinutes));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => CaptureSheet(
        initialKind: switch (entry.kind) {
          'income' => CaptureKind.income,
          'transfer' => CaptureKind.transfer,
          _ => CaptureKind.expense,
        },
        initialAmountMinor: entry.amountMinor.abs(),
        initialCategoryId: entry.categoryParentId ?? entry.categoryId,
        initialSubcategoryId: entry.categoryParentId == null ? null : entry.categoryId,
        initialAccountId: entry.accountId,
        initialToAccountId: entry.toAccountId,
        initialNote: entry.note,
        initialOccurredAt: occurredAt,
        initialPhotoPath: entry.photoPath,
        editingTransactionId: entry.transactionId,
      ),
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

  /// Home above the ledger: jatah, strip, insight, quick chips.
  Widget _homeHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: WudgetTokens.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TodayHeader(
            todayDay: _today,
            jatah: _jatah,
            strip: _strip,
            insight: _insight,
            firstRun: _entries.isEmpty,
            onOpenKantong: widget.onOpenKantong == null
                ? null
                : () {
                    ref.read(analyticsRepositoryProvider).logEvent('home_open_kantong',
                        props: {'budgetSet': _jatah.valueOrNull?.allowance != null});
                    widget.onOpenKantong!();
                  },
            onCapture: () => showCaptureLaunch(
              context,
              const CaptureLaunch(kind: CaptureKind.expense),
              source: CaptureSource.home,
            ),
            onRetry: () => _loadTodayHeader(_loadGeneration),
          ),
          if (_quickChips.isNotEmpty)
            _QuickChips(
              chips: _quickChips,
              onTap: (chip) => showCaptureLaunch(
                context,
                CaptureLaunch.fromChip(chip),
                source: CaptureSource.chip,
              ),
            ),
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
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: WudgetTokens.space4),
              children: [_homeHeader()],
            );
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
      // The header is item 0, so the day list is offset by one. It only
      // appears on the unfiltered ledger: a filtered view is a search
      // result, and "today" is not what the user is looking at.
      itemCount: days.length + 2,
      itemBuilder: (context, index) {
        if (index == 0) {
          if (_hasActiveFilter) return const SizedBox.shrink();
          return _homeHeader();
        }
        index -= 1;
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
                      onEdit: () => _editEntry(entry),
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
  const _EntryRow({required this.entry, required this.onDelete, required this.onEdit});
  final LedgerEntry entry;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

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
        onTap: onEdit,
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

/// "Warung 18.000": a past entry repeated in one tap, ranked for this hour.
class _QuickChips extends StatelessWidget {
  const _QuickChips({required this.chips, required this.onTap});
  final List<QuickChip> chips;
  final ValueChanged<QuickChip> onTap;

  static const _formatter = MoneyFormatter();

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    return Padding(
      padding: const EdgeInsets.only(top: WudgetTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Sering kamu catat jam segini'),
          Wrap(
            spacing: WudgetTokens.space2,
            runSpacing: WudgetTokens.space2,
            children: [
              for (final chip in chips)
                ActionChip(
                  key: Key('quickChip_${chip.note}'),
                  avatar: CircleAvatar(radius: 5, backgroundColor: tokens.hueFor(chip.hueIndex)),
                  label: Text.rich(TextSpan(children: [
                    TextSpan(text: '${chip.note} '),
                    TextSpan(
                      text: _formatter.format(Money.fromMinor(chip.amountMinor, 'IDR'), showSymbol: false),
                      style: TextStyle(color: tokens.ink2),
                    ),
                  ])),
                  onPressed: () => onTap(chip),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
