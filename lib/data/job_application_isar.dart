import 'package:isar_community/isar.dart';

import '../models/job_application.dart';

// W2D3 in-class challenge, Part 2.2 — the Isar generator emits this
// `.g.dart` file (containing the collection schema + adapter code).
// Isar's generator uses `part`; the file exists after
// `dart run build_runner build` has run at least once.
part 'job_application_isar.g.dart';

/// The Isar row-shape for a cached [JobApplication].
///
/// Deliberately a SEPARATE class from the domain [JobApplication]:
///   - the domain model must not import Isar (Assessment Criteria);
///   - the schema has an auto-incrementing `Id` field the domain model
///     has no business owning;
///   - `status` is stored as a **String** (the API's PascalCase wire-form
///     via [ApplicationStatusX.wireName]), because Isar's own enum
///     support conflicts with the "status stored as a string" rule.
///
/// A [uniqueKey] index is added on the composite `applicantId::jobListingId`
/// pair so the cache write can `putBy` in an atomic idempotent manner
/// — re-caching the same application updates the row in place rather
/// than duplicating it.
@Collection()
class JobApplicationIsar {
  /// The auto-incrementing primary key required by Part 2.2. Isar
  /// uses `Isar.autoIncrement` as the sentinel for "assign me one".
  Id id = Isar.autoIncrement;

  /// The composite `${applicantId}::${jobListingId}` — indexed unique
  /// so cache upserts don't duplicate rows for a re-fetched application.
  @Index(unique: true, replace: true)
  late String uniqueKey;

  late String applicantId;
  late String jobListingId;
  late String jobTitle;
  late String companyName;

  /// ISO-8601 seconds since epoch (UTC). Storing the parsed instant
  /// rather than a re-serialised string keeps sort-by-date cheap and
  /// avoids parsing on every cache read.
  late DateTime submittedAt;

  /// PascalCase wire-form (see [ApplicationStatusX.wireName]).
  late String status;

  JobApplicationIsar();

  /// Domain → row. Used by the repository's `fetchAndCache` inside
  /// `writeTxn`.
  factory JobApplicationIsar.fromDomain(JobApplication app) {
    return JobApplicationIsar()
      ..uniqueKey = app.id
      ..applicantId = app.applicantId
      ..jobListingId = app.jobListingId
      ..jobTitle = app.jobTitle
      ..companyName = app.companyName
      ..submittedAt = app.submittedAt
      ..status = app.status.wireName;
  }

  /// Row → domain. Used by the repository's cache-read path. The
  /// composite id is reconstructed via
  /// [JobApplication.compositeId] so cache and network paths produce
  /// values that compare equal.
  JobApplication toDomain() {
    return JobApplication(
      id: JobApplication.compositeId(applicantId, jobListingId),
      applicantId: applicantId,
      jobListingId: jobListingId,
      jobTitle: jobTitle,
      companyName: companyName,
      submittedAt: submittedAt,
      status: ApplicationStatusX.fromWire(status),
    );
  }
}
