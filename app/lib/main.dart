import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/providers.dart';
import 'data/database.dart';
import 'design/tokens.dart';
import 'domain/default_categories.dart';
import 'features/ledger/ledger_screen.dart';
import 'features/pantau/pantau_screen.dart';
import 'features/wallets/wallets_screen.dart';
import 'features/widget/home_widget_service.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  final db = WudgetDatabase();
  await seedDefaultsIfEmpty(db);

  runApp(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const WudgetApp(),
    ),
  );

  await HomeWidgetService(navigatorKey).init();
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

/// Kantong, Catat and Pantau (Sprint 8) are the three tabs through v1.0.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _screens = [WalletsScreen(), LedgerScreen(), PantauScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), label: 'Kantong'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Catat'),
          NavigationDestination(icon: Icon(Icons.insights_outlined), label: 'Pantau'),
        ],
      ),
    );
  }
}
