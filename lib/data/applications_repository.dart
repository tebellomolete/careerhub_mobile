import 'package:dio/dio.dart';
import 'package:isar_community/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/job_application.dart';
import '../providers/persistence_providers.dart';
import 'api_result.dart';
import 'job_application_dto.dart';
import 'job_application_isar.dart';
import 'jobs_repository.dart' show dioProvider;

part 'applications_repository.g.dart';

/// W2D3 in-class challenge, Part 3 — the applications repository.
///
/// Owns the two paths off the network + cache boundary:
///   - [readCache] : pure Isar read, returns a `List<JobApplication>`
///     synchronously w.r.t. the network (no HTTP call). Called first
///     by the notifier so the UI shows cached data on cold boot.
///   - [fetchAndCache] : Dio → parse → atomic Isar upsert. Wraps the
///     write in `writeTxn` per the assessment criteria.
///
/// Both Dio AND Isar are accepted via the constructor — the repository
/// never obtains either itself. That is what lets the widget test
/// override the Dio instance (fake HTTP) and the notifier test open an
/// in-memory Isar in a temp directory.
class ApplicationsRepository {
  final Dio _dio;
  final Isar _isar;

  ApplicationsRepository({required Dio dio, required Isar isar})
      : _dio = dio,
        _isar = isar;

  /// Cache-only read. Ordered newest-first so the UI's ListView renders
  /// the most recent application at the top without a client-side sort.
  Future<List<JobApplication>> readCache() async {
    final rows = await _isar.jobApplicationIsars
        .where()
        .sortBySubmittedAtDesc()
        .findAll();
    return rows.map((row) => row.toDomain()).toList(growable: false);
  }

