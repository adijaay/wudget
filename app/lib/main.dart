import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show TableUpdateQuery;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'core/providers.dart';
import 'data/analytics_repository.dart';
import 'data/database.dart';
import 'data/feature_flags_repository.dart';
import 'data/goals_repository.dart';
import 'data/notification_scheduler.dart';
import 'data/payment_auto_save_repository.dart';
import 'data/recurrence_repository.dart';
import 'data/reminder_orchestrator.dart';
import 'design/tokens.dart';
import 'domain/period.dart';
import 'features/comeback/comeback_screen.dart';
import 'domain/default_categories.dart';
import 'features/capture/capture_sheet.dart';
import 'features/ledger/ledger_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/pantau/pantau_screen.dart';
import 'features/settings/backup_screen.dart';
import 'features/settings/saya_screen.dart';
import 'features/shell/nav_bar.dart';
import 'features/budget/budget_screen.dart';
import 'features/widget/capture_deeplink.dart';
import 'features/widget/home_widget_service.dart';

final navigatorKey = GlobalKey<NavigatorState>();

/// How far ahead recurring items are materialised on every app open — far
/// enough that "upcoming" always has something to show, not so far that a
/// year of placeholder rows pile up unconfirmed.
const _materializeLookaheadDays = 60;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');

  WudgetDatabase db;
  try {
    db = WudgetDatabase();
    await seedDefaultsIfEmpty(db);
  } catch (_) {
    // A database that can't even open or seed is corrupt beyond this app's
    // repair — plan/04-ux-design.md's states table: "Catat, new user
    // error: corrupt database routes to restore." The old file is moved
    // aside (never deleted outright — it may still hold recoverable rows
    // a person could inspect by hand) and a fresh one takes its place, so
    // the restore screen has somewhere real to write into.
    final documents = await getApplicationDocumentsDirectory();
    final dbFile = File(p.join(documents.path, 'wudget.sqlite'));
    if (dbFile.existsSync()) {
      await dbFile.rename('${dbFile.path}.corrupt-${DateTime.now().millisecondsSinceEpoch}');
    }
    db = WudgetDatabase();
    await seedDefaultsIfEmpty(db);

    runApp(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          title: 'wudget',
          theme: buildWudgetTheme(WudgetTokens.light, Brightness.light),
          darkTheme: buildWudgetTheme(WudgetTokens.dark, Brightness.dark),
          home: const BackupScreen(),
        ),
      ),
    );
    return;
  }

  await FeatureFlagsRepository(db).assignPaceFirstVariant();

  // Process any auto-saved payments from the notification listener
  await PaymentAutoSaveRepository(db).processPendingPayments();

  runApp(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const WudgetApp(),
    ),
  );

  await AnalyticsRepository(db).logEvent('app_open');
  final fromWidget = await HomeWidgetService(navigatorKey).init();
  // Cold start only: main() does not run again on resume.
  if (!fromWidget) await showLaunchSurface(db);

  // Materialisation runs on every app open, per plan/03-architecture.md —
  // idempotent by watermark (RecurrenceRepository), so this is safe to
  // call unconditionally rather than tracking "did we already run today".
  final today = DateTime.now();
  final todayBucket = DateTime.utc(today.year, today.month, today.day).difference(DateTime.utc(1970, 1, 1)).inDays;
  await RecurrenceRepository(db).materializeAll(toDayInclusive: todayBucket + _materializeLookaheadDays);

  final notificationScheduler = NotificationScheduler(navigatorKey);
  await notificationScheduler.init();
  await scheduleUpcomingReminders(db, notificationScheduler);
  // Chained so two quick saves cannot interleave a cancel with a schedule.
  var retention = scheduleRetentionReminders(db, notificationScheduler);
  // A save today drops today's evening reminder; a Saya switch takes effect.
  db
      .tableUpdates(TableUpdateQuery.onAllTables([db.transactions, db.featureFlags, db.appSettings]))
      .listen((_) => retention = retention.catchError((_) {}).then((_) => scheduleRetentionReminders(db, notificationScheduler)));
  // A milestone is announced once, whichever write moved the wallet.
  final goals = GoalsRepository(db);
  var milestones = goals.announceMilestones(notificationScheduler.showNow);
  db
      .tableUpdates(TableUpdateQuery.onAllTables([db.postings, db.goals]))
      .listen((_) => milestones = milestones.catchError((_) {}).then((_) => goals.announceMilestones(notificationScheduler.showNow)));
}

