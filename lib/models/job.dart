import 'package:freezed_annotation/freezed_annotation.dart';

import '../data/job_dto.dart';

// Assignment 2.2, Part 5 — the SINGLE part directive Freezed needs.
// There is NO `.g.dart` part for this file because `Job` is never
// deserialised directly from JSON: only `JobDto` reads the wire shape
// (see README 2.2, Q2). Until `build_runner` runs at least once, the
// IDE will underline `_$Job` and `_Job` below. That is expected. See
// README 2.2, Q3.
part 'job.freezed.dart';

/// How a role is performed physically. A small, closed set of categories
/// the seeker filters by — hybrid is a first-class option (a real modern
/// arrangement), not a derived guess about a `Job`'s `location` string.
enum LocationType {
  onSite,
  remote,
  hybrid,
}

/// Assignment 2.2, Part 3 (Step 3.1) — the enum display extension the
/// brief's checklist requires converted to a switch EXPRESSION (single
/// expression body, not a multi-arm switch statement). Used by the
/// filter dropdown label rendering.
extension LocationTypeX on LocationType {
  String get displayName => switch (this) {
        LocationType.onSite => 'On-site',
        LocationType.remote => 'Remote',
        LocationType.hybrid => 'Hybrid',
      };
}

/// The core data entity of CareerHub.
///
/// Every decision in this class — which fields are nullable, what type
/// salary is, how status is represented — is deliberate.
///
/// Assignment 2.1 changes:
///   - `id` is now `String`, not `int`. The CareerHub API's primary key
///     is a `Guid` (see `CareerHub.Api/Models/JobListing.cs`), which
///     serialises as `"6e8d9f34-..."`. Every URL, every provider that
///     keys on job identity, and every test fixture uses that string
///     verbatim.
///   - `Job.fromDto` is the single translation layer from the wire
///     shape (`JobDto`) to this UI-friendly model. Every field-name
///     mismatch between the API and the model (`companyName` → `company`,
///     `type` → `employmentType`, `salaryDisplay` → `salary`) is
///     resolved here and ONLY here. See README 2.1, Q1.
///
/// Assignment 2.2 changes:
///   - `class Job { ... }` is now `@freezed sealed class Job with _$Job
///     { ... }`. The `==`, `hashCode`, `copyWith`, and `toString` are
///     supplied by the generated mixin — two `Job` instances with
///     identical field values now compare EQUAL by value, not by
///     identity (see README 2.2, Q1).
///   - `const Job._()` sits above the `const factory Job(...)` so the
///     hand-written accessors below (`canApply`, `displaySalary`,
///     `matches`) can live on the class body. Without the private
///     constructor, Freezed's mixin would refuse to compile them (see
///     README 2.2, Q3).
///   - `factory Job.fromDto`, `factory Job.closed`, `factory Job.remote`
///     are now `static` methods returning `Job`. Freezed interprets
///     factory constructors on an `@freezed` class as UNION VARIANTS
///     (named shapes of a sealed data type); we do not want three
///     variants here, we want three helpers that build the ONE variant.
///     Call sites (`Job.fromDto(dto)`, `Job.closed(...)`, `Job.remote(...)`)
///     stay syntactically identical. See README 2.2, Q3.
///   - Stretch B — `userNote` is a UI-only field with an `@Default('')`.
///     It is never sent to or read from the API; a `Job` built via
///     `fromDto` always starts with `userNote == ''`. The job detail
///     screen uses `copyWith(userNote: ...)` to produce an edited copy
///     that lives in a `StateProvider<Job?>`, leaving the original job
///     in the list untouched. See README 2.2 Stretch B.
@freezed
sealed class Job with _$Job {
  /// The private, no-argument constructor Freezed's generated mixin
  /// needs to apply itself to this class. Its presence is what lets us
  /// declare instance getters (`canApply`, `displaySalary`) and instance
  /// methods (`matches`) directly on `Job` — without it, any instance
  /// member you write here would be rejected by the mixin's contract.
  /// The `const` matches the factory below so `Job` remains a
  /// canonicalisable const class. See README 2.2, Q3.
  const Job._();

