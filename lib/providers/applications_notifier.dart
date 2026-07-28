import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/api_result.dart';
import '../data/applications_repository.dart';
import '../data/auth_repository.dart';
import '../models/application.dart';

// Assignment 3.3 scaffolding — the code-generator part directive.
part 'applications_notifier.g.dart';

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
@Riverpod(keepAlive: true)
class ApplicationsNotifier extends _$ApplicationsNotifier {
  @override
  Future<List<Application>> build() async {
    // Capture BEFORE any await — the Part 5 checkpoint requires
    // this even when the current build has only one await; the
    // pattern is uniform across every notifier that talks to an
    // authenticated endpoint so a future refactor that adds a
    // second await doesn't accidentally re-read a stale ref.
    final repo = ref.read(applicationsRepositoryProvider);
    final authRepo = ref.read(authRepositoryProvider);

    final result = await repo.getApplications();

    // Part 5 — the 401 arm. Handled before the value-return switch
    // so the `await authRepo.logout()` sits cleanly in the outer
    // async body (an async closure inside a switch arm makes the
    // future observation semantics harder to reason about).
    if (result case ServerFailure(:final statusCode) when statusCode == 401) {
      await authRepo.logout();
      throw Exception('Your session has expired. Please sign in again.');
    }

    return switch (result) {
      Success(:final data) => data,
      // The GET endpoint is aspirational against today's backend
      // (see README 3.3 backend audit) — a NetworkFailure or a
      // 404 is the expected state until the endpoint ships.
      // Rendering an empty list keeps the screen usable and lets
      // the hub-connection log surface in the terminal, which is
      // what Part 6.5's verification depends on. Any OTHER failure
      // (a 500, a genuine 503) rethrows so the user sees a real
      // error rather than a silently empty screen.
      NetworkFailure() => const <Application>[],
      ServerFailure(:final statusCode) when statusCode == 404 =>
        const <Application>[],
      ServerFailure(:final message) => throw Exception(message),
      UnknownFailure(:final message) => throw Exception(message),
    };
  }

  /// Called by `ApplyScreen.submit` on the online path. Posts the
  /// application, and — on Success — invalidates this notifier so
  /// the newly-created row appears on the /applications screen next
  /// time it renders. Returns the ApiResult so the screen can render
  /// the exact user-facing message (409 duplicate, 422 closed
  /// listing) as a SnackBar rather than a generic error banner.
  Future<ApiResult<void>> submit(
    String jobId,
    Map<String, dynamic> payload,
  ) async {
    final repo = ref.read(applicationsRepositoryProvider);
    final authRepo = ref.read(authRepositoryProvider);

    final result = await repo.submitApplication(jobId, payload);

    // Part 5 pattern — 401 automatic logout. On any other
    // failure, hand the ApiResult back to the caller so the
    // SnackBar text matches the mapped user-facing message
    // (409's exact string, 422's exact string).
    if (result case ServerFailure(:final statusCode) when statusCode == 401) {
      await authRepo.logout();
      throw Exception('Your session has expired. Please sign in again.');
    }

    if (result is Success<void>) {
      // Force `/applications` to refetch on next mount so the new
      // row is visible. `invalidateSelf` is safe here because
      // this method is called from the widget layer (ApplyScreen)
      // not from inside `build()`.
      ref.invalidateSelf();
    }

    return result;
  }

  /// Called by the SignalR `ApplicationStatusUpdated` handler in
  /// `application_hub_service.dart` via the callback wired inside
  /// `application_hub_provider.dart`. `invalidateSelf` triggers a
  /// server refetch so the JobSeeker's status list reconciles with
  /// authoritative state after every push — see README 3.3 Q3's
  /// offline-tunnel scenario for why in-place mutation would drift.
  void onHubStatusUpdated() {
    ref.invalidateSelf();
  }
}

