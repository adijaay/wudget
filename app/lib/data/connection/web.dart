import 'package:drift/drift.dart';

/// wudget does not persist on the web. The app ships to Android and iOS,
/// and its store is a native sqlite file; a browser build exists only to
/// look at screens (see lib/preview_web.dart), which never opens a
/// database.
///
/// This throws rather than silently handing back an in-memory database,
/// because a store that quietly forgets everything on refresh is the worst
/// possible failure for a money app. Making the web build persist means
/// drift's WasmDatabase plus the sqlite3 wasm and worker assets.
QueryExecutor openWudgetConnection() {
  throw UnsupportedError(
    'wudget has no web database. The browser build is for previewing '
    'screens only; use the Android or iOS build for real data.',
  );
}

Future<String> wudgetDatabasePath() {
  throw UnsupportedError('wudget has no web database file.');
}
