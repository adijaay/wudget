import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wudget/data/budgets_repository.dart';
import 'package:wudget/data/database.dart';

void main() {
  late WudgetDatabase db;
  late BudgetsRepository repo;

  setUp(() {
    db = WudgetDatabase(NativeDatabase.memory());
    repo = BudgetsRepository(db);
  });

  tearDown(() => db.close());

  test('starts empty, then round-trips a set amount', () async {
    expect(await repo.watchAll().first, isEmpty);

    await repo.setAmount('cat_makan', 500000);
    expect(await repo.watchAll().first, {'cat_makan': 500000});
  });

  test('setAmount on an existing key overwrites rather than duplicating', () async {
    await repo.setAmount('cat_makan', 500000);
    await repo.setAmount('cat_makan', 600000);
    expect(await repo.watchAll().first, {'cat_makan': 600000});
  });

  test('getAll matches watchAll, as a one-shot read', () async {
    await repo.setAmount('cat_makan', 500000);
    await repo.setAmount('irregular', 20000);
    expect(await repo.getAll(), {'cat_makan': 500000, 'irregular': 20000});
  });
}
