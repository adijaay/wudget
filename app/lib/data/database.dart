import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

/// Wallets, cards, savings, debts. See plan/03-architecture.md "Data model".
class Accounts extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => text()(); // cash|bank|ewallet|card|savings|debt|other
  TextColumn get providerKey => text().nullable()();
  TextColumn get currency => text()();
  IntColumn get openingMinor => integer().withDefault(const Constant(0))();
  IntColumn get statementDay => integer().nullable()();
  IntColumn get dueDay => integer().nullable()();
  IntColumn get creditLimitMinor => integer().nullable()();
  IntColumn get archivedAt => integer().nullable()();
  TextColumn get householdId => text().nullable()();
  TextColumn get visibility => text().withDefault(const Constant('private'))();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();
  TextColumn get deviceId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get parentId => text().nullable().references(Categories, #id)();
  TextColumn get name => text()();
  TextColumn get kind => text()(); // expense|income
  TextColumn get iconKey => text()();
  IntColumn get hueIndex => integer()();
  BoolColumn get isIrregular => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get kind => text()(); // expense|income|transfer|adjustment
  IntColumn get occurredAt => integer()(); // utc millis
  IntColumn get tzOffsetMinutes => integer()();
  TextColumn get title => text().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get photoPath => text().nullable()(); // added in schema v2
  TextColumn get recurrenceId => text().nullable()();
  BoolColumn get isProjected => boolean().withDefault(const Constant(false))();
  RealColumn get lat => real().nullable()();
  RealColumn get lon => real().nullable()();
  TextColumn get householdId => text().nullable()();
  TextColumn get visibility => text().withDefault(const Constant('private'))();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();
  TextColumn get deviceId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Two or more per transaction. Must sum to zero in base currency — enforced
/// by PostingsRepository.insertTransaction, not by the schema, because
/// SQLite cannot check a cross-row aggregate in a column constraint.
class Postings extends Table {
  TextColumn get id => text()();
  TextColumn get transactionId => text().references(Transactions, #id)();
  TextColumn get accountId => text().nullable().references(Accounts, #id)();
  TextColumn get categoryId => text().nullable().references(Categories, #id)();
  IntColumn get amountMinor => integer()(); // signed
  TextColumn get currency => text()();
  RealColumn get rateToBase => real().withDefault(const Constant(1.0))();
  IntColumn get baseAmountMinor => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Accounts, Categories, Transactions, Postings])
class WudgetDatabase extends _$WudgetDatabase {
  WudgetDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(transactions, transactions.photoPath);
          }
        },
      );

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'wudget.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }
}
