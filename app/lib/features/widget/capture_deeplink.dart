import '../capture/capture_sheet.dart';

/// Everything a `wudget://capture?...` URI can prefill the capture sheet
/// with. The home widget tap and app-icon shortcut (Sprint 7) only ever
/// set [kind]; a bill reminder notification action (Sprint 13) sets the
/// rest, so the sheet opens already matching the recurring item instead of
/// blank.
class CaptureLaunch {
  const CaptureLaunch({
    required this.kind,
    this.categoryId,
    this.accountId,
    this.amountMinor,
    this.note,
    this.confirmingTransactionId,
  });

  final CaptureKind kind;
  final String? categoryId;
  final String? accountId;
  final int? amountMinor;
  final String? note;

  /// The recurrence engine's projected placeholder this launch confirms —
  /// see `CaptureSheet.confirmingTransactionId`.
  final String? confirmingTransactionId;
}

/// Parses the `wudget://capture` URI used by the home widget tap, the
/// app-icon long-press shortcut, and a bill reminder notification's action
/// (Sprint 13). Pure so it's testable without a platform channel; unknown
/// or missing `kind` defaults to expense, since that's the one-tap path
/// the widget and shortcut are for.
CaptureLaunch parseCaptureDeepLink(Uri? uri) {
  if (uri == null || uri.scheme != 'wudget' || uri.host != 'capture') {
    return const CaptureLaunch(kind: CaptureKind.expense);
  }
  final params = uri.queryParameters;
  final kind = switch (params['kind']) {
    'income' => CaptureKind.income,
    'transfer' => CaptureKind.transfer,
    _ => CaptureKind.expense,
  };
  final amountMinor = params['amountMinor'] == null ? null : int.tryParse(params['amountMinor']!);
  return CaptureLaunch(
    kind: kind,
    categoryId: params['categoryId'],
    accountId: params['accountId'],
    amountMinor: amountMinor,
    note: params['note'],
    confirmingTransactionId: params['confirmTxId'],
  );
}
