import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wudget/data/backup_repository.dart';
import 'package:wudget/data/database.dart';
import 'package:wudget/data/recurrence_repository.dart';
import 'package:wudget/data/recurring_queries.dart';
import 'package:wudget/domain/recurrence.dart';

void main() {
  late WudgetDatabase db;
  setUp(() => db = WudgetDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> add(int amount, RecurrenceFreq freq, {bool sub = true}) =>
      RecurrenceRepository(db).create(
        template: RecurrenceTemplate(kind: 'expense', currency: 'IDR', fixedAmountMinor: amount),
        rule: RecurrenceRule(freq: freq, byMonthDay: 5, byWeekday: 1, startsOn: 100),
        isSubscription: sub,
      );

  test('the Langganan total counts only subscriptions, scaled to a month', () async {
    await add(54000, RecurrenceFreq.monthly);
    await add(1200000, RecurrenceFreq.yearly);
    await add(150000, RecurrenceFreq.monthly, sub: false);
    final rules = await RecurringQueries(db).activeRules();
    expect(subscriptionMonthlyMinor(rules), 54000 + 100000);
  });

  test('a backup from before the flag restores with every rule unflagged', () async {
    await add(54000, RecurrenceFreq.monthly);
    final backup = BackupRepository(db, backupDir: Directory.systemTemp);
    final json = await backup.exportJson();
    for (final r in json['recurrences'] as List) {
      (r as Map).remove('isSubscription');
    }
    await backup.importJson(json);
    expect((await db.select(db.recurrences).getSingle()).isSubscription, isFalse);
  });
}
