import 'package:flutter_test/flutter_test.dart';

import 'package:careerhub_mobile/models/job.dart';

/// Assignment 2.2, Stretch A — value-equality unit tests for the
/// Freezed-generated `Job`.
///
/// This file deliberately does NOT import any Flutter widget code:
/// only `flutter_test` (for the `test`/`expect` matchers) and the
/// model file itself. The point is to prove that value equality is a
/// property of the MODEL, independent of Riverpod, the widget tree,
/// or any test scaffolding.
///
/// Set membership test — the SECOND checkpoint in the brief — is the
/// interesting one: a `Set` uses `hashCode` FIRST to pick a bucket
/// and `==` SECOND to break ties. Under identity equality (the
/// Assignment 2.1 shape of `Job`) each of the five instances hashes
/// differently, so the Set would hold FIVE entries even though every
/// field matched. With Freezed's generated `hashCode` (derived from
/// the field values), all five hash to the same bucket, `==` reports
/// them equal, and the Set collapses to ONE entry. See README 2.2,
/// Stretch A.
void main() {
  group('Job value equality (Assignment 2.2, Stretch A)', () {
    Job sampleJob({String id = 'job-1'}) => Job(
          id: id,
          title: 'Flutter Developer',
          company: 'Bitcube',
          location: 'Cape Town, ZA',
          locationType: LocationType.onSite,
          salary: 'R55 000 – R75 000 per month',
          employmentType: 'Full-time',
          closingDate: DateTime(2026, 8, 15),
          description: 'Build production apps.',
          isOpen: true,
        );

    test('two Job instances with identical field values are equal and '
        'share a hashCode', () {
      final a = sampleJob();
      final b = sampleJob();

      // Sanity check — two constructor calls DO produce distinct
      // instances at the memory level. Without Freezed, identical(a, b)
      // and a == b would give the SAME answer (both false). Freezed
      // decouples the two: identity is still false, value equality
      // is true.
      expect(identical(a, b), isFalse,
          reason: 'The test must exercise TWO instances, not one.');

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('two Job instances that differ in exactly ONE field are NOT '
        'equal', () {
      final base = sampleJob();
      // Freezed's generated copyWith — a new Job with `title` swapped,
      // every other field identical.
      final differentTitle = base.copyWith(title: 'Senior Flutter Developer');

      expect(base == differentTitle, isFalse);
      // hashCode is allowed to collide (hashCodes are not required to
      // be unique for unequal values) — but for two Jobs that differ
      // in a String field it would be a genuine coincidence, and
      // Freezed's derived hash makes it exceptionally unlikely.
      expect(base.hashCode == differentTitle.hashCode, isFalse);
    });

    test('a Set of five identical Job instances contains ONE entry', () {
      // Five DISTINCT constructor calls, all producing the same field
      // values.
      final jobs = <Job>{
        sampleJob(),
        sampleJob(),
        sampleJob(),
        sampleJob(),
        sampleJob(),
      };

      // Under identity equality this Set would have five entries.
      // With Freezed's value equality + derived hashCode, it collapses
      // to one.
      expect(jobs.length, equals(1));
    });
  });
}
