import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/prefs_provider.dart';

/// Assignment 2.3, Part 6 — connectivity detection and the offline flag.
///
/// This file is deliberately WITHOUT `@riverpod` / code generation:
///   - It contains only two plain providers whose factories are tiny.
///   - There is no reason to run `build_runner` for it.
///   - Keeping it hand-written matches the pattern for other
///     "adapter" providers in this codebase (`isarProvider`,
///     `prefsProvider`).
///
/// No `part` directive; nothing generated. See README 2.3, Part 6.

/// A single module-level [Connectivity] instance. Declared OUTSIDE any
/// provider factory so `connectivity_plus`'s single platform-channel
/// subscription is created once per process rather than re-created
/// every time Riverpod rebuilds the stream provider.
final Connectivity _connectivity = Connectivity();

/// Assignment 2.3, Part 6 — the raw connectivity change stream.
///
/// **Type parameter must be `List<ConnectivityResult>`, not
/// `ConnectivityResult`.** connectivity_plus changed its API in
/// version 5.0 to emit a list because a device can be reachable
/// through multiple network interfaces simultaneously (wifi +
/// cellular on Android's auto-transport, for example). Declaring the
/// provider as `StreamProvider<ConnectivityResult>` compiles and
/// works on a phone with only one active connection — then throws a
/// runtime cast exception (`_TypeError: type
/// 'List<ConnectivityResult>' is not a subtype of type
/// 'ConnectivityResult'`) the first time it emits on a
/// multi-connected device. See README 2.3, Part 6.
///
/// The stream does NOT emit on subscription — it fires only when
/// connectivity CHANGES. This is what produces the "banner hidden for
/// the first frame after cold boot" behaviour documented in
/// README 2.3, Q4.
final StreamProvider<List<ConnectivityResult>> connectivityStreamProvider =
    StreamProvider<List<ConnectivityResult>>((ref) {
  return _connectivity.onConnectivityChanged;
});

/// Assignment 2.3, Part 6 — the derived "is the device offline?" flag.
///
/// Watches [connectivityStreamProvider] and `.when()`s over the
/// resulting `AsyncValue<List<ConnectivityResult>>`:
///
/// - **`data:`** — return `true` iff EVERY element in the list is
///   `ConnectivityResult.none`. If any transport reports something
///   else (wifi, mobile, ethernet, vpn, bluetooth) the device has a
///   route and we treat it as online. `.every` (not `.any`) is
///   deliberate: a phone in a tunnel might report `[none, mobile]`
///   for a beat as the wifi radio negotiates — we shouldn't flash
///   the banner in that transient state.
/// - **`loading:`** — cold-boot state, before the first change event
///   has arrived. Returns `false` so the banner is HIDDEN on the very
///   first frame, even if the device is actually offline. The
///   trade-off — a single-frame cosmetic delay in exchange for
///   avoiding another platform-channel round-trip inside `main()` —
///   is called out in README 2.3, Q4.
/// - **`error:`** — same conservative `false`. A misbehaving
///   connectivity plugin should not commandeer the UI to say
///   "offline" when the app might in fact be online.
final Provider<bool> isOfflineProvider = Provider<bool>((ref) {
  final async = ref.watch(connectivityStreamProvider);
  return async.when(
    data: (results) =>
        results.every((result) => result == ConnectivityResult.none),
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Assignment 2.3, Stretch A — a human-readable "Last updated N …"
/// string derived from `SharedPreferences['jobs_last_synced']`.
///
/// Returns `null` when no timestamp has ever been stored (a fresh
/// install that has never had a successful network response). The
/// banner uses this null-safety to fall back to a generic
/// "You're offline — showing cached jobs." message on the first-ever
/// airplane-mode cold boot — see README 2.3, Stretch A's edge-case
/// note.
///
/// The provider is a plain [Provider] rather than a [StreamProvider]:
/// SharedPreferences does not expose a change stream, and the value
/// only changes when the network fetch writes a new timestamp — at
/// which point the notifier's rebuild invalidates dependents anyway.
/// The banner therefore reads a snapshot; the string ages while the
/// user stares at the banner, but that discrepancy is only ever a
/// handful of seconds and self-corrects on the next rebuild.
final Provider<String?> cacheAgeProvider = Provider<String?>((ref) {
  final prefs = ref.watch(prefsProvider);
  final millis = prefs.getInt('jobs_last_synced');
  if (millis == null) return null;

  final then = DateTime.fromMillisecondsSinceEpoch(millis);
  final diff = DateTime.now().difference(then);

  // A small, deliberate ladder. Reading top-to-bottom mirrors how a
  // person would describe an interval — the smallest human unit that
  // still fits.
  if (diff.inSeconds < 60) return 'Last updated just now';
  if (diff.inMinutes < 60) {
    final n = diff.inMinutes;
    return 'Last updated $n minute${n == 1 ? '' : 's'} ago';
  }
  if (diff.inHours < 24) {
    final n = diff.inHours;
    return 'Last updated $n hour${n == 1 ? '' : 's'} ago';
  }
  final n = diff.inDays;
  return 'Last updated $n day${n == 1 ? '' : 's'} ago';
});
