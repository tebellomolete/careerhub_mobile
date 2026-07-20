import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Part 2.1 — the two placeholder providers that MUST be overridden in
/// `main()` before `runApp`.
///
/// Neither provider knows how to construct its value: `Isar.open` and
/// `SharedPreferences.getInstance` are both async, and Riverpod
/// providers are synchronous unless you accept a `Future`/`Stream`. We
/// don't want widget code paying that cost — we want the instance
/// waiting in the graph, fully materialised, from frame one. So `main`
/// does the awaits, then hands the resolved singletons to
/// `ProviderScope.overrides`.
///
/// Throwing inside the default body is deliberate: if a widget calls
/// `ref.watch(isarProvider)` in a code path that boots without the
/// override in place (a test that forgets it, a future rewrite that
/// drops the `main` wiring), the failure is loud and immediate, not a
/// silent null. Same pattern as the Riverpod docs recommend for
/// bootstrap-time singletons.
final isarProvider = Provider<Isar>((ref) {
  throw UnimplementedError(
    'isarProvider was read without being overridden. main() must call '
    'Isar.open() and override this provider in ProviderScope.',
  );
});

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider was read without being overridden. main() '
    'must call SharedPreferences.getInstance() and override this '
    'provider in ProviderScope.',
  );
});
