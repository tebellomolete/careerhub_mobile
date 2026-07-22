import 'user.dart';

// Assignment 2.4, Part 3.2 — the sealed hierarchy that drives
// the entire authentication flow.
//
// **Why sealed, not enum.** The four variants have irreconcilable
// payload shapes: `Unauthenticated` and `Authenticating` carry
// nothing, `Authenticated` carries a non-null `User`, and
// `AuthError` carries a non-null `String`. A Dart enum cannot
// express per-variant fields; a sealed class can, and Dart 3's
// exhaustiveness checker enforces that every consumer's `switch`
// handles all four. See README 2.4, Q2 (first bullet).
//
// **Why plain Dart.** No `@freezed`, no `part` directive, no
// generated code. Dart 3's `sealed` is a first-class language
// keyword and the compiler alone is enough — every subclass in
// this file is `final` so the closed set is compiler-enforced.
sealed class AuthState {
  const AuthState();
}

/// The initial state at cold boot when no valid token is present
/// in secure storage, and the state after a successful `logout()`.
final class Unauthenticated extends AuthState {
  const Unauthenticated();

  @override
  bool operator ==(Object other) => other is Unauthenticated;

  @override
  int get hashCode => 0;

  @override
  String toString() => 'Unauthenticated()';
}

/// Emitted **only** during a `login(email, password)` call — never
/// during the cold-boot token check (which uses the outer
/// `AsyncValue.loading`). Distinguishing the two lets the login
/// screen render its inline spinner without the router
/// mis-treating the state as unresolved. See README 2.4, Q2
/// (second bullet).
final class Authenticating extends AuthState {
  const Authenticating();

  @override
  bool operator ==(Object other) => other is Authenticating;

  @override
  int get hashCode => 1;

  @override
  String toString() => 'Authenticating()';
}

/// The success state — a valid, non-expired access token exists
/// in secure storage and a `User` has been decoded from it.
final class Authenticated extends AuthState {
  final User user;

  const Authenticated({required this.user});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Authenticated &&
          runtimeType == other.runtimeType &&
          user == other.user;

  @override
  int get hashCode => user.hashCode;

  @override
  String toString() => 'Authenticated(user: $user)';
}

/// Emitted when `login()` fails — bad credentials, a 4xx from the
/// server, or a network error. The `message` is a user-facing
/// string suitable for rendering under the password field.
final class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthError &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;

  @override
  String toString() => 'AuthError($message)';
}
