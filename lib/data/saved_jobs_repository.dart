import 'package:dio/dio.dart';
import 'package:isar_community/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/isar_provider.dart';
import 'jobs_repository.dart';
import 'saved_job_cache.dart';

part 'saved_jobs_repository.g.dart';

/// Assignment 2.4 Stretch C — the repository behind the bookmark
/// icon.
///
/// Three responsibilities:
///   1. `save(jobId)` — persist immediately to Isar (pending or
///      synced depending on whether the server call succeeded),
///      and optimistically report success to the UI.
///   2. `remove(jobId)` — DELETE from the server (best effort)
///      and remove the local row.
///   3. `syncPending()` — walk every `pending == true` row,
///      re-POST each to the server, flip to `pending == false`
///      on 200, and REMOVE the row on 404 (the job listing
///      disappeared, per the stretch spec's failure case).
///
/// The service uses the authenticated `dio` from `dioProvider`
/// so every call carries the current Bearer token via the
/// AuthInterceptor.
@Riverpod(keepAlive: true)
SavedJobsRepository savedJobsRepository(Ref ref) {
  return SavedJobsRepository(
    dio: ref.watch(dioProvider),
    isar: ref.watch(isarProvider),
  );
}

class SavedJobsRepository {
  final Dio _dio;
  final Isar _isar;

  SavedJobsRepository({required Dio dio, required Isar isar})
      : _dio = dio,
        _isar = isar;

  /// Watch the currently-saved set as a stream of `Set<String>`.
  /// Fires on every write against `SavedJobCache`.
  Stream<Set<String>> watchSavedIds() async* {
    yield await _readSavedIds();
    await for (final _ in _isar.savedJobCaches.watchLazy()) {
      yield await _readSavedIds();
    }
  }

  Future<Set<String>> _readSavedIds() async {
    final rows = await _isar.savedJobCaches.where().findAll();
    return rows.map((r) => r.jobId).toSet();
  }

  /// Save a job. Attempts the online POST first; on any failure
  /// falls back to writing a pending row. The return value is
  /// `SaveOutcome.saved` if the server accepted immediately,
  /// `SaveOutcome.queued` if it was written offline, and
  /// `SaveOutcome.notFound` if the server returned 404.
  Future<SaveOutcome> save(String jobId) async {
    // Optimistic local write — pending until confirmed.
    await _writeRow(jobId, pending: true);

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/saved',
        data: {'jobId': jobId},
      );
      if (response.statusCode == 200) {
        await _writeRow(jobId, pending: false, syncedAt: DateTime.now());
        return SaveOutcome.saved;
      }
      return SaveOutcome.queued;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 404) {
        // Server says the job is gone. Remove the optimistic row.
        await _isar.writeTxn(() async {
          await _isar.savedJobCaches.filter().jobIdEqualTo(jobId).deleteAll();
        });
        return SaveOutcome.notFound;
      }
      // Any other error (network, 5xx) — leave the row pending
      // for the sync service to retry later.
      return SaveOutcome.queued;
    }
  }

  /// Remove a bookmark. DELETE is best-effort — a failure just
  /// leaves the server row stale until the next full reconcile.
  Future<void> remove(String jobId) async {
    await _isar.writeTxn(() async {
      await _isar.savedJobCaches.filter().jobIdEqualTo(jobId).deleteAll();
    });
    try {
      await _dio.delete<void>('/saved/$jobId');
    } catch (_) {
      // Ignore — the row is gone locally, which is what the UI
      // cares about.
    }
  }

  /// Drain pending rows on connectivity restore. Called by
  /// PendingSyncService.
  Future<PendingSyncSummary> syncPending() async {
    final pending = await _isar.savedJobCaches
        .filter()
        .pendingEqualTo(true)
        .findAll();

    int synced = 0;
    int removed = 0;
    for (final row in pending) {
      try {
        final response = await _dio.post<Map<String, dynamic>>(
          '/saved',
          data: {'jobId': row.jobId},
        );
        if (response.statusCode == 200) {
          await _writeRow(row.jobId,
              pending: false, syncedAt: DateTime.now());
          synced++;
        }
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          await _isar.writeTxn(() async {
            await _isar.savedJobCaches
                .filter()
                .jobIdEqualTo(row.jobId)
                .deleteAll();
          });
          removed++;
        }
        // 5xx / network: leave for the next drain.
      }
    }
    return PendingSyncSummary(synced: synced, removed: removed);
  }

  Future<void> _writeRow(
    String jobId, {
    required bool pending,
    DateTime? syncedAt,
  }) async {
    await _isar.writeTxn(() async {
      // Unique index with `replace: true` — no manual dedupe needed.
      await _isar.savedJobCaches.put(
        SavedJobCache()
          ..jobId = jobId
          ..savedAt = DateTime.now()
          ..pending = pending
          ..syncedAt = syncedAt,
      );
    });
  }
}

/// The outcome the UI branches on to decide which SnackBar to show.
enum SaveOutcome {
  saved,
  queued,
  notFound,
}

class PendingSyncSummary {
  final int synced;
  final int removed;
  const PendingSyncSummary({required this.synced, required this.removed});
}