  /// Network fetch + atomic cache upsert. Returns an [ApiResult] so the
  /// notifier can pattern-match on the failure variants instead of
  /// unwrapping exceptions.
  ///
  /// The write is wrapped in `writeTxn` so an interrupted process
  /// leaves Isar with either the whole new snapshot or the previous
  /// one — never a partial mid-batch state.
  Future<ApiResult<List<JobApplication>>> fetchAndCache() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/applications',
        queryParameters: const {'page': 1, 'pageSize': 100},
      );

      final envelope = response.data;
      if (envelope == null) {
        return const UnknownFailure(
          'CareerHub API returned an empty body for GET /applications.',
        );
      }

      final rawList = envelope['data'] as List<dynamic>;
      final dtos = rawList
          .map((raw) => JobApplicationDto.fromJson(raw as Map<String, dynamic>))
          .toList(growable: false);
      final apps =
          dtos.map(JobApplication.fromDto).toList(growable: false);

      await _writeSnapshotToCache(apps);

      return Success(apps);
    } on DioException catch (e) {
      final message = _messageForDioException(e);
      final statusCode = e.response?.statusCode;
      return statusCode != null
          ? ServerFailure(message: message, statusCode: statusCode)
          : NetworkFailure(message);
    } catch (_) {
      return const UnknownFailure(
        'Something went wrong while loading your applications. '
        'Please try again.',
      );
    }
  }

  /// Wipe-and-replace the cache atomically. The list-endpoint response
  /// is the ground truth for the entire cache — if a row is missing
  /// from the response it has been withdrawn on the server and should
  /// disappear locally too.
  ///
  /// `putBy...` on the unique `uniqueKey` index is what makes the upsert
  /// idempotent within the txn: the row's auto-inc id changes on every
  /// write, but the composite key stays stable.
  Future<void> _writeSnapshotToCache(List<JobApplication> apps) async {
    await _isar.writeTxn(() async {
      await _isar.jobApplicationIsars.clear();
      await _isar.jobApplicationIsars.putAll(
        apps.map(JobApplicationIsar.fromDomain).toList(growable: false),
      );
    });
  }

  /// Public helper the notifier calls on first launch when the API
  /// endpoint isn't wired up yet (see repository comment at the top of
  /// the file). Writes a fixed sample dataset directly to Isar so the
  /// end-to-end demo (list, filter, offline) works today; deleting
  /// this method + its call site is the ONLY change needed once the
  /// backend `GET /applications` endpoint ships.
  Future<void> seedCacheForDemo() async {
    await _writeSnapshotToCache(_demoSeed);
  }

  /// A tiny, focused demo dataset covering every [ApplicationStatus]
  /// value so the filter chips have something to filter on. Dates are
  /// spread over the last three months so the sort-by-date behaviour is
  /// visible.
  static final List<JobApplication> _demoSeed = [
    JobApplication(
      id: JobApplication.compositeId('me', 'seed-1'),
      applicantId: 'me',
      jobListingId: 'seed-1',
      jobTitle: 'Senior Flutter Developer',
      companyName: 'Bitcube',
      submittedAt: DateTime(2026, 7, 12),
      status: ApplicationStatus.submitted,
    ),
    JobApplication(
      id: JobApplication.compositeId('me', 'seed-2'),
      applicantId: 'me',
      jobListingId: 'seed-2',
      jobTitle: 'Backend Engineer',
      companyName: 'Nimbus Systems',
      submittedAt: DateTime(2026, 7, 8),
      status: ApplicationStatus.underReview,
    ),
    JobApplication(
      id: JobApplication.compositeId('me', 'seed-3'),
      applicantId: 'me',
      jobListingId: 'seed-3',
      jobTitle: 'DevOps Engineer',
      companyName: 'Skyforge',
      submittedAt: DateTime(2026, 6, 30),
      status: ApplicationStatus.interviewing,
    ),
    JobApplication(
      id: JobApplication.compositeId('me', 'seed-4'),
      applicantId: 'me',
      jobListingId: 'seed-4',
      jobTitle: 'Product Designer',
      companyName: 'Loop Studio',
      submittedAt: DateTime(2026, 6, 22),
      status: ApplicationStatus.offered,
    ),
    JobApplication(
      id: JobApplication.compositeId('me', 'seed-5'),
      applicantId: 'me',
      jobListingId: 'seed-5',
      jobTitle: 'UX Researcher',
      companyName: 'Meridian Labs',
      submittedAt: DateTime(2026, 6, 10),
      status: ApplicationStatus.hired,
    ),
    JobApplication(
      id: JobApplication.compositeId('me', 'seed-6'),
      applicantId: 'me',
      jobListingId: 'seed-6',
      jobTitle: 'Mobile QA Engineer',
      companyName: 'Fathom Analytics',
      submittedAt: DateTime(2026, 5, 28),
      status: ApplicationStatus.rejected,
    ),
    JobApplication(
      id: JobApplication.compositeId('me', 'seed-7'),
      applicantId: 'me',
      jobListingId: 'seed-7',
      jobTitle: 'Full-stack Developer',
      companyName: 'Sable Cloud',
      submittedAt: DateTime(2026, 5, 15),
      status: ApplicationStatus.underReview,
    ),
    JobApplication(
      id: JobApplication.compositeId('me', 'seed-8'),
      applicantId: 'me',
      jobListingId: 'seed-8',
      jobTitle: 'Site Reliability Engineer',
      companyName: 'Beacon Ops',
      submittedAt: DateTime(2026, 5, 3),
      status: ApplicationStatus.submitted,
    ),
  ];

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
              'Could not find the applications endpoint on the CareerHub server.',
            final int code =>
              'CareerHub returned an unexpected response (status $code).',
            null => 'CareerHub returned an unexpected response.',
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

/// Part 3.3 — reads `dioProvider` and `isarProvider` from the graph
/// rather than constructing new instances. Both dependencies are
/// long-lived singletons, so this provider is `keepAlive: true`.
@Riverpod(keepAlive: true)
ApplicationsRepository applicationsRepository(Ref ref) {
  return ApplicationsRepository(
    dio: ref.watch(dioProvider),
    isar: ref.watch(isarProvider),
  );
}
