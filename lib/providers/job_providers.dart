import 'package:flutter_riverpod/flutter_riverpod.dart';
// StateProvider moved out of the main flutter_riverpod.dart import as of
// Riverpod 3.0 (it's now "legacy" — discouraged in favour of Notifier,
// but fully supported). We use it deliberately here anyway: see the
// justification on selectedFilterProvider below and README Q2.
import 'package:flutter_riverpod/legacy.dart';

import '../models/job.dart';

/// ---------------------------------------------------------------------
/// Provider 1 — the full job list, loaded asynchronously.
///
/// FutureProvider is the right tool here: this data is fetched once
/// (simulating a network round-trip), and Riverpod's job is to represent
/// the three states of that fetch — loading, error, data — for us.
/// FutureProvider wraps its result in AsyncValue<List<Job>> automatically,
/// so nothing else in the app hand-rolls a loading flag or a nullable
/// error field. "Retry" is just `ref.invalidate(jobsProvider)`, which
/// FutureProvider already supports — reaching for the heavier
/// AsyncNotifier (Riverpod 3's now-preferred async class) would add a
/// class, a `build()` override, and an `AsyncNotifierProvider` wrapper
/// for zero extra capability at this stage, since CareerHub never needs
/// to mutate this list piecemeal — only re-fetch it wholesale.
/// ---------------------------------------------------------------------
final jobsProvider = FutureProvider<List<Job>>(
  (ref) async {
    // Simulated network round-trip. Assignment 1.3 Part 2 requires the
    // loading state to be visible for at least one second; the Part 3
    // checkpoint expects "approximately 1.5 seconds."
    await Future.delayed(const Duration(milliseconds: 1500));

    // Stretch B: deliberately ref.read, not ref.watch. Watching here
    // would make jobsProvider reactive to shouldFailProvider all by
    // itself, so simply flipping the switch would silently re-trigger a
    // fetch with no explicit ref.invalidate needed — which contradicts
    // the brief's two-step design ("toggles shouldFailProvider AND calls
    // ref.invalidate(jobsProvider)"), and risks the two mechanisms firing
    // a double fetch. ref.read takes a one-off snapshot at the moment
    // THIS execution starts — exactly what a provider body that only
    // wants "whatever the flag is right now" needs. It's the same
    // watch-vs-read reasoning as README Q1, just applied inside a
    // provider instead of a widget.
    final shouldFail = ref.read(shouldFailProvider);
    if (shouldFail) {
      throw Exception(
        'Simulated network failure. Tap the toggle again to recover.',
      );
    }
    return _mockJobs;
  },
  // Riverpod 3.0 auto-retries a throwing provider by default — up to 10
  // attempts, with an exponential backoff from 200ms to 6.4s — before
  // AsyncValue ever reaches `error`. That's exactly wrong for a MANUAL
  // failure toggle: without this override, tapping "simulate failure"
  // would appear to do nothing for up to ~38 seconds while Riverpod
  // silently retries (and fails) behind the scenes. Disabled here, only
  // for this provider, so Stretch B's fail/retry sequence is instant.
  retry: (retryCount, error) => null,
);

/// ---------------------------------------------------------------------
/// Provider 2 — the label of the currently selected filter chip.
///
/// StateProvider is the right tool here: it's a single, simple, directly
/// overwritable value. There's no async work and no derivation in "the
/// user tapped a different chip" — every tap just replaces the old label
/// with the new one outright, which is exactly the case StateProvider
/// exists for.
/// ---------------------------------------------------------------------
final selectedFilterProvider = StateProvider<String>((ref) => 'All');

/// ---------------------------------------------------------------------
/// Provider 3 — the filtered job list, derived from providers 1 and 2.
///
/// Plain Provider is the right tool here: nothing ever "sets" this value
/// directly — it's a pure computation over the two providers above, so
/// Riverpod recomputes it automatically the instant either input
/// changes. That's precisely what rules out the manual-sync bug
/// described in README Q2: this provider has no state of its own to fall
/// out of sync.
/// ---------------------------------------------------------------------
final filteredJobsProvider = Provider<AsyncValue<List<Job>>>((ref) {
  final jobsAsync = ref.watch(jobsProvider);
  final selectedFilter = ref.watch(selectedFilterProvider);

  return jobsAsync.whenData((jobs) {
    if (selectedFilter == 'All') return jobs;
    return jobs.where((job) => _matchesFilter(job, selectedFilter)).toList();
  });
});

/// Matches a job against a filter label using real Job fields only —
/// never a synthetic/derived tag. 'Remote' checks `location`, which
/// `Job.remote()` stamps to exactly `'Remote'`; every other label checks
/// `employmentType` directly, since 'Full-time' and 'Contract' are
/// already the literal `employmentType` strings used throughout
/// CareerHub's mock data.
bool _matchesFilter(Job job, String filterLabel) {
  if (filterLabel == 'Remote') {
    return job.location == 'Remote';
  }
  return job.employmentType == filterLabel;
}

