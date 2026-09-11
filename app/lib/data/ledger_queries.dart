import 'package:drift/drift.dart';

import 'actual_transactions.dart';
import 'database.dart';

/// One row in the Catat list: a transaction plus the names a human reads,
/// not raw ids. For a transfer, [categoryName] is null and [accountName]
/// describes both legs ("Bank -> Tunai"); for expense/income it's the one
/// account and one category. [amountMinor] is the "from"/only account
/// leg's signed amount — negative for an outflow (expense, transfer-out),
/// positive for an inflow (income).
class LedgerEntry {
  const LedgerEntry({
    required this.transactionId,
    required this.kind,
    required this.occurredAtUtcMillis,
    required this.tzOffsetMinutes,
    required this.note,
    required this.amountMinor,
    required this.accountName,
    this.categoryName,
  });
  final String transactionId;
  final String kind;
  final int occurredAtUtcMillis;
  final int tzOffsetMinutes;
  final String? note;
  final int amountMinor;
  final String accountName;
  final String? categoryName;
}

/// Active filters for the ledger list. All optional; an unset field means
/// "don't filter on this."
class LedgerFilter {
  const LedgerFilter({
    this.categoryId,
    this.categoryName,
    this.accountId,
    this.accountName,
    this.noteQuery,
    this.minAmountMinor,
    this.maxAmountMinor,
    this.periodStartUtcMillis,
    this.periodEndUtcMillis,
  });
  final String? categoryId;
  final String? categoryName; // carried alongside the id, for the empty-state message
  final String? accountId;
  final String? accountName;
  final String? noteQuery;
  final int? minAmountMinor;
  final int? maxAmountMinor;
  final int? periodStartUtcMillis;
  final int? periodEndUtcMillis;

  /// Names what's excluding everything, for the filtered-empty state
  /// (plan/05-sprints.md Sprint 6 done-when) — never just "no results."
  String describe() {
    final parts = <String>[
      if (categoryName != null) 'kategori "$categoryName"',
      if (accountName != null) 'dompet "$accountName"',
      if (noteQuery != null && noteQuery!.isNotEmpty) 'catatan mengandung "$noteQuery"',
      if (minAmountMinor != null || maxAmountMinor != null) 'jumlah dalam rentang tertentu',
      if (periodStartUtcMillis != null) 'periode yang dipilih',
    ];
    return parts.join(', ');
  }
}

/// Projected (recurrence-generated, unconfirmed) transactions are excluded
/// here for now — Sprint 13 gives them their own "upcoming" surface, and
/// mixing a forecast into the recorded-history list would misrepresent it
/// as something that already happened. Confirming an instance clears
/// `is_projected`, at which point it appears here like any other entry.
class LedgerQueries {
  LedgerQueries(this._db);
  final WudgetDatabase _db;

  /// A page of entries, newest first. Bounded by [limit]/[offset] so the
  /// initial render never scans the whole table — the done-when in
  /// plan/05-sprints.md ("10,000 transactions render in under 300ms")
  /// depends on this staying a page fetch, not a full-table one.
  Future<List<LedgerEntry>> page({
    required int limit,
    required int offset,
    LedgerFilter filter = const LedgerFilter(),
  }) async {
    final txIds = await _matchingTransactionIds(limit: limit, offset: offset, filter: filter);
    if (txIds.isEmpty) return [];
    return _assembleEntries(txIds);
  }

