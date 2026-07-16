import 'package:freezed_annotation/freezed_annotation.dart';

// Assignment 2.2, Part 4 — the two part directives freezed +
// json_serializable each require. `job_dto.freezed.dart` holds the
// mixin containing `==`, `hashCode`, `copyWith`, and `toString`;
// `job_dto.g.dart` holds `_$JobDtoFromJson` and `_$JobDtoToJson`,
// which the fromJson factory below delegates to.
//
// Both files are produced by `dart run build_runner build
// --delete-conflicting-outputs` and MUST NOT be edited by hand. Until
// the generator has run at least once, the IDE will show red underlines
// on these two `part` lines and on `_$JobDto`, `_JobDto`, and the
// generated function names below. That is expected. See README 2.2, Q3.
part 'job_dto.freezed.dart';
part 'job_dto.g.dart';

/// Assignment 2.1 → 2.2 — the wire-shape mirror of the CareerHub API's
/// `JobResponse` record (see `CareerHub.Api/DTOs/JobResponse.cs`).
///
/// The DTO is deliberately a 1:1 mirror of the API JSON:
///   - field NAMES match the API exactly (`companyName`, `salaryDisplay`,
///     `postedAt`, `applicationCount`) — this is the ONLY place in the app
///     that ever spells those names,
///   - field TYPES match how `System.Text.Json` serialises the C# record
///     (`Guid` → `String`, `JobType` → enum-string, `DateTime` →
///     ISO-8601 `String`).
///
/// Assignment 2.2 changes:
///   - `class JobDto { ... }` (plain Dart class) is now
///     `@freezed class JobDto with _$JobDto { ... }` — the `==`,
///     `hashCode`, `copyWith`, and `toString` are supplied by the
///     generated mixin, and `fromJson` delegates to the
///     `json_serializable`-generated function in `job_dto.g.dart`.
///   - The hand-written `factory JobDto.fromJson(json) { ... }` body is
///     gone — Freezed + json_serializable read the field declarations
///     below to write it for us. See README 2.2, Q2.
///
/// This class has NO knowledge of the `Job` model, NO Riverpod, and NO
/// Dio import. It is a data-shape only.
@freezed
sealed class JobDto with _$JobDto {
  /// The single `const factory` constructor is what Freezed reads to
  /// generate the private implementation class `_JobDto`, the equality,
  /// and `copyWith`. Because every field is `final` and the constructor
  /// is `const`, `JobDto` is immutable AND canonicalisable — two DTOs
  /// with the same field values compare equal by value, not identity.
  const factory JobDto({
    /// The API's primary key is a `Guid`, serialised as a lowercase-hex
    /// string like `"6e8d9f34-..."`. It travels through the app as a
    /// `String` and is used verbatim as the URL path segment for
    /// `/jobs/:id`. The JSON key is `id`, which matches the Dart field
    /// name — no `@JsonKey(name: ...)` needed.
    required String id,
    required String title,

    /// API JSON key: `companyName`. Flutter's `Job` model calls this
    /// `company` — the rename lives in `Job.fromDto`, not here.
    /// The Dart field name and JSON key already match, so no
    /// `@JsonKey(name: ...)` override is required. See README 2.2, Q2.
    required String companyName,
    required String location,

    /// The API returns a description string on the list endpoint too, so
    /// we can capture it eagerly rather than making a second call per card.
    /// `@Default('')` reproduces the previous hand-written tolerance
    /// for a missing `description` key: Freezed forwards the default
    /// through both `JobDto()` construction AND
    /// `json_serializable`'s generated `fromJson`, so a missing key
    /// yields `''` instead of a runtime type error.
    @Default('') String description,

    /// The API's `JobType` enum comes over as a Pascal-cased String
    /// (`"FullTime"`, `"PartTime"`, `"Contract"`, `"Internship"`) thanks
    /// to `JsonStringEnumConverter` in `Program.cs`. Kept as the raw
    /// string here; the Flutter-friendly re-hyphenation ("Full-time")
    /// is a concern of `Job.fromDto`.
    required String type,

    /// ISO-8601 date-time. Kept as `String` on the DTO because the DTO's
    /// only job is to mirror the wire shape faithfully — parsing to
    /// `DateTime` is a modelling decision that belongs on the way OUT of
    /// the DTO, not here.
    required String postedAt,

    /// A pre-formatted display string. When the employer omitted salary
    /// entirely the API sends the literal `"Salary not specified"` (see
    /// `JobResponse.FromListing`). The Flutter model prefers `null` for
    /// that case so `Job.displaySalary` can render "Market-related";
    /// that translation happens in `Job.fromDto`.
    required String salaryDisplay,

    /// Not currently rendered by any Flutter widget — captured anyway so
    /// the DTO stays a complete mirror of the API. `@Default(0)` keeps
    /// this tolerant of an older API build that omitted the key.
    @Default(0) int applicationCount,
  }) = _JobDto;

  /// The one-line delegation the whole conversion is aimed at. The
  /// generator produces `_$JobDtoFromJson` in `job_dto.g.dart` by
  /// reading the field declarations above and calling the appropriate
  /// `as`-cast / `DateTime.parse` / `int.parse` per type. Renaming or
  /// re-typing any field above regenerates this function automatically
  /// on the next `build_runner` run — no hand-written parse code to
  /// forget to update. See README 2.2, Q2.
  factory JobDto.fromJson(Map<String, dynamic> json) =>
      _$JobDtoFromJson(json);
}
