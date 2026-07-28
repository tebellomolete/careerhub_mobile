import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/app_config.dart';
import 'core/isar_provider.dart';
import 'core/prefs_provider.dart';
import 'data/application_draft.dart';
import 'data/job_cache.dart';
import 'data/saved_job_cache.dart';
import 'providers/pending_sync_service.dart';
import 'router/app_router.dart';

/// Assignment 3.3, Part 7 — the boot sequence, wrapped in
/// `runZonedGuarded`.
///
/// The dual error-surface design (README 3.3 Q4):
///
///   - `FlutterError.onError` catches errors raised inside the
///     Flutter framework's synchronous build/layout/paint pipeline
///     (a `build()` throw, an assertion failure inside a
///     `RenderObject`, a missing ancestor widget). The handler
///     forwards to `FlutterError.presentError` (which prints the
///     framework error to stderr in dev mode and swallows it in
///     release mode) AND to `_reportError` so the same event is
///     routed to Crashlytics/Sentry in prod.
///
///   - `runZonedGuarded`'s second argument catches Dart-level
///     async errors that escape a `try/catch`: a Future that
///     rejects with no handler, a Stream `onError` no one
///     subscribed to, an `async` function called without `await`
///     whose returned Future rejects. `_reportError` is registered
///     directly as the zone handler so the two surfaces converge
///     on the same reporter.
///
/// `WidgetsFlutterBinding.ensureInitialized()` MUST be called inside
/// the zone (before `runApp`) — otherwise the binding is bound to
/// the root zone and framework-error routing happens outside the
/// zone we set up.
///
/// Preserves the pre-3.3 boot sequence:
///   - `Isar.open` with all three schemas.
///   - `ProviderContainer` with `isarProvider` and `prefsProvider`
///     overrides (Assignment 2.3 Part 4 requirement — the
///     providers cannot construct their own async values, they
///     must receive the already-opened instances).
///   - `container.read(pendingSyncServiceProvider)` to warm up
///     the connectivity listener before the first frame.
Future<void> main() async {
  runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Assignment 3.3, Part 7.3 — the FlutterError.onError
      // surface. Set inside the zone so the framework's error
      // routing is bound before the first widget builds. Calls
      // presentError (which handles the dev-mode debug print
      // itself) AND _reportError, so a framework error is both
      // visible in the console and forwarded to the crash reporter
      // in production.
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        _reportError(details.exception, details.stack);
      };

      final dir = await getApplicationDocumentsDirectory();

      final isar = await Isar.open(
        [JobCacheSchema, SavedJobCacheSchema, ApplicationDraftSchema],
        directory: dir.path,
      );

      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          isarProvider.overrideWithValue(isar),
          prefsProvider.overrideWithValue(prefs),
        ],
      );

      container.read(pendingSyncServiceProvider);

      runApp(
        UncontrolledProviderScope(
          container: container,
          child: const CareerHubApp(),
        ),
      );
    },
    // Assignment 3.3, Part 7.1 — the zone's error handler. Passed
    // as `_reportError` directly (not as a wrapping lambda) so the
    // signature matches `void Function(Object, StackTrace)` — the
    // exact type `runZonedGuarded` expects.
    _reportError,
  );
}

/// Assignment 3.3, Part 7.2 — the crash-reporting sink.
///
/// Two-branch behaviour gated on `AppConfig.isProduction`:
///
///   - **Development** (`AppConfig.environment == 'dev'`) — print
///     to the debug console. The developer sees the error in the
///     `flutter run` terminal immediately. Forwarding to
///     Crashlytics in dev would flood the release-quality signal
///     with every deliberate throw the developer types (see
///     README 3.3 Q4's second paragraph).
///
///   - **Production** (`AppConfig.environment == 'prod'`) — forward
///     to Crashlytics or Sentry via a `recordError` call. Leaving
///     this branch as a commented `TODO` so the app compiles
///     without a Crashlytics dependency; wiring it is a one-line
///     addition once the crash reporter is chosen.
///
/// `stackTrace` is nullable because `FlutterError.onError`'s
/// `details.stack` is nullable (the framework may not have a stack
/// for every error path). `debugPrint` handles nulls gracefully;
/// the Crashlytics call in production would pass through the
/// nullable to `recordError`'s optional stackTrace parameter.
void _reportError(Object error, StackTrace? stackTrace) {
  if (!AppConfig.isProduction) {
    // Dev — write to the debug console. The stack print goes on a
    // separate call so an oversized stack doesn't get truncated
    // by debugPrint's internal buffer limit.
    debugPrint('[UNCAUGHT ERROR] $error');
    if (stackTrace != null) {
      debugPrint(stackTrace.toString());
    }
    return;
  }
  // TODO: Production — forward to Crashlytics / Sentry.
  //
  // Crashlytics wire-up (once firebase_core + firebase_crashlytics
  // are added to pubspec.yaml and Firebase is initialised in
  // `main()` before `runApp`):
  //
  //   FirebaseCrashlytics.instance
  //       .recordError(error, stackTrace, fatal: true);
  //
  // Sentry equivalent:
  //
  //   Sentry.captureException(error, stackTrace: stackTrace);
}

class CareerHubApp extends ConsumerWidget {
  const CareerHubApp({super.key});

  static const Color _seedColor = Color(0xFF00695C);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
