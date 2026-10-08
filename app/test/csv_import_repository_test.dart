import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wudget/data/csv_import_repository.dart';
import 'package:wudget/data/database.dart';
import 'package:wudget/domain/csv_import.dart';

void main() {
  late WudgetDatabase db;
  late CsvImportRepository repo;

  setUp(() {
    db = WudgetDatabase(NativeDatabase.memory());
    repo = CsvImportRepository(db);
  });

  tearDown(() => db.close());

  test('creates an account and category by name, and writes a balanced transaction', () async {
    final result = await repo.importRows(
      [
        const ParsedImportRow(
          rowNumber: 2, occurredAtUtcMillis: 0, amountMinor: -15000, kind: 'expense',
          categoryName: 'Makan', accountName: 'Tunai', note: 'sarapan',
        ),
      ],
      currency: 'IDR',
    );

    expect(result.importedCount, 1);
    expect(result.failures, isEmpty);

    final accounts = await db.select(db.accounts).get();
    expect(accounts.single.name, 'Tunai');

    final categories = await db.select(db.categories).get();
    expect(categories.single.name, 'Makan');

    final postings = await db.select(db.postings).get();
    expect(postings.fold<int>(0, (sum, p) => sum + p.baseAmountMinor), 0);
  });

  test('a second row for the same account/category name reuses the same rows, not new ones', () async {
    await repo.importRows(
      [
        const ParsedImportRow(rowNumber: 2, occurredAtUtcMillis: 0, amountMinor: -10000, kind: 'expense',
            categoryName: 'Makan', accountName: 'Tunai'),
        const ParsedImportRow(rowNumber: 3, occurredAtUtcMillis: 0, amountMinor: -20000, kind: 'expense',
            categoryName: 'makan', accountName: 'tunai'), // different case, same name
      ],
      currency: 'IDR',
    );

    expect(await db.select(db.accounts).get(), hasLength(1));
    expect(await db.select(db.categories).get(), hasLength(1));
    expect(await db.select(db.transactions).get(), hasLength(2));
  });

  test('rows with no category name fall back to "Lainnya" rather than failing', () async {
    final result = await repo.importRows(
      [
        const ParsedImportRow(rowNumber: 2, occurredAtUtcMillis: 0, amountMinor: -5000, kind: 'expense',
            accountName: 'Tunai'),
      ],
      currency: 'IDR',
    );
    expect(result.importedCount, 1);
    expect((await db.select(db.categories).get()).single.name, 'Lainnya');
  });

  test('a CSV row with two account columns and no category imports as a balanced transfer', () async {
    final parsed = parseImportRows(
      headers: ['Date', 'Amount', 'Category', 'From', 'To'],
      dataRows: [
        ['2026-10-01', '500000', '', 'BCA', 'Tunai'],
        ['2026-10-01', '-20000', 'Makan', 'Tunai', ''],
      ],
      mapping: const ColumnMapping(
        dateColumn: 'Date', amountColumn: 'Amount', categoryColumn: 'Category',
        accountColumn: 'From', toAccountColumn: 'To',
      ),
    );
    expect([for (final r in parsed.rows) r.kind], ['transfer', 'expense']);

    final result = await repo.importRows(parsed.rows, currency: 'IDR');
    expect(result.importedCount, 2);
    final tx = await (db.select(db.transactions)..where((t) => t.kind.equals('transfer'))).getSingle();
    final legs = await (db.select(db.postings)..where((p) => p.transactionId.equals(tx.id))).get();
    final names = {for (final a in await db.select(db.accounts).get()) a.id: a.name};
    expect({for (final l in legs) names[l.accountId]: l.amountMinor}, {'BCA': -500000, 'Tunai': 500000});
    expect(legs.every((l) => l.categoryId == null), isTrue);
  });
}
