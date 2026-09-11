import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/money.dart';
import '../../core/money_formatter.dart';
import '../../core/providers.dart';
import '../../data/database.dart';
import '../../data/wallets_repository.dart';
import '../../design/tokens.dart';
import '../capture/capture_sheet.dart';
import '../import/import_screen.dart';
import '../settings/backup_screen.dart';

const _uuid = Uuid();
const _walletTypes = ['cash', 'bank', 'ewallet', 'card', 'savings', 'debt', 'other'];
const _formatter = MoneyFormatter();

/// Kantong: wallet list with running balances. See plan/05-sprints.md
/// Sprint 5. Provider "logos" are a coloured initial rather than real bank
/// / e-wallet artwork — see DECISIONS.md for why.
class WalletsScreen extends ConsumerWidget {
  const WalletsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    final repo = ref.watch(walletsRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kantong'),
        actions: [
          IconButton(
            tooltip: 'Data & cadangan',
            icon: const Icon(Icons.settings_backup_restore),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BackupScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Impor dari CSV',
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ImportScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Tambah dompet',
            icon: const Icon(Icons.add_card_outlined),
            onPressed: () => _showCreateWalletSheet(context, repo),
          ),
        ],
      ),
      body: StreamBuilder<List<WalletWithBalance>>(
        stream: repo.watchWallets(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final wallets = snapshot.data!;
          if (wallets.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(WudgetTokens.space5),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Belum ada dompet. Tambah satu untuk mulai mencatat.', textAlign: TextAlign.center),
                    const SizedBox(height: WudgetTokens.space3),
                    FilledButton(
                      onPressed: () => _showCreateWalletSheet(context, repo),
                      child: const Text('Tambah dompet'),
                    ),
                  ],
                ),
              ),
            );
          }

          final currencies = wallets.map((w) => w.account.currency).toSet();
          final canSumDirectly = currencies.length == 1;

          return ListView(
            padding: const EdgeInsets.all(WudgetTokens.space4),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(WudgetTokens.space4),
                  child: canSumDirectly
                      ? Text(
                          'Total: ${_formatter.format(Money.fromMinor(
                            wallets.fold<int>(0, (s, w) => s + w.balanceMinor),
                            currencies.single,
                          ))}',
                          style: Theme.of(context).textTheme.titleMedium,
                        )
                      : const Text(
                          // Chart rule #8: a number that can't be honestly computed '
                          // renders blank with a reason, never an invented one.
                          'Total antar mata uang belum tersedia. Beda mata uang '
                          'butuh kurs. Lihat saldo per dompet di bawah.',
                        ),
                ),
              ),
              const SizedBox(height: WudgetTokens.space4),
              for (final w in wallets)
                _WalletTile(
                  wallet: w,
                  onArchive: () => repo.archive(w.account.id),
                  onPayCard: w.account.type == 'card' && w.balanceMinor < 0
                      ? () => _openCardPayment(context, db, w)
                      : null,
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => const CaptureSheet(),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openCardPayment(BuildContext context, WudgetDatabase db, WalletWithBalance card) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => CaptureSheet(
        initialKind: CaptureKind.transfer,
        initialToAccountId: card.account.id,
        initialAmountMinor: -card.balanceMinor, // owed amount, as a positive payment
      ),
    );
  }

  void _showCreateWalletSheet(BuildContext context, WalletsRepository repo) {
    final nameController = TextEditingController();
    var type = 'cash';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
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
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nama dompet'),
              ),
              const SizedBox(height: WudgetTokens.space3),
              DropdownButtonFormField<String>(
                value: type,
                items: [for (final t in _walletTypes) DropdownMenuItem(value: t, child: Text(t))],
                onChanged: (v) => setState(() => type = v!),
                decoration: const InputDecoration(labelText: 'Jenis'),
              ),
              const SizedBox(height: WudgetTokens.space4),
              FilledButton(
                onPressed: () {
                  if (nameController.text.isEmpty) return;
                  repo.create(
                    id: _uuid.v4(),
                    name: nameController.text,
                    type: type,
                    currency: 'IDR',
                  );
                  Navigator.of(context).pop();
                },
                child: const Text('Simpan'),
              ),
              const SizedBox(height: WudgetTokens.space4),
            ],
          ),
        ),
      ),
    );
  }
}

class _WalletTile extends StatelessWidget {
  const _WalletTile({required this.wallet, required this.onArchive, this.onPayCard});
  final WalletWithBalance wallet;
  final VoidCallback onArchive;
  final VoidCallback? onPayCard;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final account = wallet.account;
    final money = Money.fromMinor(wallet.balanceMinor, account.currency);

    return Card(
      margin: const EdgeInsets.only(bottom: WudgetTokens.space2),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: tokens.accent,
          child: Text(account.name.isEmpty ? '?' : account.name[0].toUpperCase()),
        ),
        title: Text(account.name),
        subtitle: account.type == 'card' && account.dueDay != null
            ? Text('Tagihan tanggal ${account.dueDay}')
            : Text(account.type),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatter.format(money, sign: MoneySign.none),
              style: TextStyle(
                fontFeatures: const [FontFeature.tabularFigures()],
                color: money.isNegative ? tokens.negative : tokens.ink1,
              ),
            ),
            if (onPayCard != null)
              IconButton(icon: const Icon(Icons.payment), onPressed: onPayCard, tooltip: 'Bayar'),
            IconButton(icon: const Icon(Icons.archive_outlined), onPressed: onArchive, tooltip: 'Arsipkan'),
          ],
        ),
      ),
    );
  }
}
