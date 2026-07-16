// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jobs_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(JobsNotifier)
const jobsProvider = JobsNotifierProvider._();

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
final class JobsNotifierProvider
    extends $AsyncNotifierProvider<JobsNotifier, List<Job>> {
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

String _$jobsNotifierHash() => r'cc01992b4d58cce1b26d2173aa853c247cbde774';

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
