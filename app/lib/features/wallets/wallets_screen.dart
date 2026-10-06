import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/money.dart';
import '../../core/money_formatter.dart';
import '../../core/providers.dart';
import '../../data/wallets_repository.dart';
import '../../design/components.dart';
import '../../design/tokens.dart';
import '../capture/capture_sheet.dart';

const _uuid = Uuid();
const _walletTypes = ['cash', 'bank', 'ewallet', 'card', 'savings', 'debt', 'other'];
const _formatter = MoneyFormatter();

/// Kantong: wallets grouped by what they are for, under one total. Built to
/// design/Kantong.dc.html. Provider logos are a type icon on a neutral
/// ground rather than real bank artwork, which the app has no licence to
/// ship and no data for (see DECISIONS.md, and R-23).
class WalletsScreen extends ConsumerWidget {
  const WalletsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(walletsRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dompet'),
        actions: [
          IconButton(
            tooltip: 'Dompet baru',
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateWalletSheet(context, repo),
          ),
          const SizedBox(width: WudgetTokens.space1),
        ],
      ),
      body: ref.watch(walletBalancesProvider).when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _BalancesUnavailable(error: error),
            data: (wallets) => wallets.isEmpty
                ? _EmptyKantong(onCreate: () => _showCreateWalletSheet(context, repo))
                : _WalletList(wallets: wallets, repo: repo),
          ),
    );
  }

  void _showCreateWalletSheet(BuildContext context, WalletsRepository repo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CreateWalletSheet(repo: repo),
    );
  }
}

class _WalletList extends StatelessWidget {
  const _WalletList({required this.wallets, required this.repo});
  final List<WalletWithBalance> wallets;
  final WalletsRepository repo;

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<WalletWithBalance>>{};
    for (final w in wallets) {
      grouped.putIfAbsent(walletGroup(w.account.type), () => []).add(w);
    }
    // A card is drawn once, as its own block: the block already carries the
    // name and what is owed, so listing it as a plain row above that would
    // print the same wallet twice.
    final cards = grouped.remove('Kartu') ?? const <WalletWithBalance>[];

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        WudgetTokens.space4,
        0,
        WudgetTokens.space4,
        WudgetTokens.space6,
      ),
      children: [
        _TotalCard(wallets: wallets),
        const SizedBox(height: WudgetTokens.space5),
        // Only groups that hold a wallet get a heading: a "KARTU" label over
        // nothing would be a section filling a template (C-3).
        for (final group in walletGroupOrder)
          if (group == 'Kartu')
            ...[
              if (cards.isNotEmpty) ...[
                const SectionLabel('Kartu'),
                for (final card in cards) _CardDetail(card: card, repo: repo),
              ],
            ]
          else if (grouped[group] != null) ...[
            SectionLabel(group),
            CardGroup(
              children: [
                for (final w in grouped[group]!)
                  _WalletRow(wallet: w, repo: repo),
              ],
            ),
            const SizedBox(height: WudgetTokens.space4),
          ],
      ],
    );
  }
}

