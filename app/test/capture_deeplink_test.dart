import 'package:flutter_test/flutter_test.dart';
import 'package:wudget/data/capture_queries.dart';
import 'package:wudget/features/capture/capture_sheet.dart';
import 'package:wudget/features/widget/capture_deeplink.dart';

void main() {
  test('defaults to expense with no uri', () {
    expect(parseCaptureDeepLink(null).kind, CaptureKind.expense);
  });

  test('parses each kind from the query param', () {
    expect(parseCaptureDeepLink(Uri.parse('wudget://capture?kind=expense')).kind, CaptureKind.expense);
    expect(parseCaptureDeepLink(Uri.parse('wudget://capture?kind=income')).kind, CaptureKind.income);
    expect(parseCaptureDeepLink(Uri.parse('wudget://capture?kind=transfer')).kind, CaptureKind.transfer);
  });

  test('defaults to expense on unknown kind or wrong scheme/host', () {
    expect(parseCaptureDeepLink(Uri.parse('wudget://capture?kind=bogus')).kind, CaptureKind.expense);
    expect(parseCaptureDeepLink(Uri.parse('https://capture?kind=income')).kind, CaptureKind.expense);
    expect(parseCaptureDeepLink(Uri.parse('wudget://other?kind=income')).kind, CaptureKind.expense);
  });

  test('a bare kind-only uri leaves every prefill field null', () {
    final launch = parseCaptureDeepLink(Uri.parse('wudget://capture?kind=expense'));
    expect(launch.categoryId, isNull);
    expect(launch.accountId, isNull);
    expect(launch.amountMinor, isNull);
    expect(launch.note, isNull);
    expect(launch.confirmingTransactionId, isNull);
  });

  test('a reminder notification\'s uri carries every prefill field', () {
    final launch = parseCaptureDeepLink(Uri.parse(
      'wudget://capture?kind=expense&categoryId=cat_tagihan&accountId=acc_bank'
      '&amountMinor=150000&note=Listrik&confirmTxId=rec1_20123',
    ));
    expect(launch.categoryId, 'cat_tagihan');
    expect(launch.accountId, 'acc_bank');
    expect(launch.amountMinor, 150000);
    expect(launch.note, 'Listrik');
    expect(launch.confirmingTransactionId, 'rec1_20123');
  });

  test('a home chip pre-fills note, category, subcategory and amount, and survives a widget uri', () {
    const chip = QuickChip(
      note: 'Warung',
      categoryId: 'cat_makan_siang',
      topCategoryId: 'cat_makan',
      categoryName: 'Makan siang',
      hueIndex: 0,
      amountMinor: 18000,
    );
    final launch = parseCaptureDeepLink(CaptureLaunch.fromChip(chip).toUri());
    expect(launch.kind, CaptureKind.expense);
    expect(launch.categoryId, 'cat_makan');
    expect(launch.subcategoryId, 'cat_makan_siang');
    expect(launch.amountMinor, 18000);
    expect(launch.note, 'Warung');
  });
}
