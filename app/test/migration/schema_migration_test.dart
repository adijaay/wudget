import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:wudget/data/database.dart';

/// Builds a fixture database on-disk shaped exactly like schema v1 (no
/// transactions.photo_path), the way a real installed app's database looks
/// before an upgrade. Hand-written rather than generated from drift's
/// schema-version tooling, to keep the fixture legible as "what v1 actually
/// was" — see plan/05-sprints.md Sprint 2, and DECISIONS.md for why this
/// test was deferred until there was a real v2 to migrate to.
Database _buildV1Fixture() {
  final db = sqlite3.openInMemory();
  db.execute('''
    CREATE TABLE accounts (
      id TEXT NOT NULL PRIMARY KEY, name TEXT NOT NULL, type TEXT NOT NULL,
      provider_key TEXT, currency TEXT NOT NULL,
      opening_minor INTEGER NOT NULL DEFAULT 0,
      statement_day INTEGER, due_day INTEGER, credit_limit_minor INTEGER,
      archived_at INTEGER, household_id TEXT,
      visibility TEXT NOT NULL DEFAULT 'private',
      updated_at INTEGER NOT NULL, deleted_at INTEGER, device_id TEXT
    );
    CREATE TABLE categories (
      id TEXT NOT NULL PRIMARY KEY, parent_id TEXT REFERENCES categories(id),
      name TEXT NOT NULL, kind TEXT NOT NULL, icon_key TEXT NOT NULL,
      hue_index INTEGER NOT NULL, is_irregular INTEGER NOT NULL DEFAULT 0,
      sort_order INTEGER NOT NULL, updated_at INTEGER NOT NULL, deleted_at INTEGER
    );
    CREATE TABLE transactions (
      id TEXT NOT NULL PRIMARY KEY, kind TEXT NOT NULL,
      occurred_at INTEGER NOT NULL, tz_offset_minutes INTEGER NOT NULL,
      title TEXT, note TEXT, recurrence_id TEXT,
      is_projected INTEGER NOT NULL DEFAULT 0, lat REAL, lon REAL,
      household_id TEXT, visibility TEXT NOT NULL DEFAULT 'private',
      updated_at INTEGER NOT NULL, deleted_at INTEGER, device_id TEXT
    );
    CREATE TABLE postings (
      id TEXT NOT NULL PRIMARY KEY,
      transaction_id TEXT NOT NULL REFERENCES transactions(id),
      account_id TEXT REFERENCES accounts(id),
      category_id TEXT REFERENCES categories(id),
      amount_minor INTEGER NOT NULL, currency TEXT NOT NULL,
      rate_to_base REAL NOT NULL DEFAULT 1.0, base_amount_minor INTEGER NOT NULL
    );
    INSERT INTO accounts (id, name, type, currency, updated_at)
      VALUES ('acc1', 'Tunai', 'cash', 'IDR', 0);
    INSERT INTO categories (id, name, kind, icon_key, hue_index, sort_order, updated_at)
      VALUES ('cat1', 'Makan', 'expense', 'food', 0, 0, 0);
    INSERT INTO transactions (id, kind, occurred_at, tz_offset_minutes, note, updated_at)
      VALUES ('tx1', 'expense', 0, 420, 'sarapan', 0);
    INSERT INTO postings (id, transaction_id, account_id, amount_minor, currency, base_amount_minor)
      VALUES ('p1', 'tx1', 'acc1', -15000, 'IDR', -15000);
    INSERT INTO postings (id, transaction_id, category_id, amount_minor, currency, base_amount_minor)
      VALUES ('p2', 'tx1', 'cat1', 15000, 'IDR', 15000);
  ''');
  db.userVersion = 1;
  return db;
}

