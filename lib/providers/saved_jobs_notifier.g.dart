// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_jobs_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Assignment 2.4 Stretch C — the "mutation controller" the UI
/// invokes to save or remove a bookmark. Returns the outcome so
/// the caller can branch on the SnackBar copy.

@ProviderFor(savedJobsController)
const savedJobsControllerProvider = SavedJobsControllerProvider._();

/// Assignment 2.4 Stretch C — the "mutation controller" the UI
/// invokes to save or remove a bookmark. Returns the outcome so
/// the caller can branch on the SnackBar copy.

final class SavedJobsControllerProvider
    extends
        $FunctionalProvider<
          SavedJobsController,
          SavedJobsController,
          SavedJobsController
        >
    with $Provider<SavedJobsController> {
  /// Assignment 2.4 Stretch C — the "mutation controller" the UI
  /// invokes to save or remove a bookmark. Returns the outcome so
  /// the caller can branch on the SnackBar copy.
  const SavedJobsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'savedJobsControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$savedJobsControllerHash();

  @$internal
  @override
  $ProviderElement<SavedJobsController> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SavedJobsController create(Ref ref) {
    return savedJobsController(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SavedJobsController value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SavedJobsController>(value),
    );
  }
}

String _$savedJobsControllerHash() =>
    r'88bb9f56e1d2af1c8b398bb61bdd040441f05eb7';
