import 'package:flutter/material.dart';

import '../core/money.dart';
import '../core/money_formatter.dart';
import 'tokens.dart';

const _formatter = MoneyFormatter();

/// The pieces every mockup in `design/` repeats. They live here so a screen
/// never reinvents a row, a card group or an amount, which is exactly how
/// the first implementation drifted into plain Material defaults.

/// The small uppercase divider above a group ("HARIAN", "SEMENTARA INI").
/// Uppercase with mild tracking, not the wide-tracked display treatment
/// R-06 rules out: its job is to separate one list from the next.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final label = Text(text.toUpperCase(), style: Theme.of(context).textTheme.labelMedium);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        WudgetTokens.space1,
        0,
        WudgetTokens.space1,
        WudgetTokens.space2,
      ),
      child: trailing == null
          ? label
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [Flexible(child: label), trailing!],
            ),
    );
  }
}

/// A flat card: the border does the separating, not a shadow. Only the
/// capture button and the sheet are allowed to lift (R-12).
class WudgetCard extends StatelessWidget {
  const WudgetCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(WudgetTokens.space4),
    this.dashed = false,
  });
  final Widget child;
  final EdgeInsets padding;

  /// A dashed outline marks a set that is deliberately apart from the
  /// normal run of rows (the unexpected-expense bucket in Pantau, the
  /// preview of a row that does not exist yet on a first run).
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final decorated = Container(
      decoration: BoxDecoration(
        color: tokens.surfaceCard,
        borderRadius: BorderRadius.circular(WudgetTokens.radiusCard),
        border: dashed ? null : Border.all(color: tokens.border),
      ),
      padding: padding,
      child: child,
    );
    if (!dashed) return decorated;
    return CustomPaint(
      painter: _DashedBorderPainter(color: tokens.borderStrong),
      child: decorated,
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(WudgetTokens.radiusCard),
    );
    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 5), paint);
        distance += 9;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) => old.color != color;
}

/// Rows inside one card, separated by a hairline that starts past the icon
/// chip so the chips read as a column (design/Kantong.dc.html: the divider
/// is inset by the chip width plus its gap, not full-bleed).
class CardGroup extends StatelessWidget {
  const CardGroup({super.key, required this.children, this.dividerIndent = 64});
  final List<Widget> children;
  final double dividerIndent;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        rows.add(Padding(
          padding: EdgeInsets.only(left: dividerIndent),
          child: Container(height: 1, color: tokens.hairline),
        ));
      }
      rows.add(children[i]);
    }
    return Container(
      decoration: BoxDecoration(
        color: tokens.surfaceCard,
        borderRadius: BorderRadius.circular(WudgetTokens.radiusCard),
        border: Border.all(color: tokens.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: rows),
    );
  }
}

/// The 38px rounded-square icon that starts every list row. Two grounds:
/// a category tint (data-bearing, hue carries which category) or a neutral
/// muted fill (a wallet, where hue would be an invented brand colour).
class IconChip extends StatelessWidget {
  const IconChip({
    super.key,
    required this.icon,
    required this.background,
    required this.foreground,
    this.size = WudgetTokens.iconChip,
  });
  final IconData icon;
  final Color background;
  final Color foreground;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(WudgetTokens.radiusChip),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: size * 0.5, color: foreground),
    );
  }
}

/// One row of a [CardGroup]: chip, name over an optional detail line, and
/// something on the right (usually an amount).
class CardRow extends StatelessWidget {
  const CardRow({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.onLongPress,
  });
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: WudgetTokens.minTapTarget),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: WudgetTokens.space3,
            vertical: WudgetTokens.space3,
          ),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: WudgetTokens.space3),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: text.titleSmall),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: text.bodySmall),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: WudgetTokens.space2),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// How every amount reaches the screen: tabular figures so a column of them
/// lines up, and a sign that carries the in/out meaning so hue is never the
/// only signal (R-25, and chart rule 7 in design/Tokens.dc.html).
class AmountText extends StatelessWidget {
  const AmountText({
    super.key,
    required this.minor,
    this.currency = 'IDR',
    this.sign = MoneySign.none,
    this.showSymbol = true,
    this.style,
    this.colorBySign = false,
    this.color,
  });

  final int minor;
  final String currency;
  final MoneySign sign;
  final bool showSymbol;
  final TextStyle? style;