  /// Selects which transactions belong on this page. A transfer has two
  /// account-leg postings, so the join below can produce two rows per
  /// transaction before `groupBy` collapses them back to one — that's what
  /// keeps a page of `limit` transactions actually `limit` transactions,
  /// not `limit` postings.
  Future<List<String>> _matchingTransactionIds({
    required int limit,
    required int offset,
    required LedgerFilter filter,
  }) async {
    final acctLeg = _db.alias(_db.postings, 'acct_leg');
    final catLeg = _db.alias(_db.postings, 'cat_leg');

    var query = _db.select(_db.transactions).join([
      innerJoin(acctLeg,
          acctLeg.transactionId.equalsExp(_db.transactions.id) & acctLeg.accountId.isNotNull()),
      leftOuterJoin(catLeg,
          catLeg.transactionId.equalsExp(_db.transactions.id) & catLeg.categoryId.isNotNull()),
    ])
      ..where(isActualTransaction(_db.transactions))
      ..groupBy([_db.transactions.id])
      ..orderBy([OrderingTerm.desc(_db.transactions.occurredAt)])
      ..limit(limit, offset: offset);

    if (filter.categoryId != null) {
      query = query..where(catLeg.categoryId.equals(filter.categoryId!));
    }
    if (filter.accountId != null) {
      query = query..where(acctLeg.accountId.equals(filter.accountId!));
    }
    if (filter.noteQuery != null && filter.noteQuery!.isNotEmpty) {
      query = query..where(_db.transactions.note.contains(filter.noteQuery!));
    }
    if (filter.minAmountMinor != null) {
      query = query..where(acctLeg.amountMinor.abs().isBiggerOrEqualValue(filter.minAmountMinor!));
    }
    if (filter.maxAmountMinor != null) {
      query = query..where(acctLeg.amountMinor.abs().isSmallerOrEqualValue(filter.maxAmountMinor!));
    }
    if (filter.periodStartUtcMillis != null) {
      query = query
        ..where(_db.transactions.occurredAt.isBiggerOrEqualValue(filter.periodStartUtcMillis!));
    }
    if (filter.periodEndUtcMillis != null) {
      query = query
        ..where(_db.transactions.occurredAt.isSmallerThanValue(filter.periodEndUtcMillis!));
    }

    final rows = await query.get();
    return [for (final row in rows) row.readTable(_db.transactions).id];
  }

  Future<List<LedgerEntry>> _assembleEntries(List<String> txIds) async {
    final transactions =
        await (_db.select(_db.transactions)..where((t) => t.id.isIn(txIds))).get();

    final accountLegRows = await (_db.select(_db.postings).join([
      innerJoin(_db.accounts, _db.accounts.id.equalsExp(_db.postings.accountId)),
    ])
          ..where(_db.postings.transactionId.isIn(txIds) & _db.postings.accountId.isNotNull()))
        .get();
    final accountLegsByTx = <String, List<TypedResult>>{};
    for (final row in accountLegRows) {
      accountLegsByTx.putIfAbsent(row.readTable(_db.postings).transactionId, () => []).add(row);
    }

    final categoryLegRows = await (_db.select(_db.postings).join([
      innerJoin(_db.categories, _db.categories.id.equalsExp(_db.postings.categoryId)),
    ])
          ..where(_db.postings.transactionId.isIn(txIds) & _db.postings.categoryId.isNotNull()))
        .get();
    final categoryNameByTx = <String, String>{
      for (final row in categoryLegRows)
        row.readTable(_db.postings).transactionId: row.readTable(_db.categories).name,
    };

    final byId = {for (final t in transactions) t.id: t};
    final entries = <LedgerEntry>[];
    for (final txId in txIds) {
      final tx = byId[txId];
      final legs = accountLegsByTx[txId];
      if (tx == null || legs == null || legs.isEmpty) continue;

      legs.sort((a, b) =>
          a.readTable(_db.postings).amountMinor.compareTo(b.readTable(_db.postings).amountMinor));
      final primary = legs.first; // the only leg, or the negative "from" leg of a transfer
      final accountName = legs.length == 1
          ? primary.readTable(_db.accounts).name
          : '${primary.readTable(_db.accounts).name} -> ${legs.last.readTable(_db.accounts).name}';

      entries.add(LedgerEntry(
        transactionId: txId,
        kind: tx.kind,
        occurredAtUtcMillis: tx.occurredAt,
        tzOffsetMinutes: tx.tzOffsetMinutes,
        note: tx.note,
        amountMinor: primary.readTable(_db.postings).amountMinor,
        accountName: accountName,
        categoryName: categoryNameByTx[txId],
      ));
    }

    entries.sort((a, b) => b.occurredAtUtcMillis.compareTo(a.occurredAtUtcMillis));
    return entries;
  }
}
