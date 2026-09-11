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

  Future<void> init() async {
    HomeWidget.widgetClicked.listen(_openCaptureSheet);
    final initialUri = await HomeWidget.initiallyLaunchedFromHomeWidget();
    if (initialUri != null) _openCaptureSheet(initialUri);
  }

  void _openCaptureSheet(Uri? uri) {
    final context = _navigatorKey.currentContext;
    if (context == null) return;
    final launch = parseCaptureDeepLink(uri);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => CaptureSheet(
        initialKind: launch.kind,
        initialCategoryId: launch.categoryId,
        initialAccountId: launch.accountId,
        initialAmountMinor: launch.amountMinor,
        initialNote: launch.note,
        confirmingTransactionId: launch.confirmingTransactionId,
      ),
    );
  }
}
