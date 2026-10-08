import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'database.dart';
import 'postings_repository.dart';

/// Reads auto-saved payments from the native PaymentListenerService and
/// writes them to the database. Called on app startup to process any
/// payments captured while the app was closed.
class PaymentAutoSaveRepository {
  PaymentAutoSaveRepository(this._db) : _postings = PostingsRepository(_db);
  final WudgetDatabase _db;
  final PostingsRepository _postings;

  static const _channel = MethodChannel('wudget/payments');

  /// Process all pending payments from SharedPreferences and save them
  /// as expense transactions. Returns the count of transactions created.
  Future<int> processPendingPayments() async {
    try {
      final paymentsJson = await _channel.invokeMethod<String>('getPendingPayments');
      if (paymentsJson == null || paymentsJson.isEmpty) return 0;

      final List<dynamic> payments = jsonDecode(paymentsJson);
      int count = 0;

      for (final payment in payments) {
        try {
          await savePayment(payment);
          count++;
        } catch (e) {
          print('Failed to save payment: $e');
        }
      }

      // Clear the pending list after processing
      await _channel.invokeMethod('clearPendingPayments');

      return count;
    } catch (e) {
      print('Error processing pending payments: $e');
      return 0;
    }
  }

  Future<void> savePayment(Map<String, dynamic> payment) async {
    final amountMinor = payment['amountMinor'] as int;
    final merchant = payment['merchant'] as String?;
    final appLabel = payment['appLabel'] as String;
    final timestamp = payment['timestamp'] as int;

    // Find or create a default cash account
    final accounts = await (_db.select(_db.accounts)
          ..where((a) => a.deletedAt.isNull()))
        .get();
    
    if (accounts.isEmpty) {
      throw Exception('No accounts available to save payment');
    }

    // Use the first account (likely the default cash/wallet)
    final account = accounts.first;

    // Find a default expense category
    final categories = await (_db.select(_db.categories)
          ..where((c) => c.kind.equals('expense') & c.deletedAt.isNull())
          ..limit(1))
        .get();

    if (categories.isEmpty) {
      throw Exception('No expense category available');
    }

    final category = categories.first;
    final now = DateTime.now().toUtc();
    final transactionId = const Uuid().v4();
    final postingId = const Uuid().v4();

    final transaction = TransactionsCompanion(
      id: Value(transactionId),
      kind: const Value('expense'),
      occurredAt: Value(DateTime.fromMillisecondsSinceEpoch(timestamp).toUtc().millisecondsSinceEpoch),
      tzOffsetMinutes: Value(DateTime.now().timeZoneOffset.inMinutes),
      title: Value(merchant),
      note: Value('Auto-saved from $appLabel notification'),
      updatedAt: Value(now.millisecondsSinceEpoch),
    );

    final postings = [
      PostingsCompanion(
        id: Value(postingId),
        transactionId: Value(transactionId),
        accountId: Value(account.id),
        categoryId: Value(category.id),
        amountMinor: Value(-amountMinor),
        currency: Value(account.currency),
        baseAmountMinor: Value(-amountMinor),
      ),
      PostingsCompanion(
        id: Value(const Uuid().v4()),
        transactionId: Value(transactionId),
        accountId: Value(account.id),
        categoryId: const Value(null),
        amountMinor: Value(amountMinor),
        currency: Value(account.currency),
        baseAmountMinor: Value(amountMinor),
      ),
    ];

    await _postings.insertTransaction(
      transaction: transaction,
      postings: postings,
    );
  }
}
