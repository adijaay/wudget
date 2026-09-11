import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wudget/core/providers.dart';
import 'package:wudget/data/database.dart';
import 'package:wudget/design/tokens.dart';
import 'package:wudget/features/import/import_screen.dart';

const _sampleCsv = 'Date,Category,Amount,Account,Note,Income/Expense\n'
    '2026-03-05,Makan,15000,Tunai,sarapan,Expense\n'
    '2026-03-06,Gaji,5000000,Bank,,Income\n'
    'not-a-date,Makan,1000,Tunai,,Expense\n';

Future<void> _pump(WidgetTester tester, WudgetDatabase db) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        theme: buildWudgetTheme(WudgetTokens.light, Brightness.light),
        home: const ImportScreen(debugInitialCsvContent: _sampleCsv, debugInitialFileName: 'export.csv'),
      ),
    ),
  );
}

void main() {
  testWidgets('loads the file, prefills the Money Manager mapping, and shows the row count',
      (tester) async {
    final db = WudgetDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await _pump(tester, db);
    await tester.pump();

    expect(find.text('3 baris ditemukan.'), findsOneWidget);
    expect(find.text('Impor'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets('importing writes the valid rows and reports the bad one by row number',
      (tester) async {
    final db = WudgetDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await _pump(tester, db);
    await tester.pump();

    await tester.tap(find.text('Impor'));
    await tester.pumpAndSettle();

    expect(find.text('2 baris berhasil diimpor.'), findsOneWidget);
    expect(find.textContaining('Baris 4'), findsOneWidget); // header + 2 good rows before it
    expect(find.textContaining('date'), findsOneWidget);

    final transactions = await db.select(db.transactions).get();
    expect(transactions, hasLength(2));

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });
}
