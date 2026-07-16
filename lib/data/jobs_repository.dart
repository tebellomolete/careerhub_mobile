import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/job.dart';
import 'api_result.dart';
import 'job_dto.dart';

// Assignment 2.1 — the part directive for the file the generator emits.
// The `.g.dart` file does not exist until `dart run build_runner build`
// has been executed at least once; the IDE will show a red underline
// on this line until then. See README, Q3.
part 'jobs_repository.g.dart';

// ─────────────────────────────────────────────────────────────────────
// Assignment 2.1 Stretch C — environment-aware base URL.
//
// Three compile-time constants, one per environment, each read via
// `String.fromEnvironment`. `String.fromEnvironment` is a special-case
// constant expression: the Dart compiler resolves it at BUILD time from
// the value passed via `--dart-define`, then constant-folds it into
// the binary. There is NO runtime lookup and NO runtime `if` anywhere
// in this file.
//
// Defaults:
//   - dev     → localhost on the host machine (matches
//               launchSettings.json's http profile). This is correct
//               for Chrome (web) and desktop targets. On an Android
//               emulator, override to `http://10.0.2.2:5254/api/v1`
//               via --dart-define since the emulator sandbox aliases
//               the host's localhost as 10.0.2.2.
//   - staging → a placeholder; override with --dart-define at build time.
//   - prod    → a placeholder; override with --dart-define at build time.
// ─────────────────────────────────────────────────────────────────────
const String _envDevBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:5254/api/v1',
);
const String _envStagingBaseUrl = String.fromEnvironment(
  'API_BASE_URL_STAGING',
  defaultValue: 'https://staging.careerhub.example.com/api/v1',
);
const String _envProdBaseUrl = String.fromEnvironment(
  'API_BASE_URL_PROD',
  defaultValue: 'https://api.careerhub.example.com/api/v1',
);

/// The environment selector, read once at build time. Values: `dev`,
/// `staging`, `prod`. Anything else falls back to `dev`.
const String _envName = String.fromEnvironment('ENV', defaultValue: 'dev');

/// A single `const` picked at build time. Because every branch of this
/// expression is itself a compile-time constant, the Dart compiler folds
/// the whole thing down to one string literal in the compiled binary and
/// tree-shakes the other two URLs out entirely.
const String _resolvedBaseUrl = _envName == 'prod'
    ? _envProdBaseUrl
    : (_envName == 'staging' ? _envStagingBaseUrl : _envDevBaseUrl);

/// Assignment 2.1 — the configured Dio instance, exposed through a
/// generated Riverpod provider.
@Riverpod(keepAlive: true)
Dio dio(Ref ref) {
  final client = Dio(
    BaseOptions(
      baseUrl: _resolvedBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: const {
        'Accept': 'application/json',
      },
    ),
  );

  client.interceptors.add(LogInterceptor(
    request: true,
    requestHeader: false,
    requestBody: false,
    responseHeader: false,
    responseBody: false,
    error: true,
  ));

  return client;
}

/// Assignment 2.1 — the repository provider. Wires the singleton Dio
/// into [JobsRepository].
@Riverpod(keepAlive: true)
JobsRepository jobsRepository(Ref ref) {
  return JobsRepository(ref.watch(dioProvider));
}

/// Assignment 2.1 → 2.2 — the repository. The rest of the app never
/// sees [Dio], never sees [JobDto], and never sees a URL. It calls
/// [getJobs] and receives an `ApiResult<List<Job>>` — either a
/// [Success] wrapping the jobs list, or one of the three sealed failure
/// variants ([NetworkFailure], [ServerFailure], [UnknownFailure]).
///
/// Assignment 2.2 changes:
///   - Return type is now `Future<ApiResult<List<Job>>>` (was
///     `Future<List<Job>>`). Errors travel as VALUES the notifier can
///     pattern-match on, not as exceptions the widget layer has to
///     unwrap. See README 2.2, Q4.
///   - The parsing step is factored into [_parseJobsPage] which returns
///     a NAMED RECORD — `({List<JobDto> dtos, List<Job> jobs})` — and
///     the call site destructures both lists into clearly named
///     locals. Part 3 Step 3.3.
///   - The `DioException` → message translation is a SWITCH EXPRESSION
///     over `e.type`, producing exactly one string per branch. Part 8.
class JobsRepository {
  final Dio _dio;

  JobsRepository(this._dio);

