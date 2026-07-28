// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'applications_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Assignment 3.3 scaffolding — the ApplicationsRepository provider.
///
/// Uses `ref.watch(dioProvider)` so the authenticated Dio client (with
/// `AuthInterceptor` attached) is what makes the call — every request
/// this repository issues carries the Bearer token automatically, and
/// a 401 that survives the interceptor's refresh flow surfaces here
/// as a `DioException` with `statusCode == 401` for the Part 4/5 401
/// mapping and automatic logout.

@ProviderFor(applicationsRepository)
const applicationsRepositoryProvider = ApplicationsRepositoryProvider._();

/// Assignment 3.3 scaffolding — the ApplicationsRepository provider.
///
/// Uses `ref.watch(dioProvider)` so the authenticated Dio client (with
/// `AuthInterceptor` attached) is what makes the call — every request
/// this repository issues carries the Bearer token automatically, and
/// a 401 that survives the interceptor's refresh flow surfaces here
/// as a `DioException` with `statusCode == 401` for the Part 4/5 401
/// mapping and automatic logout.

final class ApplicationsRepositoryProvider
    extends
        $FunctionalProvider<
          ApplicationsRepository,
          ApplicationsRepository,
          ApplicationsRepository
        >
    with $Provider<ApplicationsRepository> {
  /// Assignment 3.3 scaffolding — the ApplicationsRepository provider.
  ///
  /// Uses `ref.watch(dioProvider)` so the authenticated Dio client (with
  /// `AuthInterceptor` attached) is what makes the call — every request
  /// this repository issues carries the Bearer token automatically, and
  /// a 401 that survives the interceptor's refresh flow surfaces here
  /// as a `DioException` with `statusCode == 401` for the Part 4/5 401
  /// mapping and automatic logout.
  const ApplicationsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'applicationsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$applicationsRepositoryHash();

  @$internal
  @override
  $ProviderElement<ApplicationsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ApplicationsRepository create(Ref ref) {
    return applicationsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ApplicationsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ApplicationsRepository>(value),
    );
  }
}

String _$applicationsRepositoryHash() =>
    r'79459ff9ccc9e5d93b355d0785a0b5c7aed6bd0c';
