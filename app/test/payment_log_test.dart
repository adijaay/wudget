import 'package:flutter_test/flutter_test.dart';
import 'package:wudget/data/payment_log_repository.dart';
import 'package:wudget/features/widget/capture_deeplink.dart';

void main() {
  test('parses the native log, newest first, with recorded state', () {
    final entries = parsePaymentLog(
      '[{"id":"b","at":1760000000000,"app":"GoPay","amountMinor":25000,"merchant":"Kopi Kenangan","title":"t","text":"x","inputted":true},'
      '{"id":"a","at":1759990000000,"app":"Jago","amountMinor":10000,"merchant":null,"title":null,"text":null,"inputted":false}]',
    );
    expect(entries.map((e) => e.id), ['b', 'a']);
    expect(entries.first.inputted, isTrue);
    expect(entries.last.merchant, isNull);
  });

  test('a payment notification tap carries its log id into capture', () {
    final launch = parseCaptureDeepLink(Uri.parse('wudget://capture?kind=expense&amountMinor=25000&note=Kopi&src=payment&logId=abc'));
    expect(launch.paymentLogId, 'abc');
    expect(parseCaptureDeepLink(launch.toUri()).paymentLogId, 'abc');
  });
}