  /// Income green / expense red. Off for a balance, which is a position
  /// rather than a movement, so only a negative one is coloured.
  final bool colorBySign;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final money = Money.fromMinor(minor, currency);
    final resolved = color ??
        (colorBySign
            ? (money.isNegative ? tokens.negative : tokens.positive)
            : (money.isNegative ? tokens.negative : null));
    final base = style ?? Theme.of(context).textTheme.titleSmall!;
    return Text(
      _formatter.format(money, sign: sign, showSymbol: showSymbol),
      style: base.copyWith(
        color: resolved ?? base.color,
        fontFeatures: const [FontFeature.tabularFigures()],
        fontWeight: base.fontWeight ?? FontWeight.w700,
      ),
    );
  }
}

/// A short statement with an icon beside it, inset on a tinted ground: the
/// over-pace warning, a card's due date, the date a budget proposal lands.
/// The icon is what keeps these readable without relying on the tint (R-25).
class InsetNotice extends StatelessWidget {
  const InsetNotice({
    super.key,
    required this.icon,
    required this.message,
    this.tone = NoticeTone.neutral,
    this.action,
    this.onAction,
  });
  final IconData icon;
  final String message;
  final NoticeTone tone;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final (ground, ink) = switch (tone) {
      NoticeTone.neutral => (tokens.surfaceMuted, tokens.ink2),
      NoticeTone.warning => (tokens.warning.withOpacity(0.14), tokens.warning),
      NoticeTone.positive => (tokens.positive.withOpacity(0.12), tokens.positive),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: WudgetTokens.space3,
        vertical: WudgetTokens.space2,
      ),
      decoration: BoxDecoration(
        color: ground,
        borderRadius: BorderRadius.circular(WudgetTokens.radiusControl),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: ink),
          const SizedBox(width: WudgetTokens.space2),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: tone == NoticeTone.neutral ? tokens.ink1 : ink,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          if (action != null && onAction != null)
            TextButton(
              onPressed: onAction,
              child: Text(action!),
            ),
        ],
      ),
    );
  }
}

enum NoticeTone { neutral, warning, positive }

/// Category icons come from Material's own set rather than a bundled icon
/// library: the `icon_key` already stored per category row is a Material
/// name, the glyphs are literally the platform's vocabulary on Android, and
/// adding a second icon package to draw eight glyphs would be weight for
/// nothing. Relevance per glyph is the point, not a uniform library look
/// (R-04).
IconData categoryIcon(String iconKey) => switch (iconKey) {
      'restaurant' => Icons.restaurant_outlined,
      'directions_car' => Icons.directions_car_outlined,
      'shopping_bag' => Icons.shopping_bag_outlined,
      'receipt_long' => Icons.receipt_long_outlined,
      'movie' => Icons.movie_outlined,
      'local_hospital' => Icons.local_hospital_outlined,
      'school' => Icons.school_outlined,
      'work' => Icons.work_outline,
      'category' => Icons.category_outlined,
      _ => Icons.label_outline,
    };

/// Wallet types, in Indonesian. The raw column values are English enum
/// strings ('cash', 'ewallet'), which is what a user was reading under
/// their wallet name before this.
String walletTypeLabel(String type) => switch (type) {
      'cash' => 'Tunai',
      'bank' => 'Rekening',
      'ewallet' => 'E-wallet',
      'card' => 'Kartu kredit',
      'savings' => 'Tabungan',
      'debt' => 'Utang',
      _ => 'Lainnya',
    };

IconData walletTypeIcon(String type) => switch (type) {
      'cash' => Icons.payments_outlined,
      'bank' => Icons.account_balance_outlined,
      'ewallet' => Icons.smartphone_outlined,
      'card' => Icons.credit_card_outlined,
      'savings' => Icons.savings_outlined,
      'debt' => Icons.handshake_outlined,
      _ => Icons.account_balance_wallet_outlined,
    };

/// Which section of Kantong a wallet belongs to. Wallet chips deliberately
/// take a neutral ground and a type icon rather than a colour: the eight
/// hues mean "this category", and reusing them per wallet would make a
/// green chip ambiguous between Kesehatan and a particular e-wallet. Real
/// provider colours would be invented brand assets (R-23), so the type icon
/// carries the distinction instead.
String walletGroup(String type) => switch (type) {
      'cash' || 'bank' || 'ewallet' => 'Harian',
      'savings' => 'Simpanan',
      'card' => 'Kartu',
      'debt' => 'Utang',
      _ => 'Lainnya',
    };

const walletGroupOrder = ['Harian', 'Simpanan', 'Kartu', 'Utang', 'Lainnya'];
