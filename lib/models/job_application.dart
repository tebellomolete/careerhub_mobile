import 'package:freezed_annotation/freezed_annotation.dart';

import '../data/job_application_dto.dart';

// W2D3 in-class challenge, Part 1.3 — Freezed part directive only. There
// is NO `.g.dart` part on the domain model: only [JobApplicationDto]
// reads the wire shape, and this file must not import Isar or any
// networking package (Assessment Criteria).
part 'job_application.freezed.dart';

/// The lifecycle of a job application, mirroring the API's
/// `ApplicationStatus` enum (see
/// `CareerHub.Api/Models/ApplicationStatus.cs`).
///
/// Six values, not four: the brief's checklist ("Pending, Reviewed,
/// Accepted, Rejected") calls for **at least** four values, so the
/// backend's fuller lifecycle is used verbatim to keep the wire shape
/// and the client model in lock-step. Adding a new status server-side
/// forces a compile error in every switch expression that consumes it
/// — see [ApplicationStatusX.displayLabel] and the
/// `ApplicationStatusBadge` widget.
enum ApplicationStatus {
  submitted,
  underReview,
  interviewing,
  offered,
  hired,
  rejected,
}

/// The display-label getter required by Part 1.2. A switch EXPRESSION
/// (not a chain of if/else) so the analyzer verifies every enum value
/// is covered — the same discipline the badge widget applies to its
/// colour mapping.
extension ApplicationStatusX on ApplicationStatus {
  String get displayLabel => switch (this) {
        ApplicationStatus.submitted => 'Submitted',
        ApplicationStatus.underReview => 'Under Review',
        ApplicationStatus.interviewing => 'Interviewing',
        ApplicationStatus.offered => 'Offered',
        ApplicationStatus.hired => 'Hired',
        ApplicationStatus.rejected => 'Rejected',
      };

  /// The API's PascalCase wire-form for this enum value. Used as the
  /// String value stored on the Isar row (Assessment Criteria: status
  /// stored as string in the schema) and as the reverse target for
  /// [ApplicationStatusX.fromWire].
  String get wireName => switch (this) {
        ApplicationStatus.submitted => 'Submitted',
        ApplicationStatus.underReview => 'UnderReview',
        ApplicationStatus.interviewing => 'Interviewing',
        ApplicationStatus.offered => 'Offered',
        ApplicationStatus.hired => 'Hired',
        ApplicationStatus.rejected => 'Rejected',
      };

  /// Reverse mapping from the API's PascalCase wire-form (or the Isar
  /// cached string) back to the enum. Unknown values fall back to
  /// `submitted` so a new server-side value can't crash a running
  /// client — the badge switch will still render, and the next app
  /// release adds the arm.
  static ApplicationStatus fromWire(String raw) => switch (raw) {
        'Submitted' => ApplicationStatus.submitted,
        'UnderReview' => ApplicationStatus.underReview,
        'Interviewing' => ApplicationStatus.interviewing,
        'Offered' => ApplicationStatus.offered,
        'Hired' => ApplicationStatus.hired,
        'Rejected' => ApplicationStatus.rejected,
        _ => ApplicationStatus.submitted,
      };
}

/// The immutable domain model for a single job application.
///
/// Assessment Criteria enforced by this file:
///   - no Isar import (kept in `lib/data/job_application_isar.dart`);
///   - no Dio import (kept in `lib/data/job_application_dto.dart`);
///   - immutable (Freezed final fields, const factory);
///   - identifier, title, company, submitted date, status all present.
///
/// The public identifier is the composite `${applicantId}::${jobListingId}`
/// — the backend's `Application` row is keyed on that pair (no single-column
/// PK exists on the model), so the URL and provider layer treats the
/// composite as an opaque string.
@freezed
sealed class JobApplication with _$JobApplication {
  const JobApplication._();

  const factory JobApplication({
    required String id,
    required String applicantId,
    required String jobListingId,
    required String jobTitle,
    required String companyName,
    required DateTime submittedAt,
    required ApplicationStatus status,
  }) = _JobApplication;

  /// Part 1.4 — the DTO → domain translation. Every wire-shape concern
  /// (string status → enum, string date → DateTime, composite id
  /// construction) lives HERE. The rest of the app never sees a
  /// [JobApplicationDto].
  static JobApplication fromDto(JobApplicationDto dto) {
    return JobApplication(
      id: _compositeId(dto.applicantId, dto.jobListingId),
      applicantId: dto.applicantId,
      jobListingId: dto.jobListingId,
      jobTitle: dto.jobTitle,
      companyName: dto.companyName,
      submittedAt: DateTime.parse(dto.submittedAt),
      status: ApplicationStatusX.fromWire(dto.status),
    );
  }

  /// Composite id builder — public so the repository can rebuild the
  /// same value when constructing a [JobApplication] from an Isar row
  /// (which stores the two component ids separately, not the composite).
  static String compositeId(String applicantId, String jobListingId) =>
      _compositeId(applicantId, jobListingId);

  static String _compositeId(String applicantId, String jobListingId) =>
      '$applicantId::$jobListingId';
}
