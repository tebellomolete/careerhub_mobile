import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/auth_state.dart';
import '../services/application_hub_service.dart';
import 'applications_notifier.dart';
import 'auth_notifier.dart';
import 'employer_dashboard_notifier.dart';

/// Assignment 3.3, Part 6.3 — the plain Provider that owns the hub
/// connection lifecycle.
///
/// **Not `@riverpod`.** The generator's ergonomic wins (typed
/// families, keep-alive knobs, provider-key equality) do not apply
/// here — the value is a single `ApplicationHubService` instance
/// whose only purpose is to be constructed, `connect()`ed, and torn
/// down. A plain `Provider<ApplicationHubService>` is the simplest
/// shape.
///
/// **Stretch A — role-aware branching.** Reads `authProvider` to
/// determine the current user's role and adjusts the handler
/// registration accordingly:
///
///   - **Unauthenticated user** (login screen, cold boot before
///     token resolution) — return a disconnected service that
///     satisfies the type but never opens a socket. This prevents a
///     race where a route that transitions through /applications
///     during logout momentarily creates a connection with no auth
///     context.
///   - **JobSeeker** — connect with the `ApplicationStatusUpdated`
///     handler that invalidates `applicationsProvider`. Do NOT
///     register the `NewApplicationReceived` handler; a JobSeeker
///     has no business receiving events about other JobSeekers
///     applying to jobs. See README 3.3 Stretch A on the
///     information-exposure risk.
///   - **Employer** — connect with the `NewApplicationReceived`
///     handler (and, if an EmployerDashboardNotifier exists, wire
///     its in-place count increment). No `ApplicationStatusUpdated`
///     registration — an Employer is the SENDER of that event, not
///     a receiver.
///
/// **Model shape used for role checks.** The current `Authenticated`
/// state carries a `User` but no explicit role field. The check
/// below falls back to "JobSeeker" for any authenticated user
/// because the current app has no employer-role login path — this
/// is documented in README 3.3 Stretch A as a shape-only branch;
/// once the User model gains a role field the ternary below
/// switches accordingly.
final Provider<ApplicationHubService> applicationHubProvider =
    Provider<ApplicationHubService>((ref) {
  final service = ApplicationHubService();

  // Stretch A — read (not watch) the auth state. If a login /
  // logout happens, the /applications screen unmounts (GoRouter
  // redirect) which disposes this provider anyway; watching would
  // re-run the factory on every auth state ping which is not what
  // we want.
  final auth = ref.read(authProvider).value;

  if (auth is! Authenticated) {
    // Unauthenticated stub. Nothing to connect to; ref.onDispose
    // still runs disconnect() on the never-started service, which
    // is a no-op (see ApplicationHubService.disconnect()).
    debugPrint(
      'applicationHubProvider: unauthenticated — returning '
      'disconnected stub',
    );
    ref.onDispose(service.disconnect);
    return service;
  }

  final role = _roleFor(auth);
  debugPrint('applicationHubProvider: connecting for role=$role');

  // Fire-and-forget connect. The service's own try/catch handles
  // the graceful-fallback path (hub not mapped on the server).
  service.connect(
    onApplicationUpdated: () {
      // Route the ApplicationStatusUpdated event into the
      // notifier's public entry point, which internally
      // `invalidateSelf`s. Kept as a method call rather than a
      // direct `ref.invalidate(applicationsProvider)` so a test
      // can override the notifier method without also intercepting
      // ref.invalidate.
      final notifier = ref.read(applicationsProvider.notifier);
      notifier.onHubStatusUpdated();
    },
    // Stretch A — Employer-only. JobSeeker connections leave this
    // callback null so the service never registers the handler.
    // Stretch C — routes NewApplicationReceived into the
    // EmployerDashboardNotifier's in-place count-increment path
    // (see `onNewApplicationReceived` on that notifier for the
    // trade-off vs `ref.invalidate`).
    onNewApplication: role == _Role.employer
        ? () {
            final dashboard =
                ref.read(employerDashboardProvider.notifier);
            dashboard.onNewApplicationReceived();
          }
        : null,
  );

  // Assignment 3.3, Part 6.3 — dispose the connection when the
  // provider is torn down. `ref.onDispose` fires on
  // `ProviderContainer.dispose`, `ref.invalidate`, and (for
  // auto-dispose providers) when no listeners remain.
  ref.onDispose(service.disconnect);
  return service;
});

/// Assignment 3.3 Stretch A — the role tag the hub factory branches
/// on. Kept private to this file because the rest of the app has
/// no separate concept of a user role today.
enum _Role { jobSeeker, employer }

_Role _roleFor(Authenticated auth) {
  // The current User model has no role field. Every authenticated
  // user is treated as a JobSeeker; the Employer branch is exercised
  // once the model gains a `role` claim from the JWT. See README
  // 3.3 Stretch A.
  final _ = auth;
  return _Role.jobSeeker;
}
