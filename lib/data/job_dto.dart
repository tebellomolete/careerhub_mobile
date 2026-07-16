/// Assignment 2.1 — the wire-shape mirror of the CareerHub API's
/// `JobResponse` record (see CareerHub.Api/DTOs/JobResponse.cs).
///
/// The DTO is deliberately a 1:1 mirror of the API JSON:
///   - field NAMES match the API exactly (companyName, salaryDisplay,
///     postedAt, applicationCount) — this is the ONLY place in the app
///     that ever spells those names,
///   - field TYPES match how System.Text.Json serialises the C# record
///     (Guid → String, JobType → enum-string, DateTime → ISO-8601 String).
///
/// The DTO captures EVERY field the API returns — including
/// `postedAt` and `applicationCount`, which the Flutter `Job` model does
/// not currently display. Capturing them here is deliberate: the field
/// list is dirt-cheap to type in this file, and having the wire
/// representation complete means a UI story six months from now
/// ("show me the number of applicants on the card") is a one-line
/// mapping in `Job.fromDto`, not a DTO change + a regeneration + a code
/// review. See README, Q1.
///
/// This class has NO knowledge of the `Job` model, NO Riverpod, and NO
/// Dio import. It is a data-shape only.
class JobDto {
  /// The API's primary key is a `Guid`, serialised as a lowercase-hex
  /// string like `"6e8d9f34-..."`. It travels through the app as a
  /// String and is used verbatim as the URL path segment for `/jobs/:id`.
  final String id;

  final String title;

  /// The API's spelling: `companyName`. The Flutter model calls this
  /// `company` — the rename lives in `Job.fromDto`, not here. See README, Q1.
  final String companyName;

  final String location;

  /// The API returns a description string on the list endpoint too, so
  /// we can capture it eagerly rather than making a second call per card.
  final String description;

  /// The API's `JobType` enum comes over as a Pascal-cased String —
  /// `"FullTime"`, `"PartTime"`, `"Contract"`, `"Internship"` — thanks
  /// to `JsonStringEnumConverter` in Program.cs. Kept as the raw string
  /// here; the Flutter-friendly re-hyphenation ("Full-time") is a
  /// concern of `Job.fromDto`.
  final String type;

  /// ISO-8601 date-time. Kept as String on the DTO because the DTO's
  /// only job is to mirror the wire shape faithfully — parsing to
  /// `DateTime` is a modelling decision that belongs on the way OUT of
  /// the DTO, not here.
  final String postedAt;

  /// A pre-formatted display string. When the employer omitted salary
  /// entirely, the API sends the literal string `"Salary not specified"`
  /// (see `JobResponse.FromListing`). The Flutter model prefers `null`
  /// for that case so `Job.displaySalary` can render "Market-related";
  /// that translation happens in `Job.fromDto`.
  final String salaryDisplay;

  /// Not currently rendered by any Flutter widget — captured anyway so
  /// the DTO stays a complete mirror of the API. See the class-level
  /// note above and README Q1.
  final int applicationCount;

  const JobDto({
    required this.id,
    required this.title,
    required this.companyName,
    required this.location,
    required this.description,
    required this.type,
    required this.postedAt,
    required this.salaryDisplay,
    required this.applicationCount,
  });

  /// Reads the raw JSON map produced by Dio's default JSON decoder.
  /// Field names here MUST match the API's casing — because System.Text
  /// .Json's default policy in ASP.NET Core is camelCase, the wire
  /// spelling of `Id` is `id`, `CompanyName` is `companyName`, etc.
  ///
  /// Uses `as` casts (not `as?`) for required fields: a malformed
  /// response should throw loudly and let the AsyncNotifier's error
  /// state surface it, not silently produce a half-populated DTO with
  /// empty strings that the UI would render as blanks.
  factory JobDto.fromJson(Map<String, dynamic> json) {
    return JobDto(
      id: json['id'] as String,
      title: json['title'] as String,
      companyName: json['companyName'] as String,
      location: json['location'] as String,
      // `description` is non-nullable on the C# record, but the DB
      // column is `string.Empty` by default — coerce a missing key to
      // empty rather than throwing, since an empty description is a
      // valid domain state that `Job.description` already handles.
      description: (json['description'] as String?) ?? '',
      type: json['type'] as String,
      postedAt: json['postedAt'] as String,
      salaryDisplay: json['salaryDisplay'] as String,
      applicationCount: (json['applicationCount'] as num?)?.toInt() ?? 0,
    );
  }
}