/// A v4-shaped fixture: `app_settings` already exists (added that
/// version), but without `last_acknowledged_period_close` (added in v8).
/// Regression fixture for the bug this exact shape hit: `createTable` in
/// an earlier `onUpgrade` step builds from the *current* Dart table
/// definition (every column, including ones added by later versions), so
/// a database that never had the table at all sailed through — this is
/// the one that needs the table to already exist, without the new column,
/// for the later `addColumn` step to have anything to do.
Database _buildV4Fixture() {
  final db = sqlite3.openInMemory();
  db.execute('''
    CREATE TABLE accounts (
      id TEXT NOT NULL PRIMARY KEY, name TEXT NOT NULL, type TEXT NOT NULL,
      provider_key TEXT, currency TEXT NOT NULL,
      opening_minor INTEGER NOT NULL DEFAULT 0,
      statement_day INTEGER, due_day INTEGER, credit_limit_minor INTEGER,
      archived_at INTEGER, household_id TEXT,
      visibility TEXT NOT NULL DEFAULT 'private',
      updated_at INTEGER NOT NULL, deleted_at INTEGER, device_id TEXT
    );
    CREATE TABLE categories (
      id TEXT NOT NULL PRIMARY KEY, parent_id TEXT REFERENCES categories(id),
      name TEXT NOT NULL, kind TEXT NOT NULL, icon_key TEXT NOT NULL,
      hue_index INTEGER NOT NULL, is_irregular INTEGER NOT NULL DEFAULT 0,
      sort_order INTEGER NOT NULL, updated_at INTEGER NOT NULL, deleted_at INTEGER
    );
    CREATE TABLE transactions (
      id TEXT NOT NULL PRIMARY KEY, kind TEXT NOT NULL,
      occurred_at INTEGER NOT NULL, tz_offset_minutes INTEGER NOT NULL,
      title TEXT, note TEXT, photo_path TEXT, recurrence_id TEXT,
      is_projected INTEGER NOT NULL DEFAULT 0, lat REAL, lon REAL,
      household_id TEXT, visibility TEXT NOT NULL DEFAULT 'private',
      updated_at INTEGER NOT NULL, deleted_at INTEGER, device_id TEXT
    );
    CREATE TABLE postings (
      id TEXT NOT NULL PRIMARY KEY,
      transaction_id TEXT NOT NULL REFERENCES transactions(id),
      account_id TEXT REFERENCES accounts(id),
      category_id TEXT REFERENCES categories(id),
      amount_minor INTEGER NOT NULL, currency TEXT NOT NULL,
      rate_to_base REAL NOT NULL DEFAULT 1.0, base_amount_minor INTEGER NOT NULL
    );
    CREATE TABLE daily_totals (day INTEGER NOT NULL PRIMARY KEY, net_minor INTEGER NOT NULL);
    CREATE TABLE app_settings (
      id INTEGER NOT NULL PRIMARY KEY DEFAULT 0,
      period_start_day INTEGER NOT NULL DEFAULT 1
    );
    INSERT INTO app_settings (id, period_start_day) VALUES (0, 15);
  ''');
  db.userVersion = 4;
  return db;
}

void main() {
  test('opening a v1 fixture upgrades to v2 and preserves every row', () async {
    final rawDb = _buildV1Fixture();
    final wudget = WudgetDatabase(NativeDatabase.opened(rawDb));
    addTearDown(wudget.close);

    // Touching the database forces drift to run its migration strategy.
    final transactions = await wudget.select(wudget.transactions).get();

    expect(transactions.single.note, 'sarapan');
    expect(transactions.single.photoPath, isNull); // column added, no data invented

    final postings = await wudget.select(wudget.postings).get();
    expect(postings.length, 2);
    expect(postings.fold<int>(0, (sum, p) => sum + p.baseAmountMinor), 0);

    expect((await wudget.select(wudget.accounts).get()).single.name, 'Tunai');
    expect((await wudget.select(wudget.categories).get()).single.name, 'Makan');
  });

  test('opening a v4 fixture (app_settings pre-existing) upgrades cleanly to the latest version',
      () async {
    final rawDb = _buildV4Fixture();
    final wudget = WudgetDatabase(NativeDatabase.opened(rawDb));
    addTearDown(wudget.close);

    final settings = await wudget.select(wudget.appSettings).getSingle();
    expect(settings.periodStartDay, 15); // pre-existing data preserved
    expect(settings.lastAcknowledgedPeriodClose, isNull); // new column, no data invented
  });
}