/// The one emphasis block on the screen. Multi-currency does not print a
/// number it cannot honestly compute: it names why and lists each currency
/// on its own line (design/States.dc.html, and chart rule 8).
class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.wallets});
  final List<WalletWithBalance> wallets;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final text = Theme.of(context).textTheme;
    final byCurrency = <String, int>{};
    for (final w in wallets) {
      byCurrency.update(
        w.account.currency,
        (v) => v + w.balanceMinor,
        ifAbsent: () => w.balanceMinor,
      );
    }
    final single = byCurrency.length == 1;

    return Container(
      decoration: BoxDecoration(
        color: tokens.surfaceInverse,
        borderRadius: BorderRadius.circular(WudgetTokens.radiusCard),
      ),
      padding: const EdgeInsets.all(WudgetTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOTAL SEMUA KANTONG',
            style: text.labelMedium?.copyWith(color: tokens.inkInverse2),
          ),
          const SizedBox(height: WudgetTokens.space1),
          if (single)
            AmountText(
              minor: byCurrency.values.single,
              currency: byCurrency.keys.single,
              style: text.headlineMedium?.copyWith(fontSize: 30),
              color: tokens.inkInverse,
            )
          else ...[
            Text(
              'Belum bisa dijumlah',
              style: text.titleLarge?.copyWith(color: tokens.inkInverse),
            ),
            const SizedBox(height: WudgetTokens.space1),
            Text(
              'Beda mata uang butuh kurs, dan wudget tidak mengambil kurs dari '
              'internet. Saldo per mata uang ada di bawah.',
              style: text.bodySmall?.copyWith(color: tokens.inkInverse2),
            ),
            const SizedBox(height: WudgetTokens.space3),
            for (final entry in byCurrency.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: WudgetTokens.space1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: text.bodySmall?.copyWith(color: tokens.inkInverse2),
                    ),
                    AmountText(
                      minor: entry.value,
                      currency: entry.key,
                      color: tokens.inkInverse,
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _WalletRow extends StatelessWidget {
  const _WalletRow({required this.wallet, required this.repo});
  final WalletWithBalance wallet;
  final WalletsRepository repo;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final account = wallet.account;
    final typeLabel = walletTypeLabel(account.type);

    return CardRow(
      leading: IconChip(
        icon: walletTypeIcon(account.type),
        background: tokens.surfaceMuted,
        foreground: tokens.ink2,
      ),
      title: account.name,
      // A wallet literally named "Tunai" does not need "Tunai" printed
      // under it as well.
      subtitle: account.name.toLowerCase() == typeLabel.toLowerCase() ? null : typeLabel,
      trailing: AmountText(minor: wallet.balanceMinor, currency: account.currency),
      onTap: () => _showWalletActions(context),
    );
  }

  void _showWalletActions(BuildContext context) =>
      showWalletActions(context, wallet, repo);
}

/// The per-wallet actions, shared by the plain row and the card block: both
/// are the only place a wallet can be renamed or archived, so neither may
/// quietly drop them (R-26).
void showWalletActions(
  BuildContext context,
  WalletWithBalance wallet,
  WalletsRepository repo,
) {
  void openCardPayment() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => CaptureSheet(
        initialKind: CaptureKind.transfer,
        initialToAccountId: wallet.account.id,
        initialAmountMinor: -wallet.balanceMinor, // owed amount, as a positive payment
      ),
    );
  }

  Future<void> renameWallet() async {
    final controller = TextEditingController(text: wallet.account.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah nama kantong'),
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
    if (name == null || name.isEmpty) return;
    await repo.rename(wallet.account.id, name);
  }

  {
    final account = wallet.account;
    final canPay = account.type == 'card' && wallet.balanceMinor < 0;
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(WudgetTokens.space4),
              child: Text(account.name, style: Theme.of(context).textTheme.titleLarge),
            ),
            if (canPay)
              ListTile(
                leading: const Icon(Icons.payments_outlined),
                title: const Text('Bayar kartu'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  openCardPayment();
                },
              ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Ubah nama'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                renameWallet();
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive_outlined),
              title: const Text('Arsipkan'),
              subtitle: const Text('Disembunyikan dari daftar, catatannya tetap ada'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                repo.archive(account.id);
              },
            ),
            const SizedBox(height: WudgetTokens.space2),
          ],
        ),
      ),
    );
  }
}

/// The card block from the mockup: statement cycle, due date and limit, each
/// line drawn only when that column actually holds a value. The note under
/// it is the point of the whole thing, and the single most common complaint
/// in the competitor reviews: a card payment is a transfer, so it is not
/// counted as spending twice.
class _CardDetail extends StatelessWidget {
  const _CardDetail({required this.card, required this.repo});
  final WalletWithBalance card;
  final WalletsRepository repo;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final text = Theme.of(context).textTheme;
    final account = card.account;
    final owed = card.balanceMinor < 0 ? -card.balanceMinor : 0;
    final dueLabel = _dueLabel(account.dueDay);

