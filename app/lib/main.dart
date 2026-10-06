import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'core/providers.dart';
import 'data/analytics_repository.dart';
import 'data/database.dart';
import 'data/notification_scheduler.dart';
import 'data/recurrence_repository.dart';
import 'data/reminder_orchestrator.dart';
import 'design/tokens.dart';
import 'domain/default_categories.dart';
import 'features/capture/capture_sheet.dart';
import 'features/ledger/ledger_screen.dart';
import 'features/pantau/pantau_screen.dart';
import 'features/settings/backup_screen.dart';
import 'features/settings/saya_screen.dart';
import 'features/shell/nav_bar.dart';
import 'features/wallets/wallets_screen.dart';
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

  runApp(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const WudgetApp(),
    ),
  );

  await AnalyticsRepository(db).logEvent('app_open');
  await HomeWidgetService(navigatorKey).init();

  // Materialisation runs on every app open, per plan/03-architecture.md —
  // idempotent by watermark (RecurrenceRepository), so this is safe to
  // call unconditionally rather than tracking "did we already run today".
  final today = DateTime.now();
  final todayBucket = DateTime.utc(today.year, today.month, today.day).difference(DateTime.utc(1970, 1, 1)).inDays;
  await RecurrenceRepository(db).materializeAll(toDayInclusive: todayBucket + _materializeLookaheadDays);

  final notificationScheduler = NotificationScheduler(navigatorKey);
  await notificationScheduler.init();
  await scheduleUpcomingReminders(db, notificationScheduler);
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
  /// Kantong: what a returning user opens the app to check. Capture itself
  /// is a button, not a tab, so the landing screen does not need to be the
  /// one you type into.
  int _index = 2;

  static const _screens = [
    LedgerScreen(),
    PantauScreen(),
    WalletsScreen(),
    SayaScreen(),
  ];

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      floatingActionButton: CaptureButton(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => const CaptureSheet(),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: WudgetNavBar(
        currentIndex: _index,
        destinations: _destinations,
        onSelected: (i) => setState(() => _index = i),
      ),
    );
  }
}
