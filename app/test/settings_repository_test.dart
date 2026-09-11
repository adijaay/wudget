import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wudget/data/database.dart';
import 'package:wudget/data/settings_repository.dart';

void main() {
  late WudgetDatabase db;
  late SettingsRepository repo;

  setUp(() {
    db = WudgetDatabase(NativeDatabase.memory());
    repo = SettingsRepository(db);
  });

  tearDown(() => db.close());

  test('defaults to day 1 with no row written yet', () async {
    expect(await repo.watchPeriodStartDay().first, 1);
  });

  test('set then watch round-trips the value', () async {
    await repo.setPeriodStartDay(25);
    expect(await repo.watchPeriodStartDay().first, 25);
  });

  test('set clamps to the 1-28 range', () async {
    await repo.setPeriodStartDay(31);
    expect(await repo.watchPeriodStartDay().first, 28);
  });
}
