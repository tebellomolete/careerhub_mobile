// Assignment 3.2, Part 5 — JobCard widget tests.
//
// **Deviation from the brief's Part 5.1.** The brief says JobCard
// is a StatelessWidget that reads no providers and requires no
// ProviderScope. In this codebase JobCard is a `ConsumerWidget`
// (see lib/widgets/job_card.dart:19) that watches
// `savedJobIdsProvider` to render the bookmark IconButton's icon.
// The tests below therefore wrap the pumped tree in a
// ProviderScope with `savedJobIdsProvider` overridden to an
// empty `Set<String>` — nothing the tests do exercises the
// bookmark button, so the override is enough. See README 3.2
// assumption 9.
//
// **JobCard has no `Chip` widgets** — location, employment type,
// and salary render via `IconLine` (Icon + Text) and the status
// tag renders via `JobStatusBadge` (a rounded Container with an
// Icon + Text). The brief's "Chip or similar tag widget" language
// resolves to asserting on the text rendered inside those widgets.
// See README 3.2 assumption 10.

import 'package:careerhub_mobile/models/job.dart';
import 'package:careerhub_mobile/providers/job_providers.dart';
import 'package:careerhub_mobile/widgets/job_card.dart';
import 'package:careerhub_mobile/widgets/job_status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// Part 5.2 — the helper. Wraps a JobCard in the smallest possible
// widget tree that satisfies its `Theme`, `Directionality`,
// `MediaQuery`, and provider dependencies. Returns void, but pumps
// the tree via `tester.pumpWidget` so the test body can assert
// on it directly.
Future<void> pumpJobCard(WidgetTester tester, Job job) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        // The bookmark IconButton reads `savedJobIdsProvider`. An
        // empty override means the icon renders as bookmark_outline
        // (isSaved == false) — its exact visual is not what these
        // tests check, but the override keeps the widget from
        // reaching for the real (undefined-in-test) Isar-backed
        // stream.
        savedJobIdsProvider.overrideWithValue(const <String>{}),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: JobCard(job: job),
        ),
      ),
    ),
  );
}

// Part 5.2 — the two fixtures the brief calls for. Different titles,
// companies, and employment types so the tests can assert that the
// card renders each fixture's actual data (not hardcoded strings).
final Job _fixtureA = Job(
  id: 'fixture-a',
  title: 'Senior Flutter Engineer',
  company: 'Bitcube',
  location: 'Cape Town, ZA',
  locationType: LocationType.onSite,
  employmentType: 'Full-time',
  salary: 'R55 000 – R75 000 per month',
);

final Job _fixtureB = Job(
  id: 'fixture-b',
  title: 'Junior Backend Developer',
  company: 'Nimbus Systems',
  location: 'Remote',
  locationType: LocationType.remote,
  employmentType: 'Contract',
);

void main() {
  group('JobCard', () {
    testWidgets('renders the fixture title, company, and a tag/badge value',
        (tester) async {
      await pumpJobCard(tester, _fixtureA);

      // Title.
      expect(find.text(_fixtureA.title), findsOneWidget);
      // Company.
      expect(find.text(_fixtureA.company), findsOneWidget);
      // The "tag" — JobCard renders JobStatusBadge for the open/
      // closed state. `_fixtureA.isOpen == true` (default), so the
      // badge text is 'Open' (see lib/widgets/job_status_badge.dart:21).
      expect(find.text('Open'), findsOneWidget);
      // And the tag widget itself is present.
      expect(find.byType(JobStatusBadge), findsOneWidget);
    });

    testWidgets('a second fixture renders its own title, not the first fixture',
        (tester) async {
      await pumpJobCard(tester, _fixtureB);

      // The first fixture's title MUST NOT appear — this is what
      // distinguishes a data-driven card from one that hardcodes
      // strings. See brief Step 5.4.
      expect(find.text(_fixtureA.title), findsNothing);
      // The second fixture's title MUST appear.
      expect(find.text(_fixtureB.title), findsOneWidget);
      // For good measure, the company also differs.
      expect(find.text(_fixtureB.company), findsOneWidget);
    });

    testWidgets('employment type text matches the fixture, not a static label',
        (tester) async {
      // Pump the second fixture — its employmentType is 'Contract',
      // deliberately different from the first fixture's 'Full-time',
      // so a card rendering a hardcoded 'Full-time' label would fail
      // this test. Brief Step 5.5.
      await pumpJobCard(tester, _fixtureB);

      expect(find.text(_fixtureB.employmentType), findsOneWidget);
      // Negative assertion — the other fixture's employment type
      // must not appear, confirming the card is not rendering a
      // static string.
      expect(find.text(_fixtureA.employmentType), findsNothing);
    });
  });
}