  /// The single `const factory` Freezed reads to generate `_Job`,
  /// `==`, `hashCode`, `copyWith`, and `toString`.
  const factory Job({
    /// A stable, unique identifier for this listing. Assignment 2.1
    /// changed this from `int` to `String` because the CareerHub API's
    /// primary key is a `Guid`. Every URL like `/jobs/<guid>` keys on
    /// this string verbatim — never a list index.
    required String id,
    required String title,
    required String company,

    /// Every role is performed somewhere (including "Remote"), so a
    /// seeker always needs a location to judge fit. Required.
    required String location,

    /// The physical work arrangement — on-site, remote, or hybrid.
    /// The CareerHub API has no dedicated `locationType` column, so
    /// `Job.fromDto` derives this via [inferLocationType].
    required LocationType locationType,

    /// An employer may choose not to disclose salary. When the API
    /// returns the sentinel `"Salary not specified"`, `Job.fromDto`
    /// maps that to `null` here so `displaySalary` can render
    /// "Market-related".
    String? salary,

    /// The employer-friendly string, e.g. "Full-time" or "Part-time".
    /// `Job.fromDto` re-hyphenates the API's Pascal-cased enum string
    /// via `_typeStringFromApi`.
    required String employmentType,

    /// Not in the list-endpoint response — the API's `JobResponse`
    /// doesn't currently expose `ClosingDate`. Left `null` for
    /// API-sourced jobs.
    DateTime? closingDate,

    /// A short summary of the role. The API's list endpoint returns
    /// a non-null (possibly empty) description; empty strings pass
    /// straight through, and the detail widget already handles them.
    String? description,

    /// The API's list endpoint only ever returns ACTIVE listings, so
    /// every job coming from `Job.fromDto` is `isOpen = true`. The
    /// field is retained so hand-constructed fixtures in tests can
    /// still model a closed job.
    @Default(true) bool isOpen,

    /// Stretch B — a UI-only field.
    ///
    /// Never populated by `Job.fromDto` because the API doesn't send
    /// it: `@Default('')` supplies the value at CONSTRUCTION time when
    /// the caller omits the argument, which `fromDto` always does. The
    /// job detail screen produces an EDITED `Job` via
    /// `original.copyWith(userNote: text)` and stores it in a
    /// `StateProvider<Job?>` (see `editedJobProvider` in
    /// `lib/providers/job_providers.dart`) — the original `Job` in the
    /// list is never mutated.
    ///
    /// Contrast with hand-writing `String userNote = ''` on a plain
    /// class constructor: `@Default` places the fallback INSIDE the
    /// Freezed factory's generated implementation, so the value is
    /// applied uniformly whether you build a `Job` directly, through
    /// `copyWith`, or via any future variant. See README 2.2, Stretch B.
    @Default('') String userNote,
  }) = _Job;

  // ─────────────────────────────────────────────────────────────────────
  // Static factory helpers — previously named constructors
  // (`Job.fromDto`, `Job.closed`, `Job.remote`). Freezed reserves
  // `factory` constructors on an `@freezed` class for UNION variants;
  // converting these to `static` methods returning `Job` preserves the
  // call-site syntax (`Job.foo(...)`) without triggering that behaviour.
  // ─────────────────────────────────────────────────────────────────────

  /// Assignment 2.1 → 2.2 — the single translation layer between the
  /// API's wire shape and the app's UI model.
  ///
  /// Every field-name mismatch enumerated in README 2.1 Q1 is resolved
  /// HERE, and nowhere else. If the API team renames `companyName` to
  /// `employerName` tomorrow, exactly two Flutter files change:
  /// [JobDto] (the JSON field declaration) and this method (the field
  /// read). Not a single screen, widget, provider, or test needs to
  /// touch. See README 2.2, Q2.
  ///
  /// Assignment 2.2 note: the method body is unchanged from Assignment
  /// 2.1 — only the keyword `factory` was swapped for `static`. Call
  /// sites like `Job.fromDto(dto)` are syntactically identical.
  static Job fromDto(JobDto dto) {
    return Job(
      id: dto.id,
      title: dto.title,
      company: dto.companyName,
      location: dto.location,
      locationType: inferLocationType(dto.location),
      salary: _salaryFromApi(dto.salaryDisplay),
      employmentType: _typeStringFromApi(dto.type),
      // Not in the list-endpoint response — see field comment above.
      closingDate: null,
      description: dto.description.isEmpty ? null : dto.description,
      // The list endpoint only returns active listings.
      isOpen: true,
      // Stretch B — always the default. `fromDto` never accepts a
      // note from the API because the API doesn't send one. See
      // README 2.2, Stretch B.
    );
  }

