import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/money.dart';
import '../../core/money_formatter.dart';
import '../../core/providers.dart';
import '../../data/wallets_repository.dart';
import '../../design/components.dart';
import '../../design/tokens.dart';
import '../../domain/period_close.dart';
import '../capture/capture_sheet.dart';
import 'recap_card.dart';

const _formatter = MoneyFormatter();

/// The period-close ritual — plan/02-flows.md #7, drawn to
/// design/PeriodClose.dc.html. Deliberately the one surface that does not
/// look like the rest of the app: it is a moment, not a tab, so it takes
/// the dark ground and its own type scale. Fires once per boundary and is
/// dismissible; the caller (PantauScreen) owns deciding whether to show it
/// and recording that it was dismissed.
///
/// The mockup also draws the envelope motif behind the content. That motif
/// is still marked [CONFIRM] in DESIGN.md ("a motif applied half-heartedly
/// is worse than none"), so it is deliberately not built here.
class PeriodCloseSheet extends ConsumerWidget {
  const PeriodCloseSheet({
    super.key,
    required this.summary,
    required this.onClose,
    this.periodLabel,
    this.recap,
    this.rangeLabel = '',
  });
  final PeriodCloseSummary summary;

  /// Present when the period had a plan; then the leftover joins the next
  /// budget at payday instead of being offered as a transfer.
  final PeriodRecap? recap;
  final String rangeLabel;
  final VoidCallback onClose;

