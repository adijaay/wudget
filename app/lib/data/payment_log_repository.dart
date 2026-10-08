import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import 'capture_queries.dart';
import 'database.dart';
import 'postings_repository.dart';

/// One payment notification wudget recognised, as PaymentLog.kt stored it.
class PaymentLogEntry {
  const PaymentLogEntry({
    required this.id,
    required this.at,
    required this.app,
    required this.amountMinor,
    required this.inputted,
    this.unread = false,
    this.pending = false,
    this.pkg,
    this.processed = false,
    this.txId,
    this.merchant,
    this.title,
    this.text,
  });

  factory PaymentLogEntry.fromJson(Map<String, dynamic> j) => PaymentLogEntry(
        id: j['id'] as String,
        at: DateTime.fromMillisecondsSinceEpoch(j['at'] as int),
        app: j['app'] as String,
        amountMinor: j['amountMinor'] as int? ?? 0,
        unread: j['kind'] == 'unread',
        pending: j['pending'] as bool? ?? false,
        pkg: j['pkg'] as String?,
        inputted: j['inputted'] as bool? ?? false,
        processed: j['processed'] as bool? ?? false,
        txId: j['txId'] as String?,
        merchant: j['merchant'] as String?,
        title: j['title'] as String?,
        text: j['text'] as String?,
      );

  final String id;
  final DateTime at;
  final String app;
  final int amountMinor;

  /// From a watched app but not read as a payment, so it has no amount and is never recorded on its own.
  final bool unread;

  /// From an app the owner has not answered about yet, so held out of the ledger.
  final bool pending;

  /// The posting app's package; missing on entries from before per-app choices.
  final String? pkg;

  /// In the ledger: as [txId] when wudget wrote it, or ticked by hand.
  final bool inputted;

  /// Already seen by the auto-save once, so an unticked entry stays out.
  final bool processed;
  final String? txId;
  final String? merchant;
  final String? title;
  final String? text;

  String get note => unread ? (title?.trim().isNotEmpty == true ? title! : app) : merchant ?? app;
}

/// The phone-only log of payment notifications, kept natively so the
/// listener can write to it while the app is closed, and the ledger
/// entries it turns into.
class PaymentLogRepository {
  PaymentLogRepository(this._db);
  final WudgetDatabase _db;

  static const _channel = MethodChannel('wudget/payments');
  static const _uuid = Uuid();
  static const fallbackCategoryId = 'cat_lainnya';
  static const _walletWords = {
    'GoPay': ['gopay'],
    'Livin\' by Mandiri': ['livin', 'mandiri'],
    'Jago': ['jago'],
    'ShopeePay': ['shopee'],
  };

  // Launch, resume and the log screen can all ask at once; one at a time keeps a payment from saving twice.
  static Future<void> _queue = Future.value();

  static Future<List<PaymentLogEntry>> all() async {
    final raw = await _channel.invokeMethod<String>('getLog').catchError((_) => null);
    if (raw == null) return const [];
    return parsePaymentLog(raw);
  }

  static Future<void> _patch(String id, Map<String, Object?> fields) =>
      _channel.invokeMethod<void>('patchLog', {'id': id, 'fields': jsonEncode(fields)}).catchError((_) {});

  /// Records every payment the listener logged since the last run.
  Future<int> recordNew() => _serial(() async {
        var saved = 0;
        for (final e in await all()) {
          if (e.processed || e.unread || e.pending) continue;
          if (e.inputted) {
            await _patch(e.id, {'processed': true});
            continue;
          }
          final txId = await _write(e);
          await _patch(e.id, {'inputted': true, 'processed': true, 'txId': txId});
          saved++;
        }
        return saved;
      });

  /// The log's checkbox: ticking writes the entry, unticking removes the one wudget wrote.
  Future<void> setRecorded(PaymentLogEntry e, bool recorded) => _serial(() async {
        if (recorded) {
          if (e.unread) return;
          final txId = await _write(e);
          await _patch(e.id, {'inputted': true, 'processed': true, 'pending': false, 'txId': txId});
        } else {
          if (e.txId != null) await PostingsRepository(_db).deleteTransaction(e.txId!);
          await _patch(e.id, {'inputted': false, 'processed': true, 'pending': false, 'txId': null});
        }
      });

