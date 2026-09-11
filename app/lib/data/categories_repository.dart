import 'package:drift/drift.dart';

import 'database.dart';

/// Creating and renaming categories — plan/01-features.md: "Users can add and
/// rename, and the default set is Indonesian in naming and in composition."
/// Until this existed, the only way a category came into being was the first
/// launch seed, a CSV import inventing one, or a backup restore.
///
/// Deleting is deliberately not here. The table has a `deleted_at` column, but
/// nothing that lists categories filters on it, and every posting already
/// written against a category still has to resolve its name. Hiding one is a
/// separate feature with its own decisions, not a byproduct of adding one.
class CategoriesRepository {
  CategoriesRepository(this._db);
  final WudgetDatabase _db;

  Stream<List<Category>> watchAll() {
    return (_db.select(_db.categories)
          ..orderBy([
            (c) => OrderingTerm.asc(c.kind),
            (c) => OrderingTerm.asc(c.sortOrder),
          ]))
        .watch();
  }

  /// [parentId] makes this a subcategory, the second of the two levels the
  /// plan allows. A subcategory inherits its parent's hue so the ledger still
  /// reads as one category at a glance.
  Future<String> create({
    required String id,
    required String name,
    required String kind,
    required String iconKey,
    required int hueIndex,
    String? parentId,
  }) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final lastOrder = await (_db.selectOnly(_db.categories)
          ..addColumns([_db.categories.sortOrder.max()]))
        .map((row) => row.read(_db.categories.sortOrder.max()))
        .getSingleOrNull();

    await _db.into(_db.categories).insert(CategoriesCompanion.insert(
          id: id,
          name: name,
          kind: kind,
          iconKey: iconKey,
          hueIndex: hueIndex,
          parentId: Value(parentId),
          sortOrder: (lastOrder ?? 0) + 1,
          updatedAt: now,
        ));
    return id;
  }

  Future<void> rename(String id, String name) {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    return (_db.update(_db.categories)..where((c) => c.id.equals(id)))
        .write(CategoriesCompanion(name: Value(name), updatedAt: Value(now)));
  }

  /// Changing the icon or hue of an existing category, so a category created
  /// by a CSV import (which has no way to guess either) can be made to look
  /// like the rest.
  Future<void> setAppearance(String id, {required String iconKey, required int hueIndex}) {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    return (_db.update(_db.categories)..where((c) => c.id.equals(id))).write(
      CategoriesCompanion(
        iconKey: Value(iconKey),
        hueIndex: Value(hueIndex),
        updatedAt: Value(now),
      ),
    );
  }
}
