// Assignment 3.2, Part 4 — filteredJobsProvider unit tests.
//
// This file does NOT import mocktail. The subclass-override
// pattern is sufficient because the assertions here are value
// assertions on the derived provider, not interaction assertions
// on a collaborator. See README 3.2 Q1.
//
// `filteredJobsProvider` watches two providers:
//   1. jobsProvider   — an AsyncNotifierProvider<List<Job>>.
//   2. filterProvider — a synchronous String notifier persisted to
//      SharedPreferences (see lib/providers/filter_notifier.dart).
//      Values: 'All' | 'onSite' | 'remote' | 'hybrid' (see the
//      `LocationType.name` mapping in job_providers.dart's
//      `_locationTypeFromFilter`).
//
// jobsProvider is overridden with a private `_FakeJobsNotifier` that
// returns a synchronous list. filterProvider is exercised via
// `SharedPreferences.setMockInitialValues` and `prefsProvider`
// override — the real notifier runs against a mocked prefs
// instance. See README 3.2 assumption 1 and Part 4 checkpoint
// notes.
//
// Assignment 3.2 Stretch C — the fourth test at the bottom of this
// group exercises the AsyncError propagation contract. It asserts
// that when jobsProvider is in AsyncError, filteredJobsProvider
// propagates the error rather than swallowing it into an empty
// AsyncData. See README 3.2 Stretch C section.

import 'package:careerhub_mobile/core/prefs_provider.dart';
import 'package:careerhub_mobile/models/job.dart';
import 'package:careerhub_mobile/providers/filter_notifier.dart';
import 'package:careerhub_mobile/providers/job_providers.dart';
import 'package:careerhub_mobile/providers/jobs_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Part 4.2 — the fake notifier. Subclasses the real notifier and
// overrides build() to return a synchronous list. No network, no
// Isar, no cache stream — the whole point of this pattern is to
// bypass every collaborator jobsProvider talks to and drop a
// literal list into the graph.
class _FakeJobsNotifier extends JobsNotifier {
  final List<Job> _jobs;
  _FakeJobsNotifier(this._jobs);

  @override
  Future<List<Job>> build() async => _jobs;
}

// Stretch C — a second fake that surfaces an error instead of data,
// so the offline-error propagation test can assert that
// filteredJobsProvider forwards the error rather than degrading it
// to an empty list. `Future.error` yields a rejected future which
// Riverpod's runBuild converts to AsyncError on the outer state.
class _ErrorJobsNotifier extends JobsNotifier {
  final Object _error;
  _ErrorJobsNotifier(this._error);

  @override
  Future<List<Job>> build() async {
    throw _error;
  }
}

// Part 4.2 — top-level fixtures. At least three jobs, at least two
// distinct values for the filter's field. Our filter reads
// `job.locationType`; the brief's example uses type 'Engineering'
// vs 'Design' but our screen filters by location, so we use two
// remote jobs and one on-site. See README 3.2 assumption 2.
final Job _remoteJob1 = Job(
  id: 'remote-1',
  title: 'Remote Frontend Engineer',
  company: 'Northwind',
  location: 'Remote',
  locationType: LocationType.remote,
  employmentType: 'Full-time',
);

final Job _remoteJob2 = Job(
  id: 'remote-2',
  title: 'Remote Product Designer',
  company: 'Loop',
  location: 'Remote',
  locationType: LocationType.remote,
  employmentType: 'Contract',
);

final Job _onSiteJob = Job(
  id: 'onsite-1',
  title: 'On-site Backend Engineer',
  company: 'Bitcube',
  location: 'Cape Town, ZA',
  locationType: LocationType.onSite,
  employmentType: 'Full-time',
);

final List<Job> _fixtureJobs = [_remoteJob1, _remoteJob2, _onSiteJob];

