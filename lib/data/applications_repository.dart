import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/application.dart';
import 'api_result.dart';
import 'jobs_repository.dart';

// Assignment 3.3, Part 4 — the code-generator part directive. The
// `.g.dart` file is emitted by
// `dart run build_runner build --delete-conflicting-outputs`.
part 'applications_repository.g.dart';

/// Assignment 3.3 scaffolding — the ApplicationsRepository provider.
///
/// Uses `ref.watch(dioProvider)` so the authenticated Dio client (with
/// `AuthInterceptor` attached) is what makes the call — every request
/// this repository issues carries the Bearer token automatically, and
/// a 401 that survives the interceptor's refresh flow surfaces here
/// as a `DioException` with `statusCode == 401` for the Part 4/5 401
/// mapping and automatic logout.
@Riverpod(keepAlive: true)
ApplicationsRepository applicationsRepository(Ref ref) {
  return ApplicationsRepository(dio: ref.watch(dioProvider));
}

/// The repository.
///
/// Public methods:
///   - `submitApplication(jobId, payload)` → `Future<ApiResult<void>>`.
///     POST `/jobs/{jobId}/applications` (the actual backend route —
///     see README 3.3's backend audit for why this differs from the
///     brief's aspirational `POST /api/applications`).
///   - `getApplications()` → `Future<ApiResult<List<Application>>>`.
///     GET `/applications`. **This endpoint does not exist on the
///     backend today** — the call falls into the null-statusCode
///     `NetworkFailure` branch until it ships, which the notifier
///     tolerates by rendering the empty state. See README 3.3.
///
/// Both methods return the sealed `ApiResult` hierarchy the rest of
/// the app already uses (`Success` / `NetworkFailure` /
/// `ServerFailure` / `UnknownFailure`); the notifier layer
/// pattern-matches on the variants exactly as the Assignment 2.2
/// Stretch C code path does elsewhere.
class ApplicationsRepository {
  final Dio _dio;

  ApplicationsRepository({required Dio dio}) : _dio = dio;

  /// POST `/jobs/{jobId}/applications`. The `payload` map is the
  /// two-step form's assembled values (see
  /// `ApplyScreen._Step2ApplicationContent`); only the fields the
  /// backend `SubmitApplicationRequest` DTO declares
  /// (`applicantName`, `applicantEmail`, plus any optional fields
  /// the endpoint accepts) are sent — the caller is expected to
  /// have prepared this shape.
  ///
  /// Returns `Success(null)` on 200/201, and one of the four
  /// `ApiResult` failure variants on any DioException. See the
  /// `switch` in the `on DioException` block for the exact mapping
  /// per status code — 400 (validation), 401 (session expired,
  /// carries `statusCode: 401` so the notifier can trigger
  /// logout), 409 (duplicate — exact user-facing string per the
  /// brief), 422 (listing closed — exact string; aspirational
  /// against today's backend which returns 400 for this case), 503
  /// (server unavailable), null-statusCode (connection error /
  /// timeout, split by DioExceptionType).
  Future<ApiResult<void>> submitApplication(
    String jobId,
    Map<String, dynamic> payload,
  ) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/jobs/$jobId/applications',
        data: payload,
      );
      return const Success<void>(null);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status != null) {
        return ServerFailure<void>(
          message: _submitApplicationMessageFor(status),
          statusCode: status,
        );
      }
      // No HTTP response received — connection error, connect
      // timeout, or receive timeout. Distinguished by
      // DioExceptionType so the user-facing message tells the user
      // which action is likely to help.
      return NetworkFailure<void>(_networkMessageFor(e.type));
    } catch (_) {
      return const UnknownFailure<void>(
        'Something went wrong while submitting your application. Please try again.',
      );
    }
  }

  /// GET `/applications`. Reads the signed-in JobSeeker's own
  /// applications. This endpoint is aspirational against today's
  /// backend — see README 3.3 backend audit.
  Future<ApiResult<List<Application>>> getApplications() async {
    try {
      final response = await _dio.get<dynamic>('/applications');
      final data = response.data;
      // Accept both a bare list (`[ ... ]`) and an envelope
      // (`{ "data": [ ... ] }`) — the .NET side's pagination
      // envelope shape is not settled for this endpoint, so decode
      // defensively.
      final List<dynamic> rawList;
      if (data is List) {
        rawList = data;
      } else if (data is Map<String, dynamic> && data['data'] is List) {
        rawList = data['data'] as List<dynamic>;
      } else if (data == null) {
        rawList = const [];
      } else {
        return const UnknownFailure<List<Application>>(
          'CareerHub returned an unexpected response shape for /applications.',
        );
      }
      final applications = rawList
          .whereType<Map<String, dynamic>>()
          .map(Application.fromJson)
          .toList(growable: false);
      return Success<List<Application>>(applications);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status != null) {
        return ServerFailure<List<Application>>(
          message: _getApplicationsMessageFor(status),
          statusCode: status,
        );
      }
      return NetworkFailure<List<Application>>(_networkMessageFor(e.type));
    } catch (_) {
      return const UnknownFailure<List<Application>>(
        'Something went wrong while loading your applications. Please try again.',
      );
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Assignment 3.3, Part 4 — status-code message maps.
  //
  // Two maps rather than one because the acceptable status set
  // differs per endpoint (submit accepts 400/409/422, list does
  // not) and the messages differ for shared codes (401 says the
  // same thing but 404 means different things — "no applications
  // found" is a different state from "the endpoint isn't there").
  // ─────────────────────────────────────────────────────────────

  String _submitApplicationMessageFor(int status) => switch (status) {
        400 => "There's a problem with your application. Please review the form and try again.",
        401 => 'Your session has expired. Please sign in again.',
        // Part 4.3 — the EXACT string the brief specifies.
        409 => 'You have already applied for this position.',
        // Part 4.3 — the EXACT string the brief specifies. The
        // backend today returns 400 for this case, not 422 — see
        // README 3.3 backend audit — so this branch is aspirational
        // against the current API. Kept because the brief mandates
        // it and because the mapping will fire the moment the
        // backend switches to 422.
        422 => 'This listing is no longer accepting applications.',
        503 => 'CareerHub is temporarily unavailable. Please try again shortly.',
        _ => 'CareerHub returned an unexpected response (status $status).',
      };

  String _getApplicationsMessageFor(int status) => switch (status) {
        401 => 'Your session has expired. Please sign in again.',
        404 => 'No applications were found for your account.',
        503 => 'CareerHub is temporarily unavailable. Please try again shortly.',
        _ => 'CareerHub returned an unexpected response (status $status).',
      };

  /// Part 4 — the null-statusCode branch, split by
  /// `DioExceptionType` so `connectionError` (no route to host)
  /// gets a "check your network" message and the two timeout
  /// variants (`connectionTimeout`, `receiveTimeout`) get a "try
  /// again in a moment" message. See README 3.3 Q2's fourth bullet
  /// for the reasoning.
  String _networkMessageFor(DioExceptionType type) => switch (type) {
        DioExceptionType.connectionError =>
          "Couldn't reach CareerHub. Check your internet connection and try again.",
        DioExceptionType.connectionTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.sendTimeout =>
          'The CareerHub server took too long to respond. Try again in a moment.',
        _ =>
          "Couldn't reach CareerHub. Check your internet connection and try again.",
      };
}
