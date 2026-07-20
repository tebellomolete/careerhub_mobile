// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'applications_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Part 3.3 — reads `dioProvider` and `isarProvider` from the graph
/// rather than constructing new instances. Both dependencies are
/// long-lived singletons, so this provider is `keepAlive: true`.

@ProviderFor(applicationsRepository)
const applicationsRepositoryProvider = ApplicationsRepositoryProvider._();

/// Part 3.3 — reads `dioProvider` and `isarProvider` from the graph
/// rather than constructing new instances. Both dependencies are
/// long-lived singletons, so this provider is `keepAlive: true`.

final class ApplicationsRepositoryProvider
    extends
        $FunctionalProvider<
          ApplicationsRepository,
          ApplicationsRepository,
          ApplicationsRepository
        >
    with $Provider<ApplicationsRepository> {
  /// Part 3.3 — reads `dioProvider` and `isarProvider` from the graph
  /// rather than constructing new instances. Both dependencies are
  /// long-lived singletons, so this provider is `keepAlive: true`.
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
    r'2a42a9053312d114ae80d70ac1fdaf9ff43f1b82';
