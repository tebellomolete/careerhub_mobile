// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_jobs_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(savedJobsRepository)
const savedJobsRepositoryProvider = SavedJobsRepositoryProvider._();

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

final class SavedJobsRepositoryProvider
    extends
        $FunctionalProvider<
          SavedJobsRepository,
          SavedJobsRepository,
          SavedJobsRepository
        >
    with $Provider<SavedJobsRepository> {
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
  const SavedJobsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'savedJobsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$savedJobsRepositoryHash();

  @$internal
  @override
  $ProviderElement<SavedJobsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SavedJobsRepository create(Ref ref) {
    return savedJobsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SavedJobsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SavedJobsRepository>(value),
    );
  }
}

String _$savedJobsRepositoryHash() =>
    r'fb724c251d69852924cb9bddf0dec134de1e4141';
