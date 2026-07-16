// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jobs_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Assignment 2.1 — the configured Dio instance, exposed through a
/// generated Riverpod provider.

@ProviderFor(dio)
const dioProvider = DioProvider._();

/// Assignment 2.1 — the configured Dio instance, exposed through a
/// generated Riverpod provider.

final class DioProvider extends $FunctionalProvider<Dio, Dio, Dio>
    with $Provider<Dio> {
  /// Assignment 2.1 — the configured Dio instance, exposed through a
  /// generated Riverpod provider.
  const DioProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dioProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dioHash();

  @$internal
  @override
  $ProviderElement<Dio> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Dio create(Ref ref) {
    return dio(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Dio value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Dio>(value),
    );
  }
}

String _$dioHash() => r'4f90e1ca19e25080c2d142f3c317502da628590a';

/// Assignment 2.1 — the repository provider. Wires the singleton Dio
/// into [JobsRepository].

@ProviderFor(jobsRepository)
const jobsRepositoryProvider = JobsRepositoryProvider._();

/// Assignment 2.1 — the repository provider. Wires the singleton Dio
/// into [JobsRepository].

final class JobsRepositoryProvider
    extends $FunctionalProvider<JobsRepository, JobsRepository, JobsRepository>
    with $Provider<JobsRepository> {
  /// Assignment 2.1 — the repository provider. Wires the singleton Dio
  /// into [JobsRepository].
  const JobsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'jobsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$jobsRepositoryHash();

  @$internal
  @override
  $ProviderElement<JobsRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  JobsRepository create(Ref ref) {
    return jobsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(JobsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<JobsRepository>(value),
    );
  }
}

String _$jobsRepositoryHash() => r'1c2a541b1de41cf94b90563bc35664d9d7b01b1c';
