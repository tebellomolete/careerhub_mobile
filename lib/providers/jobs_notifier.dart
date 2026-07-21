import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/api_result.dart';
// Directly imported so the `GetJobCacheCollection on Isar` extension
// (generated into `lib/data/job_cache.g.dart` as a part of
// `job_cache.dart`) is in scope here — that's what makes
// `isar.jobCaches` resolve. Importing via `jobs_repository.dart`
// alone would NOT bring the extension into this file's namespace.
import '../data/job_cache.dart';
import '../data/jobs_repository.dart';
import '../models/job.dart';

// The generated file — created by
// `dart run build_runner build --delete-conflicting-outputs`. Until
// that runs, the IDE will show a red underline on `_$JobsNotifier`
// below. This is expected.
part 'jobs_notifier.g.dart';

/// Assignment 2.3, Stretch B — the reactive cache stream.
///
/// `isar.jobCaches.watchLazy()` returns a `Stream<void>` that fires
/// once per write transaction against the `jobCaches` collection. This
/// provider transforms every void emission into a fresh
/// `List<Job>` snapshot by calling `getCachedJobs()` on the repository.
///
/// The notifier uses `ref.listen(cachedJobsStreamProvider, ...)` in
/// its `build()` to reactively invalidate itself when the Isar
/// collection changes underneath it — see the `_selfWrote` guard for
/// the circular-write problem this creates and how it is prevented.
/// See README 2.3, Stretch B.
///
/// `fireImmediately` is left `false` (its default): the initial cache
/// read is done directly by `build()` (see Part 8 below), so an
/// immediate emission on subscription would race the initial read and
/// invalidate the notifier before it finished building. The stream
/// only needs to signal FUTURE writes.
final StreamProvider<List<Job>> cachedJobsStreamProvider =
    StreamProvider<List<Job>>((ref) async* {
  final repo = ref.watch(jobsRepositoryProvider);
  // Convert each void emission into a resolved snapshot.
  await for (final _ in repo.isar.jobCaches.watchLazy()) {
    yield await repo.getCachedJobs();
  }
});

/// Assignment 2.1 → 2.3 — the async source of truth for the jobs list.
///
/// Assignment 2.3 changes:
///   - `build()` is now CACHE-THEN-NETWORK (Part 8, Step 8.1). The
///     algorithm:
///       1. Read the cache via `getCachedJobs()`.
///       2. If non-empty, `state = AsyncData(cachedJobs)` — this
///          transitions `jobsProvider` from `AsyncLoading` to
///          `AsyncData` immediately, so the widget layer replaces the
///          spinner with the cached list BEFORE the network call
///          begins. This is exactly the second of the three state
///          transitions documented in README 2.3, Q4.
///       3. Call `getJobs()` (the network call).
///       4. Pattern-match on the `ApiResult`:
///          - `Success(data)` → return `data` (fresh from network).
///          - Any `Failure` → return `cachedJobs` if non-empty; else
///            throw (which surfaces as `AsyncError` on `jobsProvider`
///            and drives the error retry screen). The Failure-with-
///            cache branch is what keeps the user's view intact when
///            a background refresh fails.
///   - Return type still `Future<List<Job>>` — the widget layer's
///     `.when()` contract is unchanged.
///
/// Assignment 2.3 Stretch B additions:
///   - `ref.listen(cachedJobsStreamProvider, ...)` subscribes to
///     write events on the Isar `jobCaches` collection. When an
///     EXTERNAL write happens (a debug tool, a future write path
///     outside this notifier), the listener invalidates the notifier
///     so the UI re-derives from the fresh cache.
///   - A private `_selfWrote` guard prevents the circular-write
///     problem: this notifier writes to Isar on every successful
///     `getJobs()` (inside the repository), which fires the stream,
///     which — without a guard — would invalidate the notifier and
///     trigger another `getJobs()` on the very next microtask. See
///     README 2.3, Stretch B.
@riverpod
class JobsNotifier extends _$JobsNotifier {
  /// Stretch B — the self-write guard. Set to `true` immediately
  /// after a `Success` return from `getJobs()`, at which point we know
  /// the repository has committed a `writeTxn` and the stream is
  /// about to emit. Reset to `false` on the next listener firing —
  /// which either happens right after our own write (in which case
  /// we've just consumed the flag and the invalidate is skipped) or
  /// on an external write (in which case the flag is already `false`
  /// from the previous listener firing and the invalidate proceeds).
  bool _selfWrote = false;

  @override
  Future<List<Job>> build() async {
    // Stretch B — subscribe to the Isar watch stream. The callback
    // fires on each emission (a write completed against `jobCaches`).
    // The `_selfWrote` guard collapses echoes of writes THIS notifier
    // caused; any OUTSIDE write (a debug menu, a future feature) still
    // invalidates the notifier and drives a fresh derive.
    ref.listen<AsyncValue<List<Job>>>(cachedJobsStreamProvider, (prev, next) {
      // Only react to concrete emissions; loading/error events are
      // not writes and should not trigger invalidation.
      if (!next.hasValue) return;
      if (_selfWrote) {
        _selfWrote = false;
        return;
      }
      // An external write — re-derive the whole `jobsProvider`.
      ref.invalidateSelf();
    });

    // Part 8, Step 8.1 — cache-then-network.
    final repo = ref.read(jobsRepositoryProvider);

    // Step 1 — read the cache. Fast; no network involved.
    final cachedJobs = await repo.getCachedJobs();

    // Step 2 — if the cache is non-empty, paint immediately.
    // Assigning `state` inside `build()` is what produces the
    // "transition 2" of README 2.3, Q4: `AsyncLoading` → `AsyncData`
    // BEFORE the returned Future resolves.
    if (cachedJobs.isNotEmpty) {
      state = AsyncData(cachedJobs);
    }

    // Step 3 — call the network.
    final result = await repo.getJobs();

    // Step 4 — pattern-match and return. On any Failure, prefer the
    // cache; only throw when the cache is empty (a cold start with
    // no network and no prior successful fetch).
    return switch (result) {
      Success(:final data) => () {
          // The write has already happened inside `getJobs()` — flip
          // the guard so the incoming stream event is treated as our
          // own echo, not an external change. See README 2.3, Stretch B.
          _selfWrote = true;
          return data;
        }(),
      NetworkFailure(:final message) ||
      ServerFailure(:final message) ||
      UnknownFailure(:final message) =>
        cachedJobs.isNotEmpty ? cachedJobs : throw Exception(message),
    };
  }

  /// Stretch A (Assignment 2.1) — pull-to-refresh wiring. Unchanged.
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