  /// A listing whose application window has ended. Was a named
  /// constructor in Assignment 2.1; is a static helper in 2.2 for the
  /// reason described in the static-helpers header above.
  static Job closed({
    required String id,
    required String title,
    required String company,
    required String location,
    required LocationType locationType,
    String? salary,
    required String employmentType,
    DateTime? closingDate,
    String? description,
  }) {
    return Job(
      id: id,
      title: title,
      company: company,
      location: location,
      locationType: locationType,
      salary: salary,
      employmentType: employmentType,
      closingDate: closingDate,
      description: description,
      isOpen: false,
    );
  }

  /// A fully remote listing. Was a named constructor in Assignment 2.1;
  /// is a static helper in 2.2 for the reason described in the
  /// static-helpers header above.
  static Job remote({
    required String id,
    required String title,
    required String company,
    String? salary,
    required String employmentType,
    DateTime? closingDate,
    String? description,
    bool isOpen = true,
  }) {
    return Job(
      id: id,
      title: title,
      company: company,
      location: 'Remote',
      locationType: LocationType.remote,
      salary: salary,
      employmentType: employmentType,
      closingDate: closingDate,
      description: description,
      isOpen: isOpen,
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Static pure helpers preserved from Assignment 2.1. `inferLocationType`
  // and `_typeStringFromApi` have been rewritten to use Dart 3 switch
  // EXPRESSIONS (Part 3, Steps 3.1 and 3.2) — behaviour is unchanged.
  // ─────────────────────────────────────────────────────────────────────

  /// Case-insensitive heuristic on the free-text `location` field.
  /// Public + static so tests can exercise it independently of the DTO.
  ///
  /// Assignment 2.2, Part 3 Step 3.2 — the previous `if`-chain is now a
  /// SWITCH EXPRESSION WITH GUARD CLAUSES. `_` is the wildcard pattern
  /// and `when` attaches a boolean condition to that arm, so the
  /// analyzer verifies exhaustiveness AND the intent (‘match any string
  /// where the lowered form contains …’) is spelled out on one line.
  /// See README 2.2, Part 3.
  static LocationType inferLocationType(String location) {
    final l = location.toLowerCase();
    return switch (l) {
      _ when l.contains('remote') => LocationType.remote,
      _ when l.contains('hybrid') => LocationType.hybrid,
      _ => LocationType.onSite,
    };
  }

  /// The API sends the literal sentinel `"Salary not specified"` when
  /// the employer omitted min/max. Mapping that back to `null` lets the
  /// existing [displaySalary] getter render "Market-related" without
  /// widget-level knowledge of the sentinel.
  static String? _salaryFromApi(String salaryDisplay) {
    if (salaryDisplay.trim().isEmpty) return null;
    if (salaryDisplay == 'Salary not specified') return null;
    return salaryDisplay;
  }

  /// `FullTime`/`PartTime` → `Full-time`/`Part-time`; the two already
  /// hyphen-free values (`Contract`, `Internship`) pass through.
  /// Matches the labels on `JobTypeFilter` so dropdown equality still
  /// works without a mapping layer.
  ///
  /// Assignment 2.2, Part 3 Step 3.1 — converted from a multi-arm
  /// `switch` statement to a single-expression `switch`. The analyzer
  /// reports the expression as exhaustive because the `_` default arm
  /// covers every remaining String value.
  static String _typeStringFromApi(String apiType) => switch (apiType) {
        'FullTime' => 'Full-time',
        'PartTime' => 'Part-time',
        'Contract' => 'Contract',
        'Internship' => 'Internship',
        _ => apiType,
      };

  // ─────────────────────────────────────────────────────────────────────
  // Instance members preserved from Assignment 2.1. These require
  // `const Job._()` above the factory (see README 2.2, Q3).
  // `toString` and `copyWith` are NOT declared here — Freezed's mixin
  // generates both.
  // ─────────────────────────────────────────────────────────────────────

  bool get canApply => isOpen;

  String get displaySalary {
    final value = salary;
    if (value == null || value.trim().isEmpty) {
      return 'Market-related';
    }
    return value;
  }

  /// Case-insensitive search across title, company, location. Used by
  /// `searchQueryProvider`'s composition inside `visibleJobsProvider`.
  bool matches(String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return true;
    return title.toLowerCase().contains(q) ||
        company.toLowerCase().contains(q) ||
        location.toLowerCase().contains(q);
  }
}