  /// The period that just ended, e.g. "September". Falls back to a neutral
  /// phrasing when the caller does not know it.
  final String? periodLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final text = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: tokens.surfaceInverse,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(WudgetTokens.radiusSheet)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(WudgetTokens.space5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'TUTUP PERIODE',
                style:
                    text.labelMedium?.copyWith(color: tokens.accentOnInverse),
              ),
              const SizedBox(height: WudgetTokens.space2),
              Text(
                periodLabel == null
                    ? 'Periode sudah kelar'
                    : '$periodLabel sudah kelar',
                style: text.headlineMedium
                    ?.copyWith(fontSize: 28, color: tokens.inkInverse),
              ),
              const SizedBox(height: WudgetTokens.space2),
              Text(
                summary.sentence((minor) =>
                    _formatter.formatCompact(Money.fromMinor(minor, 'IDR'))),
                style: text.bodyMedium?.copyWith(color: tokens.inkInverse2),
              ),
              if (recap != null) ...[
                const SizedBox(height: WudgetTokens.space4),
                RecapShare(
                    recap: recap!,
                    rangeLabel: rangeLabel,
                    inkColor: tokens.inkInverse2),
              ],
              const SizedBox(height: WudgetTokens.space4),
              _InOutCard(summary: summary),
              if (recap == null && summary.surplusMinor > 0) ...[
                const SizedBox(height: WudgetTokens.space3),
                _SurplusCard(
                    surplusMinor: summary.surplusMinor, onDone: onClose),
              ],
              const SizedBox(height: WudgetTokens.space4),
              Center(
                child: TextButton(
                  onPressed: onClose,
                  child: Text(
                    'Lanjut ke periode berikutnya',
                    style:
                        text.titleMedium?.copyWith(color: tokens.inkInverse2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// What happened, split into the two directions money moved, with the one
/// category that changed most against the previous period underneath.
class _InOutCard extends StatelessWidget {
  const _InOutCard({required this.summary});
  final PeriodCloseSummary summary;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final text = Theme.of(context).textTheme;
    final changed = summary.mostChangedCategoryName;

    return Container(
      decoration: BoxDecoration(
        // A step lighter than the sheet's own ground, so it reads as a card
        // on the dark surface without introducing a second palette.
        color: WudgetTokens.onInverseSurfaceStep,
        borderRadius: BorderRadius.circular(WudgetTokens.radiusCard),
      ),
      padding: const EdgeInsets.all(WudgetTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _Figure(
                  label: 'MASUK',
                  minor: summary.incomeMinor,
                  // The sheet is dark in both app themes, so its figures
                  // take the inverse palette whatever the app is set to.
                  color: WudgetTokens.onInversePositive,
                ),
              ),
              Container(
                  width: 1, height: 42, color: WudgetTokens.onInverseHairline),
              const SizedBox(width: WudgetTokens.space3),
              Expanded(
                child: _Figure(
                  label: 'KELUAR',
                  minor: -summary.expenseMinor,
                  color: WudgetTokens.onInverseNegative,
                ),
              ),
            ],
          ),
          if (changed != null) ...[
            const SizedBox(height: WudgetTokens.space3),
            Container(height: 1, color: WudgetTokens.onInverseHairline),
            const SizedBox(height: WudgetTokens.space3),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  summary.mostChangedCategoryDeltaMinor >= 0
                      ? Icons.trending_up
                      : Icons.trending_down,
                  size: 18,
                  color: tokens.accentOnInverse,
                ),
                const SizedBox(width: WudgetTokens.space2),
                Expanded(
                  child: Text(
                    'Beda paling besar: $changed '
                    '${summary.mostChangedCategoryDeltaMinor >= 0 ? 'naik' : 'turun'} '
                    '${_formatter.format(Money.fromMinor(summary.mostChangedCategoryDeltaMinor.abs(), 'IDR'))}.',
                    style: text.bodySmall?.copyWith(color: tokens.inkInverse),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure(
      {required this.label, required this.minor, required this.color});
  final String label;
  final int minor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: text.labelMedium?.copyWith(color: tokens.inkInverse2)),
        const SizedBox(height: 2),
        AmountText(
          minor: minor,
          sign: MoneySign.explicit,
          showSymbol: false,
          color: color,
          style: text.titleLarge?.copyWith(fontSize: 17),
        ),
      ],
    );
  }
}

/// The surplus, offered as a move rather than left on screen to be spent.
/// The offer is a transfer into the first goal's wallet, or into a savings
/// wallet when there is no goal, and it only appears when one exists.
class _SurplusCard extends ConsumerWidget {
  const _SurplusCard({required this.surplusMinor, required this.onDone});
  final int surplusMinor;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final text = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        // A light card on the dark sheet: the surplus is the thing to act
        // on, and this is the one place in the app that inverts twice.
        color: tokens.surfaceCard,
        borderRadius: BorderRadius.circular(WudgetTokens.radiusCard),
      ),
      padding: const EdgeInsets.all(WudgetTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('SISA PERIODE INI', style: text.labelMedium),
          const SizedBox(height: WudgetTokens.space1),
          AmountText(
            minor: surplusMinor,
            style: text.headlineMedium?.copyWith(fontSize: 28),
            color: tokens.ink1,
          ),
          const SizedBox(height: WudgetTokens.space2),
          Text(
            'Kalau didiamkan, biasanya kepakai.',
            style: text.bodyMedium,
          ),
          Builder(
            builder: (context) {
              final wallets = ref.watch(walletBalancesProvider).value ??
                  const <WalletWithBalance>[];
              final goal = ref.watch(goalsProvider).valueOrNull?.firstOrNull?.goal;
              final savings = goal != null
                  ? wallets.where((w) => w.account.id == goal.accountId).toList()
                  : wallets.where((w) => w.account.type == 'savings').toList();
              if (savings.isEmpty) {
                // No savings wallet, so no honest offer to make. Say what
                // would make one possible instead of a dead button (R-26).
                return const Padding(
                  padding: EdgeInsets.only(top: WudgetTokens.space3),
                  child: InsetNotice(
                    icon: Icons.savings_outlined,
                    message: 'Belum ada kantong tabungan buat memindahkannya.',
                  ),
                );
              }
              final target = savings.first;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: WudgetTokens.space3),
                  CardRow(
                    leading: IconChip(
                      icon: Icons.savings_outlined,
                      background: tokens.accent,
                      foreground: tokens.inkOnAccent,
                    ),
                    title: goal?.name ?? target.account.name,
                    subtitle: 'Sekarang ${_formatter.format(
                      Money.fromMinor(
                          target.balanceMinor, target.account.currency),
                    )}',
                  ),
                  const SizedBox(height: WudgetTokens.space2),
                  FilledButton(
                    onPressed: () {
                      onDone();
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => CaptureSheet(
                          initialKind: CaptureKind.transfer,
                          initialToAccountId: target.account.id,
                          initialAmountMinor: surplusMinor,
                        ),
                      );
                    },
                    child: Text(
                      'Sisihkan ${_formatter.format(Money.fromMinor(surplusMinor, 'IDR'))}',
                    ),
                  ),
                ],
              );
            },
          ),
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
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final text = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: tokens.surfaceInverse,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(WudgetTokens.radiusSheet)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(WudgetTokens.space5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Sudah beberapa waktu',
                style: text.headlineMedium
                    ?.copyWith(fontSize: 24, color: tokens.inkInverse),
              ),
              const SizedBox(height: WudgetTokens.space2),
              Text(
                'Tidak apa, lanjutkan dari hari ini. Catatan lamamu tetap ada.',
                style: text.bodyMedium?.copyWith(color: tokens.inkInverse2),
              ),
              const SizedBox(height: WudgetTokens.space4),
              FilledButton(onPressed: onClose, child: const Text('Lanjut')),
            ],
          ),
        ),
      ),
    );
  }
}

/// The label PantauScreen passes in, kept here so the sheet and its caller
/// cannot disagree about how a period is named.
String periodCloseLabel(DateTime startDate) =>
    DateFormat('MMMM', 'id_ID').format(startDate);
