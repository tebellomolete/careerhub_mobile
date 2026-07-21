import 'package:isar_community/isar.dart';

// Assignment 2.3, Part 3 — the Isar code-generator emits `job_cache.g.dart`
// containing the schema descriptor (`JobCacheSchema`) that `Isar.open()`
// consumes, plus the per-field binary encoders/decoders and the typed
// query surface (`isar.jobCaches.where()…`). Until `build_runner` runs
// this line will be underlined red in the IDE — expected, resolves after
// Part 9's build_runner invocation. See README 2.3, Part 3.
part 'job_cache.g.dart';

/// Assignment 2.3, Part 3 — the STORAGE representation of a job.
///
/// This is a THIRD class distinct from [Job] (the domain model) and
/// [JobDto] (the network-boundary shape). It exists solely so Isar has
/// a schema class that satisfies its `@collection` contract, which is
/// mutually exclusive with `@freezed`'s `final`-fields-only contract
/// (see README 2.3, Q1): a single class cannot be both
/// const-immutable-with-final-fields (Freezed's requirement) and
/// mutable-with-late-fields (Isar's requirement), so the storage
/// concern gets its own class.
///
/// Design rules enforced here:
///   1. `@collection` on the class — Isar's schema-generation trigger.
///   2. `Id id = Isar.autoIncrement` — Isar picks the row's primary key
///      on `put`. The domain [Job.id] (a `Guid` String from the API) is
///      stored as an ordinary field (`jobId`) so it round-trips through
///      the cache; conflating it with Isar's numeric primary key would
///      break re-fetches, which do not know the numeric id.
///   3. Every field is `late`, never `final`. Isar's generated bindings
///      hydrate an instance by zero-arg constructing it and then writing
///      each field via its setter; a `final` field has no setter, and a
///      const factory constructor has no zero-arg shape.
///   4. The `LocationType` enum is stored as its `.name` String, because
///      Isar 3.x does not support Dart enums natively (only `bool`,
///      `byte`, `short`, `int`, `float`, `double`, `DateTime`, `String`,
///      and lists of those). The reverse lookup uses a fallback (see
///      `JobsRepository._locationTypeFromName`), not a throw, to
///      survive an enum-rename between the build that wrote the cache
///      and the build that reads it — the whole point of the cache is
///      graceful degradation. See README 2.3, Q2.
///   5. No `@freezed`, no `fromJson`, no `freezed_annotation` import.
///      The conversion methods `_toCache` / `_toJob` live privately on
///      [JobsRepository], one direction each, so neither `Job` nor
///      `JobCache` knows the other exists.
///   6. `DateTime` fields are declared as `DateTime?` and Isar stores
///      them natively — the round-trip is safe against a device-time-
///      zone switch between write and read, which the epoch-int
///      alternative silently corrupts. See README 2.3, Q2.
@collection
class JobCache {
  /// Isar's numeric primary key. Autoincrement is the right choice
  /// because the domain [Job.id] is a `Guid` String, not an int — we
  /// need Isar to invent a primary key it can index on, and we key
  /// re-writes off `clear()` + `putAll()` in the repository rather
  /// than manual id preservation. See README 2.3, Part 5.
  Id id = Isar.autoIncrement;

  /// The domain [Job.id] — the API's `Guid` String. Stored so the
  /// cache row can be converted back into a [Job] whose identity
  /// matches what the network layer produced. Not indexed here
  /// because the cache is small (~100 rows) and every read walks the
  /// full collection; adding `@Index(unique: true)` would guard
  /// against duplicate writes but we already guarantee that with
  /// `clear()` + `putAll()` inside `writeTxn` (Part 5).
  late String jobId;

  late String title;
  late String company;
  late String location;

  /// The `LocationType` enum's `.name` — see class-doc rule 4 above.
  /// Reverse-mapped via `JobsRepository._locationTypeFromName`, which
  /// returns `LocationType.onSite` if the stored value doesn't match
  /// any known member (schema-migration safety).
  late String locationTypeName;

  /// Nullable — an employer may omit salary; the API returns the
  /// literal sentinel `"Salary not specified"` in that case, which
  /// `Job.fromDto` maps to `null`. Kept nullable through the cache so
  /// the round-trip preserves the domain-level null.
  String? salary;

  late String employmentType;

  /// Nullable — the API's list endpoint currently omits `ClosingDate`,
  /// so this field will typically be `null` for API-sourced rows.
  /// Kept as `DateTime?` (not `int?` epoch) for the time-zone-safety
  /// reason in README 2.3, Q2.
  DateTime? closingDate;

  /// Nullable — the API's `description` is a possibly-empty string;
  /// `Job.fromDto` maps the empty string to `null` and this field
  /// preserves that.
  String? description;

  /// The list endpoint only ever returns active listings, so this is
  /// always `true` for API-sourced rows — but hand-constructed test
  /// fixtures (see `test/widget_test.dart`) can produce closed jobs,
  /// so the field is retained on the cache too. Non-nullable in the
  /// domain model, non-nullable here.
  late bool isOpen;

  /// The Stretch-B `@Default('')` field from Assignment 2.2 — a
  /// UI-only note the user types on the detail screen. Never
  /// populated by `Job.fromDto` (the API doesn't send it), but if the
  /// user typed a note before force-closing the app it would be
  /// present on the domain `Job` and must round-trip through the
  /// cache. Non-nullable in the domain model, non-nullable here.
  late String userNote;
}
