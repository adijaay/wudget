import 'package:flutter/material.dart';

import '../../design/tokens.dart';

/// The bottom bar from every mockup in `design/`: four labelled tabs with a
/// gap in the middle, and the capture button docked into that gap. Capture
/// is the one action the product lives on, so it sits in the centre of the
/// bar rather than in a corner where a right-handed reach finds it last.
class WudgetNavBar extends StatelessWidget {
  const WudgetNavBar({
    super.key,
    required this.currentIndex,
    required this.onSelected,
    required this.destinations,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;
  final List<NavDestination> destinations;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final half = destinations.length ~/ 2;
    return Container(
      decoration: BoxDecoration(
        color: tokens.surfaceCard,
        border: Border(top: BorderSide(color: tokens.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: WudgetTokens.navBarHeight,
          child: Row(
            children: [
              for (var i = 0; i < destinations.length; i++) ...[
                // The docked capture button's footprint. Left empty so a
                // mis-hit near it does nothing rather than switching tabs.
                if (i == half) const SizedBox(width: 76),
                Expanded(
                  child: _NavTab(
                    // Keyed because each tab's label also appears as the
                    // title of its own screen, which an IndexedStack keeps
                    // built whether or not it is the visible one.
                    key: Key('navTab_${destinations[i].label}'),
                    destination: destinations[i],
                    selected: i == currentIndex,
                    onTap: () => onSelected(i),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class NavDestination {
  const NavDestination({required this.label, required this.icon, required this.selectedIcon});
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    super.key,
    required this.destination,
    required this.selected,
    required this.onTap,
  });
  final NavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    // Selected state is carried by the filled glyph and the weight as well
    // as the colour, so it survives being unable to see the hue (R-25).
    final color = selected ? tokens.accent : tokens.ink2;
    return Semantics(
      selected: selected,
      button: true,
      label: destination.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? destination.selectedIcon : destination.icon, size: 24, color: color),
            const SizedBox(height: 3),
            Text(
              destination.label,
              style: TextStyle(
                fontFamily: WudgetTokens.fontFamily,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The docked capture button. A rounded square, not a circle: the mockups
/// use the same 18px corner as the identity's other lifted surface, and it
/// reads as "the one raised control" rather than a stock Material FAB.
class CaptureButton extends StatelessWidget {
  const CaptureButton({super.key, required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    return Semantics(
      button: true,
      label: 'Catat transaksi',
      excludeSemantics: true,
      child: Container(
        width: WudgetTokens.captureButton,
        height: WudgetTokens.captureButton,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: tokens.accent.withOpacity(0.34),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: tokens.accent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(18),
            child: Icon(Icons.add, size: 26, color: tokens.inkOnAccent),
          ),
        ),
      ),
    );
  }
}
