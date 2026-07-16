import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/job.dart';
import 'job_dto.dart';

// Assignment 2.1 — the part directive for the file the generator emits.
// The .g.dart file does not exist until `dart run build_runner build`
// has been executed at least once; the IDE will show a red underline
// on this line until then, and on `_$dioHash`, `_$jobsRepositoryHash`,
// and the two generated `Provider` variables below. This is expected.
// See README, Q3.
part 'jobs_repository.g.dart';

// ─────────────────────────────────────────────────────────────────────
// Stretch C — environment-aware base URL.
//
// Three compile-time constants, one per environment, each read via
// `String.fromEnvironment`. `String.fromEnvironment` is a special-case
// constant expression: the Dart compiler resolves it at BUILD time from
// the value passed via `--dart-define`, then constant-folds it into
// the binary. There is NO runtime lookup and NO runtime `if` anywhere
// in this file. See README Stretch C.
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
/// tree-shakes the other two URLs out entirely. See README Stretch C.
const String _resolvedBaseUrl = _envName == 'prod'
    ? _envProdBaseUrl
    : (_envName == 'staging' ? _envStagingBaseUrl : _envDevBaseUrl);

/// Assignment 2.1 — the configured Dio instance, exposed through a
/// generated Riverpod provider.
///
/// The base URL, timeouts, and interceptors all live here so that
/// [JobsRepository] receives a ready-to-use client and never has to
/// know how it was constructed. Anything else that needs an HTTP client
/// (an ApplicationsRepository, an AuthRepository) will read this
/// provider — one client, one place to configure it.
@Riverpod(keepAlive: true)
Dio dio(Ref ref) {
  final client = Dio(
    BaseOptions(
      baseUrl: _resolvedBaseUrl,
      // Reasonable defaults for a mobile client on a home wifi hitting
      // a dev API — long enough that a cold-start EF Core query
      // (~2-3s) succeeds, short enough that a wedged connection
      // surfaces to the user without staring at a spinner for a
      // minute.
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: const {
        'Accept': 'application/json',
      },
    ),
  );

  // The brief's Part 5 verification requires "two log lines from
  // LogInterceptor — a request to your jobs endpoint and a 200
  // response." LogInterceptor writes to Dio's `logPrint`, which is
  // `print` by default and shows in `flutter run`'s terminal.
  client.interceptors.add(LogInterceptor(
    request: true,
    requestHeader: false,
    requestBody: false,
    responseHeader: false,
    // The paged jobs response is verbose enough (~200 rows × ~200 bytes)
    // that dumping the whole body swamps the terminal. Set to true
    // while debugging a wire-shape mismatch.
    responseBody: false,
    error: true,
  ));

  return client;
}

/// Assignment 2.1 — the repository provider. Exposes the singleton
/// [JobsRepository] instance to `JobsNotifier` and to any other layer
/// that wants to bypass the notifier (e.g. a one-off ID lookup).
///
/// This function's ONLY job is wiring — receive the Dio provider's
/// value and hand it to the repository constructor. That indirection
/// is exactly what lets tests substitute a fake Dio (or a fake
/// [JobsRepository]) through `ProviderScope.overrides` without touching
/// production code.
@Riverpod(keepAlive: true)
JobsRepository jobsRepository(Ref ref) {
  return JobsRepository(ref.watch(dioProvider));
}

/// Assignment 2.1 — the repository. The rest of the app never sees
/// [Dio], never sees [JobDto], and never sees a URL. It calls
/// [getJobs] and receives `List<Job>` — exactly the shape the widget
/// layer has always expected.
///
/// The class deliberately does NOT import anything from Riverpod: it
/// receives its Dio instance through the constructor. That makes it
/// trivially unit-testable (pass a Dio backed by
/// [DioAdapter]/[MockAdapter] in a plain `test()` block) and keeps the
/// framework boundary at exactly one file — this one.
class JobsRepository {
  final Dio _dio;

  JobsRepository(this._dio);

  /// `GET /jobs?page=1&pageSize=100` — the CareerHub list endpoint.
  /// Unwraps the `PagedResponse<JobResponse>` envelope, decodes each
  /// row into a [JobDto], and maps each DTO onto a [Job] via
  /// `Job.fromDto`. Anything downstream sees only `Job`s.
  ///
  /// Errors (network failure, non-2xx, malformed JSON) propagate as
  /// `DioException`s / `TypeError`s. The AsyncNotifier that watches
  /// this method surfaces them as `AsyncValue.error`, which the widget
  /// layer already renders with the Retry state introduced in
  /// Assignment 1.3.
  Future<List<Job>> getJobs() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/jobs',
      queryParameters: const {
        'page': 1,
        // 100 is comfortably above the seeded ~200 → first page shows
        // the majority of listings for the demo without implementing
        // infinite scroll (which is out of scope for Assignment 2.1).
        'pageSize': 100,
      },
    );

    final envelope = response.data;
    if (envelope == null) {
      throw StateError(
        'CareerHub API returned an empty body for GET /jobs — '
        'expected a PagedResponse envelope with a `data` array.',
      );
    }

    final rawList = envelope['data'] as List<dynamic>;
    return rawList
        .map((raw) => JobDto.fromJson(raw as Map<String, dynamic>))
        .map(Job.fromDto)
        .toList(growable: false);
  }
}
