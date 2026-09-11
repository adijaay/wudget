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

/// One row per local calendar day that has any account-leg posting. Kept
/// current by DailyTotalsRepository.recomputeDay, called from
/// PostingsRepository after every write or delete — the Catat list reads
/// this instead of summing postings on every render (Sprint 6 done-when:
/// 10,000 transactions render in under 300ms).
class DailyTotals extends Table {
  IntColumn get day => integer()(); // local calendar day, see dayBucketFor()
  IntColumn get netMinor => integer()();

  @override
  Set<Column> get primaryKey => {day};
}

/// Single-row app settings, read by [SettingsRepository]. A missing row
/// means every setting is at its default — see SettingsRepository, rather
/// than seeding one on create.
class AppSettings extends Table {
  IntColumn get id => integer().withDefault(const Constant(0))();
  IntColumn get periodStartDay => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Accounts, Categories, Transactions, Postings, DailyTotals, AppSettings])
class WudgetDatabase extends _$WudgetDatabase {
  WudgetDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(transactions, transactions.photoPath);
          }
          if (from < 3) {
            await m.createTable(dailyTotals);
          }
          if (from < 4) {
            await m.createTable(appSettings);
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
