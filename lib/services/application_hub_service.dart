import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';

import '../config/app_config.dart';

/// Assignment 3.3, Part 6.2 — the SignalR client that connects to the
/// CareerHub API's applications hub.
///
/// **Handler registration order.** `connect()` follows the exact
/// sequence Part 6.2 mandates:
///   1. Construct `HubConnection` via `HubConnectionBuilder()
///      .withUrl(...)` and `.withAutomaticReconnect()`.
///   2. Register the `ApplicationStatusUpdated` handler via
///      `hubConnection.on(...)` — MUST happen before `start()` so
///      any event that fires during the initial connection handshake
///      is not missed.
///   3. Register `onclose` and `onreconnecting` for debug-console
///      lifecycle prints.
///   4. Call `start()` inside a `try/catch(Exception)`. The catch
///      prints the error and a "real-time updates are unavailable"
///      fallback message and DOES NOT re-throw — a missing hub on
///      the server side is the expected graceful-degradation path
///      (see README 3.3 backend audit: the API does not currently
///      map a hub at `/hubs/applications`).
///
/// **Why not re-throw.** The `applicationHubProvider` factory calls
/// `connect()` fire-and-forget. Re-throwing here would surface an
/// unhandled Future to the zone (`runZonedGuarded` from Part 7) on
/// every provider construction — the graceful path is to log and
/// continue, so the /applications screen keeps working via
/// pull-to-refresh while the hub is unavailable.
///
/// **Stretch A hook.** The optional `onNewApplication` callback is
/// registered against the `NewApplicationReceived` event when
/// non-null. `applicationHubProvider` passes it only for Employer
/// role users (Stretch A); a JobSeeker's provider construction leaves
/// it null and the handler never registers.
class ApplicationHubService {
  HubConnection? _hubConnection;

  /// Assignment 3.3, Part 6.2 — the single public connect method.
  /// Accepts an `onApplicationUpdated` callback that is fired once
  /// per `ApplicationStatusUpdated` push. Returns a `Future<void>`
  /// that completes when the connection reaches the connected state
  /// OR when `start()` throws (graceful fallback). The caller
  /// (`applicationHubProvider`) does not await the future — the side-
  /// effect of the subscription is the whole point; the return value
  /// exists so a test seam or a Stretch-B future test can await it.
  Future<void> connect({
    required VoidCallback onApplicationUpdated,
    VoidCallback? onNewApplication,
  }) async {
    final url = '${AppConfig.apiBaseUrl}/hubs/applications';

    // Step 1 — construct the hub connection. `withAutomaticReconnect()`
    // enables the retry state machine documented in README 3.3 Q3's
    // offline-tunnel scenario.
    _hubConnection = HubConnectionBuilder()
        .withUrl(url)
        .withAutomaticReconnect()
        .build();

    // Step 2 — register the ApplicationStatusUpdated handler BEFORE
    // start(). The handler ignores the arguments — the callback's
    // job is to invalidate `applicationsProvider`, which triggers a
    // full refetch from the server. See README 3.3 Q3's fourth
    // paragraph on why invalidate-driven refetch beats in-place
    // client-side mutation (avoids drift when events are missed
    // during a connectivity outage).
    _hubConnection!.on('ApplicationStatusUpdated', (arguments) {
      debugPrint(
        'ApplicationHubService: ApplicationStatusUpdated received '
        '(args=$arguments)',
      );
      onApplicationUpdated();
    });

    // Stretch A hook — Employer-role hub connections register a
    // second handler for the NewApplicationReceived event. Left
    // unregistered for JobSeekers (onNewApplication is null on
    // their provider construction).
    if (onNewApplication != null) {
      _hubConnection!.on('NewApplicationReceived', (arguments) {
        debugPrint(
          'ApplicationHubService: NewApplicationReceived received '
          '(args=$arguments)',
        );
        onNewApplication();
      });
    }

    // Step 3 — lifecycle callbacks for the debug console. These
    // fire from within the signalr_netcore reconnect state machine
    // during the offline-tunnel scenario (README 3.3 Q3).
    _hubConnection!.onclose(({error}) {
      debugPrint('ApplicationHubService: connection closed (error=$error)');
    });
    _hubConnection!.onreconnecting(({error}) {
      debugPrint('ApplicationHubService: reconnecting (error=$error)');
    });

    // Step 4 — start the connection. Wrapped in try/catch because
    // the API side of Assignment 3.3 does not currently map a hub
    // at /hubs/applications (see README 3.3 backend audit); a
    // connection attempt against a URL with no hub throws, and the
    // graceful fallback per the brief is to print + carry on.
    try {
      await _hubConnection!.start();
      debugPrint('ApplicationHubService: connected to $url');
    } on Exception catch (e) {
      debugPrint('ApplicationHubService: connection failed ($e)');
      debugPrint(
        'ApplicationHubService: real-time updates are unavailable — '
        'the /applications screen will show static data and rely on '
        'pull-to-refresh.',
      );
      // Deliberately: no re-throw.
    }
  }

  /// Assignment 3.3, Part 6.2 — the disconnect method. Called from
  /// `applicationHubProvider`'s `ref.onDispose` so a hub connection
  /// does not outlive the /applications screen (or the
  /// ProviderScope that hosts it).
  Future<void> disconnect() async {
    final connection = _hubConnection;
    if (connection == null) return;
    try {
      await connection.stop();
    } finally {
      _hubConnection = null;
    }
  }
}
