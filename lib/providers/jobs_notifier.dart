import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/jobs_repository.dart';
import '../models/job.dart';

// The generated file — created by
// `dart run build_runner build --delete-conflicting-outputs`. Until
// that runs, the IDE will show a red underline on `_$JobsNotifier`
// below. This is expected. See README, Q3.
part 'jobs_notifier.g.dart';

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
@riverpod
class JobsNotifier extends _$JobsNotifier {
  /// The generator reads the return type of this method — `Future<List<Job>>`
  /// — to determine that the emitted provider is an
  /// `AsyncNotifierProvider<JobsNotifier, List<Job>>`. Rename or retype
  /// this method and the provider's type parameters update
  /// automatically on the next `build_runner` run. See README, Q3.
  @override
  Future<List<Job>> build() async {
    // Deliberately `ref.read`, not `ref.watch`: the repository
    // provider is `keepAlive: true` and never changes for the lifetime
    // of the app, so watching it would only add a subscription for a
    // value we know is stable. A one-off `read` is honest about that.
    final repo = ref.read(jobsRepositoryProvider);
    return repo.getJobs();
  }

  /// Stretch A — pull-to-refresh wiring.
  ///
  /// `ref.invalidateSelf()` marks this notifier's cached value as
  /// stale, which fires a rebuild that calls [build] again and moves
  /// the AsyncValue into the loading state. `future` is then the
  /// pending Future the fresh `build()` returns; awaiting it keeps the
  /// RefreshIndicator's spinner on screen until data (or an error)
  /// arrives. Returning early — without awaiting — would end the
  /// indicator's animation immediately while the fetch was still in
  /// flight. See README Stretch A.
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
