import 'dart:math';

import 'package:wudget/data/analytics_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wudget/data/database.dart';
import 'package:wudget/data/feature_flags_repository.dart';

void main() {
  late WudgetDatabase db;
  late FeatureFlagsRepository repo;

  setUp(() {
    db = WudgetDatabase(NativeDatabase.memory());
    repo = FeatureFlagsRepository(db);
  });

  tearDown(() => db.close());

  test('defaults to the caller-supplied value with no row written yet', () async {
    expect(await repo.watchBool('x', defaultValue: true).first, isTrue);
    expect(await repo.watchBool('x', defaultValue: false).first, isFalse);
    expect(await repo.getBool('x', defaultValue: true), isTrue);
  });

  test('set then read round-trips through both watchBool and getBool', () async {
    await repo.setBool(paceFirstFlagKey, false);
    expect(await repo.watchBool(paceFirstFlagKey, defaultValue: true).first, isFalse);
    expect(await repo.getBool(paceFirstFlagKey, defaultValue: true), isFalse);
  });

  test('a beta install gets one framing at random, kept on later launches, and logs it', () async {
    final db = WudgetDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = FeatureFlagsRepository(db);
    final first = await repo.assignPaceFirstVariant(Random(1));
    expect(await repo.assignPaceFirstVariant(Random(2)), first);
    expect(await repo.getBool(paceFirstFlagKey, defaultValue: !first), first);
    final events = await AnalyticsRepository(db).all();
    expect(events.single.name, 'variant_assigned');
    expect(events.single.propsJson, contains(first ? 'pace_first' : 'remaining_first'));
  });
}