    return Padding(
      padding: const EdgeInsets.only(bottom: WudgetTokens.space4),
      child: InkWell(
        onTap: () => showWalletActions(context, card, repo),
        borderRadius: BorderRadius.circular(WudgetTokens.radiusCard),
        child: WudgetCard(
        padding: const EdgeInsets.all(WudgetTokens.space3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(account.name, style: text.titleSmall),
                ),
                if (account.creditLimitMinor != null)
                  Text(
                    'limit ${_formatter.formatCompact(Money.fromMinor(account.creditLimitMinor!, account.currency))}',
                    style: text.bodySmall,
                  ),
              ],
            ),
            if (owed > 0) ...[
              const SizedBox(height: WudgetTokens.space1),
              Row(
                children: [
                  Text('Terpakai ', style: text.bodySmall),
                  AmountText(
                    minor: owed,
                    currency: account.currency,
                    style: text.bodySmall,
                    color: tokens.ink1,
                  ),
                ],
              ),
            ],
            if (dueLabel != null) ...[
              const SizedBox(height: WudgetTokens.space3),
              InsetNotice(
                icon: Icons.schedule_outlined,
                message: dueLabel,
                tone: NoticeTone.neutral,
                action: owed > 0 ? 'Bayar' : null,
                onAction: owed > 0
                    ? () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => CaptureSheet(
                            initialKind: CaptureKind.transfer,
                            initialToAccountId: account.id,
                            initialAmountMinor: owed,
                          ),
                        )
                    : null,
              ),
            ],
            const SizedBox(height: WudgetTokens.space2),
            Text(
              'Bayar kartu dicatat sebagai transfer, jadi tidak ikut terhitung '
              'sebagai belanja bulan ini.',
              style: text.bodySmall,
            ),
          ],
        ),
        ),
      ),
    );
  }

  /// Counts to the next occurrence of the billing day, so "7 hari lagi" is
  /// true on the day it is read rather than only in the month it was set.
  String? _dueLabel(int? dueDay) {
    if (dueDay == null) return null;
    final now = DateTime.now();
    var due = DateTime(now.year, now.month, dueDay);
    if (due.isBefore(DateTime(now.year, now.month, now.day))) {
      due = DateTime(now.year, now.month + 1, dueDay);
    }
    final days = due.difference(DateTime(now.year, now.month, now.day)).inDays;
    final date = DateFormat('d MMM', 'id_ID').format(due);
    return switch (days) {
      0 => 'Jatuh tempo hari ini, $date',
      1 => 'Jatuh tempo besok, $date',
      _ => 'Jatuh tempo $date, $days hari lagi',
    };
  }
}

/// First run. Shows the shape of the row that will exist, rather than the
/// words "no data" (design/States.dc.html, and R-27).
class _EmptyKantong extends StatelessWidget {
  const _EmptyKantong({required this.onCreate});
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
                      icon: Icons.payments_outlined,
                      background: tokens.surfaceMuted,
                      foreground: tokens.ink3,
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
                'Tiap kantong muncul begini: namanya, jenisnya, dan saldonya. '
                'Totalnya ada di kartu paling atas.',
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
              Text('Mulai dari satu kantong', style: text.titleLarge),
              const SizedBox(height: WudgetTokens.space2),
              Text(
                'Dompet buat uang tunai sudah cukup untuk mulai. Rekening dan '
                'e-wallet bisa ditambah kapan saja.',
                style: text.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: WudgetTokens.space4),
        FilledButton(onPressed: onCreate, child: const Text('Tambah kantong pertama')),
      ],
    );
  }
}

class _CreateWalletSheet extends StatefulWidget {
  const _CreateWalletSheet({required this.repo});
  final WalletsRepository repo;

  @override
  State<_CreateWalletSheet> createState() => _CreateWalletSheetState();
}

class _CreateWalletSheetState extends State<_CreateWalletSheet> {
  final _nameController = TextEditingController();
  final _openingController = TextEditingController();
  final _limitController = TextEditingController();
  String _type = 'cash';
  int? _statementDay;
  int? _dueDay;

