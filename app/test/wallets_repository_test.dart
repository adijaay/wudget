import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wudget/data/database.dart';
import 'package:wudget/data/wallets_repository.dart';

void main() {
  late WudgetDatabase db;
  late WalletsRepository repo;

  setUp(() {
    db = WudgetDatabase(NativeDatabase.memory());
    repo = WalletsRepository(db);
  });

  tearDown(() => db.close());

  test('balance is opening balance plus every posting against the account, even with none yet',
      () async {
    await repo.create(id: 'acc1', name: 'Tunai', type: 'cash', currency: 'IDR', openingMinor: 50000);

    final first = await repo.watchWallets().first;
    expect(first.single.balanceMinor, 50000); // no postings yet — must not be dropped to 0

    await db.into(db.transactions).insert(TransactionsCompanion.insert(
          id: 'tx1',
          kind: 'expense',
          occurredAt: 0,
          tzOffsetMinutes: 0,
          updatedAt: 0,
        ));
    await db.into(db.postings).insert(PostingsCompanion.insert(
          id: 'p1',
          transactionId: 'tx1',
          accountId: const Value('acc1'),
          amountMinor: -15000,
          currency: 'IDR',
          baseAmountMinor: -15000,
        ));
    await db.into(db.postings).insert(PostingsCompanion.insert(
          id: 'p2',
          transactionId: 'tx1',
          accountId: const Value('acc1'),
          amountMinor: 20000,
          currency: 'IDR',
          baseAmountMinor: 20000,
        ));

    final updated = await repo.watchWallets().first;
    expect(updated.single.balanceMinor, 50000 - 15000 + 20000);
  });

  test('archived wallets are excluded from watchWallets', () async {
    await repo.create(id: 'acc1', name: 'Tunai', type: 'cash', currency: 'IDR');
    await repo.archive('acc1');

    final wallets = await repo.watchWallets().first;
    expect(wallets, isEmpty);
  });
}
