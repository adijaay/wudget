import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wudget/core/providers.dart';
import 'package:wudget/data/database.dart';
import 'package:wudget/design/tokens.dart';
import 'package:wudget/domain/period.dart';
import 'package:wudget/features/payday/payday_card.dart';

void main() {
  testWidgets('with no salary on record the card asks for the amount and drops Beda jumlah', (tester) async {
    final db = WudgetDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final period = Period.containing(todayDayBucket(), monthStartDay: 25);

    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        theme: buildWudgetTheme(WudgetTokens.light, Brightness.light),
        home: Scaffold(
          body: PaydayCard(
            data: PaydayCardData(period: period, lastSalaryMinor: null, leftoverMinor: 0),
            todayDay: period.startDay,
            onChanged: () {},
          ),
        ),
      ),
    ));

    expect(find.text('Gaji periode ini sudah masuk?'), findsOneWidget);
    expect(find.text('Isi jumlah gaji'), findsOneWidget);
    expect(find.text('Sudah masuk'), findsNothing);
    expect(find.text('Beda jumlah'), findsNothing);
    expect(find.text('Belum'), findsOneWidget);
  });
}
