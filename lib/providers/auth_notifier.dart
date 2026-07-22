import 'dart:async';
import 'dart:convert';

import 'package:local_auth/local_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/api_result.dart';
import '../data/auth_repository.dart';
import '../models/auth_state.dart';
import '../models/user.dart';

// Assignment 2.4, Part 5 — the code-generator part directive.
part 'auth_notifier.g.dart';

/// Assignment 2.4, Part 5 — the state machine that drives the
/// authentication flow.
///
/// `AuthNotifier extends AsyncNotifier<AuthState>` gives us two
/// dimensions of state at once (see README 2.4, Q2):
///   - the outer `AsyncValue` says whether the notifier itself has
///     finished its `build()`,
///   - the inner sealed `AuthState` says what the resolved value
///     represents (`Unauthenticated` / `Authenticating` /
///     `Authenticated` / `AuthError`).
///
/// Stretch A additions:
///   - When `build()` returns `Authenticated`, a `Timer` is
///     scheduled to fire 60 seconds before the access token's
///     `exp` claim. On fire, `tryRefresh()` runs silently; success
///     leaves the state as `Authenticated` (same `User`, new
///     tokens in storage), failure transitions to
///     `Unauthenticated` and clears storage.
///   - The timer is cancelled in `ref.onDispose` — a
///     logout-triggered rebuild wouldn't otherwise cancel a
///     previously-scheduled timer.
///
/// Stretch B additions:
///   - Before returning `Authenticated`, `build()` calls
///     `LocalAuthentication.authenticate()` if the device has
///     enrolled biometrics. A dismissed prompt clears storage and
///     returns `Unauthenticated`. A device without biometrics
///     skips the gate (we choose "usable" over "strictly gated" —
///     the alternative would lock the app on any device without a
///     configured fingerprint/face).
@riverpod
class AuthNotifier extends _$AuthNotifier {
  /// Stretch A — the scheduled refresh timer. Nullable because
  /// no timer exists in the `Unauthenticated` / `Authenticating`
  /// / `AuthError` states. Only set when `build()` returns
  /// `Authenticated`.
  Timer? _expiryTimer;

  /// Stretch B — a test seam. Overridden in the widget test's
  /// `_FakeAuthNotifier` to `false` so the biometric prompt is
  /// bypassed. Not a public API of the class — the fake sets
  /// this before `build()` runs.
  bool skipBiometricGate = false;

  @override
  Future<AuthState> build() async {
    // Stretch A — ensure any previous timer is cancelled when
    // `build()` re-runs (which happens on `ref.invalidate` from
    // the interceptor's onUnauthenticated callback).
    ref.onDispose(() {
      _expiryTimer?.cancel();
      _expiryTimer = null;
    });

    // Part 5 — `ref.read` (NOT `ref.watch`) because we don't
    // want `build()` to re-run when the repository's identity
    // (which never changes in this app) hypothetically flips.
    // Using `watch` would tie the entire auth state machine to
    // an unrelated provider's rebuild schedule.
    final repo = ref.read(authRepositoryProvider);

    // 1) Read the access token from secure storage.
    final token = await repo.readAccessToken();
    if (token == null) {
      return const Unauthenticated();
    }

    // 2) If expired, try refresh once. A failed refresh already
    //    clears secure storage inside the repository, so no
    //    additional wipe is needed here.
    if (repo.isTokenExpired(token)) {
      final refreshed = await repo.tryRefresh();
      if (refreshed == null) {
        return const Unauthenticated();
      }
      final gated = await _gateAndSchedule(repo, refreshed);
      return gated;
    }

    // 3) Token exists and hasn't expired — decode the User.
    final user = repo.decodeUser(token);
    final gated = await _gateAndSchedule(repo, user);
    return gated;
  }

  /// Stretch B + A — biometric gate at cold boot, then schedule
  /// the expiry timer. Broken out because both the fresh-token
  /// and refreshed-token paths use it. Returns the resolved
  /// `AuthState` — either `Authenticated(user: ...)` on pass, or
  /// `Unauthenticated()` on gate failure.
  Future<AuthState> _gateAndSchedule(AuthRepository repo, User user) async {
    if (!skipBiometricGate) {
      final passed = await _biometricGate();
      if (!passed) {
        await repo.logout();
        return const Unauthenticated();
      }
    }
    _scheduleExpiryTimer(repo);
    return Authenticated(user: user);
  }

