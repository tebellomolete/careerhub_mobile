import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/saved_jobs_repository.dart';

part 'saved_jobs_notifier.g.dart';

/// Assignment 2.4 Stretch C — the reactive Set<String> that
/// UI widgets read to determine whether a job is bookmarked.
///
/// Backed by `SavedJobsRepository.watchSavedIds()` which watches
/// the Isar `savedJobCaches` collection. Every write against the
/// collection re-emits, and this stream provider re-derives.
final StreamProvider<Set<String>> savedJobIdsStreamProvider =
    StreamProvider<Set<String>>((ref) {
  final repo = ref.watch(savedJobsRepositoryProvider);
  return repo.watchSavedIds();
});

/// Assignment 2.4 Stretch C — the "mutation controller" the UI
/// invokes to save or remove a bookmark. Returns the outcome so
/// the caller can branch on the SnackBar copy.
@Riverpod(keepAlive: true)
SavedJobsController savedJobsController(Ref ref) {
  return SavedJobsController(ref.watch(savedJobsRepositoryProvider));
}

class SavedJobsController {
  final SavedJobsRepository _repo;
  SavedJobsController(this._repo);

  Future<SaveOutcome> save(String jobId) => _repo.save(jobId);

  Future<void> remove(String jobId) => _repo.remove(jobId);
}
