import '../data/job_dto.dart';

/// How a role is performed physically. A small, closed set of categories
/// the seeker filters by — hybrid is a first-class option (a real modern
/// arrangement), not a derived guess about a Job's `location` string.
enum LocationType {
  onSite,
  remote,
  hybrid,
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
///     mismatch between the API and the model (companyName→company,
///     type→employmentType, salaryDisplay→salary) is resolved here and
///     ONLY here. See README, Q1.
class Job {
  /// A stable, unique identifier for this listing. In Assignment 1.4 this
  /// was an `int`; in Assignment 2.1 it becomes a `String` because the
  /// CareerHub API's primary key is a `Guid`. The type change is
  /// mechanical, but the invariant is the same: this is the ONLY thing a
  /// URL like `/jobs/<guid>` is allowed to key on — never a list index.
  final String id;

  final String title;
  final String company;

  /// Every role is performed somewhere (including "Remote"), so a seeker
  /// always needs a location to judge fit. Required.
  final String location;

  /// The physical work arrangement — on-site, remote, or hybrid.
  ///
  /// Assignment 2.1 note: the CareerHub API has no dedicated locationType
  /// column — it stores only a free-text `location`. `Job.fromDto`
  /// derives this via [inferLocationType]: a case-insensitive substring
  /// check that maps "remote" → remote, "hybrid" → hybrid, and
  /// everything else → onSite. This is a UI concern, not a data
  /// concern, so it lives on the model rather than in the DTO.
  final LocationType locationType;

  /// An employer may choose not to disclose salary. When the API returns
  /// the sentinel `"Salary not specified"`, `Job.fromDto` maps that to
  /// `null` here so `displaySalary` can render "Market-related".
  final String? salary;

  /// The employer-friendly string, e.g. "Full-time" or "Part-time". The
  /// API returns a Pascal-cased enum string (`FullTime`, `PartTime`);
  /// `Job.fromDto` re-hyphenates it via [_typeStringFromApi] so the
  /// widget layer and the existing dropdown labels don't need to know
  /// two spellings for the same value.
  final String employmentType;

  /// Not in the list-endpoint response — the API's `JobResponse` doesn't
  /// currently expose `ClosingDate`. Kept nullable and left `null` for
  /// API-sourced jobs. When we add the detail-endpoint call in a future
  /// assignment (Assignment 2.2+) this can be populated from there.
  final DateTime? closingDate;

  /// A short summary of the role. The API's list endpoint returns a
  /// non-null (possibly empty) description; empty strings pass straight
  /// through, and the detail widget already handles them.
  final String? description;

  /// The API's list endpoint only ever returns ACTIVE listings (see
  /// `JobListingRepository.GetActiveListingsPagedAsync`), so every job
  /// coming from `Job.fromDto` is `isOpen = true`. The field is retained
  /// so hand-constructed fixtures in tests can still model a closed job.
  final bool isOpen;

  const Job({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.locationType,
    this.salary,
    required this.employmentType,
    this.closingDate,
    this.description,
    this.isOpen = true,
  });

  /// A listing whose application window has ended.
  const Job.closed({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.locationType,
    this.salary,
    required this.employmentType,
    this.closingDate,
    this.description,
  }) : isOpen = false;

  /// A fully remote listing.
  const Job.remote({
    required this.id,
    required this.title,
    required this.company,
    this.salary,
    required this.employmentType,
    this.closingDate,
    this.description,
    this.isOpen = true,
  })  : location = 'Remote',
        locationType = LocationType.remote;

  /// Assignment 2.1 — the single translation layer between the API's
  /// wire shape and the app's UI model.
  ///
  /// Every field-name mismatch enumerated in README Q1 is resolved
  /// HERE, and nowhere else. If the API team renames `companyName` to
  /// `employerName` tomorrow, exactly two Flutter files change:
  /// [JobDto.fromJson] (the JSON key) and this factory (the field read).
  /// Not a single screen, widget, provider, or test needs to touch.
  factory Job.fromDto(JobDto dto) {
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
    );
  }

  /// Case-insensitive heuristic on the free-text location field.
  /// Public + static so tests can exercise it independently of the DTO.
  static LocationType inferLocationType(String location) {
    final l = location.toLowerCase();
    if (l.contains('remote')) return LocationType.remote;
    if (l.contains('hybrid')) return LocationType.hybrid;
    return LocationType.onSite;
  }

  /// The API sends the literal sentinel `"Salary not specified"` when
  /// the employer omitted min/max. Mapping that back to `null` lets the
  /// existing `displaySalary` getter render "Market-related" without
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
  static String _typeStringFromApi(String apiType) {
    switch (apiType) {
      case 'FullTime':
        return 'Full-time';
      case 'PartTime':
        return 'Part-time';
      case 'Contract':
        return 'Contract';
      case 'Internship':
        return 'Internship';
      default:
        return apiType;
    }
  }

  bool get canApply => isOpen;

  String get displaySalary {
    final value = salary;
    if (value == null || value.trim().isEmpty) {
      return 'Market-related';
    }
    return value;
  }

  @override
  String toString() {
    return 'Job(id: $id, title: $title, company: $company, '
        'location: $location, locationType: ${locationType.name}, '
        'salary: ${salary ?? '—'}, employmentType: $employmentType, '
        'closingDate: ${closingDate?.toIso8601String() ?? '—'}, '
        'isOpen: $isOpen, canApply: $canApply)';
  }

  Job copyWith({
    String? id,
    String? title,
    String? company,
    String? location,
    LocationType? locationType,
    String? salary,
    String? employmentType,
    DateTime? closingDate,
    String? description,
    bool? isOpen,
  }) {
    return Job(
      id: id ?? this.id,
      title: title ?? this.title,
      company: company ?? this.company,
      location: location ?? this.location,
      locationType: locationType ?? this.locationType,
      salary: salary ?? this.salary,
      employmentType: employmentType ?? this.employmentType,
      closingDate: closingDate ?? this.closingDate,
      description: description ?? this.description,
      isOpen: isOpen ?? this.isOpen,
    );
  }

  /// Case-insensitive search across title, company, location. Used by
  /// [searchQueryProvider]'s composition inside `visibleJobsProvider`.
  bool matches(String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return true;
    return title.toLowerCase().contains(q) ||
        company.toLowerCase().contains(q) ||
        location.toLowerCase().contains(q);
  }
}
