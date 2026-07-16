/// Assignment 2.2, Part 7 (+ Stretch C) — the sealed result type the
/// repository returns and the notifier pattern-matches on.
///
/// This file uses NO `@freezed`, NO `part` directive, and needs NO
/// `build_runner` run. `sealed` is a first-class Dart 3 keyword — the
/// compiler enforces two rules directly:
///   1. **File-location rule.** Every direct subclass of a `sealed`
///      class MUST be declared in the SAME LIBRARY (this file). That is
///      what lets the compiler know the ENTIRE closed set of variants
///      at check time.
///   2. **Exhaustiveness checking.** A `switch` expression over a
///      `sealed` type is a compile-time error if any variant is
///      unhandled — the compiler refuses to compile a `switch` that
///      forgets `NetworkFailure`, `ServerFailure`, `UnknownFailure`, or
///      `Success`. Contrast with a plain `abstract class`: the compiler
///      cannot see the full subclass set, so it must ASSUME another
///      variant may exist and downgrades the check to a runtime lint
///      warning at best. See README 2.2, Q4.
///
/// Stretch C — the single `Failure<T>` of Part 7 has been split into
/// three concrete failure variants so the notifier's switch expression
/// distinguishes them at compile time and the compiler forces every
/// future variant to be handled in every switch. See README 2.2,
/// Stretch C.
library;

/// The sealed parent. Empty body — every method that operates on an
/// `ApiResult<T>` does so by pattern-matching on the variant, not by
/// calling an overridable method here. That is exactly how sealed
/// hierarchies encourage the caller to think in terms of the KNOWN
/// closed set of shapes.
sealed class ApiResult<T> {
  const ApiResult();
}

/// The success arm. Holds exactly one payload of type `T` — for the
/// `getJobs()` call this is a `List<Job>`.
final class Success<T> extends ApiResult<T> {
  const Success(this.data);

  final T data;
}

/// Stretch C — a connection could not be established at all: DNS
/// failure, connect timeout, TLS handshake refused, no route to host.
/// The message is a human-readable string suitable for the widget
/// layer's error state; no `statusCode` because no HTTP response was
/// ever received.
final class NetworkFailure<T> extends ApiResult<T> {
  const NetworkFailure(this.message);

  final String message;
}

/// Stretch C — the server responded, but with a non-2xx status. Carries
/// both the human-readable message AND the raw status code so the UI
/// (or a future analytics layer) can branch on it if needed. Because
/// the server DID respond, `statusCode` is `int` (non-nullable) —
/// contrast with the single-`Failure` design in Part 7 where the code
/// had to be nullable to accommodate the network-failure case.
final class ServerFailure<T> extends ApiResult<T> {
  const ServerFailure({required this.message, required this.statusCode});

  final String message;
  final int statusCode;
}

/// Stretch C — the catch-all: a `TypeError` from an unexpected wire
/// shape, a `StateError` from the empty-envelope check in the
/// repository, or a `DioException` whose `type` didn't match any of
/// the known network/server categories. No `statusCode` because we
/// don't have one to attach; the message is generic enough to be
/// user-facing without leaking a stack trace.
final class UnknownFailure<T> extends ApiResult<T> {
  const UnknownFailure(this.message);

  final String message;
}
