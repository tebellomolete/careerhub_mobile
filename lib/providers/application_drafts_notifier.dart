import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';

import '../core/isar_provider.dart';
import '../data/application_draft.dart';

/// Assignment 3.1 Stretch C — providers and controller for the
/// offline-application-draft queue.
///
/// This file is deliberately hand-written (no `@riverpod`
/// annotation, no `part` directive) — the three providers here are
/// simple derivations over the Isar collection, and the controller
/// has no signature the generator can improve on. Same pattern as
/// `lib/providers/auth_provider.dart`.

/// Live stream of every ApplicationDraft row, keyed by savedAt
/// ascending (oldest first — the sync loop drains in FIFO order).
/// Backed by Isar's `.watch(fireImmediately: true)` so widgets that
/// depend on it repaint the instant any row is inserted or removed.
final StreamProvider<List<ApplicationDraft>> applicationDraftsStreamProvider =
    StreamProvider<List<ApplicationDraft>>((ref) {
  final isar = ref.watch(isarProvider);
  return isar.applicationDrafts
      .where()
      .sortBySavedAt()
      .watch(fireImmediately: true);
});

/// True when at least one draft exists. Widget-level derivation so
/// the banner rebuilds on any collection change without exposing
/// the whole list.
final Provider<bool> hasPendingDraftsProvider = Provider<bool>((ref) {
  final async = ref.watch(applicationDraftsStreamProvider);
  return async.maybeWhen(
    data: (drafts) => drafts.isNotEmpty,
    orElse: () => false,
  );
});

/// Count of pending drafts — surfaced in the banner text.
final Provider<int> pendingDraftsCountProvider = Provider<int>((ref) {
  final async = ref.watch(applicationDraftsStreamProvider);
  return async.maybeWhen(
    data: (drafts) => drafts.length,
    orElse: () => 0,
  );
});

/// The controller lifecycle-owned by the provider. Two entry
/// points:
///
///   - `saveDraft(jobId, values)` — called from `ApplyScreen.submit`
///     when `isOfflineProvider` reports the device is offline.
///     Writes one row to Isar and returns.
///   - `syncPending()` — called from the jobs screen's
///     `ref.listen<bool>(isOfflineProvider, ...)` callback on the
///     `previous == true && next == false` transition. Reads every
///     draft, "attempts" to submit each, deletes the successful
///     ones. The mock server has no `/applications` endpoint, so
///     the fake submit is unconditionally successful — see the
///     failure-case discussion in README 3.1 Stretch C.
final Provider<ApplicationDraftsController>
    applicationDraftsControllerProvider =
    Provider<ApplicationDraftsController>(
  (ref) => ApplicationDraftsController(ref),
);

class ApplicationDraftsController {
  final Ref _ref;

  ApplicationDraftsController(this._ref);

  /// Save the two-step FormBuilder's assembled value map as a
  /// draft. `values` is expected to contain every field the two
  /// FormBuilders together defined; any missing keys default to
  /// safe empty values so a partial write still produces a
  /// well-formed row.
  Future<void> saveDraft(String jobId, Map<String, dynamic> values) async {
    final isar = _ref.read(isarProvider);
    final draft = ApplicationDraft()
      ..jobId = jobId
      ..fullName = (values['full_name'] as String?) ?? ''
      ..email = (values['email'] as String?) ?? ''
      ..coverLetter = (values['cover_letter'] as String?) ?? ''
      ..yearsExperience =
          int.tryParse((values['years_experience'] as String?) ?? '') ?? 0
      ..startDate = (values['start_date'] as DateTime?) ?? DateTime.now()
      ..portfolioUrl = (values['portfolio_url'] as String?) ?? ''
      ..terms = (values['terms'] as bool?) ?? false
      ..savedAt = DateTime.now();

    await isar.writeTxn(() async {
      await isar.applicationDrafts.put(draft);
    });
  }

  /// Drain every pending draft. Called on offline → online
  /// transition. In production the loop would POST each draft to
  /// `/applications`, retain 4xx failures with an error state, and
  /// abort on 5xx / network error to retry on the next
  /// connectivity event; here the mock server has no such
  /// endpoint so the drain is unconditionally successful and
  /// every row is deleted.
  Future<void> syncPending() async {
    final isar = _ref.read(isarProvider);
    final drafts =
        await isar.applicationDrafts.where().sortBySavedAt().findAll();
    if (drafts.isEmpty) return;

    // Delete all successfully "submitted" drafts in one transaction
    // so the Isar watch stream fires once (single banner
    // disappearance), not N times.
    await isar.writeTxn(() async {
      for (final d in drafts) {
        // Where a real API rejected a draft we would call `continue`
        // here; every retained row keeps the banner up.
        await isar.applicationDrafts.delete(d.id);
      }
    });
  }
}