  @override
  void dispose() {
    _nameController.dispose();
    _openingController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
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
            Text('Kantong baru', style: text.titleLarge),
            const SizedBox(height: WudgetTokens.space4),
            TextField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'Nama kantong, misal GoPay'),
            ),
            const SizedBox(height: WudgetTokens.space3),
            const SectionLabel('Jenis'),
            Wrap(
              spacing: WudgetTokens.space2,
              runSpacing: WudgetTokens.space2,
              children: [
                for (final t in _walletTypes)
                  ChoiceChip(
                    label: Text(walletTypeLabel(t)),
                    avatar: Icon(walletTypeIcon(t), size: 16),
                    selected: _type == t,
                    onSelected: (_) => setState(() => _type = t),
                  ),
              ],
            ),
            const SizedBox(height: WudgetTokens.space4),
            TextField(
              controller: _openingController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'Saldo awal, boleh dikosongkan'),
            ),
            // Only a card has a statement cycle and a limit, so only a card
            // is asked for them. Left blank they stay null, and Kantong
            // simply does not draw those lines.
            if (_type == 'card') ...[
              const SizedBox(height: WudgetTokens.space4),
              const SectionLabel('Siklus tagihan'),
              Row(
                children: [
                  Expanded(child: _DayField(label: 'Tanggal cetak', onChanged: (v) => _statementDay = v)),
                  const SizedBox(width: WudgetTokens.space3),
                  Expanded(child: _DayField(label: 'Jatuh tempo', onChanged: (v) => _dueDay = v)),
                ],
              ),
              const SizedBox(height: WudgetTokens.space3),
              TextField(
                controller: _limitController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Limit kartu, boleh dikosongkan'),
              ),
            ],
            const SizedBox(height: WudgetTokens.space4),
            FilledButton(onPressed: _save, child: const Text('Simpan')),
            const SizedBox(height: WudgetTokens.space4),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (_nameController.text.isEmpty) return;
    final opening = int.tryParse(_openingController.text.replaceAll(RegExp(r'[^0-9-]'), '')) ?? 0;
    final limit = int.tryParse(_limitController.text.replaceAll(RegExp(r'[^0-9]'), ''));
    widget.repo.create(
      id: _uuid.v4(),
      name: _nameController.text,
      type: _type,
      currency: 'IDR',
      openingMinor: opening,
      statementDay: _type == 'card' ? _statementDay : null,
      dueDay: _type == 'card' ? _dueDay : null,
      creditLimitMinor: _type == 'card' && limit != null ? limit : null,
    );
    Navigator.of(context).pop();
  }
}

class _DayField extends StatelessWidget {
  const _DayField({required this.label, required this.onChanged});
  final String label;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      keyboardType: TextInputType.number,
      decoration: InputDecoration(hintText: label),
      onChanged: (v) {
        final day = int.tryParse(v);
        onChanged(day != null && day >= 1 && day <= 28 ? day : null);
      },
    );
  }
}

/// The balances could not be computed at all. The states table
/// (plan/04-ux-design.md) covers a conversion that cannot be done; this is
/// the harder case where the query itself failed, and the rule is the same:
/// say the cause, and do not pretend to still be loading.
final _lineBreak = RegExp('\r?\n');

class _BalancesUnavailable extends StatelessWidget {
  const _BalancesUnavailable({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(WudgetTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Saldo kantong tidak bisa dihitung.', style: text.titleMedium),
          const SizedBox(height: WudgetTokens.space2),
          Text(
            'Catatanmu aman, yang gagal cuma penjumlahannya. Buat cadangan '
            'lewat Saya dulu, lalu catat pesan ini:',
            style: text.bodyMedium,
          ),
          const SizedBox(height: WudgetTokens.space3),
          // First line only: a drift exception carries the entire generated
          // SELECT after it, which filled the screen and buried the cause.
          SelectableText('$error'.split(_lineBreak).first, style: text.bodySmall),
        ],
      ),
    );
  }
}
