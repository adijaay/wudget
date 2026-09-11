import '../capture/capture_sheet.dart';

/// Parses the `wudget://capture?kind=expense` URI used by both the home
/// screen widget tap and the app-icon long-press shortcuts (Sprint 7). Pure
/// so it's testable without a platform channel; unknown or missing `kind`
/// defaults to expense, since that's the one-tap path both entry points are
/// for.
CaptureKind parseCaptureDeepLink(Uri? uri) {
  if (uri == null || uri.scheme != 'wudget' || uri.host != 'capture') {
    return CaptureKind.expense;
  }
  switch (uri.queryParameters['kind']) {
    case 'income':
      return CaptureKind.income;
    case 'transfer':
      return CaptureKind.transfer;
    default:
      return CaptureKind.expense;
  }
}