  /// An edit in capture replaces the transaction, so the log follows the new id.
  static Future<void> relink(String logId, String txId) =>
      _patch(logId, {'inputted': true, 'processed': true, 'txId': txId});

  /// The ledger transaction behind [logId], if it still exists.
  Future<({PaymentLogEntry entry, String accountId, String categoryId})?> savedFor(String logId) async {
    await recordNew();
    final entry = (await all()).where((e) => e.id == logId).firstOrNull;
    final txId = entry?.txId;
    if (entry == null || txId == null) return null;
    final tx = await (_db.select(_db.transactions)..where((t) => t.id.equals(txId) & t.deletedAt.isNull()))
        .getSingleOrNull();
    if (tx == null) return null;
    final legs = await (_db.select(_db.postings)..where((p) => p.transactionId.equals(txId))).get();
    final account = legs.where((p) => p.accountId != null).firstOrNull?.accountId;
    final category = legs.where((p) => p.categoryId != null).firstOrNull?.categoryId;
    if (account == null || category == null) return null;
    return (entry: entry, accountId: account, categoryId: category);
  }

  Future<T> _serial<T>(Future<T> Function() run) {
    final next = _queue.then((_) => run());
    _queue = next.then((_) {}, onError: (_) {});
    return next;
  }

  Future<String> _write(PaymentLogEntry e) async {
    final accountId = await _accountFor(e.app);
    final account = await (_db.select(_db.accounts)..where((a) => a.id.equals(accountId))).getSingle();
    final categoryId = await _categoryId();
    final txId = _uuid.v4();
    await PostingsRepository(_db).insertTransaction(
      transaction: TransactionsCompanion.insert(
        id: txId,
        kind: 'expense',
        occurredAt: e.at.toUtc().millisecondsSinceEpoch,
        tzOffsetMinutes: e.at.timeZoneOffset.inMinutes,
        note: Value(e.note),
        updatedAt: DateTime.now().toUtc().millisecondsSinceEpoch,
      ),
      postings: [
        PostingsCompanion.insert(
          id: _uuid.v4(),
          transactionId: txId,
          accountId: Value(accountId),
          amountMinor: -e.amountMinor,
          currency: account.currency,
          baseAmountMinor: -e.amountMinor,
        ),
        PostingsCompanion.insert(
          id: _uuid.v4(),
          transactionId: txId,
          categoryId: Value(categoryId),
          amountMinor: e.amountMinor,
          currency: account.currency,
          baseAmountMinor: e.amountMinor,
        ),
      ],
    );
    return txId;
  }

  /// The wallet named after the paying app ("GoPay", "Jago", "Mandiri"), else the default wallet.
  Future<String> _accountFor(String app) async {
    final accounts = await (_db.select(_db.accounts)..where((a) => a.archivedAt.isNull() & a.deletedAt.isNull())).get();
    final words = _walletWords[app] ?? [app.toLowerCase()];
    for (final a in accounts) {
      final name = a.name.toLowerCase();
      if (words.any(name.contains)) return a.id;
    }
    return CaptureQueries(_db).defaultAccountId();
  }

  Future<String> _categoryId() async {
    final other = await (_db.select(_db.categories)
          ..where((c) => c.id.equals(fallbackCategoryId) & c.deletedAt.isNull()))
        .getSingleOrNull();
    if (other != null) return other.id;
    final any = await (_db.select(_db.categories)
          ..where((c) => c.kind.equals('expense') & c.parentId.isNull() & c.deletedAt.isNull())
          ..limit(1))
        .getSingle();
    return any.id;
  }
}

List<PaymentLogEntry> parsePaymentLog(String raw) => [
      for (final e in jsonDecode(raw) as List) PaymentLogEntry.fromJson(e as Map<String, dynamic>),
    ];
