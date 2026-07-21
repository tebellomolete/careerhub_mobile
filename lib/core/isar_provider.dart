import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';

/// Assignment 2.3, Part 4 — the placeholder provider for the single
/// application-scoped [Isar] instance.
///
/// **Why a plain `Provider`, not `@riverpod`.** This provider is *never*
/// read from its own factory — the factory here throws because reading
/// without an override is a bug worth catching loudly. The real instance
/// is produced in `main()` (after `Isar.open()` completes) and injected
/// via `ProviderScope.overrides` using `overrideWithValue`. Code
/// generation would produce a `.g.dart` for a provider that only ever
/// gets replaced at boot, which is unnecessary ceremony.
///
/// **Why throw rather than return `null` or a default.** If the override
/// were forgotten:
///   - Returning `null` (typed as `Isar?`) delays the failure until the
///     first `isar.jobCaches` deref inside the repository, throwing a
///     confusing `_TypeError: type 'Null' is not a subtype of 'Isar'`
///     from a stack frame that names `JobsRepository`, not `main.dart`.
///   - Returning a `late` un-initialised default has the same shape.
///   - Throwing here produces `UnimplementedError` at the exact site
///     that needs to be fixed, naming `isarProvider` and pointing at
///     the override in `main.dart`.
///
/// **When the override takes effect.** `overrideWithValue` is applied
/// the moment the `ProviderScope`'s `ProviderContainer` is constructed
/// — which is inside `ProviderScope.initState`, *before* `runApp`
/// mounts any descendant widget. Every synchronous `ref.watch(isarProvider)`
/// inside a `build()` therefore sees the real, opened [Isar] instance,
/// never this stub. See README 2.3, Q3.
final Provider<Isar> isarProvider = Provider<Isar>(
  (ref) => throw UnimplementedError(
    'isarProvider was read without an override. Override it in main.dart '
    'via `ProviderScope(overrides: [isarProvider.overrideWithValue(isar)])` '
    'before calling runApp — see lib/main.dart.',
  ),
);
