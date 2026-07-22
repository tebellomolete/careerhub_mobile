import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:isar_community/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/isar_provider.dart';
import '../core/prefs_provider.dart';
import '../models/job.dart';
import '../providers/auth_provider.dart';
import 'api_result.dart';
import 'auth_interceptor.dart';
import 'job_cache.dart';
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

/// Assignment 2.1 → 2.4 — the configured Dio instance.
///
/// Assignment 2.4 additions (Part 9.1):
///   - A second, plain `retryDio` instance is created alongside
///     the main client. It has ONLY the baseUrl set and NO
///     interceptors — this is the Dio the AuthInterceptor uses
///     to POST to `/auth/refresh` and to replay the original
///     request. Its lack of interceptors is what breaks the
///     infinite-refresh-loop analysed in README 2.4, Q3.
///   - `AuthInterceptor` is added AFTER `LogInterceptor` on the
///     main client. The order matters: LogInterceptor sits at
///     the top of the chain and logs the raw request/response,
///     AuthInterceptor sits below it and rewrites the
///     Authorization header + handles 401s.
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

  // Assignment 2.4, Part 9.1 — the retry Dio the AuthInterceptor
  // uses to POST /refresh and to replay the original request. No
  // interceptors, same baseUrl.
  final retryDio = Dio(
    BaseOptions(
      baseUrl: _resolvedBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: const {'Accept': 'application/json'},
    ),
  );

  client.interceptors.add(
    AuthInterceptor(
      storage: const FlutterSecureStorage(),
      retryDio: retryDio,
      onUnauthenticated: ref.read(onUnauthenticatedProvider),
    ),
  );

  return client;
}

/// Assignment 2.1 → 2.3 — the repository provider. Wires the singleton
/// Dio, the singleton Isar instance, and the singleton SharedPreferences
/// instance into [JobsRepository].
///
/// Assignment 2.3 change: this provider now also watches
/// [isarProvider] and [prefsProvider] — both of which are overridden
/// in `main.dart` with real, opened instances before `runApp`. See
/// README 2.3, Part 5.
@Riverpod(keepAlive: true)
JobsRepository jobsRepository(Ref ref) {
  return JobsRepository(
    dio: ref.watch(dioProvider),
    isar: ref.watch(isarProvider),
    prefs: ref.watch(prefsProvider),
  );
}

/// Assignment 2.1 → 2.3 — the repository.
///
/// The rest of the app never sees [Dio], never sees [JobDto], never
/// sees [Isar], never sees [SharedPreferences], and never sees a URL.
/// It calls [getJobs] / [getCachedJobs] and receives typed values —
/// either an `ApiResult<List<Job>>` (network path) or a `List<Job>`
/// (cache path).
///
/// Assignment 2.2 changes (retained):
///   - Return type of [getJobs] is `Future<ApiResult<List<Job>>>`.
///   - The parsing step is factored into [_parseJobsPage] which returns
///     a named record.
///   - The `DioException` → message translation is a switch expression.
///
/// Assignment 2.3 changes:
///   - Constructor now takes required named [isar] and [prefs] fields.
///   - New [getCachedJobs] reads every row from the Isar `jobCaches`
///     collection and returns `Future<List<Job>>` — no network call.
///   - [getJobs], on `Success`, writes the fresh list to Isar inside a
///     single `writeTxn` — `clear()` before `putAll()` — and updates
///     the `jobs_last_synced` SharedPreferences key (Stretch A).
///   - Two private conversion methods live here (one per direction),
///     so `Job` (domain) and `JobCache` (storage) never import each
///     other. See README 2.3, Part 5.
///   - A private [_locationTypeFromName] helper reverse-maps the
///     stored enum name to a [LocationType]; on unknown input it
///     returns `LocationType.onSite` rather than throwing. See
///     README 2.3, Q2.
class JobsRepository {
  final Dio _dio;
  final Isar _isar;
  final SharedPreferences _prefs;

  JobsRepository({
    required Dio dio,
    required Isar isar,
    required SharedPreferences prefs,
  })  : _dio = dio,
        _isar = isar,
        _prefs = prefs;

  /// Assignment 2.3, Stretch A — the SharedPreferences key the cache-
  /// age indicator reads from. Written here alongside every successful
  /// Isar write; read by `cacheAgeProvider` (see
  /// `lib/providers/connectivity_provider.dart`).
  static const String _lastSyncedKey = 'jobs_last_synced';

  /// Assignment 2.3 — expose the Isar handle so a downstream
  /// `StreamProvider` (Stretch B) can subscribe to `jobCaches.watchLazy`
  /// without needing to inject `isarProvider` a second time. The
  /// getter is deliberately narrow: callers can subscribe, but every
  /// WRITE still goes through [getJobs] which owns the `writeTxn` +
  /// clear+putAll sequence and the sibling `_lastSyncedKey` update.
  Isar get isar => _isar;

