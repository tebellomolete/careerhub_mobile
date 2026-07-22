// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Assignment 2.4, Part 4 — the AuthRepository provider.
///
/// **Why this creates its own Dio, and not `ref.watch(dioProvider)`.**
/// Reusing the authenticated `dioProvider` here would route the
/// login and refresh calls through `AuthInterceptor`. A 401 on
/// `/refresh` would then trigger the interceptor to attempt
/// another refresh, which would 401 again — the exact infinite
/// loop described in README 2.4, Q3. This provider therefore
/// constructs a **plain Dio** with only `baseUrl` set and NO
/// interceptors attached.
///
/// `keepAlive: true` because the repository holds a
/// `FlutterSecureStorage` instance and there's no benefit to
/// tearing it down between UI transitions.

@ProviderFor(authRepository)
const authRepositoryProvider = AuthRepositoryProvider._();

/// Assignment 2.4, Part 4 — the AuthRepository provider.
///
/// **Why this creates its own Dio, and not `ref.watch(dioProvider)`.**
/// Reusing the authenticated `dioProvider` here would route the
/// login and refresh calls through `AuthInterceptor`. A 401 on
/// `/refresh` would then trigger the interceptor to attempt
/// another refresh, which would 401 again — the exact infinite
/// loop described in README 2.4, Q3. This provider therefore
/// constructs a **plain Dio** with only `baseUrl` set and NO
/// interceptors attached.
///
/// `keepAlive: true` because the repository holds a
/// `FlutterSecureStorage` instance and there's no benefit to
/// tearing it down between UI transitions.

final class AuthRepositoryProvider
    extends $FunctionalProvider<AuthRepository, AuthRepository, AuthRepository>
    with $Provider<AuthRepository> {
  /// Assignment 2.4, Part 4 — the AuthRepository provider.
  ///
  /// **Why this creates its own Dio, and not `ref.watch(dioProvider)`.**
  /// Reusing the authenticated `dioProvider` here would route the
  /// login and refresh calls through `AuthInterceptor`. A 401 on
  /// `/refresh` would then trigger the interceptor to attempt
  /// another refresh, which would 401 again — the exact infinite
  /// loop described in README 2.4, Q3. This provider therefore
  /// constructs a **plain Dio** with only `baseUrl` set and NO
  /// interceptors attached.
  ///
  /// `keepAlive: true` because the repository holds a
  /// `FlutterSecureStorage` instance and there's no benefit to
  /// tearing it down between UI transitions.
  const AuthRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authRepositoryHash();

  @$internal
  @override
  $ProviderElement<AuthRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthRepository create(Ref ref) {
    return authRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthRepository>(value),
    );
  }
}

String _$authRepositoryHash() => r'cceefc47168da29488ee8c1dcd2eebf94f3885cb';
