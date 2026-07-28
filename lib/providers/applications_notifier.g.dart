// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'applications_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Assignment 3.3 scaffolding — the notifier that backs the
/// `/applications` screen.
///
/// **Part 5 pattern (Auth 401 automatic logout).**
/// Every method that calls an authenticated endpoint follows the
/// same shape:
///   1. Capture `ref.read(applicationsRepositoryProvider)` and
///      `ref.read(authRepositoryProvider)` into locals BEFORE the
///      first `await`.
///   2. Pattern-match the returned `ApiResult`. On a
///      `ServerFailure(:final statusCode) when statusCode == 401`,
///      call `authRepo.logout()` and then `throw` an
///      Exception so the widget's AsyncError state briefly flashes
///      before the router redirect fires. See README 3.3 Part 5 on
///      why the throw is necessary (the GoRouter refresh fires from
///      the `authProvider` change; without the throw the widget
///      would rebuild against stale data during the transition).
///
/// **Deviation from the brief's exact pattern.** The brief writes
/// `if (result case Failure(statusCode: 401))` against a single
/// `Failure` variant. This codebase's sealed `ApiResult` uses three
/// concrete failure variants (`NetworkFailure`, `ServerFailure`,
/// `UnknownFailure`) from Assignment 2.2 Stretch C, so the pattern
/// is `case ServerFailure(:final statusCode) when statusCode == 401`
/// against the extant hierarchy. Same semantics, correct syntax.

@ProviderFor(ApplicationsNotifier)
const applicationsProvider = ApplicationsNotifierProvider._();

/// Assignment 3.3 scaffolding — the notifier that backs the
/// `/applications` screen.
///
/// **Part 5 pattern (Auth 401 automatic logout).**
/// Every method that calls an authenticated endpoint follows the
/// same shape:
///   1. Capture `ref.read(applicationsRepositoryProvider)` and
///      `ref.read(authRepositoryProvider)` into locals BEFORE the
///      first `await`.
///   2. Pattern-match the returned `ApiResult`. On a
///      `ServerFailure(:final statusCode) when statusCode == 401`,
///      call `authRepo.logout()` and then `throw` an
///      Exception so the widget's AsyncError state briefly flashes
///      before the router redirect fires. See README 3.3 Part 5 on
///      why the throw is necessary (the GoRouter refresh fires from
///      the `authProvider` change; without the throw the widget
///      would rebuild against stale data during the transition).
///
/// **Deviation from the brief's exact pattern.** The brief writes
/// `if (result case Failure(statusCode: 401))` against a single
/// `Failure` variant. This codebase's sealed `ApiResult` uses three
/// concrete failure variants (`NetworkFailure`, `ServerFailure`,
/// `UnknownFailure`) from Assignment 2.2 Stretch C, so the pattern
/// is `case ServerFailure(:final statusCode) when statusCode == 401`
/// against the extant hierarchy. Same semantics, correct syntax.
final class ApplicationsNotifierProvider
    extends $AsyncNotifierProvider<ApplicationsNotifier, List<Application>> {
  /// Assignment 3.3 scaffolding — the notifier that backs the
  /// `/applications` screen.
  ///
  /// **Part 5 pattern (Auth 401 automatic logout).**
  /// Every method that calls an authenticated endpoint follows the
  /// same shape:
  ///   1. Capture `ref.read(applicationsRepositoryProvider)` and
  ///      `ref.read(authRepositoryProvider)` into locals BEFORE the
  ///      first `await`.
  ///   2. Pattern-match the returned `ApiResult`. On a
  ///      `ServerFailure(:final statusCode) when statusCode == 401`,
  ///      call `authRepo.logout()` and then `throw` an
  ///      Exception so the widget's AsyncError state briefly flashes
  ///      before the router redirect fires. See README 3.3 Part 5 on
  ///      why the throw is necessary (the GoRouter refresh fires from
  ///      the `authProvider` change; without the throw the widget
  ///      would rebuild against stale data during the transition).
  ///
  /// **Deviation from the brief's exact pattern.** The brief writes
  /// `if (result case Failure(statusCode: 401))` against a single
  /// `Failure` variant. This codebase's sealed `ApiResult` uses three
  /// concrete failure variants (`NetworkFailure`, `ServerFailure`,
  /// `UnknownFailure`) from Assignment 2.2 Stretch C, so the pattern
  /// is `case ServerFailure(:final statusCode) when statusCode == 401`
  /// against the extant hierarchy. Same semantics, correct syntax.
  const ApplicationsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'applicationsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$applicationsNotifierHash();

  @$internal
  @override
  ApplicationsNotifier create() => ApplicationsNotifier();
}

String _$applicationsNotifierHash() =>
    r'3cc45f53b3c685844eb4fa39335684d4ffdb7e88';

/// Assignment 3.3 scaffolding — the notifier that backs the
/// `/applications` screen.
///
/// **Part 5 pattern (Auth 401 automatic logout).**
/// Every method that calls an authenticated endpoint follows the
/// same shape:
///   1. Capture `ref.read(applicationsRepositoryProvider)` and
///      `ref.read(authRepositoryProvider)` into locals BEFORE the
///      first `await`.
///   2. Pattern-match the returned `ApiResult`. On a
///      `ServerFailure(:final statusCode) when statusCode == 401`,
///      call `authRepo.logout()` and then `throw` an
///      Exception so the widget's AsyncError state briefly flashes
///      before the router redirect fires. See README 3.3 Part 5 on
///      why the throw is necessary (the GoRouter refresh fires from
///      the `authProvider` change; without the throw the widget
///      would rebuild against stale data during the transition).
///
/// **Deviation from the brief's exact pattern.** The brief writes
/// `if (result case Failure(statusCode: 401))` against a single
/// `Failure` variant. This codebase's sealed `ApiResult` uses three
/// concrete failure variants (`NetworkFailure`, `ServerFailure`,
/// `UnknownFailure`) from Assignment 2.2 Stretch C, so the pattern
/// is `case ServerFailure(:final statusCode) when statusCode == 401`
/// against the extant hierarchy. Same semantics, correct syntax.

abstract class _$ApplicationsNotifier
    extends $AsyncNotifier<List<Application>> {
  FutureOr<List<Application>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<AsyncValue<List<Application>>, List<Application>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Application>>, List<Application>>,
              AsyncValue<List<Application>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
