import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/providers.dart';
import 'data/database.dart';
import 'design/tokens.dart';
import 'domain/default_categories.dart';
import 'features/wallets/wallets_screen.dart';

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
}

class WudgetApp extends StatelessWidget {
  const WudgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'wudget',
      theme: buildWudgetTheme(WudgetTokens.light, Brightness.light),
      darkTheme: buildWudgetTheme(WudgetTokens.dark, Brightness.dark),
      // Temporary home: Kantong is the first real tab, with its own FAB
      // into the capture sheet. Real tab navigation (Catat/Kantong/Pantau)
      // is Sprint 6+ — see DECISIONS.md.
      home: const WalletsScreen(),
    );
  }
}
