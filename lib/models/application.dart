/// Assignment 3.3, Part 4/5/6 scaffolding — the Application domain
/// model.
///
/// The .NET backend's `Application` entity carries a `Status` enum
/// (`Submitted`, `UnderReview`, `Interviewing`, `Offered`, `Hired`,
/// `Rejected`), an `ApplicantId`, a `JobListingId`, a `SubmittedAt`
/// timestamp, and the navigation properties (Applicant, JobListing).
/// The Flutter side mirrors the enum verbatim so the SignalR
/// `ApplicationStatusUpdated` event's status field decodes without a
/// second translation layer.
///
/// Kept as a plain (non-`@freezed`) class because there is no
/// build-runner benefit — no JSON deserialisation is delegated to a
/// generated helper (`fromJson` is hand-written to keep the shape
/// tolerant of the backend's `PascalCase` DTO field names), and
/// `copyWith` / equality are not called anywhere in the Assignment 3.3
/// flow. If Stretch C or a future assignment starts calling `copyWith`
/// on this model, promoting to `@freezed` is a one-file change.
library;

enum ApplicationStatus {
  submitted,
  underReview,
  interviewing,
  offered,
  hired,
  rejected,
}

extension ApplicationStatusX on ApplicationStatus {
  /// Human-readable label for widgets. Also used as the value written
  /// to `Semantics(label:)` on the status indicator (Part 8) so
  /// TalkBack reads out "Interviewing" instead of the enum's `.name`.
  String get displayName => switch (this) {
        ApplicationStatus.submitted => 'Submitted',
        ApplicationStatus.underReview => 'Under review',
        ApplicationStatus.interviewing => 'Interviewing',
        ApplicationStatus.offered => 'Offered',
        ApplicationStatus.hired => 'Hired',
        ApplicationStatus.rejected => 'Rejected',
      };
}

/// The Application domain object.
///
/// `jobTitle` is nullable because the backend's `GET .../applicants/{id}`
/// response shape (`ApplicationResponse`) does not currently include
/// the job title; the aspirational `GET /applications` endpoint that
/// Assignment 3.3's `/applications` screen consumes is expected to
/// include it. The nullable typing lets the current in-app UI
/// gracefully render "Untitled listing" until the endpoint ships.
class Application {
  final String id;
  final String jobId;
  final String? jobTitle;
  final ApplicationStatus status;
  final DateTime submittedAt;

  const Application({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.status,
    required this.submittedAt,
  });

  /// Decode from the backend JSON shape. The `.NET` API serialises
  /// enum values as either strings (`"Submitted"`) or integers (0..5),
  /// depending on the serializer configuration. This decoder accepts
  /// both so the client keeps working across a backend serializer
  /// change without a coordinated Flutter release.
  factory Application.fromJson(Map<String, dynamic> json) {
    return Application(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      jobId: (json['jobListingId'] ??
              json['JobListingId'] ??
              json['jobId'] ??
              json['JobId'] ??
              '')
          .toString(),
      jobTitle: (json['jobTitle'] ?? json['JobTitle']) as String?,
      status: _parseStatus(json['status'] ?? json['Status']),
      submittedAt: _parseDate(json['submittedAt'] ?? json['SubmittedAt']),
    );
  }

  static ApplicationStatus _parseStatus(dynamic raw) {
    if (raw is int) {
      // Same declaration order as the .NET enum:
      //   Submitted=0, UnderReview=1, Interviewing=2, Offered=3,
      //   Hired=4, Rejected=5.
      if (raw >= 0 && raw < ApplicationStatus.values.length) {
        return ApplicationStatus.values[raw];
      }
      return ApplicationStatus.submitted;
    }
    if (raw is String) {
      return switch (raw.toLowerCase()) {
        'submitted' => ApplicationStatus.submitted,
        'underreview' || 'under_review' || 'under-review' =>
          ApplicationStatus.underReview,
        'interviewing' => ApplicationStatus.interviewing,
        'offered' => ApplicationStatus.offered,
        'hired' => ApplicationStatus.hired,
        'rejected' => ApplicationStatus.rejected,
        _ => ApplicationStatus.submitted,
      };
    }
    return ApplicationStatus.submitted;
  }

  static DateTime _parseDate(dynamic raw) {
    if (raw is String) {
      return DateTime.tryParse(raw) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
