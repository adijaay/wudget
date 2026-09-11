import 'package:flutter_test/flutter_test.dart';
import 'package:wudget/data/notification_scheduler.dart';
import 'package:wudget/features/widget/capture_deeplink.dart';

void main() {
  test('round-trips every field through parseCaptureDeepLink', () {
    final uri = reminderDeepLink(
      categoryId: 'cat_tagihan',
      accountId: 'acc_bank',
      amountMinor: 150000,
      note: 'Listrik Maret',
      confirmingTransactionId: 'rec1_20123',
    );
    final launch = parseCaptureDeepLink(Uri.parse(uri));

    expect(launch.categoryId, 'cat_tagihan');
    expect(launch.accountId, 'acc_bank');
    expect(launch.amountMinor, 150000);
    expect(launch.note, 'Listrik Maret');
    expect(launch.confirmingTransactionId, 'rec1_20123');
  });

  test('omits categoryId from the uri when null, rather than the string "null"', () {
    final uri = reminderDeepLink(
      categoryId: null,
      accountId: 'acc_bank',
      amountMinor: 50000,
      note: '',
      confirmingTransactionId: 'rec2_1',
    );
    expect(uri, isNot(contains('categoryId')));
  });
}
