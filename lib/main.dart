import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/job_application_isar.dart';
import 'providers/persistence_providers.dart';
import 'router/app_router.dart';

/// W2D3 in-class challenge, Part 2.1 — async bootstrap.
///
/// Everything the provider graph needs as a synchronous singleton is
/// resolved here BEFORE the first `runApp` frame, then handed to
/// `ProviderScope.overrides`. That way widgets and providers never
/// have to unwrap a `FutureProvider` for prefs or Isar — the values are
/// already there.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
    [JobApplicationIsarSchema],
    directory: dir.path,
  );
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        isarProvider.overrideWithValue(isar),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const CareerHubApp(),
    ),
  );
}

/// Assignment 1.4: CareerHubApp is a ConsumerWidget so it can read the
/// GoRouter out of goRouterProvider, and switches from MaterialApp with
/// a `home:` to MaterialApp.router driven by that router. The URL is
/// the source of truth for what is on screen — there is no single home
/// widget any more.
class CareerHubApp extends ConsumerWidget {
  const CareerHubApp({super.key});

  // Same deep-teal seed from Assignment 1.1.
  static const Color _seedColor = Color(0xFF00695C);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'CareerHub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: _seedColor),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
