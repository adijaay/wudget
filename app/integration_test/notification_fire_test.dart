import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Proves the manifest receivers deliver a scheduled reminder on a real
/// phone: same channel and schedule mode as NotificationScheduler.scheduleReminder.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('an inexact reminder scheduled a minute ahead is shown', (tester) async {
    tzdata.initializeTimeZones();
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ));
    final android = plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()!;
    const id = 1999;
    await plugin.cancel(id);

    await plugin.zonedSchedule(
      id,
      'Belum ada catatan hari ini',
      'Kalau tadi ada pengeluaran, ketuk untuk mencatat.',
      tz.TZDateTime.now(tz.UTC).add(const Duration(minutes: 1)),
      const NotificationDetails(android: AndroidNotificationDetails('reminders', 'Pengingat')),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
    expect((await plugin.pendingNotificationRequests()).any((r) => r.id == id), isTrue);
    // ignore: avoid_print
    print('EXACT_ALLOWED=${await android.canScheduleExactNotifications()}');

    var shown = false;
    for (var i = 0; i < 36 && !shown; i++) {
      await Future<void>.delayed(const Duration(seconds: 5));
      shown = (await android.getActiveNotifications()).any((n) => n.id == id);
    }
    // ignore: avoid_print
    print('REMINDER_SHOWN=$shown');
    expect(shown, isTrue, reason: 'not shown within 3 minutes');
  }, timeout: const Timeout(Duration(minutes: 5)));
}
