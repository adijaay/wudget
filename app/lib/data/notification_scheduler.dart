import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../domain/reminder_schedule.dart';
import '../features/capture/capture_sheet.dart';
import '../features/widget/capture_deeplink.dart';

const _defaultReminderHour = 9;

/// What `scheduleUpcomingReminders` (reminder_orchestrator.dart) needs —
/// implemented by [NotificationScheduler] and by a fake in tests, so the
/// per-instance scheduling logic (which reminder gets which copy) is
/// testable without a platform channel.
abstract interface class ReminderScheduler {
  Future<void> scheduleForInstance({
    required String transactionId,
    required int dueDay,
    required String title,
    required String body,
    required String deepLinkPayload,
    int hour = _defaultReminderHour,
  });

  Future<void> cancelForInstance(String transactionId);

  /// Evening, payday and weekly recap reminders: fixed small [id]s, so a
  /// reschedule cancels and replaces them without a lookup table.
  Future<void> scheduleReminder({
    required int id,
    required int day,
    required int hour,
    required String title,
    required String body,
    String? payload,
  });

  Future<void> cancelReminder(int id);
}

/// Schedules and cancels local bill-reminder notifications, and opens the
/// capture sheet — prefilled, per the notification's deep link payload —
/// when one is tapped. Thin by design: the DST-correct fire-time math
/// lives in `domain/reminder_schedule.dart`, tested on its own without a
/// platform channel; this class only talks to the plugin.
/// See plan/05-sprints.md Sprint 13.
class NotificationScheduler implements ReminderScheduler {
  NotificationScheduler(this._navigatorKey);
  final GlobalKey<NavigatorState> _navigatorKey;
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    final deviceTimeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(deviceTimeZone));

    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (response) => _openFromPayload(response.payload),
    );
    _initialized = true;
    // Android 13+ asks once; later calls return the stored answer.
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// A stable notification id derived from the transaction id, so
  /// scheduling the same instance twice replaces rather than duplicates,
  /// and cancelling needs no separate id-lookup table.
  int _notificationId(String transactionId) => transactionId.hashCode & 0x7fffffff;

  /// [deepLinkPayload] is the same `wudget://capture?...` string the home
  /// widget uses, carrying this instance's category/account/amount/note
  /// and `confirmTxId` — see capture_deeplink.dart.
  @override
  Future<void> scheduleForInstance({
    required String transactionId,
    required int dueDay,
    required String title,
    required String body,
    required String deepLinkPayload,
    int hour = _defaultReminderHour,
  }) async {
    await _plugin.zonedSchedule(
      _notificationId(transactionId),
      title,
      body,
      reminderFireTime(location: tz.local, dueDay: dueDay, hour: hour, minute: 0),
      const NotificationDetails(
        android: AndroidNotificationDetails('bills', 'Tagihan', importance: Importance.high),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: deepLinkPayload,
    );
  }

  @override
  Future<void> cancelForInstance(String transactionId) {
    return _plugin.cancel(_notificationId(transactionId));
  }

  @override
  Future<void> scheduleReminder({
    required int id,
    required int day,
    required int hour,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      reminderFireTime(location: tz.local, dueDay: day, hour: hour, minute: 0),
      const NotificationDetails(
        android: AndroidNotificationDetails('reminders', 'Pengingat'),
        iOS: DarwinNotificationDetails(),
      ),
      // Inexact is fine for "this evening" and needs no exact-alarm grant.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  @override
  Future<void> cancelReminder(int id) => _plugin.cancel(id);

  /// Shown immediately, for news that has already happened (a goal
  /// milestone) rather than a time to come.
  Future<void> showNow(int id, String body) => _plugin.show(
        id,
        'Target',
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails('goals', 'Target'),
          iOS: DarwinNotificationDetails(),
        ),
      );

  void _openFromPayload(String? payload) {
    final context = _navigatorKey.currentContext;
    if (context == null || payload == null) return;
    final launch = parseCaptureDeepLink(Uri.tryParse(payload));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => CaptureSheet(
        initialKind: launch.kind,
        initialCategoryId: launch.categoryId,
        initialAccountId: launch.accountId,
        initialAmountMinor: launch.amountMinor,
        initialNote: launch.note,
        confirmingTransactionId: launch.confirmingTransactionId,
      ),
    );
  }
}

/// The `wudget://capture` URI a reminder notification's action opens —
/// same shape [NotificationScheduler.scheduleForInstance] passes as its
/// `payload`, built here so the query-building logic has one home.
String reminderDeepLink({
  required String? categoryId,
  required String accountId,
  required int amountMinor,
  required String note,
  required String confirmingTransactionId,
}) {
  final params = {
    'kind': 'expense',
    if (categoryId != null) 'categoryId': categoryId,
    'accountId': accountId,
    'amountMinor': '$amountMinor',
    'note': note,
    'confirmTxId': confirmingTransactionId,
  };
  return Uri(scheme: 'wudget', host: 'capture', queryParameters: params).toString();
}
