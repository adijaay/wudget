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
}
