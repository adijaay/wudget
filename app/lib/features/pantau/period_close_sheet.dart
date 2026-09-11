import 'package:flutter/material.dart';

import '../../core/money.dart';
import '../../core/money_formatter.dart';
import '../../design/tokens.dart';
import '../../domain/period_close.dart';

const _formatter = MoneyFormatter();

/// The period-close ritual — plan/02-flows.md #7. Fires once per boundary
/// and is dismissible; the caller (PantauScreen) owns deciding whether to
/// show it and recording that it was dismissed.
class PeriodCloseSheet extends StatelessWidget {
  const PeriodCloseSheet({super.key, required this.summary, required this.onClose});
  final PeriodCloseSummary summary;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    return Padding(
      padding: const EdgeInsets.all(WudgetTokens.space5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Periode selesai', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: WudgetTokens.space3),
          Text(
            summary.sentence((minor) => _formatter.formatCompact(Money.fromMinor(minor, 'IDR'))),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: WudgetTokens.space4),
          _Row(label: 'Pemasukan', value: summary.incomeMinor),
          _Row(label: 'Pengeluaran', value: summary.expenseMinor),
          if (summary.largestCategoryName != null)
            _Row(label: 'Terbesar: ${summary.largestCategoryName}', value: summary.largestCategoryAmountMinor),
          const Divider(height: WudgetTokens.space5),
          if (summary.surplusMinor > 0) ...[
            Text('Sisa periode ini', style: Theme.of(context).textTheme.bodyMedium),
            Text(
              _formatter.format(Money.fromMinor(summary.surplusMinor, 'IDR')),
              style: Theme.of(context).textTheme.headlineSmall!.copyWith(color: tokens.positive),
            ),
            const SizedBox(height: WudgetTokens.space2),
            Text(
              'Bisa dipertimbangkan untuk ditabung.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: WudgetTokens.space4),
          ],
          Text(
            'Anggaran periode berikutnya tetap sama — ubah lewat Anggaran kapan saja.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: WudgetTokens.space4),
          FilledButton(onPressed: onClose, child: const Text('Tutup')),
        ],
      ),
    );
  }
}

/// The shortened, non-scolding version for a user returning after more
/// than one period gap — plan/02-flows.md: "a lapsed user returning: a
/// shortened version that does not scold, offering to resume from today."
class LapsedReturnSheet extends StatelessWidget {
  const LapsedReturnSheet({super.key, required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(WudgetTokens.space5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Sudah beberapa waktu', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: WudgetTokens.space3),
          const Text('Tidak apa — lanjutkan dari hari ini.'),
          const SizedBox(height: WudgetTokens.space4),
          FilledButton(onPressed: onClose, child: const Text('Lanjut')),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: WudgetTokens.space1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(_formatter.format(Money.fromMinor(value, 'IDR'))),
        ],
      ),
    );
  }
}