  /// Assignment 2.3, Part 5 — read every cached job from Isar as a
  /// `List<Job>`. Never touches the network. Returns an empty list
  /// when the collection is empty (a fresh install, or after
  /// `writeTxn(() => isar.clear())` from a debug menu). No error
  /// path — Isar's `.findAll()` on an open instance can't fail in a
  /// way the caller is expected to recover from; a corrupt DB file
  /// throws an unrecoverable `IsarError` that bubbles up as an
  /// `AsyncError` on the notifier, exactly like a network error would.
  Future<List<Job>> getCachedJobs() async {
    final rows = await _isar.jobCaches.where().findAll();
    return rows.map(_toJob).toList(growable: false);
  }

  /// `GET /jobs?page=1&pageSize=100` — the CareerHub list endpoint.
  ///
  /// Assignment 2.3 change: on `Success` the fresh `List<Job>` is
  /// written to Isar inside a single `writeTxn` — `clear()` before
  /// `putAll()` — so a job the server removed between requests does
  /// not linger in the cache. The write is fire-and-forget from the
  /// caller's perspective: the returned `Success(jobs)` is unchanged
  /// in shape from 2.2, so the notifier's pattern-match is
  /// unaffected.
  ///
  /// The sibling `_prefs.setInt(_lastSyncedKey, ...)` write is
  /// Stretch A — the cache-age indicator in the offline banner. It
  /// runs AFTER the Isar write so a mid-flight failure cannot leave
  /// the timestamp advanced against an empty (or older) collection.
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

      // Assignment 2.3, Part 5 — write the fresh list to Isar. The
      // ordering inside the transaction is critical:
      //   1. `clear()` — remove every previous cache row so a job the
      //      server dropped between requests does not linger.
      //   2. `putAll()` — insert every fresh row. Isar assigns each
      //      row a new autoincrement `id` (the domain `jobId` String
      //      is stored as an ordinary field, see `job_cache.dart`).
      // Both operations happen inside a single `writeTxn` so a mid-
      // transaction crash leaves the collection either fully old or
      // fully new — never half-populated with a mix.
      final caches = jobs.map(_toCache).toList(growable: false);
      await _isar.writeTxn(() async {
        await _isar.jobCaches.clear();
        await _isar.jobCaches.putAll(caches);
      });

      // Assignment 2.3, Stretch A — after the Isar write succeeds,
      // update the last-synced timestamp so the offline banner can
      // render "Last updated N minutes ago" instead of a generic
      // string on the next offline launch. The `Future<bool>`
      // returned by `setInt` is intentionally not awaited — the
      // write is best-effort; failing to advance the timestamp only
      // costs the user an accurate "N minutes ago" string, not the
      // cache itself. See README 2.3, Stretch A.
      // ignore: unawaited_futures
      _prefs.setInt(_lastSyncedKey, DateTime.now().millisecondsSinceEpoch);

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

  /// Assignment 2.3, Part 5 — the ONE domain-to-storage conversion.
  /// Private on purpose: nothing outside this file constructs a
  /// [JobCache], and no widget/screen/provider ever imports the class.
  JobCache _toCache(Job job) {
    return JobCache()
      ..jobId = job.id
      ..title = job.title
      ..company = job.company
      ..location = job.location
      // See README 2.3, Q2 — enum stored as its `.name`.
      ..locationTypeName = job.locationType.name
      ..salary = job.salary
      ..employmentType = job.employmentType
      // See README 2.3, Q2 — `DateTime?` stored natively.
      ..closingDate = job.closingDate
      ..description = job.description
      ..isOpen = job.isOpen
      ..userNote = job.userNote;
  }

  /// Assignment 2.3, Part 5 — the ONE storage-to-domain conversion.
  /// The mirror of [_toCache].
  Job _toJob(JobCache cache) {
    return Job(
      id: cache.jobId,
      title: cache.title,
      company: cache.company,
      location: cache.location,
      locationType: _locationTypeFromName(cache.locationTypeName),
      salary: cache.salary,
      employmentType: cache.employmentType,
      closingDate: cache.closingDate,
      description: cache.description,
      isOpen: cache.isOpen,
      userNote: cache.userNote,
    );
  }

  /// Assignment 2.3, Q2 — reverse-map the stored `.name` String back to
  /// a [LocationType] value, with a NAMED FALLBACK.
  ///
  /// The lookup uses `LocationType.values.byName` which throws
  /// `ArgumentError` on any string it does not recognise — for example
  /// if the cache was written by a build that had a `LocationType.contract`
  /// member that has since been renamed to `LocationType.contractor`.
  /// A throw here would take down `getCachedJobs()` — the code path
  /// the entire offline demo relies on — so the try/catch converts
  /// the miss into `LocationType.onSite`, which:
  ///   1. Keeps the rest of the cached list rendering (the whole
  ///      point of the offline story).
  ///   2. Is the safest visible fallback — "onSite" is the
  ///      most-common state and won't accidentally hide the job from
  ///      an active `Remote`/`Hybrid` filter (worst case: the job
  ///      appears when it "shouldn't" for that filter, which is
  ///      strictly better than "the app crashed on cold boot").
  /// See README 2.3, Q2.
  LocationType _locationTypeFromName(String name) {
    try {
      return LocationType.values.byName(name);
    } on ArgumentError {
      return LocationType.onSite;
    }
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
