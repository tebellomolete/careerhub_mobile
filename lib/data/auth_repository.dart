import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/user.dart';
import 'api_result.dart';

// Assignment 2.4, Part 4 — the code-generator part directive.
// The `.g.dart` file does not exist until `dart run build_runner
// build` runs. See README 2.4, § build_runner output.
part 'auth_repository.g.dart';

// ─────────────────────────────────────────────────────────────────
// Assignment 2.4 — SECURE STORAGE KEY CONSTANTS.
//
// These MUST match the identically-spelled constants in
// `auth_interceptor.dart`. The brief calls this out explicitly
// (Q3, interceptor section): a mismatch means the interceptor
// reads from one storage slot while the repository writes to
// another, and the app appears "signed in" while every request
// still 401s.
//
// Kept top-level-const so the compiler is guaranteed to inline
// them and no runtime plumbing can accidentally shadow the value.
// ─────────────────────────────────────────────────────────────────
const String kAccessTokenStorageKey = 'careerhub.auth.access_token';
const String kRefreshTokenStorageKey = 'careerhub.auth.refresh_token';

// Assignment 2.4 — the base URL for the plain (interceptor-free)
// Dio the AuthRepository owns. Read with `String.fromEnvironment`
// so the value is compile-time constant folded to the same value
// `dioProvider` uses in `jobs_repository.dart`. Kept as a
// re-declaration here (rather than an import) so this file does
// NOT depend on `jobs_repository.dart` — that dependency direction
// would produce a cycle (jobs_repository imports auth_interceptor
// which shares its keys with THIS file).
const String _authBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:5254/api/v1',
);

// Assignment 2.4 — the auth endpoint suffixes. Kept as constants
// so the interceptor's refresh-endpoint guard (Case 2) can match
// against the same string this file POSTs to.
const String kLoginPath = '/auth/login';
const String kRefreshPath = '/auth/refresh';

/// Assignment 2.4, Part 4 — the AuthRepository provider.
///
/// **Why this creates its own Dio, and not `ref.watch(dioProvider)`.**
/// Reusing the authenticated `dioProvider` here would route the
/// login and refresh calls through `AuthInterceptor`. A 401 on
/// `/refresh` would then trigger the interceptor to attempt
/// another refresh, which would 401 again — the exact infinite
/// loop described in README 2.4, Q3. This provider therefore
/// constructs a **plain Dio** with only `baseUrl` set and NO
/// interceptors attached.
///
/// `keepAlive: true` because the repository holds a
/// `FlutterSecureStorage` instance and there's no benefit to
/// tearing it down between UI transitions.
@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: _authBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: const {'Accept': 'application/json'},
    ),
  );
  // Deliberately: no interceptors on this Dio. See docstring.
  return AuthRepository(
    dio: dio,
    storage: const FlutterSecureStorage(),
  );
}

/// The repository. Six public methods per the assignment brief:
/// `readAccessToken`, `isTokenExpired`, `decodeUser`, `login`,
/// `tryRefresh`, `logout`. JWT decoding lives in a single private
/// static helper so the login / refresh / cold-boot paths all use
/// the same parsing logic.
class AuthRepository {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  const AuthRepository({
    required Dio dio,
    required FlutterSecureStorage storage,
  })  : _dio = dio,
        _storage = storage;

  /// Read the access token from secure storage — returns null if
  /// none is stored. Called by `AuthNotifier.build()` on cold
  /// boot.
  Future<String?> readAccessToken() async {
    return _storage.read(key: kAccessTokenStorageKey);
  }

  /// Is the token past its `exp` claim? Returns `true` on decode
  /// failure (a corrupt token is treated as expired), and `false`
  /// when the `exp` claim is absent (a token that never expires —
  /// the caller may still choose to reject such a token, but this
  /// method reports what the claim says, not policy).
  bool isTokenExpired(String token) {
    try {
      final payload = _decodePayload(token);
      final exp = payload['exp'];
      if (exp is! int) {
        return false;
      }
      final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
      return expiry.isBefore(DateTime.now().toUtc());
    } catch (_) {
      // Any parse failure — corrupted token, unexpected shape —
      // is treated as "expired" so the caller falls into the
      // refresh or Unauthenticated path.
      return true;
    }
  }

  /// Decode the JWT payload into a `User`. Uses `sub` as id,
  /// `email` as email, and `name` as displayName — falling back
  /// to `email` when `name` is absent. Throws on decode failure
  /// (unlike `isTokenExpired`, which returns `true`); the caller
  /// (typically `AuthNotifier.build()`) is expected to have
  /// already gated on `isTokenExpired == false`, so a throw here
  /// is a genuine bug worth surfacing.
  User decodeUser(String token) {
    final payload = _decodePayload(token);
    final id = payload['sub'] as String?;
    final email = payload['email'] as String?;
    final name = payload['name'] as String?;
    if (id == null || email == null) {
      throw const FormatException(
        'JWT payload missing required sub/email claims.',
      );
    }
    return User(
      id: id,
      email: email,
      displayName: name ?? email,
    );
  }

