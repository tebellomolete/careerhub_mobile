// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jobs_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Assignment 2.1 — the async source of truth for the jobs list.
///
/// Replaces the Week-1 `FutureProvider` + hardcoded list with a
/// generator-backed `AsyncNotifier`. Two capabilities motivated the
/// upgrade:
///   1. `refresh()` — an explicit method the UI can call for pull-to-refresh
///      (Stretch A) that both invalidates and awaits the next value,
///      so the RefreshIndicator's spinner stays up until the fetch
///      completes.
///   2. Testability — the generator emits `_$JobsNotifier` as an
///      abstract base class, which the widget test extends with a
///      `_FakeJobsNotifier` and swaps in via `ProviderScope.overrideWith`
///      (see test/widget_test.dart and README, Q4).
///
/// The class does exactly ONE thing: read the repository and return
/// what it returns. No filtering, no sorting, no search — those
/// concerns live in the derived providers in `job_providers.dart` so
/// that this notifier stays focused on "the current server truth."

@ProviderFor(JobsNotifier)
const jobsProvider = JobsNotifierProvider._();

/// Assignment 2.1 — the async source of truth for the jobs list.
///
/// Replaces the Week-1 `FutureProvider` + hardcoded list with a
/// generator-backed `AsyncNotifier`. Two capabilities motivated the
/// upgrade:
///   1. `refresh()` — an explicit method the UI can call for pull-to-refresh
///      (Stretch A) that both invalidates and awaits the next value,
///      so the RefreshIndicator's spinner stays up until the fetch
///      completes.
///   2. Testability — the generator emits `_$JobsNotifier` as an
///      abstract base class, which the widget test extends with a
///      `_FakeJobsNotifier` and swaps in via `ProviderScope.overrideWith`
///      (see test/widget_test.dart and README, Q4).
///
/// The class does exactly ONE thing: read the repository and return
/// what it returns. No filtering, no sorting, no search — those
/// concerns live in the derived providers in `job_providers.dart` so
/// that this notifier stays focused on "the current server truth."
final class JobsNotifierProvider
    extends $AsyncNotifierProvider<JobsNotifier, List<Job>> {
  /// Assignment 2.1 — the async source of truth for the jobs list.
  ///
  /// Replaces the Week-1 `FutureProvider` + hardcoded list with a
  /// generator-backed `AsyncNotifier`. Two capabilities motivated the
  /// upgrade:
  ///   1. `refresh()` — an explicit method the UI can call for pull-to-refresh
  ///      (Stretch A) that both invalidates and awaits the next value,
  ///      so the RefreshIndicator's spinner stays up until the fetch
  ///      completes.
  ///   2. Testability — the generator emits `_$JobsNotifier` as an
  ///      abstract base class, which the widget test extends with a
  ///      `_FakeJobsNotifier` and swaps in via `ProviderScope.overrideWith`
  ///      (see test/widget_test.dart and README, Q4).
  ///
  /// The class does exactly ONE thing: read the repository and return
  /// what it returns. No filtering, no sorting, no search — those
  /// concerns live in the derived providers in `job_providers.dart` so
  /// that this notifier stays focused on "the current server truth."
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

String _$jobsNotifierHash() => r'91362491d41e162c2aae37530c048a8d68b8fda1';

/// Assignment 2.1 — the async source of truth for the jobs list.
///
/// Replaces the Week-1 `FutureProvider` + hardcoded list with a
/// generator-backed `AsyncNotifier`. Two capabilities motivated the
/// upgrade:
///   1. `refresh()` — an explicit method the UI can call for pull-to-refresh
///      (Stretch A) that both invalidates and awaits the next value,
///      so the RefreshIndicator's spinner stays up until the fetch
///      completes.
///   2. Testability — the generator emits `_$JobsNotifier` as an
///      abstract base class, which the widget test extends with a
///      `_FakeJobsNotifier` and swaps in via `ProviderScope.overrideWith`
///      (see test/widget_test.dart and README, Q4).
///
/// The class does exactly ONE thing: read the repository and return
/// what it returns. No filtering, no sorting, no search — those
/// concerns live in the derived providers in `job_providers.dart` so
/// that this notifier stays focused on "the current server truth."

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
