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
/// salary is, how status is represented — is deliberate. In Week 2 this
/// class gains a `Job.fromJson()` constructor and the shape must not
/// change, so the nullability and typing decisions are locked in now.
class Job {
  /// A stable, unique identifier for this listing (Assignment 1.4).
  ///
  /// This is the ONLY thing a URL like `/jobs/3` is allowed to key on. It
  /// is deliberately NOT the job's position in any list: a list index is a
  /// property of *how the data is currently displayed* (which filter is
  /// active, which sort order, how far the user has scrolled), whereas the
  /// URL must identify *which job* regardless of display state — so that a
  /// push notification, a shared link, or a back-button restore all resolve
  /// to the same listing forever. See README Q3. In Week 2 this maps
  /// directly onto the primary key the backend already assigns.
  final int id;

  /// A listing must have a title — a job with no title is not a job a
  /// seeker could ever meaningfully browse or apply to.
  final String title;

  /// A listing must name the hiring company — an anonymous employer is
  /// not a credible listing on a career platform.
  final String company;

  /// Every role is performed somewhere (including "Remote"), so a seeker
  /// always needs a location to judge fit. Required.
  final String location;

  /// The physical work arrangement — on-site, remote, or hybrid. Required
  /// so the location dropdown filter has an unambiguous truth to match on,
  /// rather than parsing the free-text `location` string.
  final LocationType locationType;

  /// An employer may choose not to disclose salary, so this is optional.
  /// See displaySalary for how the absent case is handled.
  final String? salary;

  /// The nature of the engagement (full-time, contract, etc.) is always
  /// something the employer knows and the seeker needs, so it is required.
  final String employmentType;

  /// A listing without a firm closing date is normal — many roles stay
  /// open until filled — so this is optional.
  final DateTime? closingDate;

  /// A short summary of the role. Draft listings are created before the
  /// full description is written, so this is optional.
  final String? description;

  /// Whether the listing is currently accepting applications. Every job
  /// is definitively either open or not, so this is required and defaults
  /// to open for a freshly posted role.
  final bool isOpen;

  /// Default constructor. Used for a standard, active listing where the
  /// employer supplies whatever fields they have.
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

  /// Named constructor: a listing whose application window has ended.
  ///
  /// Domain scenario: an employer's closing date has passed or they have
  /// filled the role, so the listing must be preserved for the record but
  /// locked against new applications — a state the default constructor
  /// cannot guarantee because it defaults isOpen to true.
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

  /// Named constructor: a remote listing.
  ///
  /// Domain scenario: a fully remote role has no fixed office, so instead
  /// of forcing the poster to type a location string, this constructor
  /// stamps location as "Remote" as an intrinsic property of the state —
  /// something the default constructor cannot encapsulate on its own.
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

  /// True only when a JobSeeker can actually apply. The rule for what
  /// makes a job applicable lives here on the model, not in any widget.
  bool get canApply => isOpen;

  /// The single source of truth for how salary is shown to a user.
  /// Formats the salary when present; returns "Market-related" when the
  /// employer has not disclosed it. Widgets call this and never touch the
  /// raw salary field.
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

  /// Stretch A — returns a new Job with the given fields replaced and all
  /// others copied unchanged. Calling copyWith() with no arguments returns
  /// an equivalent Job. This is auto-generated by the `freezed` package
  /// (introduced Week 2 Day 2).
  ///
  /// Note: because location is intrinsic on a remote job we treat it as a
  /// plain field here; and because salary/closingDate/description are
  /// nullable, copyWith cannot distinguish "leave unchanged" from "set to
  /// null" without sentinels — freezed solves this properly later.
  Job copyWith({
    int? id,
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

  /// Stretch B — case-insensitive search across title, company, location.
  /// This is the filter logic that gets wired to Riverpod state in Day 3.
  bool matches(String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return true;
    return title.toLowerCase().contains(q) ||
        company.toLowerCase().contains(q) ||
        location.toLowerCase().contains(q);
  }
}
