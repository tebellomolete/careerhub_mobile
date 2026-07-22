import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_notifier.dart';

// Assignment 2.4, Part 6 — the indirection layer between the
// data layer (which must not import Riverpod) and the auth
// notifier (which lives in `providers/`).
//
// This file has NO `@riverpod` annotation and NO `part`
// directive by deliberate design — every symbol is a plain
// Provider. See README 2.4, Q4 (circular-import chain analysis).

/// Assignment 2.4, Part 6.1 — the callback the AuthInterceptor
/// invokes when a refresh fails and the session has definitively
/// ended.
///
/// The value is a `void Function()` — a closure that captures
/// `ref` and, when invoked, calls
/// `ref.invalidate(authProvider)`. This is what makes
/// the notifier re-run its `build()` (which finds empty storage
/// and returns `Unauthenticated`), which fires the
/// `AuthStateListenable` (see 6.2 below), which drives GoRouter
/// to redirect the user to `/login`.
///
/// **Why a plain Provider (not `@riverpod`)**: the value is a
/// closure literal — there is no signature the generator can
/// improve on, and the family/keepAlive knobs `@riverpod`
/// exposes are irrelevant here.
final Provider<void Function()> onUnauthenticatedProvider =
    Provider<void Function()>((ref) {
  return () {
    ref.invalidate(authProvider);
  };
});

/// Assignment 2.4, Part 6.2 — the `ChangeNotifier` bridge that
/// GoRouter's `refreshListenable` requires.
///
/// GoRouter re-runs its redirect callback every time a
/// `Listenable` fires. This class translates every state change
/// on `authProvider` into a `notifyListeners()` call, so
/// a login / logout / cold-boot resolution automatically drives
/// the router's redirect without any manual `context.go(...)`
/// calls.
///
/// **Disposal contract:** the constructor stores the
/// `ProviderSubscription` returned by `ref.listen`; `dispose()`
/// closes it before calling `super.dispose()`. Without this,
/// the listener would outlive the router and leak subscriptions
/// into every subsequent `ProviderScope`.
class AuthStateListenable extends ChangeNotifier {
  late final ProviderSubscription _sub;

  AuthStateListenable(Ref ref) {
    _sub = ref.listen<Object?>(
      authProvider,
      (previous, next) {
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}

/// The plain Provider that hands the `AuthStateListenable` to
/// the router. `ref.onDispose` closes the listenable when the
/// provider is torn down (which happens when the whole app
/// container is disposed — never in normal running, but is
/// exercised by tests).
final Provider<AuthStateListenable> authStateListenableProvider =
    Provider<AuthStateListenable>((ref) {
  final listenable = AuthStateListenable(ref);
  ref.onDispose(listenable.dispose);
  return listenable;
});
