import 'package:flutter/material.dart';

import '../../core/money.dart';
import '../../core/money_formatter.dart';
import '../../design/components.dart';
import '../../design/tokens.dart';
import '../../domain/flow.dart';
import '../period/period_selector.dart';
import 'flow_diagram.dart';

const _formatter = MoneyFormatter();

/// Everything Aliran needs, gathered once by [PantauScreen].
class AliranData {
  const AliranData({
    required this.isPeriodRunning,
    required this.flow,
    required this.deltas,
    required this.previousLabel,
  });

  /// A flow diagram of a period still in progress would grow after you
  /// look away, so the running period gets a notice instead of a diagram.
  final bool isPeriodRunning;

  /// Null when the period has no income to hang a flow off.
  final FlowBreakdown? flow;
  final List<CategoryDelta> deltas;

  /// What the deltas are measured against, named so "yang berubah" is not
  /// a comparison against something unstated.
  final String previousLabel;
}

/// Pantau's "Aliran" view: one closed period's money from where it came in
/// to where it went out. Built to design/Aliran.dc.html.
class AliranView extends StatelessWidget {
  const AliranView({super.key, required this.data});

  final AliranData data;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final text = Theme.of(context).textTheme;

    const padding = EdgeInsets.fromLTRB(
      WudgetTokens.space4,
      0,
      WudgetTokens.space4,
      WudgetTokens.space6,
    );

