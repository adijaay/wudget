import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncValue, AsyncData, AsyncError;
import 'package:intl/intl.dart';

import '../../core/money.dart';
import '../../core/money_formatter.dart';
import '../../design/components.dart';
import '../../design/tokens.dart';
import '../../domain/insight.dart';
import '../../domain/pola.dart';

const _formatter = MoneyFormatter();
final _fullDate = DateFormat('EEEE, d MMMM yyyy', 'id_ID');
String _rp(int minor) => _formatter.format(Money.fromMinor(minor, 'IDR'));

/// The jatah card's numbers, loaded by the ledger screen.
class TodayHeaderData {
  const TodayHeaderData({
    required this.todayDay,
    required this.todaySpendMinor,
    required this.allowance,
  });

  final int todayDay;
  final int todaySpendMinor;

  /// Null when no budget is set for the period; the card then explains
  /// what fills it instead of printing a number.
  final DailyAllowance? allowance;
}

/// The logged-days strip: one square per day of the period.
class LoggedStripData {
  const LoggedStripData({
    required this.startDay,
    required this.endDayExclusive,
    required this.todayDay,
    required this.entryDays,
  });

  final int startDay;
  final int endDayExclusive;
  final int todayDay;
  final Set<int> entryDays;

  int get daysSoFar => todayDay - startDay + 1;
  int get logged => entryDays.where((d) => d >= startDay && d <= todayDay).length;
}

/// Home, top to bottom: today's jatah, the logged-days strip, one new
/// sentence. Built to design/Retention.html screens 1 and 7. Each block
/// loads and fails on its own, so one broken query never blanks home.
class TodayHeader extends StatelessWidget {
  const TodayHeader({
    super.key,
    required this.todayDay,
    required this.jatah,
    required this.strip,
    required this.insight,
    this.firstRun = false,
    this.onOpenKantong,
    this.onSetNow,
    this.onCapture,
    this.onRetry,
  });

  final int todayDay;
  final AsyncValue<TodayHeaderData> jatah;
  final AsyncValue<LoggedStripData> strip;
  final AsyncValue<Insight?> insight;

  /// No entries yet: the strip and insight give way to one task.
  final bool firstRun;
  final VoidCallback? onOpenKantong;

  /// Opens the "Atur sekarang" sheet from the no-budget card.
  final VoidCallback? onSetNow;
  final VoidCallback? onCapture;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final text = Theme.of(context).textTheme;
    const gap = SizedBox(height: WudgetTokens.space3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _fullDate.format(DateTime.utc(1970, 1, 1).add(Duration(days: todayDay))),
          style: text.labelMedium?.copyWith(color: tokens.ink2),
        ),
        gap,
        switch (jatah) {
          AsyncData(:final value) => _JatahCard(data: value, onOpenKantong: onOpenKantong, onSetNow: onSetNow),
          AsyncError() => _BlockError('Jatah hari ini belum bisa dihitung.', onRetry: onRetry),
          _ => const _BlockLoading(height: 132, label: 'Menghitung jatah hari ini'),
        },
        if (firstRun) ...[
          gap,
          _FirstTaskCard(onCapture: onCapture),
        ] else ...[
          gap,
          switch (strip) {
            AsyncData(:final value) => LoggedDaysStrip(data: value),
            AsyncError() => _BlockError('Hari tercatat belum bisa dimuat.', onRetry: onRetry),
            _ => const _BlockLoading(height: 64, label: 'Memuat hari tercatat'),
          },
          switch (insight) {
            AsyncData(value: final Insight value) => Padding(
                padding: const EdgeInsets.only(top: WudgetTokens.space3),
                child: WudgetCard(child: Text(value.text, style: text.bodyLarge)),
              ),
            // A missing sentence is not worth an error card; home just says less.
            _ => const SizedBox.shrink(),
          },
        ],
      ],
    );
  }
}

class _JatahCard extends StatelessWidget {
  const _JatahCard({required this.data, this.onOpenKantong, this.onSetNow});
  final TodayHeaderData data;
  final VoidCallback? onOpenKantong;
  final VoidCallback? onSetNow;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final text = Theme.of(context).textTheme;
    final allowance = data.allowance;

