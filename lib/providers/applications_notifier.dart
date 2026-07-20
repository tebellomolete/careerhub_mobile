import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/api_result.dart';
import '../data/applications_repository.dart';
import '../models/job_application.dart';
import 'persistence_providers.dart';

part 'applications_notifier.g.dart';

/// SharedPreferences key for the currently-selected filter chip.
/// Stored as the enum's [ApplicationStatus.wireName] (or the sentinel
/// `'All'`) so the value is human-readable in the on-device store.
const _kFilterPrefsKey = 'applications.filter';

/// SharedPreferences key for the "last synced" timestamp shown in the
/// offline banner (stretch goal). Stored as milliseconds since epoch —
/// an int is the smallest, most portable representation prefs supports.
const _kLastSyncedPrefsKey = 'applications.lastSyncedMillis';

/// The sentinel value the filter notifier exposes when NO status is
/// selected — i.e. the "All" chip is highlighted.
///
/// A sentinel + non-nullable `ApplicationStatus?` (rather than plain
/// null) makes the filter chip's `onSelected` callback and the derived
/// provider's `where` filter symmetric: both branches speak the same
/// vocabulary.
typedef ApplicationFilter = ApplicationStatus?;

/// Part 4.1 — the cache-then-network AsyncNotifier.
///
/// `build()`:
///   1. reads Isar synchronously w.r.t. the network via
///      `repo.readCache()`;
///   2. if the cache is non-empty, calls `state = AsyncData(cached)`
///      immediately so the UI leaves the loading spinner on the very
///      first frame after the notifier is watched;
///   3. `await`s the network fetch;
///   4. on success returns the fresh list (which replaces the state);
///   5. on failure with a NON-empty cache returns the cache instead
///      of throwing — the user must see data, not an error screen.
///
/// The "seed on empty" behaviour lives HERE (not in the repository)
/// because the repository is a stateless adapter and the "did the
/// initial fetch fail with nothing cached yet" decision is a
/// notifier-level policy — deleting it once the backend endpoint ships
/// is a one-file change.
@riverpod
class ApplicationsNotifier extends _$ApplicationsNotifier {
  @override
  Future<List<JobApplication>> build() async {
    final repo = ref.read(applicationsRepositoryProvider);

    final cached = await repo.readCache();
    if (cached.isNotEmpty) {
      // Push the cached snapshot to the widget layer immediately so the
      // ListView renders before the network fetch resolves. The `state`
      // setter is inherited from AsyncNotifier.
      state = AsyncData(cached);
    }

    final result = await repo.fetchAndCache();
    return switch (result) {
      Success(:final data) => _onFetchSuccess(data),
      NetworkFailure(:final message) => _onFetchFailure(cached, message),
      ServerFailure(:final message) => _onFetchFailure(cached, message),
      UnknownFailure(:final message) => _onFetchFailure(cached, message),
    };
  }

  List<JobApplication> _onFetchSuccess(List<JobApplication> fresh) {
    // Fresh data has just replaced the cache — record the sync time so
    // the offline banner can render "Last synced …".
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setInt(
      _kLastSyncedPrefsKey,
      DateTime.now().millisecondsSinceEpoch,
    );
    return fresh;
  }

  /// Failure policy: prefer cache over throwing when we have anything
  /// to show. If the cache is empty AND the network path failed AND
  /// we haven't already seeded, seed the demo dataset once so the
  /// first-run experience is not a permanent error screen (see the
  /// note on the `seedCacheForDemo` method in
  /// `applications_repository.dart` — this is a temporary bootstrap).
  Future<List<JobApplication>> _onFetchFailure(
    List<JobApplication> cached,
    String message,
  ) async {
    if (cached.isNotEmpty) {
      return cached;
    }
    final repo = ref.read(applicationsRepositoryProvider);
    await repo.seedCacheForDemo();
    return repo.readCache();
  }

  /// Stretch — pull-to-refresh + the retry button both call this.
  /// `invalidateSelf` re-runs `build()` (which re-runs the whole
  /// cache-then-network dance); awaiting `future` keeps the
  /// `RefreshIndicator`'s spinner on screen until the fetch settles.
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

/// Part 4.2 — the filter notifier.
///
/// Not `@riverpod` because we need direct setter access
/// (`ref.read(applicationFilterProvider.notifier).select(...)`) and
/// because `build()` MUST return a value SYNCHRONOUSLY here — the
/// SharedPreferences instance is already resolved in the graph (via
/// [sharedPreferencesProvider]), so there is no async work to do.
/// Using a plain [Notifier] keeps that guarantee visible in the type.
class ApplicationFilterNotifier extends Notifier<ApplicationFilter> {
  @override
  ApplicationFilter build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final raw = prefs.getString(_kFilterPrefsKey);
    if (raw == null || raw == _kAllSentinel) {
      return null;
    }
    return ApplicationStatusX.fromWire(raw);
  }

  /// Setter used by the filter-chip taps. Synchronous write to prefs +
  /// synchronous state update — no `await`, no debounce, no
  /// FutureProvider. `SharedPreferences.setString` returns a
  /// `Future<bool>` but the value is stored in the in-memory map
  /// immediately, so the next `getString` reads the new value even
  /// before the async platform-channel write resolves. See README.
  void select(ApplicationFilter next) {
    final prefs = ref.read(sharedPreferencesProvider);
    final raw = next == null ? _kAllSentinel : next.wireName;
    prefs.setString(_kFilterPrefsKey, raw);
    state = next;
  }

  static const _kAllSentinel = 'All';
}

/// The provider handle for the filter notifier. Manual because
/// [ApplicationFilterNotifier] is a plain `Notifier` (see the
/// justification on the class above).
final applicationFilterProvider =
    NotifierProvider<ApplicationFilterNotifier, ApplicationFilter>(
  ApplicationFilterNotifier.new,
);

/// Part 4.3 — the derived provider widgets watch. Composes the
/// AsyncNotifier's data with the filter notifier's synchronous state,
/// keeping the loading/error facets of the AsyncValue intact so the
/// screen's `AsyncValue.when` still has three branches to render.
final filteredApplicationsProvider =
    Provider<AsyncValue<List<JobApplication>>>((ref) {
  final applicationsAsync = ref.watch(applicationsProvider);
  final filter = ref.watch(applicationFilterProvider);

  return applicationsAsync.whenData((apps) {
    if (filter == null) return apps;
    return apps.where((app) => app.status == filter).toList(growable: false);
  });
});

/// Stretch — the "last synced" timestamp exposed to the offline
/// banner. `null` when the app has never completed a successful
/// network fetch (fresh install, or every fetch so far has failed).
final lastSyncedProvider = Provider<DateTime?>((ref) {
  // Rebuild whenever the applications notifier settles: a successful
  // fetch writes the prefs value inside `_onFetchSuccess`, and we want
  // the banner to reflect that immediately.
  ref.watch(applicationsProvider);
  final prefs = ref.read(sharedPreferencesProvider);
  final millis = prefs.getInt(_kLastSyncedPrefsKey);
  if (millis == null) return null;
  return DateTime.fromMillisecondsSinceEpoch(millis);
});
