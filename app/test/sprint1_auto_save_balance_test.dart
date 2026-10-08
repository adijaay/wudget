import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wudget/data/database.dart';
import 'package:wudget/data/payment_auto_save_repository.dart';

void main() {
  test('auto-save creates balanced postings (sum to zero)', () async {
    final db = WudgetDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final autoSaveRepo = PaymentAutoSaveRepository(db);

    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await db.into(db.accounts).insert(AccountsCompanion.insert(
      id: 'test-account',
      name: 'Test Wallet',
      type: 'ewallet',
      currency: 'IDR',
      updatedAt: now,
    ));

    await db.into(db.categories).insert(CategoriesCompanion.insert(
      id: 'test-category',
      name: 'Food',
      kind: 'expense',
      iconKey: 'food',
      hueIndex: 0,
      sortOrder: 0,
      updatedAt: now,
    ));

    final payment = {
      'amountMinor': 25000,
      'merchant': 'Warung Makan',
      'appLabel': 'GoPay',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    await autoSaveRepo.savePayment(payment);

    final transactions = await db.select(db.transactions).get();
    expect(transactions.length, 1);

    final postings = await (db.select(db.postings)
      ..where((p) => p.transactionId.equals(transactions.first.id)))
        .get();

    expect(postings.length, 2);

    final sum = postings.fold<int>(0, (acc, p) => acc + p.baseAmountMinor);
    expect(sum, 0, reason: 'Postings must sum to zero');

    final expensePosting = postings.firstWhere((p) => p.baseAmountMinor < 0);
    expect(expensePosting.amountMinor, -25000);
    expect(expensePosting.categoryId, 'test-category');

    final sourcePosting = postings.firstWhere((p) => p.baseAmountMinor > 0);
    expect(sourcePosting.amountMinor, 25000);
    expect(sourcePosting.accountId, 'test-account');
  });
}
