// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Assignment 2.4, Part 8.1 — the router provider.
///
/// The redirect callback uses `ref.read`, NOT `ref.watch`,
/// because a `watch` inside the callback would create a fresh
/// subscription on every route resolution and drive the app into
/// the infinite navigation loop analysed in README 2.4, Q2
/// (third bullet). The `ref.watch(authStateListenableProvider)`
/// at the top of this function body is correct because it fires
/// exactly once per router construction and pushes the
/// `Listenable` into GoRouter's `refreshListenable` — a
/// push-based signal that does not consult `ref.watch` at
/// callback time.

@ProviderFor(appRouter)
const appRouterProvider = AppRouterProvider._();

/// Assignment 2.4, Part 8.1 — the router provider.
///
/// The redirect callback uses `ref.read`, NOT `ref.watch`,
/// because a `watch` inside the callback would create a fresh
/// subscription on every route resolution and drive the app into
/// the infinite navigation loop analysed in README 2.4, Q2
/// (third bullet). The `ref.watch(authStateListenableProvider)`
/// at the top of this function body is correct because it fires
/// exactly once per router construction and pushes the
/// `Listenable` into GoRouter's `refreshListenable` — a
/// push-based signal that does not consult `ref.watch` at
/// callback time.

final class AppRouterProvider
    extends $FunctionalProvider<GoRouter, GoRouter, GoRouter>
    with $Provider<GoRouter> {
  /// Assignment 2.4, Part 8.1 — the router provider.
  ///
  /// The redirect callback uses `ref.read`, NOT `ref.watch`,
  /// because a `watch` inside the callback would create a fresh
  /// subscription on every route resolution and drive the app into
  /// the infinite navigation loop analysed in README 2.4, Q2
  /// (third bullet). The `ref.watch(authStateListenableProvider)`
  /// at the top of this function body is correct because it fires
  /// exactly once per router construction and pushes the
  /// `Listenable` into GoRouter's `refreshListenable` — a
  /// push-based signal that does not consult `ref.watch` at
  /// callback time.
  const AppRouterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appRouterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appRouterHash();

  @$internal
  @override
  $ProviderElement<GoRouter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GoRouter create(Ref ref) {
    return appRouter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoRouter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoRouter>(value),
    );
  }
}

String _$appRouterHash() => r'c60b4e31f3207b4d6ca901ec177959195afef353';
