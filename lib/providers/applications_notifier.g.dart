// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'applications_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Part 4.1 — the cache-then-network AsyncNotifier.
///
/// `build()`:
///   1. reads Isar synchronously w.r.t. the network via
///      `repo.readCache()`;
///   2. if the cache is non-empty, calls `state = AsyncData(cached)`
///      immediately so the UI leaves the loading spinner on the very
///      first frame after the notifier is watched;
///   3. `await`s the network fetch;
///   4. on success returns the fresh list (which replaces the state);
///   5. on failure with a NON-empty cache returns the cache instead
///      of throwing — the user must see data, not an error screen.
///
/// The "seed on empty" behaviour lives HERE (not in the repository)
/// because the repository is a stateless adapter and the "did the
/// initial fetch fail with nothing cached yet" decision is a
/// notifier-level policy — deleting it once the backend endpoint ships
/// is a one-file change.

@ProviderFor(ApplicationsNotifier)
const applicationsProvider = ApplicationsNotifierProvider._();

/// Part 4.1 — the cache-then-network AsyncNotifier.
///
/// `build()`:
///   1. reads Isar synchronously w.r.t. the network via
///      `repo.readCache()`;
///   2. if the cache is non-empty, calls `state = AsyncData(cached)`
///      immediately so the UI leaves the loading spinner on the very
///      first frame after the notifier is watched;
///   3. `await`s the network fetch;
///   4. on success returns the fresh list (which replaces the state);
///   5. on failure with a NON-empty cache returns the cache instead
///      of throwing — the user must see data, not an error screen.
///
/// The "seed on empty" behaviour lives HERE (not in the repository)
/// because the repository is a stateless adapter and the "did the
/// initial fetch fail with nothing cached yet" decision is a
/// notifier-level policy — deleting it once the backend endpoint ships
/// is a one-file change.
final class ApplicationsNotifierProvider
    extends $AsyncNotifierProvider<ApplicationsNotifier, List<JobApplication>> {
  /// Part 4.1 — the cache-then-network AsyncNotifier.
  ///
  /// `build()`:
  ///   1. reads Isar synchronously w.r.t. the network via
  ///      `repo.readCache()`;
  ///   2. if the cache is non-empty, calls `state = AsyncData(cached)`
  ///      immediately so the UI leaves the loading spinner on the very
  ///      first frame after the notifier is watched;
  ///   3. `await`s the network fetch;
  ///   4. on success returns the fresh list (which replaces the state);
  ///   5. on failure with a NON-empty cache returns the cache instead
  ///      of throwing — the user must see data, not an error screen.
  ///
  /// The "seed on empty" behaviour lives HERE (not in the repository)
  /// because the repository is a stateless adapter and the "did the
  /// initial fetch fail with nothing cached yet" decision is a
  /// notifier-level policy — deleting it once the backend endpoint ships
  /// is a one-file change.
  const ApplicationsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'applicationsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$applicationsNotifierHash();

  @$internal
  @override
  ApplicationsNotifier create() => ApplicationsNotifier();
}

String _$applicationsNotifierHash() =>
    r'c5bc208dbdf53bfb123a92b3c04558df90325b5e';

/// Part 4.1 — the cache-then-network AsyncNotifier.
///
/// `build()`:
///   1. reads Isar synchronously w.r.t. the network via
///      `repo.readCache()`;
///   2. if the cache is non-empty, calls `state = AsyncData(cached)`
///      immediately so the UI leaves the loading spinner on the very
///      first frame after the notifier is watched;
///   3. `await`s the network fetch;
///   4. on success returns the fresh list (which replaces the state);
///   5. on failure with a NON-empty cache returns the cache instead
///      of throwing — the user must see data, not an error screen.
///
/// The "seed on empty" behaviour lives HERE (not in the repository)
/// because the repository is a stateless adapter and the "did the
/// initial fetch fail with nothing cached yet" decision is a
/// notifier-level policy — deleting it once the backend endpoint ships
/// is a one-file change.

abstract class _$ApplicationsNotifier
    extends $AsyncNotifier<List<JobApplication>> {
  FutureOr<List<JobApplication>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref
            as $Ref<AsyncValue<List<JobApplication>>, List<JobApplication>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<JobApplication>>,
                List<JobApplication>
              >,
              AsyncValue<List<JobApplication>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
