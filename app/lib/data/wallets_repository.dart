import 'package:drift/drift.dart';

import 'database.dart';

/// A wallet with its running balance — opening balance plus every posting
/// against it. Computed from postings, never stored, so it can never drift
/// out of sync with the ledger (plan/03-architecture.md "Balances").
class WalletWithBalance {
  const WalletWithBalance({required this.account, required this.balanceMinor});
  final Account account;
  final int balanceMinor;
}

class WalletsRepository {
  WalletsRepository(this._db);
  final WudgetDatabase _db;

  Stream<List<WalletWithBalance>> watchWallets() {
    final balanceSum = _db.postings.amountMinor.sum();
    final query = _db.select(_db.accounts).join([
      leftOuterJoin(_db.postings, _db.postings.accountId.equalsExp(_db.accounts.id)),
    ])
      ..where(_db.accounts.archivedAt.isNull())
      ..addColumns([balanceSum])
      ..groupBy([_db.accounts.id]);

    return query.watch().map((rows) => [
          for (final row in rows)
            WalletWithBalance(
              account: row.readTable(_db.accounts),
              balanceMinor: (row.read(balanceSum) ?? 0) + row.readTable(_db.accounts).openingMinor,
            ),
        ]);
  }

  Future<void> create({
    required String id,
    required String name,
    required String type,
    required String currency,
    String? providerKey,
    int openingMinor = 0,
    int? statementDay,
    int? dueDay,
    int? creditLimitMinor,
  }) {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    return _db.into(_db.accounts).insert(AccountsCompanion.insert(
          id: id,
          name: name,
          type: type,
          currency: currency,
          providerKey: Value(providerKey),
          openingMinor: Value(openingMinor),
          statementDay: Value(statementDay),
          dueDay: Value(dueDay),
          creditLimitMinor: Value(creditLimitMinor),
          updatedAt: now,
        ));
  }

  Future<void> archive(String id) {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    return (_db.update(_db.accounts)..where((a) => a.id.equals(id)))
        .write(AccountsCompanion(archivedAt: Value(now), updatedAt: Value(now)));
  }

  Future<void> rename(String id, String name) {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    return (_db.update(_db.accounts)..where((a) => a.id.equals(id)))
        .write(AccountsCompanion(name: Value(name), updatedAt: Value(now)));
  }
}
