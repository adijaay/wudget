import 'dart:convert';

import 'package:flutter/services.dart';

/// One payment notification wudget recognised, as PaymentLog.kt stored it.
class PaymentLogEntry {
  const PaymentLogEntry({
    required this.id,
    required this.at,
    required this.app,
    required this.amountMinor,
    required this.inputted,
    this.merchant,
    this.title,
    this.text,
  });

  factory PaymentLogEntry.fromJson(Map<String, dynamic> j) => PaymentLogEntry(
        id: j['id'] as String,
        at: DateTime.fromMillisecondsSinceEpoch(j['at'] as int),
        app: j['app'] as String,
        amountMinor: j['amountMinor'] as int,
        inputted: j['inputted'] as bool? ?? false,
        merchant: j['merchant'] as String?,
        title: j['title'] as String?,
        text: j['text'] as String?,
      );

  final String id;
  final DateTime at;
  final String app;
  final int amountMinor;
  final bool inputted;
  final String? merchant;
  final String? title;
  final String? text;
}

/// The phone-only log of payment notifications, kept natively so the
/// listener can write to it while the app is closed.
abstract final class PaymentLogRepository {
  static const _channel = MethodChannel('wudget/payments');

  static Future<List<PaymentLogEntry>> all() async {
    final raw = await _channel.invokeMethod<String>('getLog').catchError((_) => null);
    if (raw == null) return const [];
    return parsePaymentLog(raw);
  }

  static Future<void> setInputted(String id, bool inputted) =>
      _channel.invokeMethod<void>('setInputted', {'id': id, 'inputted': inputted}).catchError((_) {});
}

List<PaymentLogEntry> parsePaymentLog(String raw) => [
      for (final e in jsonDecode(raw) as List) PaymentLogEntry.fromJson(e as Map<String, dynamic>),
    ];
