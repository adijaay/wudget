import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// The app's real connection: one sqlite file in the documents directory.
/// Unchanged from when this lived inline in database.dart; it moved out so
/// that `dart:io` and `drift/native.dart` are only imported on platforms
/// that have them.
QueryExecutor openWudgetConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'wudget.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

/// Where the database file lives, for the backup and restore paths.
Future<String> wudgetDatabasePath() async {
  final dir = await getApplicationDocumentsDirectory();
  return p.join(dir.path, 'wudget.sqlite');
}