  /// POST `/auth/login`. On 200, write both tokens to secure
  /// storage and return `Success` with the decoded `User`. On
  /// `400` or `401`, return a `Failure` with a human-readable
  /// invalid-credentials message. On any other DioException, map
  /// to the network/server/unknown message via the same switch
  /// pattern JobsRepository uses.
  Future<ApiResult<User>> login(String email, String password) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        kLoginPath,
        data: {
          'email': email,
          'password': password,
        },
      );
      final body = response.data;
      if (body == null) {
        return const UnknownFailure(
          'CareerHub returned an empty body for login.',
        );
      }

      final accessToken = body['accessToken'] as String?;
      final refreshToken = body['refreshToken'] as String?;
      if (accessToken == null || refreshToken == null) {
        return const UnknownFailure(
          'CareerHub returned a login response missing tokens.',
        );
      }

      await _storage.write(
        key: kAccessTokenStorageKey,
        value: accessToken,
      );
      await _storage.write(
        key: kRefreshTokenStorageKey,
        value: refreshToken,
      );

      return Success(decodeUser(accessToken));
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 400 || status == 401) {
        return const NetworkFailure('Invalid email or password.');
      }
      return NetworkFailure(_messageForDioException(e));
    } catch (_) {
      return const UnknownFailure('Something went wrong while signing in.');
    }
  }

  /// POST `/auth/refresh`. Reads the refresh token from storage;
  /// if none exists, returns null. On success, writes the new
  /// access token (and, if the server rotated, the new refresh
  /// token) and returns the decoded User. On ANY failure, clears
  /// all secure storage and returns null — a failed refresh is
  /// treated as a hard end of session.
  Future<User?> tryRefresh() async {
    final refreshToken = await _storage.read(key: kRefreshTokenStorageKey);
    if (refreshToken == null) {
      return null;
    }
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        kRefreshPath,
        data: {'refreshToken': refreshToken},
      );
      final body = response.data;
      if (body == null) {
        await _storage.deleteAll();
        return null;
      }

      final newAccess = body['accessToken'] as String?;
      final newRefresh = body['refreshToken'] as String?;
      if (newAccess == null) {
        await _storage.deleteAll();
        return null;
      }

      await _storage.write(key: kAccessTokenStorageKey, value: newAccess);
      if (newRefresh != null) {
        await _storage.write(key: kRefreshTokenStorageKey, value: newRefresh);
      }
      return decodeUser(newAccess);
    } catch (_) {
      await _storage.deleteAll();
      return null;
    }
  }

  /// Clear both tokens from secure storage. `AuthNotifier.logout`
  /// calls this and then transitions to `Unauthenticated`.
  Future<void> logout() async {
    await _storage.deleteAll();
  }

  // ───────────────────────────────────────────────────────────────
  // JWT decoding — private, static, handling Base64URL padding.
  //
  // The brief calls out that the middle segment's length is not
  // guaranteed to be a multiple of four (Base64URL omits padding),
  // and requires the exact `(4 - length % 4) % 4` formula for the
  // padding recomputation.
  // ───────────────────────────────────────────────────────────────
  static Map<String, dynamic> _decodePayload(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw const FormatException('Malformed JWT — expected three segments.');
    }
    final segment = parts[1];
    final padded = segment + ('=' * ((4 - segment.length % 4) % 4));
    final decoded = utf8.decode(base64Url.decode(padded));
    final payload = jsonDecode(decoded);
    if (payload is! Map<String, dynamic>) {
      throw const FormatException('JWT payload is not a JSON object.');
    }
    return payload;
  }

  static String _messageForDioException(DioException e) => switch (e.type) {
        DioExceptionType.connectionTimeout =>
          'The connection to CareerHub timed out. Check your internet and try again.',
        DioExceptionType.sendTimeout =>
          'The request took too long to send.',
        DioExceptionType.receiveTimeout =>
          'CareerHub took too long to respond.',
        DioExceptionType.badCertificate =>
          'CareerHub presented an invalid security certificate.',
        DioExceptionType.badResponse => 'CareerHub returned an error.',
        DioExceptionType.cancel => 'The request was cancelled.',
        DioExceptionType.transformTimeout =>
          'CareerHub responded, but the response took too long to decode.',
        DioExceptionType.connectionError =>
          'Could not reach CareerHub. Make sure the API is running.',
        DioExceptionType.unknown =>
          'Something went wrong while contacting CareerHub.',
      };
}