    if (data.isPeriodRunning) {
      return ListView(
        padding: padding,
        children: [
          const PeriodSelector(),
          const SizedBox(height: WudgetTokens.space4),
          WudgetCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.timelapse_outlined, size: 26, color: tokens.ink2),
                const SizedBox(height: WudgetTokens.space3),
                Text('Periode ini masih jalan', style: text.titleMedium),
                const SizedBox(height: WudgetTokens.space2),
                Text(
                  'Aliran cuma digambar untuk periode yang sudah tutup. '
                  'Setengah periode akan terlihat seperti fakta padahal '
                  'pitanya masih akan melebar. Mundur satu periode untuk '
                  'melihat yang terakhir selesai.',
                  style: text.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      );
    }

    final flow = data.flow;
    if (flow == null) {
      return ListView(
        padding: padding,
        children: [
          const PeriodSelector(),
          const SizedBox(height: WudgetTokens.space4),
          WudgetCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.call_split_outlined, size: 26, color: tokens.ink2),
                const SizedBox(height: WudgetTokens.space3),
                Text('Belum ada pemasukan di periode ini', style: text.titleMedium),
                const SizedBox(height: WudgetTokens.space2),
                Text(
                  'Aliran berangkat dari uang yang masuk. Tanpa itu tidak ada '
                  'pangkal yang jujur untuk digambar, jadi tidak digambar.',
                  style: text.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: padding,
      children: [
        const PeriodSelector(),
        const SizedBox(height: WudgetTokens.space3),

        const SectionLabel('Masuk dari mana, keluar ke mana'),
        WudgetCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FlowDiagram(flow: flow),
              const SizedBox(height: WudgetTokens.space3),
              Divider(height: 1, color: tokens.hairline),
              const SizedBox(height: WudgetTokens.space3),
              for (final band in flow.bands) ...[
                _BandRow(band: band, spentMinor: flow.spentMinor),
                const SizedBox(height: WudgetTokens.space3),
              ],
              if (!flow.isDeficit) ...[
                Divider(height: 1, color: tokens.hairline),
                const SizedBox(height: WudgetTokens.space3),
                Row(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: tokens.positive,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: WudgetTokens.space3),
                    Expanded(
                      child: Text('Tidak terpakai',
                          style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                    ),
                    AmountText(
                      minor: flow.savedMinor,
                      sign: MoneySign.explicit,
                      colorBySign: true,
                      style: text.titleSmall,
                    ),
                  ],
                ),
              ],
              const SizedBox(height: WudgetTokens.space3),
              Divider(height: 1, color: tokens.hairline),
              const SizedBox(height: WudgetTokens.space3),
              Text(_flowSentence(flow), style: text.bodyMedium),
            ],
          ),
        ),
        const SizedBox(height: WudgetTokens.space5),

        if (data.deltas.isNotEmpty) ...[
          SectionLabel('Yang berubah dari ${data.previousLabel}'),
          WudgetCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final delta in data.deltas) ...[
                  _DeltaRow(delta: delta),
                  const SizedBox(height: WudgetTokens.space3),
                ],
                Divider(height: 1, color: tokens.hairline),
                const SizedBox(height: WudgetTokens.space3),
                Text(_deltaSentence(), style: text.bodyMedium?.copyWith(color: tokens.ink2)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _flowSentence(FlowBreakdown flow) {
    if (flow.isDeficit) {
      final over = _formatter.format(Money.fromMinor(-flow.savedMinor, 'IDR'));
      return 'Periode ini keluar lebih banyak dari yang masuk, selisihnya $over. '
          'Bedanya diambil dari saldo yang sudah ada, bukan dari pemasukan periode ini.';
    }
    // "Dari tiap Rp 100.000" is a ratio meant to be grasped, so it is
    // rounded to the nearest thousand. Rp 26.941 is arithmetically right
    // and useless to read.
    int perHundredThousand(num fraction) => (fraction * 100).round() * 1000;

    final saved = perHundredThousand(flow.savedFraction);
    final topTwo = flow.bands.take(2).fold<int>(0, (sum, b) => sum + b.amountMinor);
    final topTwoShare = perHundredThousand(topTwo / flow.incomeMinor);
    // Names keep their own capitalisation: lowercasing turned "Rumah" into
    // a typo at the start of a clause.
    final names = flow.bands.take(2).map((b) => b.name).join(' dan ');
    return 'Dari tiap Rp 100.000 yang masuk, '
        '${_formatter.format(Money.fromMinor(saved, 'IDR'))} tidak kamu pakai. '
        '$names berdua sudah ambil '
        '${_formatter.format(Money.fromMinor(topTwoShare, 'IDR'))}.';
  }

  String _deltaSentence() {
    final moved = data.deltas.where((d) => !d.isFlat).length;
    if (moved == 0) return 'Tidak ada kategori yang bergerak berarti.';
    if (moved == 1) {
      return 'Perubahannya terpusat di satu kategori, bukan menyebar.';
    }
    return 'Perubahannya menyebar di $moved kategori, bukan satu belanja besar.';
  }
}

class _BandRow extends StatelessWidget {
  const _BandRow({required this.band, required this.spentMinor});
  final FlowBand band;
  final int spentMinor;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final text = Theme.of(context).textTheme;
    final share = spentMinor == 0 ? 0 : (band.amountMinor * 100 / spentMinor).round();

    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: band.isRemainder
                ? tokens.ink3
                : tokens.categoryHues[band.hueIndex % tokens.categoryHues.length],
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: WudgetTokens.space3),
        Expanded(child: Text(band.name, style: text.bodyMedium)),
        Text('$share%', style: text.labelMedium?.copyWith(color: tokens.ink2)),
        const SizedBox(width: WudgetTokens.space3),
        AmountText(minor: band.amountMinor, showSymbol: false, style: text.titleSmall),
      ],
    );
  }
}

/// Direction is carried by the arrow and the sign together, never by the
/// colour alone (chart rule 7).
class _DeltaRow extends StatelessWidget {
  const _DeltaRow({required this.delta});
  final CategoryDelta delta;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final text = Theme.of(context).textTheme;

    if (delta.isFlat) {
      return Row(
        children: [
          Icon(Icons.remove, size: 16, color: tokens.ink2),
          const SizedBox(width: WudgetTokens.space3),
          Expanded(child: Text(delta.name, style: text.bodyMedium?.copyWith(color: tokens.ink2))),
          Text('tetap', style: text.labelMedium?.copyWith(color: tokens.ink2)),
        ],
      );
    }

    final rose = delta.deltaMinor > 0;
    return Row(
      children: [
        Icon(
          rose ? Icons.arrow_upward : Icons.arrow_downward,
          size: 16,
          color: rose ? tokens.warning : tokens.positive,
        ),
        const SizedBox(width: WudgetTokens.space3),
        Expanded(child: Text(delta.name, style: text.bodyMedium)),
        AmountText(
          minor: delta.deltaMinor,
          sign: MoneySign.explicit,
          showSymbol: false,
          style: text.titleSmall,
        ),
      ],
    );
  }
}
