import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../domain/csv_import.dart';
import 'database.dart';
import 'postings_repository.dart';

const _uuid = Uuid();

class ImportWriteResult {
  const ImportWriteResult({required this.importedCount, required this.failures});
  final int importedCount;
  final List<ImportRowFailure> failures;
}

/// Writes already-parsed rows into the ledger, creating an account or
/// category by name when one doesn't already exist (matched
/// case-insensitively) — an imported CSV names things by their label, not
/// by wudget's internal ids. plan/03-architecture.md: "a partial import
/// that keeps the valid rows and reports the failures with row numbers" —
/// each row is its own transaction, so one bad row never rolls back the
/// others.
class CsvImportRepository {
  CsvImportRepository(this._db) : _postings = PostingsRepository(_db);
  final WudgetDatabase _db;
  final PostingsRepository _postings;

  Future<ImportWriteResult> importRows(List<ParsedImportRow> rows, {required String currency}) async {
    final accountIdByName = {
      for (final a in await _db.select(_db.accounts).get()) a.name.toLowerCase(): a.id,
    };
    final categoryIdByName = {
      for (final c in await _db.select(_db.categories).get()) c.name.toLowerCase(): c.id,
    };

    var imported = 0;
    final failures = <ImportRowFailure>[];
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;

    for (final row in rows) {
      try {
        final accountId = await _resolveAccount(row.accountName, currency, accountIdByName, now);
        if (row.kind == 'transfer') {
          final toId = await _resolveAccount(row.toAccountName, currency, accountIdByName, now);
          final txId = _uuid.v4();
          await _postings.insertTransaction(
            transaction: TransactionsCompanion.insert(
              id: txId,
              kind: 'transfer',
              occurredAt: row.occurredAtUtcMillis,
              tzOffsetMinutes: 0,
              note: row.note == null ? const Value.absent() : Value(row.note),
              updatedAt: now,
            ),
            postings: [
              for (final (suffix, id, sign) in [('a', accountId, -1), ('b', toId, 1)])
                PostingsCompanion.insert(
                  id: '${txId}_$suffix',
                  transactionId: txId,
                  accountId: Value(id),
                  amountMinor: sign * row.amountMinor,
                  currency: currency,
                  baseAmountMinor: sign * row.amountMinor,
                ),
            ],
          );
          imported++;
          continue;
        }
        final categoryId = await _resolveCategory(row.categoryName, row.kind, categoryIdByName, now);
        if (categoryId == null) {
          failures.add(ImportRowFailure(rowNumber: row.rowNumber, reason: 'Tidak ada kategori tujuan'));
          continue;
        }

        final txId = _uuid.v4();
        await _postings.insertTransaction(
          transaction: TransactionsCompanion.insert(
            id: txId,
            kind: row.kind,
            occurredAt: row.occurredAtUtcMillis,
            tzOffsetMinutes: 0,
            note: row.note == null ? const Value.absent() : Value(row.note),
            updatedAt: now,
          ),
          postings: [
            PostingsCompanion.insert(
              id: '${txId}_a',
              transactionId: txId,
              accountId: Value(accountId),
              amountMinor: row.amountMinor,
              currency: currency,
              baseAmountMinor: row.amountMinor,
            ),
            PostingsCompanion.insert(
              id: '${txId}_c',
              transactionId: txId,
              categoryId: Value(categoryId),
              amountMinor: -row.amountMinor,
              currency: currency,
              baseAmountMinor: -row.amountMinor,
            ),
          ],
        );
        imported++;
      } catch (e) {
        failures.add(ImportRowFailure(rowNumber: row.rowNumber, reason: '$e'));
      }
    }

    return ImportWriteResult(importedCount: imported, failures: failures);
  }

  Future<String> _resolveAccount(
    String? name,
    String currency,
    Map<String, String> accountIdByName,
    int now,
  ) async {
    final key = (name ?? 'Impor').toLowerCase();
    final existing = accountIdByName[key];
    if (existing != null) return existing;

    final id = _uuid.v4();
    await _db.into(_db.accounts).insert(AccountsCompanion.insert(
          id: id,
          name: name ?? 'Impor',
          type: 'cash',
          currency: currency,
          updatedAt: now,
        ));
    accountIdByName[key] = id;
    return id;
  }

  Future<String?> _resolveCategory(
    String? name,
    String kind,
    Map<String, String> categoryIdByName,
    int now,
  ) async {
    final key = (name ?? 'Lainnya').toLowerCase();
    final existing = categoryIdByName[key];
    if (existing != null) return existing;
    if (kind != 'expense' && kind != 'income') return null;

    final id = _uuid.v4();
    await _db.into(_db.categories).insert(CategoriesCompanion.insert(
          id: id,
          name: name ?? 'Lainnya',
          kind: kind,
          iconKey: 'category',
          hueIndex: 7,
          sortOrder: 999,
          updatedAt: now,
        ));
    categoryIdByName[key] = id;
    return id;
  }
}
