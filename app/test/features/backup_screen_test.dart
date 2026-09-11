import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wudget/core/providers.dart';
import 'package:wudget/data/database.dart';
import 'package:wudget/design/tokens.dart';
import 'package:wudget/domain/default_categories.dart';
import 'package:wudget/features/settings/backup_screen.dart';

// Real disk writes inside a testWidgets body reliably hang in this
// environment (flutter_tester's process, unlike a plain `test()`, never
// completes the write) — see DECISIONS.md, Sprint 17. This file sticks to
// what testWidgets can do safely: render and read state, no file I/O
// triggered by a tap. BackupRepository's actual read/write behaviour
// (createBackup, exportJson/importJson) is covered by
// test/backup_round_trip_test.dart, a plain test() using real files.
void main() {
  testWidgets('shows no-backup-yet until one exists, with every action available', (tester) async {
    final db = WudgetDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await seedDefaultsIfEmpty(db);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: buildWudgetTheme(WudgetTokens.light, Brightness.light),
          home: BackupScreen(debugDocumentsDir: Directory.systemTemp),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Belum ada cadangan.'), findsOneWidget);
    expect(find.text('Buat cadangan sekarang'), findsOneWidget);
    expect(find.text('Ekspor JSON (lengkap)'), findsOneWidget);
    expect(find.text('Ekspor CSV (spreadsheet)'), findsOneWidget);
    expect(find.text('Pulihkan dari file JSON...'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });
}
