import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Guards Sprint 1's exit criterion literally: "a guard test fails the build
// if a `double` or a raw `NumberFormat` appears in the money path"
// (plan/05-sprints.md). This is a repo-wide grep, not a type check, because
// the thing it prevents is a human reaching for `NumberFormat.currency()`
// or a `double` balance field months from now without remembering why not to.
void main() {
  test('no NumberFormat or double appears outside core/money*.dart', () {
    final libDir = Directory('lib');
    final offenders = <String>[];

    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.endsWith('.g.dart')) continue; // generated, not hand-written
      final relative = entity.path.replaceAll('\\', '/');
      if (relative.contains('core/money')) continue; // the formatter itself
      // Design tokens (elevation, radius, opacity) are legitimately doubles —
      // the ban is on the money path, not every double in the app.
      if (relative.contains('lib/design/')) continue;

      final content = entity.readAsStringSync();
      if (content.contains('NumberFormat')) {
        offenders.add('$relative uses NumberFormat directly — go through MoneyFormatter');
      }
      // "double" as a standalone word, not inside a longer identifier.
      final doubleUses = RegExp(r'\bdouble\b').allMatches(content);
      for (final m in doubleUses) {
        final line = content.substring(0, m.start).split('\n').length;
        offenders.add('$relative:$line declares a double — money is int minor units, never double');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: offenders.isEmpty ? '' : '\n${offenders.join('\n')}',
    );
  });
}