  /// `GET /jobs?page=1&pageSize=100` — the CareerHub list endpoint.
  ///
  /// Behaviour is unchanged from Assignment 2.1 on the happy path:
  /// unwrap the `PagedResponse<JobResponse>` envelope, decode each row
  /// into a [JobDto], map each DTO onto a [Job]. What is different is
  /// the failure path: exceptions never leave this method. Every
  /// failure is caught and returned as a [NetworkFailure],
  /// [ServerFailure], or [UnknownFailure] — the notifier's switch
  /// expression handles them exhaustively (see [JobsNotifier.build]).
  Future<ApiResult<List<Job>>> getJobs() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/jobs',
        queryParameters: const {
          'page': 1,
          // 100 is comfortably above the seeded ~200 → first page shows
          // the majority of listings for the demo.
          'pageSize': 100,
        },
      );

      final envelope = response.data;
      if (envelope == null) {
        // A 200 with an empty body is a wire-shape bug on the server —
        // surface it through the sealed hierarchy rather than throwing.
        return const UnknownFailure(
          'CareerHub API returned an empty body for GET /jobs.',
        );
      }

      // Part 3 Step 3.3 — the parsing step is a private helper whose
      // return type is a NAMED RECORD. `dtos` and `jobs` are BOUND at
      // the call site with pattern destructuring; the record is a
      // one-shot structural type — no class needed.
      final (:dtos, :jobs) = _parseJobsPage(envelope);

      // `dtos` is deliberately unused after destructuring: the current
      // implementation only ships the mapped `jobs` list to the
      // notifier. It's still worth destructuring both because it
      // documents the two-stage nature of the parse (wire shape →
      // domain), and a future extension (‘log DTO count for
      // telemetry’) is a one-line addition, not a signature change.
      final _ = dtos;

      return Success(jobs);
    } on DioException catch (e) {
      // Part 8 — DioException.type is an enum with a small, closed set
      // of values; a switch expression over it is exhaustive and
      // produces exactly one message + failure variant per branch. No
      // if-chain, no fall-through, no `default` swallowing an
      // unhandled type by accident.
      final message = _messageForDioException(e);
      final statusCode = e.response?.statusCode;
      if (statusCode != null) {
        // Stretch C — the server DID respond, so this is a
        // ServerFailure with a concrete (non-null) status code.
        return ServerFailure(message: message, statusCode: statusCode);
      }
      // Stretch C — no response received, so classify as a
      // NetworkFailure (connection could not be established).
      return NetworkFailure(message);
    } catch (e) {
      // Anything else (TypeError from a wire-shape mismatch, a
      // StateError, a rogue String? cast) — Stretch C classifies as
      // UnknownFailure. The message is deliberately GENERIC because
      // exposing the underlying exception's toString would leak stack
      // detail into the widget layer.
      return const UnknownFailure(
        'Something went wrong while loading jobs. Please try again.',
      );
    }
  }

  /// Part 3 Step 3.3 — the private parsing helper. Returns a NAMED
  /// RECORD holding both the raw wire shapes (`dtos`) and the mapped
  /// domain objects (`jobs`). The record's fields are named so the
  /// call site can destructure with `(:dtos, :jobs)` and read
  /// self-documenting variable names, not `.$1` / `.$2` positional
  /// indexing.
  ({List<JobDto> dtos, List<Job> jobs}) _parseJobsPage(
    Map<String, dynamic> envelope,
  ) {
    final rawList = envelope['data'] as List<dynamic>;
    final dtos = rawList
        .map((raw) => JobDto.fromJson(raw as Map<String, dynamic>))
        .toList(growable: false);
    final jobs = dtos.map(Job.fromDto).toList(growable: false);
    return (dtos: dtos, jobs: jobs);
  }

  /// Part 8 — the DioException → human-readable-message translator.
  /// A switch EXPRESSION on `e.type` so the Dart analyzer verifies
  /// every enum value is covered (`DioExceptionType` is a small, fixed
  /// enum). Anything unmatched falls through to the `_` arm with a
  /// generic message — but every named case is spelled out so the
  /// intent is inspectable at review time.
  String _messageForDioException(DioException e) => switch (e.type) {
        DioExceptionType.connectionTimeout =>
          'The connection to CareerHub timed out. Check your internet and try again.',
        DioExceptionType.sendTimeout =>
          'The request to CareerHub took too long to send. Try again.',
        DioExceptionType.receiveTimeout =>
          'CareerHub took too long to respond. Try again in a moment.',
        DioExceptionType.badCertificate =>
          'The CareerHub server presented an invalid security certificate.',
        DioExceptionType.badResponse => switch (e.response?.statusCode) {
            final int code when code >= 500 =>
              'CareerHub is having trouble right now (server error $code). Please try again shortly.',
            final int code when code == 404 =>
              'Could not find the jobs endpoint on the CareerHub server.',
            final int code =>
              'CareerHub returned an unexpected response (status $code).',
            null =>
              'CareerHub returned an unexpected response.',
          },
        DioExceptionType.cancel => 'The request was cancelled.',
        DioExceptionType.transformTimeout =>
          'CareerHub responded, but the response took too long to decode. Try again.',
        DioExceptionType.connectionError =>
          'Could not reach the CareerHub server. Make sure the API is running and try again.',
        DioExceptionType.unknown =>
          'Something went wrong while contacting CareerHub. Please try again.',
      };
}
