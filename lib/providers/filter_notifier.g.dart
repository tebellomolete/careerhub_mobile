// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'filter_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(FilterNotifier)
const filterProvider = FilterNotifierProvider._();

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
final class FilterNotifierProvider
    extends $NotifierProvider<FilterNotifier, String> {
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
  const FilterNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'filterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$filterNotifierHash();

  @$internal
  @override
  FilterNotifier create() => FilterNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$filterNotifierHash() => r'7aa8589f196cde32c95201531f763e1ce1f91da3';

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

abstract class _$FilterNotifier extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
