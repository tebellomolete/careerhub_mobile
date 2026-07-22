import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Assignment 2.4, Part 7 — the interceptor that transparently
// attaches Bearer tokens, queues concurrent 401s onto a single
// refresh call, and hands control back to the auth layer when a
// refresh fails.
//
// **No Riverpod import in this file.** The interceptor lives in
// the data layer; its only inputs are (a) the storage instance,
// (b) a plain retry Dio, and (c) a `void Function()` callback
// the outer wiring layer provides. This decouples the file from
// the providers/ layer entirely — the alternative (importing
// auth_notifier.dart to invalidate directly) is exactly the
// circular-import chain analysed in README 2.4, Q4.

// ─────────────────────────────────────────────────────────────────
// Assignment 2.4 — SECURE STORAGE KEY CONSTANTS.
//
// These MUST match the same-named constants in
// `auth_repository.dart`. A mismatch means this interceptor
// reads from a different storage slot than the repository
// writes to — the repository writes a valid token, this
// interceptor reads null, and every request goes out
// unauthenticated. Kept as top-level `const` so a rename in one
// file is a compile-time break in the other.
// ─────────────────────────────────────────────────────────────────
const String _kAccessTokenStorageKey = 'careerhub.auth.access_token';
const String _kRefreshTokenStorageKey = 'careerhub.auth.refresh_token';

/// The path segment that identifies the refresh endpoint. The
/// guard in Case 2 uses `.contains(_kRefreshPathFragment)` on
/// the failing request's path rather than an equality check, so
/// both `/auth/refresh` and `/api/v1/auth/refresh` match.
const String _kRefreshPathFragment = '/auth/refresh';

class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage storage;
  final Dio retryDio;
  final void Function() onUnauthenticated;

  bool _isRefreshing = false;
  final List<Completer<String>> _queue = <Completer<String>>[];

  AuthInterceptor({
    required this.storage,
    required this.retryDio,
    required this.onUnauthenticated,
  });

  // ───────────────────────────────────────────────────────────────
  // Part 7.2 — attach the Bearer token to every outgoing request.
  // ───────────────────────────────────────────────────────────────
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await storage.read(key: _kAccessTokenStorageKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  // ───────────────────────────────────────────────────────────────
  // Part 7.3 — the four-case 401 flow.
  //   Case 1: not a 401 → pass through.
  //   Case 2: 401 on refresh endpoint → definitive session end.
  //   Case 3: 401 while refresh already in progress → queue.
  //   Case 4: 401 with no refresh in progress → start refresh.
  // ───────────────────────────────────────────────────────────────
  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Case 1 — anything other than 401 flows through unchanged.
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    final requestPath = err.requestOptions.path;

    // Case 2 — 401 on the refresh endpoint itself. The refresh
    // token is invalid; the session is definitively over. Drain
    // any parked callers with the same error, clear storage,
    // notify the auth layer, and propagate the 401 to the
    // original caller. Without this guard the app would enter an
    // infinite refresh loop and never surface the login screen
    // (see README 2.4, Q3 third bullet).
    if (requestPath.contains(_kRefreshPathFragment)) {
      _drainQueue(err);
      await storage.deleteAll();
      onUnauthenticated();
      handler.next(err);
      return;
    }

    // Case 3 — another refresh is already in progress. Park the
    // caller on a Completer and wait for the outer refresh to
    // fulfil it. The three-concurrent-401s scenario in README
    // 2.4, Q3 (second bullet) is exactly this path.
    if (_isRefreshing) {
      final completer = Completer<String>();
      _queue.add(completer);
      try {
        final newToken = await completer.future;
        // Attach the fresh token to the original request's
        // headers and replay via retryDio.
        final retried = await retryDio.fetch<dynamic>(
          err.requestOptions
            ..headers['Authorization'] = 'Bearer $newToken',
        );
        handler.resolve(retried);
      } catch (_) {
        handler.next(err);
      }
      return;
    }

    // Case 4 — no refresh in progress. Become the refresh runner.
    _isRefreshing = true;
    try {
      final refreshToken = await storage.read(key: _kRefreshTokenStorageKey);
      if (refreshToken == null) {
        // No refresh token stored — the session is over.
        _drainQueue(err);
        await storage.deleteAll();
        onUnauthenticated();
        handler.next(err);
        return;
      }

      final Response<Map<String, dynamic>> refreshResponse;
      try {
        refreshResponse = await retryDio.post<Map<String, dynamic>>(
          _kRefreshPathFragment,
          data: {'refreshToken': refreshToken},
        );
      } on DioException catch (refreshErr) {
        // The refresh call itself failed. Drain the queue with
        // this error, clear storage, and unauth.
        _drainQueue(refreshErr);
        await storage.deleteAll();
        onUnauthenticated();
        handler.next(err);
        return;
      }

      final body = refreshResponse.data;
      final newAccess = body?['accessToken'] as String?;
      final newRefresh = body?['refreshToken'] as String?;
      if (newAccess == null) {
        _drainQueue(err);
        await storage.deleteAll();
        onUnauthenticated();
        handler.next(err);
        return;
      }

      // Persist the new tokens BEFORE draining the queue — the
      // parked callers will re-fire immediately and the next
      // `onRequest` will read from storage.
      await storage.write(key: _kAccessTokenStorageKey, value: newAccess);
      if (newRefresh != null) {
        await storage.write(key: _kRefreshTokenStorageKey, value: newRefresh);
      }

      // Complete every parked completer with the new token.
      for (final completer in _queue) {
        completer.complete(newAccess);
      }
      _queue.clear();

      // Replay the ORIGINAL request that triggered this Case 4
      // frame, with the fresh Bearer.
      final retried = await retryDio.fetch<dynamic>(
        err.requestOptions
          ..headers['Authorization'] = 'Bearer $newAccess',
      );
      handler.resolve(retried);
    } finally {
      // MUST reset in `finally` so a mid-refresh throw doesn't
      // leave `_isRefreshing` stuck at `true` (see Part 7
      // checkpoint on the finally block).
      _isRefreshing = false;
    }
  }

  /// Complete every parked completer with the supplied error and
  /// clear the queue. Called by Case 2 and by both failure
  /// branches of Case 4.
  void _drainQueue(DioException err) {
    for (final completer in _queue) {
      completer.completeError(err);
    }
    _queue.clear();
  }
}
