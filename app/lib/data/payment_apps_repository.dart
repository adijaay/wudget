import 'dart:convert';

import 'package:flutter/services.dart';

/// Whether an app's payments are recorded, as PaymentApps.kt keeps it.
enum PaymentAppState { on, off, ask }

class PaymentApp {
  const PaymentApp({required this.pkg, required this.label, required this.state, this.count = 0, this.lastAt});

  final String pkg;
  final String label;
  final PaymentAppState state;

  /// Payment notifications this app has sent since wudget started listening.
  final int count;
  final DateTime? lastAt;
}

/// An app with a launcher icon, for adding one before it has sent anything.
typedef InstalledApp = ({String pkg, String label});

/// The per-app choices live natively, so the listener can read them while
/// wudget is closed and the "Ya, selalu catat" button can answer without it.
abstract final class PaymentAppsRepository {
  static const _channel = MethodChannel('wudget/payments');

  static Future<List<PaymentApp>> all() async {
    final raw = await _channel.invokeMethod<String>('getApps').catchError((_) => null);
    return raw == null ? const [] : parsePaymentApps(raw);
  }

  static Future<void> set(String pkg, String label, PaymentAppState state) =>
      _channel.invokeMethod<void>('setApp', {'pkg': pkg, 'label': label, 'state': state.name}).catchError((_) {});

  static Future<List<InstalledApp>> installed() async {
    final raw = await _channel.invokeListMethod<Map>('installedApps').catchError((_) => null);
    return [for (final a in raw ?? const <Map>[]) (pkg: a['pkg'] as String, label: a['label'] as String)];
  }
}

/// Most active first, so the apps that pay most often sit at the top.
List<PaymentApp> parsePaymentApps(String raw) {
  final map = jsonDecode(raw) as Map<String, dynamic>;
  final apps = [
    for (final MapEntry(:key, :value) in map.entries)
      PaymentApp(
        pkg: key,
        label: (value as Map<String, dynamic>)['label'] as String? ?? key,
        state: PaymentAppState.values.asNameMap()[value['state']] ?? PaymentAppState.ask,
        count: value['count'] as int? ?? 0,
        lastAt: value['lastAt'] == null ? null : DateTime.fromMillisecondsSinceEpoch(value['lastAt'] as int),
      ),
  ];
  return apps..sort((a, b) => b.count.compareTo(a.count));
}