    Widget link(String label, {VoidCallback? onPressed}) => Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: onPressed ?? onOpenKantong,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 44),
              foregroundColor: tokens.accent,
            ),
            child: Text(label, style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: tokens.accent)),
          ),
        );

    final List<Widget> body;
    if (allowance == null) {
      body = [
        const SizedBox(height: WudgetTokens.space2),
        Text('Jatah muncul setelah kamu isi gaji atau anggaran per kategori.', style: text.bodyLarge),
        link('Atur anggaran sekarang', onPressed: onSetNow),
      ];
    } else if (allowance.isOverBudget) {
      body = [
        const SizedBox(height: WudgetTokens.space1),
        AmountText(minor: 0, style: text.headlineMedium?.copyWith(fontSize: 34)),
        const SizedBox(height: WudgetTokens.space1),
        Text(
          'Anggaran periode ini sudah lewat ${_rp(-allowance.remainingMinor)}.',
          style: text.bodyMedium?.copyWith(color: tokens.warning, fontWeight: FontWeight.w600),
        ),
        link('Lihat anggaran di Kantong'),
      ];
    } else {
      final per = allowance.perDayMinor;
      final spent = data.todaySpendMinor;
      final over = spent > per;
      body = [
        const SizedBox(height: WudgetTokens.space1),
        AmountText(minor: per, style: text.headlineMedium?.copyWith(fontSize: 34)),
        const SizedBox(height: WudgetTokens.space3),
        Row(
          children: [
            Expanded(child: Text('Sudah keluar', style: text.bodyMedium?.copyWith(color: tokens.ink2))),
            AmountText(minor: spent, style: text.titleSmall, color: over ? tokens.warning : null),
          ],
        ),
        const SizedBox(height: WudgetTokens.space2),
        Semantics(
          label: '${_rp(spent)} dari jatah ${_rp(per)}',
          excludeSemantics: true,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: per == 0 ? 1.0 : (spent / per).clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: tokens.surfaceMuted,
              valueColor: AlwaysStoppedAnimation(over ? tokens.warning : tokens.accent),
            ),
          ),
        ),
        link('Sisa periode ${_rp(allowance.remainingMinor)} untuk ${allowance.daysRemaining} hari'),
      ];
    }

    return WudgetCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(WudgetTokens.radiusCard),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 46,
              child: IgnorePointer(child: CustomPaint(painter: _FlapPainter(tokens.accent.withValues(alpha: 0.16)))),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  WudgetTokens.space4, WudgetTokens.space4, WudgetTokens.space4, WudgetTokens.space2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Jatah hari ini', style: text.labelMedium?.copyWith(color: tokens.ink2)),
                  ...body,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The amplop flap from DESIGN.md, on the one card that holds money.
class _FlapPainter extends CustomPainter {
  const _FlapPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height * 40 / 46)
      ..lineTo(size.width, 0);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
  }

  @override
  bool shouldRepaint(_FlapPainter old) => old.color != color;
}

/// Logged days filled, missed days hollow, today outlined, future muted.
/// Missed days are just hollow: no streak to break.
class LoggedDaysStrip extends StatelessWidget {
  const LoggedDaysStrip({super.key, required this.data});
  final LoggedStripData data;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final text = Theme.of(context).textTheme;
    final summary = '${data.logged} dari ${data.daysSoFar}';

    return Semantics(
      container: true,
      label: '$summary hari tercatat',
      excludeSemantics: true,
      child: WudgetCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Hari tercatat periode ini', style: text.labelMedium?.copyWith(color: tokens.ink2)),
                ),
                Text(summary, style: text.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: WudgetTokens.space2),
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: [
                for (var day = data.startDay; day < data.endDayExclusive; day++)
                  _DaySquare(
                    logged: data.entryDays.contains(day),
                    today: day == data.todayDay,
                    future: day > data.todayDay,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DaySquare extends StatelessWidget {
  const _DaySquare({required this.logged, required this.today, required this.future});
  final bool logged;
  final bool today;
  final bool future;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final square = Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: future ? tokens.surfaceMuted : (logged ? tokens.accent : null),
        borderRadius: BorderRadius.circular(4),
        border: !future && !logged ? Border.all(color: tokens.borderStrong, width: 1.5) : null,
      ),
    );
    if (!today) return square;
    return Container(
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: tokens.ink1, width: 2),
      ),
      child: square,
    );
  }
}

class _FirstTaskCard extends StatelessWidget {
  const _FirstTaskCard({this.onCapture});
  final VoidCallback? onCapture;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final text = Theme.of(context).textTheme;
    return WudgetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Catat satu pengeluaran hari ini', style: text.titleSmall),
          const SizedBox(height: WudgetTokens.space1),
          Text('Yang paling gampang diingat dulu, misalnya makan siang tadi.',
              style: text.bodyMedium?.copyWith(color: tokens.ink2)),
          const SizedBox(height: WudgetTokens.space3),
          FilledButton(onPressed: onCapture, child: const Text('Catat pengeluaran')),
        ],
      ),
    );
  }
}

class _BlockLoading extends StatelessWidget {
  const _BlockLoading({required this.height, required this.label});
  final int height;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: WudgetCard(
        child: SizedBox(height: (height - 32).toDouble(), child: const Center(child: CircularProgressIndicator())),
      ),
    );
  }
}

class _BlockError extends StatelessWidget {
  const _BlockError(this.message, {this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final text = Theme.of(context).textTheme;
    return WudgetCard(
      child: Row(
        children: [
          Expanded(child: Text(message, style: text.bodyMedium?.copyWith(color: tokens.ink2))),
          if (onRetry != null) TextButton(onPressed: onRetry, child: const Text('Muat ulang')),
        ],
      ),
    );
  }
}
