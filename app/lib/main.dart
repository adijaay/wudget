import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers.dart';
import 'data/database.dart';
import 'design/token_demo_screen.dart';
import 'design/tokens.dart';
import 'domain/default_categories.dart';
import 'features/capture/capture_sheet.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      home: const HomeShell(),
    );
  }
}

/// Temporary home: the token demo plus a FAB into the capture sheet. Real
/// tab navigation (Catat/Kantong/Pantau) is Sprint 5+.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const TokenDemoScreen(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => const CaptureSheet(),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
