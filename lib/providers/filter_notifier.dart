import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/prefs_provider.dart';

// Assignment 2.3, Part 7 — the part directive for the generator's
// output. `dart run build_runner build --delete-conflicting-outputs`
// emits `filter_notifier.g.dart` containing the private base class
// `_$FilterNotifier` and the `filterProvider` variable this
// file exports. Until that runs the IDE will underline `_$FilterNotifier`
// and every mention of `filterProvider` — expected. See
// README 2.3, Part 7.
part 'filter_notifier.g.dart';

/// The value stored in SharedPreferences for the "no location filter
/// selected" state. Kept as a class-level constant so the sentinel
/// spelling lives in exactly one place — `filteredJobsProvider` reads
/// it too and a rename would otherwise silently desynchronise the two
/// files.
const String kFilterAll = 'All';

/// The SharedPreferences key. Same rationale — one spelling, one
/// place. Namespaced by feature (`selected_filter`) rather than by
/// domain (`location`) because the brief specifies the exact key.
const String kSelectedFilterKey = 'selected_filter';

/// Assignment 2.3, Part 7 — the persisted filter notifier.
///
/// **Scope decision — see README 2.3, Part 7.** The brief describes a
/// single-slot string `FilterNotifier` defaulting to `'All'`. CareerHub
/// already replaced its original string-based filter chip row with two
/// typed dropdowns (`locationFilterProvider` + `jobTypeFilterProvider`,
/// commit 0ae5c03). Rather than add a third filter surface just to
/// match the brief's chip-row shape literally, this notifier persists
/// the LOCATION dropdown selection as `'All' | 'onSite' | 'remote' |
/// 'hybrid'`. The job-type dropdown stays ephemeral. The old
/// `locationFilterProvider` in `job_providers.dart` is deleted;
/// `filteredJobsProvider` and the location dropdown in `home_screen.dart`
/// now go through this notifier.
///
/// **Two crucial ref rules** — see README 2.3, Part 7 (paraphrasing
/// Assignment 1.3 Q1's `watch` vs `read` rule):
///
///   - `build()` uses `ref.watch(prefsProvider)`. This is a subscription
///     — if the (overridden) `prefsProvider` ever changed identity
///     (it won't in production, but a test might), `build()` would
///     re-run and pick up the new instance. `ref.read` inside `build()`
///     would cache the first-observed instance forever, so a hot-
///     restart in a test could produce stale reads.
///   - `select()` uses `ref.read(prefsProvider)`. This is a mutation
///     method, not a build method — creating a subscription here would
///     leak a listener that has nothing to redraw. See Assignment 1.3
///     Q1 for the widget-level version of the same rule.
///
/// **Why the return type is a synchronous `String`, not
/// `Future<String>`.** `prefsProvider` is a plain `Provider<SharedPreferences>`
/// overridden with a real, already-`getInstance()`-ed instance at
/// startup (see `main.dart`). `ref.watch(prefsProvider)` therefore
/// returns a resolved `SharedPreferences` synchronously, and
/// `prefs.getString(...)` is a synchronous read from the plugin's
/// in-memory cache (SharedPreferences loads the plist/XML once, at
/// `getInstance()` time). No `Future` is involved.
@riverpod
class FilterNotifier extends _$FilterNotifier {
  @override
  String build() {
    final prefs = ref.watch(prefsProvider);
    return prefs.getString(kSelectedFilterKey) ?? kFilterAll;
  }

  /// Update the persisted filter and the in-memory state atomically-
  /// ish. `setString` returns a `Future<bool>` that resolves when the
  /// underlying plist/XML write completes — it is DELIBERATELY not
  /// awaited: the write is best-effort. If the OS kills the process
  /// mid-write the user only loses this one preference; on next
  /// launch `build()` reads the previous stored value and the app
  /// still works.
  void select(String value) {
    final prefs = ref.read(prefsProvider);
    // ignore: unawaited_futures
    prefs.setString(kSelectedFilterKey, value);
    state = value;
  }
}
