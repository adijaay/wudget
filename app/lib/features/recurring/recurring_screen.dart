import 'dart:convert';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/money.dart';
import '../../core/money_formatter.dart';
import '../../core/providers.dart';
import '../../data/database.dart';
import '../../data/recurrence_repository.dart';
import '../../data/recurring_queries.dart';
import '../../design/components.dart';
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

  Future<void> _createRecurring() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _CreateRecurringSheet(),
    );
    await _load();
  }

  void _editRecurring(BuildContext context, Recurrence row) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EditRecurringSheet(recurrence: row),
    ).then((_) => _load());
  }

  Future<void> _deleteRecurring(BuildContext context, Recurrence row) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus item berulang?'),
        content: const Text('Item yang sudah dibuat tidak akan terpengaruh.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (confirmed != true) return;
    
    final db = ref.read(databaseProvider);
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await (db.update(db.recurrences)..where((r) => r.id.equals(row.id)))
        .write(RecurrencesCompanion(deletedAt: Value(now)));
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final upcoming = _upcoming;
    final active = _active;
    if (upcoming == null || active == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final today = _todayDayBucket();
    final subscriptions = [for (final r in active) if (r.isSubscription) r];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Berulang & tagihan'),
        actions: [
          IconButton(icon: const Icon(Icons.add), tooltip: 'Tambah item berulang', onPressed: _createRecurring),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          WudgetTokens.space4,
          0,
          WudgetTokens.space4,
          WudgetTokens.space6,
        ),
        children: [
          const SectionLabel('Akan datang'),
          if (upcoming.isEmpty)
            WudgetCard(
              child: Text(
                'Tidak ada tagihan yang menunggu dikonfirmasi.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          else
            CardGroup(
              children: [
                for (final instance in upcoming)
                  _UpcomingTile(
                    instance: instance,
                    onConfirm: () => _confirm(instance),
                    onSkip: () => _skip(instance),
                  ),
              ],
            ),
          if (subscriptions.isNotEmpty) ...[
            const SizedBox(height: WudgetTokens.space5),
            const SectionLabel('Langganan'),
            CardGroup(
              children: [
                for (final row in subscriptions)
                  _ActiveTile(
                    row: row,
                    today: today,
                    onEdit: () => _editRecurring(context, row),
                    onDelete: () => _deleteRecurring(context, row),
                  ),
                CardRow(
                  title: 'Total per bulan',
                  trailing: AmountText(minor: subscriptionMonthlyMinor(subscriptions)),
                ),
              ],
            ),
          ],
          const SizedBox(height: WudgetTokens.space5),
          const SectionLabel('Aktif'),
          if (active.isEmpty)
            WudgetCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Item berulang adalah tagihan atau pemasukan yang datang lagi tiap periode, '
                    'seperti "Listrik, Rp150.000, tiap tanggal 5".',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: WudgetTokens.space3),
                  FilledButton(
                    onPressed: _createRecurring,
                    child: const Text('Tambah item berulang'),
                  ),
                ],
              ),
            )
          else
            CardGroup(
              children: [
                for (final row in active)
                  _ActiveTile(
                    row: row,
                    today: today,
                    onEdit: () => _editRecurring(context, row),
                    onDelete: () => _deleteRecurring(context, row),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _CreateRecurringSheet extends ConsumerStatefulWidget {
  const _CreateRecurringSheet();

  @override
  ConsumerState<_CreateRecurringSheet> createState() => _CreateRecurringSheetState();
}

class _CreateRecurringSheetState extends ConsumerState<_CreateRecurringSheet> {
  final _noteController = TextEditingController();
  final _amountController = TextEditingController();
  final _dayController = TextEditingController(text: '${DateTime.now().day}');
  String? _categoryId;
  String? _accountId;
  WeekendRule _weekendRule = WeekendRule.none;
  bool _isSubscription = false;

  @override
  void dispose() {
    _noteController.dispose();
    _amountController.dispose();
    _dayController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amountMinor = int.tryParse(_amountController.text);
    final dayOfMonth = int.tryParse(_dayController.text);
    if (amountMinor == null || amountMinor <= 0 || dayOfMonth == null || _categoryId == null || _accountId == null) {
      return;
    }

    final today = _todayDayBucket();
    final rule = RecurrenceRule(
      freq: RecurrenceFreq.monthly,
      byMonthDay: dayOfMonth,
      weekendRule: _weekendRule,
      startsOn: today,
    );
    await RecurrenceRepository(ref.read(databaseProvider)).create(
      template: RecurrenceTemplate(
        kind: 'expense',
        accountId: _accountId,
        categoryId: _categoryId,
        currency: 'IDR',
        fixedAmountMinor: amountMinor,
        note: _noteController.text.isEmpty ? null : _noteController.text,
      ),
      rule: rule,
      isSubscription: _isSubscription,
    );

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: WudgetTokens.space4,
        right: WudgetTokens.space4,
        top: WudgetTokens.space4,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Tambah item berulang', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: WudgetTokens.space3),
            TextField(controller: _noteController, decoration: const InputDecoration(labelText: 'Nama (mis. Listrik)')),
            const SizedBox(height: WudgetTokens.space3),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Jumlah (Rp)'),
            ),
            const SizedBox(height: WudgetTokens.space3),
            TextField(
              controller: _dayController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Tanggal tiap bulan (1-31)'),
            ),
            const SizedBox(height: WudgetTokens.space3),
            StreamBuilder<List<Category>>(
              stream: db.select(db.categories).watch(),
              builder: (context, snapshot) {
                final categories = snapshot.data ?? const [];
                return DropdownButtonFormField<String?>(
                  value: _categoryId,
                  decoration: const InputDecoration(labelText: 'Kategori'),
                  items: [for (final c in categories) DropdownMenuItem(value: c.id, child: Text(c.name))],
                  onChanged: (id) => setState(() => _categoryId = id),
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
                  items: [for (final a in accounts) DropdownMenuItem(value: a.id, child: Text(a.name))],
                  onChanged: (id) => setState(() => _accountId = id),
                );
              },
            ),
            const SizedBox(height: WudgetTokens.space3),
            DropdownButtonFormField<WeekendRule>(
              value: _weekendRule,
              decoration: const InputDecoration(labelText: 'Jika jatuh di akhir pekan'),
              items: const [
                DropdownMenuItem(value: WeekendRule.none, child: Text('Tetap di tanggal itu')),
                DropdownMenuItem(value: WeekendRule.before, child: Text('Majukan ke Jumat')),
                DropdownMenuItem(value: WeekendRule.after, child: Text('Undurkan ke Senin')),
              ],
              onChanged: (v) => setState(() => _weekendRule = v ?? WeekendRule.none),
            ),
            const SizedBox(height: WudgetTokens.space3),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Langganan'),
              subtitle: const Text('Masuk daftar langganan, mis. Netflix atau Spotify'),
              value: _isSubscription,
              onChanged: (v) => setState(() => _isSubscription = v),
            ),
            const SizedBox(height: WudgetTokens.space4),
            FilledButton(onPressed: _save, child: const Text('Simpan')),
            const SizedBox(height: WudgetTokens.space4),
          ],
        ),
      ),
    );
  }
}

