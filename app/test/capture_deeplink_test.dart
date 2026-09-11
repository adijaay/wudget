import 'package:flutter_test/flutter_test.dart';
import 'package:wudget/features/capture/capture_sheet.dart';
import 'package:wudget/features/widget/capture_deeplink.dart';

void main() {
  test('defaults to expense with no uri', () {
    expect(parseCaptureDeepLink(null), CaptureKind.expense);
  });

  test('parses each kind from the query param', () {
    expect(parseCaptureDeepLink(Uri.parse('wudget://capture?kind=expense')), CaptureKind.expense);
    expect(parseCaptureDeepLink(Uri.parse('wudget://capture?kind=income')), CaptureKind.income);
    expect(parseCaptureDeepLink(Uri.parse('wudget://capture?kind=transfer')), CaptureKind.transfer);
  });

  test('defaults to expense on unknown kind or wrong scheme/host', () {
    expect(parseCaptureDeepLink(Uri.parse('wudget://capture?kind=bogus')), CaptureKind.expense);
    expect(parseCaptureDeepLink(Uri.parse('https://capture?kind=income')), CaptureKind.expense);
    expect(parseCaptureDeepLink(Uri.parse('wudget://other?kind=income')), CaptureKind.expense);
  });
}
