import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

import '../capture/capture_sheet.dart';
import 'capture_deeplink.dart';

/// Wires the home screen widget tap and app-shortcut deep links (both land
/// as a `wudget://capture?...` intent, see AndroidManifest) to the capture
/// sheet. Same entry point for both, since home_widget already forwards any
/// ACTION_VIEW intent MainActivity receives, not just widget-originated ones.
class HomeWidgetService {
  HomeWidgetService(this._navigatorKey);

  final GlobalKey<NavigatorState> _navigatorKey;

  /// True when the app was cold-launched from the widget, so the caller
  /// does not open a second sheet on top.
  Future<bool> init() async {
    HomeWidget.widgetClicked.listen(_openCaptureSheet);
    final initialUri = await HomeWidget.initiallyLaunchedFromHomeWidget();
    if (initialUri != null) _openCaptureSheet(initialUri);
    return initialUri != null;
  }

  void _openCaptureSheet(Uri? uri) {
    final context = _navigatorKey.currentContext;
    if (context == null) return;
    // A payment-notification suggestion arrives on the same deep link, tagged src=payment.
    final source = uri?.queryParameters['src'] == 'payment' ? CaptureSource.payment : CaptureSource.widget;
    showCaptureLaunch(context, parseCaptureDeepLink(uri), source: source);
  }
}
