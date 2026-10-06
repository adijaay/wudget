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

  test('defaults to payday 25 with no row written yet (R3.1)', () async {
    expect(await repo.watchPeriodStartDay().first, 25);
  });

  test('set then watch round-trips the value', () async {
    await repo.setPeriodStartDay(25);
    expect(await repo.watchPeriodStartDay().first, 25);
  });

  test('set clamps to the 1-28 range', () async {
    await repo.setPeriodStartDay(31);
    expect(await repo.watchPeriodStartDay().first, 28);
  });

  group('period close acknowledgement', () {
    test('null with nothing acknowledged yet', () async {
      expect(await repo.getLastAcknowledgedPeriodClose(), isNull);
    });

    test('round-trips the acknowledged period\'s start day', () async {
      await repo.setLastAcknowledgedPeriodClose(20123);
      expect(await repo.getLastAcknowledgedPeriodClose(), 20123);
    });

    test('setting it does not disturb periodStartDay, and vice versa', () async {
      await repo.setPeriodStartDay(15);
      await repo.setLastAcknowledgedPeriodClose(20123);
      expect(await repo.watchPeriodStartDay().first, 15);
      expect(await repo.getLastAcknowledgedPeriodClose(), 20123);

      await repo.setPeriodStartDay(20);
      expect(await repo.getLastAcknowledgedPeriodClose(), 20123);
    });
  });
}
