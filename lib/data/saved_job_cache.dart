import 'package:isar_community/isar.dart';

// Assignment 2.4 Stretch C — Isar-backed cache of bookmarks.
part 'saved_job_cache.g.dart';

/// Assignment 2.4 Stretch C — the STORAGE representation of a
/// bookmarked job.
///
/// Rules follow the same pattern as `JobCache` (Assignment 2.3,
/// Part 3): every field `late`, `Id id = Isar.autoIncrement`,
/// no `@freezed`, no `fromJson`. The domain-level identifier is
/// the `jobId` string (a Guid) — indexed uniquely so that a
/// double-tap on the bookmark can't insert two rows for the same
/// job.
///
/// `pending` is the flag the connectivity listener reads: `true`
/// means "created offline, not yet POSTed to the server", `false`
/// means "already synced" (either because the save happened
/// online, or because the pending-sync service drained it).
@collection
class SavedJobCache {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String jobId;

  late DateTime savedAt;

  late bool pending;

  /// Optional — set when the row transitions from pending to
  /// synced. Not used by the UI; kept for debugging.
  DateTime? syncedAt;
}