/// Cold launch: the first-run tour if it has never been seen, else the
/// comeback screen after a gap, else the capture sheet.
Future<void> showLaunchSurface(WudgetDatabase db) async {
  final context = navigatorKey.currentContext;
  if (context != null && context.mounted) {
    final toured = await FeatureFlagsRepository(db)
        .getBool(onboardingCompletedKey, defaultValue: false)
        .catchError((_) => false);
    if (!toured) {
          // The tour is a new install's launch surface. The capture sheet used to
          // open here instead, which asked someone to record an expense before
          // anything had explained what recording means. Not awaited, so launch
          // work (materialisation, reminders) still runs behind the tour.
          unawaited(Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const OnboardingScreen())));
          return;
        }

        // A failed check just means no welcome screen this time.
    final comeback = await loadComeback(db, todayDayBucket()).catchError((_) => null);
    if (comeback != null && context.mounted) {
      unawaited(AnalyticsRepository(db).logEvent('comeback_shown', props: {'lastEntryDay': comeback.lastEntryDay}));
      unawaited(Navigator.of(context)
          .push<bool>(MaterialPageRoute(builder: (_) => ComebackScreen(data: comeback)))
          .then((startToday) {
        final ctx = navigatorKey.currentContext;
        if (startToday == true && ctx != null && ctx.mounted) {
          showCaptureLaunch(ctx, const CaptureLaunch(kind: CaptureKind.expense), source: CaptureSource.launch);
        }
      }));
    } else if (context.mounted) {
      unawaited(showCaptureLaunch(
        context,
        const CaptureLaunch(kind: CaptureKind.expense),
        source: CaptureSource.launch,
      ));
    }
  }
}

class WudgetApp extends StatelessWidget {
  const WudgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'wudget',
      theme: buildWudgetTheme(WudgetTokens.light, Brightness.light),
      darkTheme: buildWudgetTheme(WudgetTokens.dark, Brightness.dark),
      home: const HomeShell(),
    );
  }
}

/// Catat, Pantau, Kantong and Saya, with capture docked in the middle of
/// the bar — the shell every mockup in `design/` is drawn inside. The tab
/// order is the mockups' own: the two review surfaces left of the capture
/// button, the two "where things are kept" surfaces right of it.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  /// Catat is home; cold launch puts the capture sheet over it (main()).
  int _index = 0;

  /// BudgetScreen reads once on load; a fresh key per visit keeps the
  /// Kantong tab current inside the IndexedStack.
  int _kantongVisits = 0;

  static const _destinations = [
    NavDestination(label: 'Catat', icon: Icons.receipt_long_outlined, selectedIcon: Icons.receipt_long),
    NavDestination(label: 'Pantau', icon: Icons.insights_outlined, selectedIcon: Icons.insights),
    NavDestination(
      label: 'Kantong',
      icon: Icons.account_balance_wallet_outlined,
      selectedIcon: Icons.account_balance_wallet,
    ),
    NavDestination(label: 'Saya', icon: Icons.person_outline, selectedIcon: Icons.person),
  ];

  /// Pantau is built on first visit: its period-close sheet must not pop over home at launch.
  bool _pantauVisited = false;

  void _select(int i) => setState(() {
        if (i == 1) _pantauVisited = true;
        if (i == 2 && _index != 2) _kantongVisits++;
        _index = i;
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: [
        LedgerScreen(onOpenKantong: () => _select(2)),
        _pantauVisited ? const PantauScreen() : const SizedBox.shrink(),
        BudgetScreen(key: ValueKey(_kantongVisits)),
        const SayaScreen(),
      ]),
      floatingActionButton: CaptureButton(
        onPressed: () => showCaptureLaunch(
          context,
          const CaptureLaunch(kind: CaptureKind.expense),
          source: CaptureSource.nav,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: WudgetNavBar(
        currentIndex: _index,
        destinations: _destinations,
        onSelected: _select,
      ),
    );
  }
}
