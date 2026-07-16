import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/api_result.dart';
import '../data/jobs_repository.dart';
import '../models/job.dart';

// The generated file — created by
// `dart run build_runner build --delete-conflicting-outputs`. Until
// that runs, the IDE will show a red underline on `_$JobsNotifier`
// below. This is expected.
part 'jobs_notifier.g.dart';

/// Assignment 2.1 → 2.2 — the async source of truth for the jobs list.
///
/// Assignment 2.2 change: `build()` still returns `Future<List<Job>>`,
/// but it now receives an `ApiResult<List<Job>>` from the repository
/// and pattern-matches on it with an EXHAUSTIVE SWITCH EXPRESSION.
/// The compiler refuses to compile the switch if any variant of the
/// sealed hierarchy (`Success`, `NetworkFailure`, `ServerFailure`,
/// `UnknownFailure`) is unhandled — that is the compile-time guarantee
/// the sealed keyword gives us. See README 2.2, Q4.
///
/// The public contract to the widget layer is UNCHANGED: on failure
/// the switch's `throw Exception(...)` surfaces as an
/// `AsyncValue.error` on `jobsProvider`, exactly as before. The widget
/// tree's existing `AsyncValue.when(error: ...)` handler already
/// renders that state — no widget-layer change is needed. That is
/// exactly why the widget test in `test/widget_test.dart` still passes
/// unchanged. See README 2.2, Part 9.
@riverpod
class JobsNotifier extends _$JobsNotifier {
  @override
  Future<List<Job>> build() async {
    // Deliberately `ref.read`, not `ref.watch`: the repository provider
    // is `keepAlive: true` and never changes for the lifetime of the
    // app.
    final repo = ref.read(jobsRepositoryProvider);
    final result = await repo.getJobs();

    // Part 8, Step 8.3 — the exhaustive switch expression. Because
    // `ApiResult` is sealed and its four subclasses live in the same
    // library file, the compiler knows the ENTIRE variant set at check
    // time. Adding a fifth variant to `api_result.dart` without adding
    // an arm here is a COMPILE ERROR, not a lurking runtime bug.
    return switch (result) {
      Success(:final data) => data,
      NetworkFailure(:final message) => throw Exception(message),
      ServerFailure(:final message) => throw Exception(message),
      UnknownFailure(:final message) => throw Exception(message),
    };
  }

  /// Stretch A (Assignment 2.1) — pull-to-refresh wiring.
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
