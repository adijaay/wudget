import 'package:drift/drift.dart' show Value;

import '../data/database.dart';

/// Seeded once on first launch so the capture sheet has something to show.
/// Real category management (create/edit/reorder) is a later sprint; this
/// is starter data, not a fixed list — see plan/01-features.md.
const _expenseCategories = <(String id, String name, String iconKey, int hue)>[
  ('cat_makan', 'Makan', 'restaurant', 0),
  ('cat_transport', 'Transport', 'directions_car', 1),
  ('cat_belanja', 'Belanja', 'shopping_bag', 2),
  ('cat_tagihan', 'Tagihan', 'receipt_long', 3),
  ('cat_hiburan', 'Hiburan', 'movie', 4),
  ('cat_kesehatan', 'Kesehatan', 'local_hospital', 5),
  ('cat_pendidikan', 'Pendidikan', 'school', 6),
  ('cat_lainnya', 'Lainnya', 'category', 7),
];

const _makanSubcategories = <(String id, String name)>[
  ('cat_makan_sarapan', 'Sarapan'),
  ('cat_makan_siang', 'Makan siang'),
  ('cat_makan_malam', 'Makan malam'),
];

const _incomeCategories = <(String id, String name, String iconKey, int hue)>[
  ('cat_gaji', 'Gaji', 'work', 0),
  ('cat_lain_income', 'Lainnya', 'category', 7),
];

/// Inserts the default account + categories if the database is empty.
/// Idempotent: safe to call on every app launch.
Future<void> seedDefaultsIfEmpty(WudgetDatabase db) async {
  final hasAccounts = (await db.select(db.accounts).get()).isNotEmpty;
  if (hasAccounts) return;

  final now = DateTime.now().toUtc().millisecondsSinceEpoch;

  await db.into(db.accounts).insert(AccountsCompanion.insert(
        id: 'acc_cash',
        name: 'Tunai',
        type: 'cash',
        currency: 'IDR',
        updatedAt: now,
      ));

  var sortOrder = 0;
  for (final (id, name, iconKey, hue) in _expenseCategories) {
    await db.into(db.categories).insert(CategoriesCompanion.insert(
          id: id,
          name: name,
          kind: 'expense',
          iconKey: iconKey,
          hueIndex: hue,
          sortOrder: sortOrder++,
          updatedAt: now,
        ));
  }
  for (final (id, name) in _makanSubcategories) {
    await db.into(db.categories).insert(CategoriesCompanion.insert(
          id: id,
          parentId: const Value('cat_makan'),
          name: name,
          kind: 'expense',
          iconKey: 'restaurant',
          hueIndex: 0,
          sortOrder: sortOrder++,
          updatedAt: now,
        ));
  }
  for (final (id, name, iconKey, hue) in _incomeCategories) {
    await db.into(db.categories).insert(CategoriesCompanion.insert(
          id: id,
          name: name,
          kind: 'income',
          iconKey: iconKey,
          hueIndex: hue,
          sortOrder: sortOrder++,
          updatedAt: now,
        ));
  }
}
