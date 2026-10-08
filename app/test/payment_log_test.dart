import 'dart:convert';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wudget/data/database.dart';
import 'package:wudget/data/payment_log_repository.dart';
import 'package:wudget/domain/default_categories.dart';
import 'package:wudget/features/widget/capture_deeplink.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late WudgetDatabase db;
  late List<Map<String, dynamic>> log;

  setUp(() async {
    db = WudgetDatabase(NativeDatabase.memory());
    await seedDefaultsIfEmpty(db);
    log = [
      {'id': 'a', 'at': 1760000000000, 'app': 'GoPay', 'amountMinor': 25000, 'merchant': 'Kopi Kenangan', 'inputted': false},
    ];
    // Stands in for PaymentLog.kt: the same getLog / patchLog contract.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('wudget/payments'), (call) async {
      final args = call.arguments as Map?;
      switch (call.method) {
        case 'getLog':
          return jsonEncode(log);
        case 'patchLog':
          log.firstWhere((e) => e['id'] == args!['id']).addAll(jsonDecode(args!['fields'] as String) as Map<String, dynamic>);
      }
      return null;
    });
  });
  tearDown(() => db.close());

  Future<List<Transaction>> live() => (db.select(db.transactions)..where((t) => t.deletedAt.isNull())).get();

  test('a logged payment goes into Catat once, as an expense under Lainnya', () async {
    final repo = PaymentLogRepository(db);
    expect(await repo.recordNew(), 1);
    expect(await repo.recordNew(), 0);
    final txs = await live();
    expect(txs.single.note, 'Kopi Kenangan');
    expect(log.single['txId'], txs.single.id);
    final legs = await (db.select(db.postings)..where((p) => p.transactionId.equals(txs.single.id))).get();
    expect(legs.map((p) => p.amountMinor).fold<int>(0, (a, b) => a + b), 0);
    expect(legs.where((p) => p.categoryId != null).single.categoryId, PaymentLogRepository.fallbackCategoryId);
  });

  test('it lands in the wallet named after the paying app', () async {
    await db.into(db.accounts).insert(AccountsCompanion.insert(
          id: 'acc_gopay', name: 'GoPay', type: 'ewallet', currency: 'IDR', updatedAt: 0));
    await PaymentLogRepository(db).recordNew();
    final legs = await db.select(db.postings).get();
    expect(legs.where((p) => p.accountId != null).single.accountId, 'acc_gopay');
  });

  test('unticking removes the entry and the auto-save leaves it out; ticking adds it back', () async {
    final repo = PaymentLogRepository(db);
    await repo.recordNew();
    await repo.setRecorded((await PaymentLogRepository.all()).single, false);
    expect(await live(), isEmpty);
    await repo.recordNew();
    expect(await live(), isEmpty);
    await repo.setRecorded((await PaymentLogRepository.all()).single, true);
    expect((await live()).single.id, log.single['txId']);
  });

  test('the notification tap finds the saved entry', () async {
    final saved = await PaymentLogRepository(db).savedFor('a');
    expect(saved!.entry.amountMinor, 25000);
    expect(saved.categoryId, PaymentLogRepository.fallbackCategoryId);
  });

  test('a payment notification tap carries its log id into capture', () {
    final launch = parseCaptureDeepLink(Uri.parse('wudget://capture?kind=expense&amountMinor=25000&note=Kopi&src=payment&logId=abc'));
    expect(launch.paymentLogId, 'abc');
    expect(parseCaptureDeepLink(launch.toUri()).paymentLogId, 'abc');
  });
}
