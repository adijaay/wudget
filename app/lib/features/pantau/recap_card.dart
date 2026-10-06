import 'dart:ui' show ImageByteFormat;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/money.dart';
import '../../core/money_formatter.dart';
import '../../core/providers.dart';
import '../../design/tokens.dart';
import '../../domain/period_close.dart';
import '../ledger/today_header.dart' show FlapPainter;

const _formatter = MoneyFormatter();
String _rp(int minor) => _formatter.format(Money.fromMinor(minor, 'IDR'));

/// Screen 5: the period recap in the amplop shape, on the accent ground.
class RecapCard extends StatelessWidget {
  const RecapCard({super.key, required this.recap, required this.rangeLabel});
  final PeriodRecap recap;
  final String rangeLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final text = Theme.of(context).textTheme;
    final ink = tokens.inkOnAccent;
    final row = text.bodyMedium?.copyWith(color: ink, fontSize: 13.5);
    final strong = row?.copyWith(fontWeight: FontWeight.w700);

    Widget line(String label, String value) => Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              Text(label, style: row),
              const SizedBox(width: WudgetTokens.space2),
              Expanded(child: Text(value, style: strong, textAlign: TextAlign.end)),
            ],
          ),
        );

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: ColoredBox(
        color: tokens.accent,
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 46,
              child: CustomPaint(painter: FlapPainter(ink.withValues(alpha: 0.35))),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 36, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rangeLabel, style: text.labelMedium?.copyWith(color: ink.withValues(alpha: 0.85))),
                  const SizedBox(height: WudgetTokens.space2),
                  Text('Terpakai', style: text.labelMedium?.copyWith(color: ink.withValues(alpha: 0.85))),
                  Text(_rp(recap.spentMinor), style: text.headlineMedium?.copyWith(color: ink, fontSize: 30)),
                  Text('dari rencana ${_rp(recap.planMinor)}', style: row),
                  const SizedBox(height: 14),
                  Container(height: 1, color: ink.withValues(alpha: 0.25)),
                  const SizedBox(height: 8),
                  if (recap.bestHeldName != null)
                    line('Paling terjaga', '${recap.bestHeldName}, ${recap.bestHeldPercent}%'),
                  if (recap.overName != null) line('Lewat', '${recap.overName}, +${_rp(recap.overMinor)}'),
                  const SizedBox(height: 14),
                  Text(
                    recap.sentence(_rp),
                    style: text.titleMedium?.copyWith(color: ink, fontSize: 15, height: 1.45),
                  ),
                  const SizedBox(height: 14),
                  Text('wudget', style: text.labelSmall?.copyWith(color: ink.withValues(alpha: 0.8))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The card, "Bagikan" and the line about the leftover. The card renders
/// through a RepaintBoundary so the shared PNG is exactly what is on screen.
class RecapShare extends ConsumerStatefulWidget {
  const RecapShare({super.key, required this.recap, required this.rangeLabel, this.inkColor});
  final PeriodRecap recap;
  final String rangeLabel;

  /// For the leftover line, when the ground behind it is not the page.
  final Color? inkColor;

  @override
  ConsumerState<RecapShare> createState() => _RecapShareState();
}

class _RecapShareState extends ConsumerState<RecapShare> {
  final _boundary = GlobalKey();
  bool _sharing = false;

  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      final render = _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await render.toImage(pixelRatio: 3);
      final png = await image.toByteData(format: ImageByteFormat.png);
      image.dispose();
      await ref.read(analyticsRepositoryProvider).logEvent('recap_shared');
      await SharePlus.instance.share(ShareParams(
        files: [XFile.fromData(png!.buffer.asUint8List(), mimeType: 'image/png')],
        fileNameOverrides: const ['rekap-wudget.png'],
      ));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)
            ?.showSnackBar(const SnackBar(content: Text('Gambar belum bisa dibagikan. Coba lagi.')));
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final leftover = widget.recap.leftoverMinor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RepaintBoundary(
          key: _boundary,
          child: RecapCard(recap: widget.recap, rangeLabel: widget.rangeLabel),
        ),
        const SizedBox(height: 14),
        FilledButton(
          onPressed: _sharing ? null : _share,
          child: const Text('Bagikan'),
        ),
        if (leftover > 0) ...[
          const SizedBox(height: WudgetTokens.space3),
          Text(
            'Sisa ${_rp(leftover)} ikut ke anggaran periode berikutnya saat gajian.',
            textAlign: TextAlign.center,
            style: text.bodySmall?.copyWith(color: widget.inkColor),
          ),
        ],
      ],
    );
  }
}
