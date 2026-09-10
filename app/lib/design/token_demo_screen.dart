import 'package:flutter/material.dart';

import 'tokens.dart';

/// Renders every token so a human can eyeball light/dark parity at a glance.
/// Sprint 0 done-when: this screen renders on both platforms in both themes.
class TokenDemoScreen extends StatelessWidget {
  const TokenDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    return Scaffold(
      appBar: AppBar(title: const Text('Design tokens')),
      body: ListView(
        padding: const EdgeInsets.all(WudgetTokens.space4),
        children: [
          _swatchRow('ink1/ink2/ink3', [tokens.ink1, tokens.ink2, tokens.ink3]),
          _swatchRow('accent/positive/negative', [tokens.accent, tokens.positive, tokens.negative]),
          _swatchRow('category hues', tokens.categoryHues),
          const SizedBox(height: WudgetTokens.space5),
          Card(
            elevation: WudgetTokens.elevationRaised,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(WudgetTokens.radiusCard),
            ),
            child: const Padding(
              padding: EdgeInsets.all(WudgetTokens.space4),
              child: Text('radiusCard + elevationRaised'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _swatchRow(String label, List<Color> colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: WudgetTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: WudgetTokens.space2),
          Row(
            children: [
              for (final c in colors)
                Container(
                  width: 32,
                  height: 32,
                  margin: const EdgeInsets.only(right: WudgetTokens.space2),
                  decoration: BoxDecoration(
                    color: c,
                    borderRadius: BorderRadius.circular(WudgetTokens.radiusControl),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
