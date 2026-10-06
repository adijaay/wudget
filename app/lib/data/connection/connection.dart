// Picks the platform's database connection at compile time, so a web
// build never imports `dart:io` or drift's ffi path.
export 'native.dart' if (dart.library.js_interop) 'web.dart';
