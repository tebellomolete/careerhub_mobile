// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jobs_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(dio)
const dioProvider = DioProvider._();

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

final class DioProvider extends $FunctionalProvider<Dio, Dio, Dio>
    with $Provider<Dio> {
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

String _$dioHash() => r'63ea183507ba90325940c052add19b3e8c0e04ac';

/// Assignment 2.1 → 2.3 — the repository provider. Wires the singleton
/// Dio, the singleton Isar instance, and the singleton SharedPreferences
/// instance into [JobsRepository].
///
/// Assignment 2.3 change: this provider now also watches
/// [isarProvider] and [prefsProvider] — both of which are overridden
/// in `main.dart` with real, opened instances before `runApp`. See
/// README 2.3, Part 5.

@ProviderFor(jobsRepository)
const jobsRepositoryProvider = JobsRepositoryProvider._();

/// Assignment 2.1 → 2.3 — the repository provider. Wires the singleton
/// Dio, the singleton Isar instance, and the singleton SharedPreferences
/// instance into [JobsRepository].
///
/// Assignment 2.3 change: this provider now also watches
/// [isarProvider] and [prefsProvider] — both of which are overridden
/// in `main.dart` with real, opened instances before `runApp`. See
/// README 2.3, Part 5.

final class JobsRepositoryProvider
    extends $FunctionalProvider<JobsRepository, JobsRepository, JobsRepository>
    with $Provider<JobsRepository> {
  /// Assignment 2.1 → 2.3 — the repository provider. Wires the singleton
  /// Dio, the singleton Isar instance, and the singleton SharedPreferences
  /// instance into [JobsRepository].
  ///
  /// Assignment 2.3 change: this provider now also watches
  /// [isarProvider] and [prefsProvider] — both of which are overridden
  /// in `main.dart` with real, opened instances before `runApp`. See
  /// README 2.3, Part 5.
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

String _$jobsRepositoryHash() => r'addf946d561648706656b7eb34fa28a9f03e02eb';
