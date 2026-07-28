import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/employer_dashboard_state.dart';

part 'employer_dashboard_notifier.g.dart';

/// Assignment 3.3, Stretch C — the Employer dashboard AsyncNotifier.
///
/// **Shape-only against today's app.** No `/dashboard` route exists,
/// no Employer login path exists, and no Employer dashboard endpoint
/// exists on the backend (see README 3.3 backend audit). This
/// notifier ships to satisfy Stretch C's "implement the in-place
/// mutation pattern" requirement — the moment the surrounding pieces
/// land, this file is what wires the hub-driven count increment.
///
/// **In-place mutation vs `ref.invalidate` — the trade-off.** A
/// `ref.invalidate(employerDashboardProvider)` on every
/// `NewApplicationReceived` event would re-fetch the counts from
/// the server, which is always accurate but incurs a network round-
/// trip per event. On a busy hiring day (imagine a batch of a
/// hundred applications arriving in a two-minute window) that is a
/// hundred `GET /dashboard` calls, each of which the server has to
/// re-compute the aggregate for. In-place mutation — read the
/// current AsyncData, produce a new AsyncData with
/// `totalApplications + 1`, publish it — is a single-CPU-instruction
/// counter increment with no network cost.
///
/// **Where in-place mutation goes wrong (README requirement).**
/// The client's count drifts from the server's whenever:
///   1. An event is missed (the offline-tunnel scenario from
///      README 3.3 Q3 — the tunnel exhausts the reconnect retries,
///      so events during the outage never arrive at the client).
///   2. A concurrent Employer-role user in another session (a
///      colleague on the same account, an admin panel) accepts or
///      rejects applications, changing the counts without the hub
///      firing this session's handler.
///   3. The server rejects a duplicate submission the hub is
///      unaware of.
///
/// **Reconciliation strategy.** Two mechanisms:
///   - **Periodic reconciliation:** every 60 seconds (or on
///     app-resume), re-fetch the true count from
///     `GET /dashboard/counts` and compare against the local
///     value. If they differ, replace state with the server value
///     and log the delta for observability.
///   - **Reconnect reconciliation:** on the SignalR
///     `onreconnected` callback (fired after the client re-enters
///     the connected state following an outage), invalidate the
///     provider once so a fresh fetch captures whatever the client
///     missed during the disconnect window.
///
/// Both mechanisms are documented but NOT wired in this file — the
/// hub-provider integration and the 60s timer would be a separate
/// unit-testable piece; see README 3.3 Stretch C for the full
/// analysis.
@Riverpod(keepAlive: true)
class EmployerDashboardNotifier extends _$EmployerDashboardNotifier {
  @override
  Future<EmployerDashboardState> build() async {
    // Shape-only: no backend endpoint to call, so return the
    // empty state as the "loaded" value. When the backend ships a
    // `GET /dashboard/counts` endpoint, this becomes an
    // `await employerRepository.getDashboardCounts()` call with
    // the same Part 5 pattern (capture ref.reads before await,
    // check for 401, etc.) the applications notifier uses.
    return const EmployerDashboardState.empty();
  }

  /// Stretch C — the entry point the hub's
  /// `NewApplicationReceived` handler calls. Implements the
  /// in-place count increment pattern:
  ///
  ///   1. Read the current AsyncData (skip if the notifier is
  ///      still loading or in error — those transient states
  ///      don't have a count to increment).
  ///   2. Produce a new AsyncData with `totalApplications + 1`.
  ///   3. Assign to `state` — a `ref.invalidateSelf` would
  ///      trigger a full re-fetch which defeats the whole
  ///      point (see the trade-off discussion in the class
  ///      docstring).
  void onNewApplicationReceived() {
    // Only mutate if the notifier has a resolved AsyncData; a
    // loading or error state has no count to increment.
    final currentState = state;
    if (currentState is! AsyncData<EmployerDashboardState>) return;
    final current = currentState.value;
    state = AsyncData(
      current.copyWith(
        totalApplications: current.totalApplications + 1,
      ),
    );
  }

  /// Stretch C — the drift-detection escape hatch. Called by the
  /// SignalR `onreconnected` callback (when wired) OR by a
  /// periodic timer (when wired) so a client that missed events
  /// during an outage recovers the true count on the next
  /// server round-trip.
  void reconcileFromServer() {
    ref.invalidateSelf();
  }
}
