// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'employer_dashboard_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(EmployerDashboardNotifier)
const employerDashboardProvider = EmployerDashboardNotifierProvider._();

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
final class EmployerDashboardNotifierProvider
    extends
        $AsyncNotifierProvider<
          EmployerDashboardNotifier,
          EmployerDashboardState
        > {
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
  const EmployerDashboardNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'employerDashboardProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$employerDashboardNotifierHash();

  @$internal
  @override
  EmployerDashboardNotifier create() => EmployerDashboardNotifier();
}

String _$employerDashboardNotifierHash() =>
    r'e514b88c78d7fcf18be72c1a54641303b5133047';

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

abstract class _$EmployerDashboardNotifier
    extends $AsyncNotifier<EmployerDashboardState> {
  FutureOr<EmployerDashboardState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref
            as $Ref<AsyncValue<EmployerDashboardState>, EmployerDashboardState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<EmployerDashboardState>,
                EmployerDashboardState
              >,
              AsyncValue<EmployerDashboardState>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
