import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Assignment 2.3, Part 4 — the placeholder provider for the single
/// application-scoped [SharedPreferences] instance.
///
/// Same rationale as [isarProvider]: this factory never actually runs
/// in the production app. `main()` awaits
/// `SharedPreferences.getInstance()` once at boot and injects the
/// result via `ProviderScope.overrides` using `overrideWithValue`.
/// Reading this provider without an override throws — the pattern is
/// intentional; see README 2.3, Q3.
///
/// **Why this must be synchronous at read time.** `FilterNotifier.build()`
/// calls `ref.watch(prefsProvider).getString('selected_filter')`
/// synchronously — Riverpod's `Notifier.build()` returning a plain
/// `String` (not `Future<String>`) depends on `prefs` being available
/// as a resolved value at read time. Overriding a `Provider<SharedPreferences>`
/// with `overrideWithValue` guarantees exactly that. A
/// `FutureProvider<SharedPreferences>` would break the whole chain —
/// see README 2.3, Q3's "Two disadvantages of FutureProvider" answer.
final Provider<SharedPreferences> prefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'prefsProvider was read without an override. Override it in main.dart '
    'via `ProviderScope(overrides: [prefsProvider.overrideWithValue(prefs)])` '
    'before calling runApp — see lib/main.dart. In tests, override it '
    'with the instance returned by `SharedPreferences.getInstance()` after '
    'calling `SharedPreferences.setMockInitialValues({})`.',
  ),
);
