import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/isar_provider.dart';
import 'core/prefs_provider.dart';
import 'data/job_cache.dart';
import 'router/app_router.dart';

/// Assignment 2.3, Part 4 — `main()` is now `Future<void>` and executes
/// two I/O operations before the first widget builds.
///
/// The order is strict and every step is called out in README 2.3, Q3:
///
///   1. `WidgetsFlutterBinding.ensureInitialized()` — MUST be first.
///      It constructs the `WidgetsBinding` singleton whose
///      `BinaryMessenger` is the pipe every subsequent MethodChannel
///      call (path_provider, shared_preferences, connectivity_plus,
///      Isar's native init) routes through. Skipping it produces a
///      `FlutterError: Binding has not yet been initialized` from
///      `path_provider`'s very first invocation.
///
///   2. `getApplicationDocumentsDirectory()` — the platform documents
///      directory that Isar will write its `.isar` file into. This is
///      a MethodChannel call under the hood, which is why step 1 is
///      required first.
///
///   3. `Isar.open([JobCacheSchema], directory: dir.path)` — opens the
///      single application-scoped Isar instance. `JobCacheSchema` is
///      emitted by `isar_community_generator` into `lib/data/job_cache.g.dart`
///      when `build_runner` runs (Part 9); until then the IDE may
///      underline `JobCacheSchema` here.
///
///   4. `SharedPreferences.getInstance()` — the singleton prefs
///      instance. Cheap on subsequent calls but the first one loads
///      the plist/XML off disk, so we do it once at boot rather than
///      inside a widget's `build()`.
///
///   5. `runApp` with `ProviderScope` overrides for both providers —
///      `overrideWithValue` takes effect the moment the container is
///      constructed (before any `build()` runs), so every subsequent
///      `ref.watch(isarProvider)` / `ref.watch(prefsProvider)` sees
///      the real instance, not the stubs from `lib/core/`.
Future<void> main() async {
  // Step 1 — see README 2.3, Q3.
  WidgetsFlutterBinding.ensureInitialized();

  // Step 2 — the documents directory. `await`ed because
  // path_provider's MethodChannel call is inherently async.
  final dir = await getApplicationDocumentsDirectory();

  // Step 3 — Isar.open. The schema list references the class the
  // generator produced a descriptor for.
  final isar = await Isar.open(
    [JobCacheSchema],
    directory: dir.path,
  );

  // Step 4 — SharedPreferences.
  final prefs = await SharedPreferences.getInstance();

  // Step 5 — inject both real instances into the provider container
  // via `overrideWithValue`. Every `ref.watch` on `isarProvider` /
  // `prefsProvider` from any `build()` in the tree now returns the
  // resolved instance synchronously.
  runApp(
    ProviderScope(
      overrides: [
        isarProvider.overrideWithValue(isar),
        prefsProvider.overrideWithValue(prefs),
      ],
      child: const CareerHubApp(),
    ),
  );
}

/// Assignment 1.4: CareerHubApp becomes a ConsumerWidget so it can read the
/// GoRouter out of goRouterProvider, and switches from MaterialApp with a
/// `home:` to MaterialApp.router driven by that router. The URL is now the
/// source of truth for what is on screen — there is no single home widget
/// any more.
///
/// Assignment 2.3 note: the root widget did NOT change for 2.3. Only
/// `main()` above changed.
class CareerHubApp extends ConsumerWidget {
  const CareerHubApp({super.key});

  // Same deep-teal seed from Assignment 1.1. Part 3a requires reusing it,
  // not choosing a new one — light and dark themes should read as the
  // same app, not two different apps.
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
      // Follows the device's system setting rather than forcing one mode.
      themeMode: ThemeMode.system,
      // Wires GoRouter's parser, delegate and back-button dispatcher in.
      routerConfig: router,
    );
  }
}