/// ---------------------------------------------------------------------
/// Stretch A — sort order.
///
/// A plain enum, not a raw String: the set of valid sort orders is
/// small, fixed, and closed, so an enum lets the compiler (and every
/// switch/comparison on it) rule out typos and invalid values the way a
/// String never could.
/// ---------------------------------------------------------------------
enum SortOrder { aToZ, zToA }

/// Second StateProvider, exactly as the brief asks for — same
/// justification as selectedFilterProvider: a single, directly
/// overwritable value with no derivation of its own.
final sortOrderProvider = StateProvider<SortOrder>((ref) => SortOrder.aToZ);

/// ---------------------------------------------------------------------
/// Stretch B — the manual failure toggle. Defaults to false, so out of
/// the box CareerHub behaves exactly as it did before this stretch goal
/// existed.
/// ---------------------------------------------------------------------
final shouldFailProvider = StateProvider<bool>((ref) => false);

/// ---------------------------------------------------------------------
/// Stretch C — the search box's current text.
/// ---------------------------------------------------------------------
final searchQueryProvider = StateProvider<String>((ref) => '');

/// ---------------------------------------------------------------------
/// The single provider HomeScreen watches for job data — filtered,
/// sorted, AND searched.
///
/// This composes ON TOP of filteredJobsProvider rather than re-reading
/// jobsProvider/selectedFilterProvider directly and re-implementing
/// filtering here: filteredJobsProvider is already "reactive to jobs and
/// the filter," so anything that watches IT is transitively reactive to
/// both, with no duplicated logic. That's what "the reactive graph
/// composes" means in practice — see README, Stretch A.
///
/// Search reuses Job.matches() — written and unit-tested in Assignment
/// 1.1's Stretch B, but never actually wired into the UI until now.
/// ---------------------------------------------------------------------
final visibleJobsProvider = Provider<AsyncValue<List<Job>>>((ref) {
  final filteredAsync = ref.watch(filteredJobsProvider);
  final sortOrder = ref.watch(sortOrderProvider);
  final searchQuery = ref.watch(searchQueryProvider);

  return filteredAsync.whenData((jobs) {
    final searched = searchQuery.trim().isEmpty
        ? jobs
        : jobs.where((job) => job.matches(searchQuery)).toList();

    final sorted = [...searched]..sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

    return sortOrder == SortOrder.zToA ? sorted.reversed.toList() : sorted;
  });
});

/// The mock "backend" data — moved here from HomeScreen (Assignment 1.3
/// Part 2: "Job data is no longer a field on HomeScreen"). Unchanged
/// from Assignment 1.2: same six jobs, same edge cases.
///
/// Filter coverage, confirmed against the labels in HomeScreen's chip
/// row (`All`, `Remote`, `Full-time`, `Contract`):
///   Remote     -> DevOps Engineer, Technical Support Engineer   (2)
///   Full-time  -> Senior Flutter Developer, Junior Backend
///                 Engineer, DevOps Engineer, UX Researcher      (4)
///   Contract   -> Product Designer, Technical Support Engineer  (2)
final List<Job> _mockJobs = [
  Job(
    title: 'Senior Flutter Developer',
    company: 'Bitcube',
    location: 'Cape Town, ZA',
    salary: 'R55 000 – R75 000 per month',
    employmentType: 'Full-time',
    closingDate: DateTime(2026, 8, 15),
    description:
        'Build production-ready cross-platform apps with a mentoring '
        'team and a real project backlog.',
    isOpen: true,
  ),
  Job(
    title: 'Junior Backend Engineer',
    company: 'Nimbus Systems',
    location: 'Johannesburg, ZA',
    employmentType: 'Full-time',
    isOpen: true,
  ),
  Job.closed(
    title: 'Product Designer',
    company: 'Loop Studio',
    location: 'Durban, ZA',
    salary: 'R40 000 per month',
    employmentType: 'Contract',
    closingDate: DateTime(2026, 5, 1),
    description: 'This role has closed for new applications.',
  ),
  Job.remote(
    title: 'DevOps Engineer',
    company: 'Skyforge',
    salary: 'R60 000 – R80 000 per month',
    employmentType: 'Full-time',
    closingDate: DateTime(2026, 9, 30),
    description: 'Fully remote infrastructure role across CI/CD pipelines.',
    isOpen: true,
  ),
  Job(
    title: 'UX Researcher',
    company: 'Meridian Labs',
    location: 'Pretoria, ZA',
    salary: 'R48 000 – R58 000 per month',
    employmentType: 'Full-time',
    closingDate: DateTime(2026, 10, 1),
    description:
        'Lead user research sessions and translate findings into '
        'product decisions.',
    isOpen: true,
  ),
  Job.remote(
    title: 'Technical Support Engineer',
    company: 'Fathom Analytics',
    employmentType: 'Contract',
    closingDate: DateTime(2026, 8, 20),
    isOpen: true,
  ),
];