class _EditRecurringSheet extends ConsumerStatefulWidget {
  const _EditRecurringSheet({required this.recurrence});
  final Recurrence recurrence;

  @override
  ConsumerState<_EditRecurringSheet> createState() => _EditRecurringSheetState();
}

class _EditRecurringSheetState extends ConsumerState<_EditRecurringSheet> {
  late final TextEditingController _noteController;
  late final TextEditingController _amountController;
  late final TextEditingController _dayController;
  String? _categoryId;
  String? _accountId;
  WeekendRule _weekendRule = WeekendRule.none;
  bool _isSubscription = false;

  @override
  void initState() {
    super.initState();
    final template = RecurrenceTemplate.fromJson(
      jsonDecode(widget.recurrence.templateJson) as Map<String, Object?>,
    );
    _noteController = TextEditingController(text: template.note ?? '');
    _amountController = TextEditingController(
      text: (template.fixedAmountMinor ?? 0).toString(),
    );
    _dayController = TextEditingController(
      text: (widget.recurrence.byMonthDay ?? 1).toString(),
    );
    _categoryId = template.categoryId;
    _accountId = template.accountId;
    _weekendRule = WeekendRule.values.byName(widget.recurrence.weekendRule);
    _isSubscription = widget.recurrence.isSubscription;
  }

