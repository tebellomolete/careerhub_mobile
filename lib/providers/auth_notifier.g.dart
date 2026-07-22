// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(AuthNotifier)
const authProvider = AuthNotifierProvider._();

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
final class AuthNotifierProvider
    extends $AsyncNotifierProvider<AuthNotifier, AuthState> {
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
  const AuthNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authNotifierHash();

  @$internal
  @override
  AuthNotifier create() => AuthNotifier();
}

String _$authNotifierHash() => r'1cd4c2392d677e273c76cdb695fc8de7ad4bf611';

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

abstract class _$AuthNotifier extends $AsyncNotifier<AuthState> {
  FutureOr<AuthState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<AuthState>, AuthState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AuthState>, AuthState>,
              AsyncValue<AuthState>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
