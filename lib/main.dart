import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/isar_provider.dart';
import 'core/prefs_provider.dart';
import 'data/job_cache.dart';
import 'data/saved_job_cache.dart';
import 'providers/pending_sync_service.dart';
import 'router/app_router.dart';

/// Assignment 2.3 → 2.4 — the boot sequence.
///
/// Assignment 2.4 changes:
///   - `Isar.open` opens with `[JobCacheSchema, SavedJobCacheSchema]`
///     (Stretch C's persistent bookmark queue).
///   - `CareerHubApp` reads `appRouterProvider` (renamed from
///     the plain `goRouterProvider` in earlier assignments) —
///     the router is now a `@riverpod` function that participates
///     in the dependency graph.
///   - After `runApp`, we read `pendingSyncServiceProvider` once
///     so the connectivity listener starts immediately without
///     needing a widget to hydrate it.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dir = await getApplicationDocumentsDirectory();

  final isar = await Isar.open(
    // Assignment 2.4 Stretch C — SavedJobCacheSchema is emitted
    // by isar_community_generator into lib/data/saved_job_cache.g.dart.
    [JobCacheSchema, SavedJobCacheSchema],
    directory: dir.path,
  );

  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [
      isarProvider.overrideWithValue(isar),
      prefsProvider.overrideWithValue(prefs),
    ],
  );

  // Assignment 2.4 Stretch C — bring up the pending-sync
  // listener. Reading the provider once is enough to construct
  // it and start its connectivity subscription; the closure it
  // returns is captured by the provider container until dispose.
  container.read(pendingSyncServiceProvider);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const CareerHubApp(),
    ),
  );
}

class CareerHubApp extends ConsumerWidget {
  const CareerHubApp({super.key});

  static const Color _seedColor = Color(0xFF00695C);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Assignment 2.4, Part 9.2 — the router is now
    // `appRouterProvider` (the @riverpod-generated version).
    final router = ref.watch(appRouterProvider);

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
