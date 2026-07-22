import 'package:isar_community/isar.dart';

// Assignment 3.1 Stretch C — the part directive for the generator.
// `dart run build_runner build --delete-conflicting-outputs` emits
// `application_draft.g.dart` (the ApplicationDraftSchema, encoders,
// and typed query API). Until that runs the IDE will underline
// `ApplicationDraftSchema` and every `isar.applicationDrafts` deref
// — expected on a fresh checkout. See README 3.1 "build_runner
// note".
part 'application_draft.g.dart';

/// Assignment 3.1 Stretch C — a single-row draft of an in-progress
/// job application saved offline.
///
/// One row per submit attempt while offline. The `id` is an
/// `Isar.autoIncrement` int (not the `jobId`) because the user may
/// draft multiple attempts for the same listing (edit and re-save
/// on connectivity flap); a unique-per-jobId key would clobber the
/// earlier draft.
///
/// Populated by `ApplicationDraftsController.saveDraft` from the
/// two-step FormBuilder's saved value map. Drained (successful
/// submits deleted) on connectivity return by
/// `ApplicationDraftsController.syncPending`, invoked from the
/// jobs screen's `ref.listen<bool>(isOfflineProvider, ...)`
/// callback.
///
/// `savedAt` supports two features: (a) rendering "saved 3 minutes
/// ago" strings on any future draft-review UI, (b) sorting the
/// sync-drain in FIFO order.
@collection
class ApplicationDraft {
  Id id = Isar.autoIncrement;

  late String jobId;

  late String fullName;
  late String email;
  late String coverLetter;
  late int yearsExperience;
  late DateTime startDate;
  late String portfolioUrl;
  late bool terms;

  late DateTime savedAt;
}
