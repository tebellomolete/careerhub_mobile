/// Assignment 3.3, Part 2 — the compile-time environment gate.
///
/// Every field on this class is a `static const` populated by
/// `String.fromEnvironment` / `bool.fromEnvironment`, which the Dart
/// compiler resolves at BUILD time from the `--dart-define-from-file`
/// flag and constant-folds into the compiled binary. There is no
/// runtime lookup, no file read, no environment-variable check at
/// launch — the values are literals in `libapp.so` by the time the
/// app runs.
///
/// See README 3.3 Q1 for the security reasoning against loading these
/// same values from a bundled asset (`config.prod.json` inside
/// `assets/flutter_assets/` is trivially extractable with Android
/// Studio's APK Analyser); Q4 for the same reasoning applied to
/// `isProduction` (a runtime SharedPreferences flag would let a
/// modified APK flip production behaviour without re-signing).
class AppConfig {
  const AppConfig._();

  /// The base URL for the CareerHub API for this build.
  ///
  /// Defaulted to `http://10.0.2.2:5254/api/v1` — the Android emulator's
  /// alias for the host machine's `localhost`, so a `flutter run`
  /// without `--dart-define-from-file` reaches a locally-running
  /// `dotnet run` API. Every real build passes an explicit value via
  /// `config.dev.json` or `config.prod.json`; the default exists so
  /// the code compiles when the flag is absent (e.g. during
  /// `flutter analyze`).
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5254/api/v1',
  );

  /// The environment name for this build. Values: `dev`, `prod`.
  /// Defaulted to `dev` so the log interceptor gate and
  /// `isProduction` stay dev-safe when the flag is absent.
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'dev',
  );

  /// Whether this build forwards uncaught errors to a real crash
  /// reporter (Crashlytics / Sentry). Defaulted to `false` so the
  /// forward path never fires in a dev build, even one that
  /// somehow slipped `ENVIRONMENT=prod` without setting this key.
  static const bool enableCrashReporting = bool.fromEnvironment(
    'ENABLE_CRASH_REPORTING',
    defaultValue: false,
  );

  /// True when this build was compiled with `ENVIRONMENT=prod`.
  /// Used by `_reportError` in `lib/main.dart` to route uncaught
  /// errors to Crashlytics in production and to `debugPrint` in
  /// development.
  static bool get isProduction => environment == 'prod';
}