  @override
  void dispose() {
    _noteController.dispose();
    _amountController.dispose();
    _dayController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amountMinor = int.tryParse(_amountController.text);
    final dayOfMonth = int.tryParse(_dayController.text);
    if (amountMinor == null || amountMinor <= 0 || dayOfMonth == null || _categoryId == null || _accountId == null) {
      return;
    }

    final db = ref.read(databaseProvider);
    final template = RecurrenceTemplate(
      kind: 'expense',
      accountId: _accountId,
      categoryId: _categoryId,
      currency: 'IDR',
      fixedAmountMinor: amountMinor,
      note: _noteController.text.isEmpty ? null : _noteController.text,
    );

    await (db.update(db.recurrences)..where((r) => r.id.equals(widget.recurrence.id))).write(
      RecurrencesCompanion(
        templateJson: Value(jsonEncode(template.toJson())),
        byMonthDay: Value(dayOfMonth),
        weekendRule: Value(_weekendRule.name),
        isSubscription: Value(_isSubscription),
        updatedAt: Value(DateTime.now().toUtc().millisecondsSinceEpoch),
      ),
    );

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: WudgetTokens.space4,
        right: WudgetTokens.space4,
        top: WudgetTokens.space4,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Edit item berulang', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: WudgetTokens.space3),
            TextField(controller: _noteController, decoration: const InputDecoration(labelText: 'Nama (mis. Listrik)')),
            const SizedBox(height: WudgetTokens.space3),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Jumlah (Rp)'),
            ),
            const SizedBox(height: WudgetTokens.space3),
            TextField(
              controller: _dayController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Tanggal tiap bulan (1-31)'),
            ),
            const SizedBox(height: WudgetTokens.space3),
            StreamBuilder<List<Category>>(
              stream: db.select(db.categories).watch(),
              builder: (context, snapshot) {
                final categories = snapshot.data ?? const [];
                return DropdownButtonFormField<String?>(
                  value: _categoryId,
                  decoration: const InputDecoration(labelText: 'Kategori'),
                  items: [for (final c in categories) DropdownMenuItem(value: c.id, child: Text(c.name))],
                  onChanged: (id) => setState(() => _categoryId = id),
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
                  items: [for (final a in accounts) DropdownMenuItem(value: a.id, child: Text(a.name))],
                  onChanged: (id) => setState(() => _accountId = id),
                );
              },
            ),
            const SizedBox(height: WudgetTokens.space3),
            DropdownButtonFormField<WeekendRule>(
              value: _weekendRule,
              decoration: const InputDecoration(labelText: 'Jika jatuh di akhir pekan'),
              items: const [
                DropdownMenuItem(value: WeekendRule.none, child: Text('Tetap di tanggal itu')),
                DropdownMenuItem(value: WeekendRule.before, child: Text('Majukan ke Jumat')),
                DropdownMenuItem(value: WeekendRule.after, child: Text('Undurkan ke Senin')),
              ],
              onChanged: (v) => setState(() => _weekendRule = v ?? WeekendRule.none),
            ),
            const SizedBox(height: WudgetTokens.space3),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Langganan'),
              subtitle: const Text('Masuk daftar langganan, mis. Netflix atau Spotify'),
              value: _isSubscription,
              onChanged: (v) => setState(() => _isSubscription = v),
            ),
            const SizedBox(height: WudgetTokens.space4),
            FilledButton(onPressed: _save, child: const Text('Simpan')),
            const SizedBox(height: WudgetTokens.space4),
          ],
        ),
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
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final dueIn = instance.dueDay - _todayDayBucket();
    return CardRow(
      leading: IconChip(
        icon: Icons.event_repeat_outlined,
        background: tokens.surfaceMuted,
        foreground: tokens.ink2,
      ),
      title: instance.note?.isNotEmpty == true ? instance.note! : 'Tagihan',
      // Days remaining as well as the date: "3 hari lagi" is what decides
      // whether this needs attention now.
      subtitle: switch (dueIn) {
        0 => 'Jatuh tempo hari ini',
        1 => 'Besok, ${_dateFormat.format(_dateForDay(instance.dueDay))}',
        final d when d > 1 => '$d hari lagi, ${_dateFormat.format(_dateForDay(instance.dueDay))}',
        _ => 'Terlewat, ${_dateFormat.format(_dateForDay(instance.dueDay))}',
      },
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AmountText(minor: instance.amountMinor),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            tooltip: 'Lewati',
            onPressed: onSkip,
          ),
          IconButton(
            icon: const Icon(Icons.check, size: 20),
            tooltip: 'Konfirmasi',
            color: tokens.accent,
            onPressed: onConfirm,
          ),
        ],
      ),
    );
  }
}

class _ActiveTile extends StatelessWidget {
  const _ActiveTile({required this.row, required this.today, required this.onEdit, required this.onDelete});
  final Recurrence row;
  final int today;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

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

    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final error = row.lastGenerationError;

    return CardRow(
      leading: IconChip(
        // A failed rule is flagged by its icon as well as its text, so the
        // state is not carried by colour alone (R-25).
        icon: error != null ? Icons.warning_amber_rounded : Icons.autorenew,
        background: error != null ? tokens.warning.withOpacity(0.14) : tokens.surfaceMuted,
        foreground: error != null ? tokens.warning : tokens.ink2,
      ),
      title: template.note?.isNotEmpty == true ? template.note! : 'Item berulang',
      subtitle: error != null
          ? 'Gagal membuat: $error'
          : 'Berikutnya ${_dateFormat.format(_dateForDay(nextDue))}',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            amountLabel,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            tooltip: 'Edit',
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            tooltip: 'Hapus',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
