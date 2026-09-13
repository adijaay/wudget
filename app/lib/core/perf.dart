import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Prints one line per measured path so the numbers in
/// plan/03-architecture.md's performance budget can be read off a real
/// device: run a profile build and watch `adb logcat -s flutter`.
///
/// The stopwatch stops after the frame, not at the call site, so a number is
/// work-plus-frame, which is what every row of that budget is about.
///
/// ponytail: post-frame callback, not raster-end, so a number includes build
/// and layout but not the GPU's last few ms. Take a real timeline trace
/// (`flutter run --profile --trace-to-file`) only if a path misses budget and
/// the reason is not obvious.
void perfMark(String path, Stopwatch sw) {
  if (kReleaseMode) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    sw.stop();
    debugPrint('PERF $path ${sw.elapsedMilliseconds}ms');
  });
}
