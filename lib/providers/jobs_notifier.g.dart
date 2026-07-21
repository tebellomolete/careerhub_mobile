// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jobs_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(JobsNotifier)
const jobsProvider = JobsNotifierProvider._();

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
final class JobsNotifierProvider
    extends $AsyncNotifierProvider<JobsNotifier, List<Job>> {
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
  const JobsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'jobsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$jobsNotifierHash();

  @$internal
  @override
  JobsNotifier create() => JobsNotifier();
}

String _$jobsNotifierHash() => r'c6be4533785e5ec89431717437f99b704b93ce47';

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

abstract class _$JobsNotifier extends $AsyncNotifier<List<Job>> {
  FutureOr<List<Job>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<List<Job>>, List<Job>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Job>>, List<Job>>,
              AsyncValue<List<Job>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