  Future<bool> _biometricGate() async {
    try {
      final auth = LocalAuthentication();
      final canCheck = await auth.canCheckBiometrics;
      final supported = await auth.isDeviceSupported();
      if (!canCheck || !supported) {
        // Device has no biometrics enrolled or doesn't support
        // them — skip the gate. See docstring: "usable" > "gated".
        return true;
      }
      final available = await auth.getAvailableBiometrics();
      if (available.isEmpty) {
        return true;
      }
      return await auth.authenticate(
        localizedReason: 'Sign in to CareerHub',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      // Any platform exception (no hardware, plugin missing) —
      // skip the gate rather than lock the app.
      return true;
    }
  }

  /// Stretch A — schedule the silent refresh timer 60 seconds
  /// before the access token expires. Cancels any previously
  /// scheduled timer first so the notifier never accumulates
  /// stale timers.
  void _scheduleExpiryTimer(AuthRepository repo) {
    _expiryTimer?.cancel();
    // Fire-and-forget: reading storage + decoding + scheduling
    // are all asynchronous but non-blocking for `build()`.
    unawaited(() async {
      final token = await repo.readAccessToken();
      if (token == null) return;
      try {
        final delay = _timeUntilRefresh(token);
        if (delay.inMilliseconds <= 0) {
          // Already inside the 60-second window — refresh now.
          await _silentRefresh(repo);
          return;
        }
        _expiryTimer = Timer(delay, () async {
          await _silentRefresh(repo);
        });
      } catch (_) {
        // Malformed token — the interceptor will handle the
        // eventual 401.
      }
    }());
  }

  /// Compute the delay until we should proactively refresh. The
  /// window is `exp - now - 60s`; if that's already negative we
  /// return `Duration.zero` so the caller refreshes immediately.
  Duration _timeUntilRefresh(String token) {
    final parts = token.split('.');
    if (parts.length != 3) throw const FormatException('Malformed JWT');
    final segment = parts[1];
    // Same Base64URL padding formula the repository uses — see
    // README 2.4 Part 4 checkpoint on the `(4 - length % 4) % 4`
    // spec point.
    final padded = segment + ('=' * ((4 - segment.length % 4) % 4));
    final decoded = utf8.decode(base64Url.decode(padded));
    final payload = jsonDecode(decoded);
    if (payload is! Map<String, dynamic>) {
      throw const FormatException('JWT payload is not a JSON object');
    }
    final exp = payload['exp'];
    if (exp is! int) throw const FormatException('No exp claim');
    final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
    final untilExpiry = expiry.difference(DateTime.now().toUtc());
    final refreshAt = untilExpiry - const Duration(seconds: 60);
    return refreshAt.isNegative ? Duration.zero : refreshAt;
  }

  Future<void> _silentRefresh(AuthRepository repo) async {
    final refreshed = await repo.tryRefresh();
    if (refreshed == null) {
      state = const AsyncData(Unauthenticated());
      return;
    }
    state = AsyncData(Authenticated(user: refreshed));
    // Chain another timer — the fresh token has a fresh `exp`.
    _scheduleExpiryTimer(repo);
  }

  /// Part 5.2 — the login mutator. `Authenticating` MUST be set
  /// **before** any await so the router sees the transition
  /// immediately (see README 2.4, Q2's second bullet).
  Future<void> login(String email, String password) async {
    state = const AsyncData(Authenticating());
    final repo = ref.read(authRepositoryProvider);
    final result = await repo.login(email, password);
    switch (result) {
      case Success(:final data):
        state = AsyncData(Authenticated(user: data));
        _scheduleExpiryTimer(repo);
      case NetworkFailure(:final message):
        state = AsyncData(AuthError(message));
      case ServerFailure(:final message):
        state = AsyncData(AuthError(message));
      case UnknownFailure(:final message):
        state = AsyncData(AuthError(message));
    }
  }

  /// Part 5 — logout. Deliberately does NOT invalidate any data
  /// notifier (the caller — the logout button — does that first,
  /// see README 2.4, Q4 on the ordering and the circular-import
  /// problem this decision avoids).
  Future<void> logout() async {
    _expiryTimer?.cancel();
    _expiryTimer = null;
    final repo = ref.read(authRepositoryProvider);
    await repo.logout();
    state = const AsyncData(Unauthenticated());
  }
}