void main() {
  // The default filter value SharedPreferences returns from
  // `getString(kSelectedFilterKey)` when the key is absent is null,
  // which `filterProvider.build()` maps to `kFilterAll` ('All').
  // Seeding mock prefs with an empty map matches that cold-boot
  // default; individual tests override by calling
  // `container.read(filterProvider.notifier).select(...)`.
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  /// Container helper — same principle as the Part 3 helper. Overrides:
  ///   - jobsProvider with `_FakeJobsNotifier(jobs)` so the test
  ///     controls the exact list flowing into filteredJobsProvider.
  ///   - prefsProvider with a mock SharedPreferences instance so
  ///     the real filterProvider can `getString` / `setString`
  ///     without a platform channel.
  ///
  /// `retry: (_, _) => null` — same rationale as the Part 3 file:
  /// tests need deterministic single-build semantics; the retry
  /// policy is a production concern.
  Future<ProviderContainer> makeContainer({
    required JobsNotifier Function() jobsNotifierFactory,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      retry: (_, __) => null,
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        // `.overrideWith(() => Notifier)` is Riverpod 3's API for
        // swapping a generated NotifierProvider's underlying notifier
        // class. The factory returns `JobsNotifier` so both subclasses
        // in this file (`_FakeJobsNotifier`, `_ErrorJobsNotifier`)
        // satisfy the same signature.
        jobsProvider.overrideWith(jobsNotifierFactory),
      ],
    );
    addTearDown(container.dispose);
    // Same auto-dispose defence as the Part 3 file.
    container.listen(jobsProvider, (_, __) {}, fireImmediately: true);
    container.listen(filteredJobsProvider, (_, __) {}, fireImmediately: true);
    return container;
  }

  group('filteredJobsProvider', () {
    test("returns the full list when the filter is 'All'", () async {
      final container = await makeContainer(
        jobsNotifierFactory: () => _FakeJobsNotifier(_fixtureJobs),
      );

      // Wait for jobsProvider's async build (returns synchronously
      // via _FakeJobsNotifier but Riverpod still schedules it on a
      // microtask). This microsecond-level await lets the AsyncData
      // transition happen before we read filteredJobsProvider.
      await container.read(jobsProvider.future);

      final result = container.read(filteredJobsProvider);
      expect(result, isA<AsyncData<List<Job>>>());
      expect(result.value, hasLength(_fixtureJobs.length));
      expect(result.value, equals(_fixtureJobs));
    });

    test("returns only remote jobs when the filter is 'remote'", () async {
      final container = await makeContainer(
        jobsNotifierFactory: () => _FakeJobsNotifier(_fixtureJobs),
      );

      // Force jobsProvider to resolve.
      await container.read(jobsProvider.future);

      // Baseline read confirms 'All' returns everything, then
      // flip the filter and read again.
      final full = container.read(filteredJobsProvider).value;
      expect(full, hasLength(3));

      container.read(filterProvider.notifier).select('remote');
      final filtered = container.read(filteredJobsProvider);

      expect(filtered, isA<AsyncData<List<Job>>>());
      // Two of the three fixtures have locationType.remote.
      expect(filtered.value, hasLength(2));
      expect(filtered.value, contains(_remoteJob1));
      expect(filtered.value, contains(_remoteJob2));
      // Positive-and-negative assertion — the on-site job MUST NOT
      // appear in the filtered result. See brief Part 4.4.
      expect(filtered.value, isNot(contains(_onSiteJob)));
    });

    test('changing the filter produces a different list on the next read',
        () async {
      final container = await makeContainer(
        jobsNotifierFactory: () => _FakeJobsNotifier(_fixtureJobs),
      );
      await container.read(jobsProvider.future);

      // First read — filter is 'All' (the mock-prefs default).
      final firstList = container.read(filteredJobsProvider).value!;

      // Flip to onSite — the fixture has one such job.
      container.read(filterProvider.notifier).select('onSite');
      final secondList = container.read(filteredJobsProvider).value!;

      // The two reads must return different lists. Comparing by
      // length is sufficient because the fixture data guarantees a
      // length asymmetry (3 vs 1).
      expect(firstList.length, isNot(equals(secondList.length)));
      // Each list must contain only items matching its filter.
      expect(firstList, containsAll(_fixtureJobs));
      expect(secondList, equals([_onSiteJob]));
    });

    // Assignment 3.2 Stretch C — offline error propagation.
    //
    // When jobsProvider is in AsyncError (network failure, empty
    // cache), filteredJobsProvider MUST propagate the error rather
    // than returning `AsyncData(const [])`. An empty list is
    // indistinguishable from "the filter excluded everything" and
    // would render the empty state — the user sees "No jobs match
    // your filter" instead of "Something went wrong, retry", which
    // is materially worse UX. See README 3.2 Stretch C.
    //
    // Implementation note: `filteredJobsProvider` uses
    // `jobsAsync.whenData(...)`, which already propagates
    // AsyncError without transforming it. So this test PASSES
    // against the current production code — no `lib/` change was
    // needed. See README 3.2 Stretch C for the confirmation.
    test(
      'propagates AsyncError from jobsProvider instead of collapsing to '
      'an empty AsyncData (Stretch C)',
      () async {
        final container = await makeContainer(
          jobsNotifierFactory: () =>
              _ErrorJobsNotifier(Exception('Offline for the test')),
        );

        // Trigger the errored build and swallow the rejection so
        // the test can consult the derived provider's state.
        await expectLater(
          container.read(jobsProvider.future),
          throwsA(isA<Exception>()),
        );

        final derived = container.read(filteredJobsProvider);

        // The critical assertion — AsyncError, not AsyncData(empty).
        expect(derived, isA<AsyncError<List<Job>>>());
        // Negative assertion — this is what a broken implementation
        // (a manual .when() that returned `[]` on the error arm)
        // would surface.
        expect(derived, isNot(isA<AsyncData<List<Job>>>()));
      },
    );
  });
}
