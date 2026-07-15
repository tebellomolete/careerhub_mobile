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
/// FutureProvider wraps its result in `AsyncValue<List<Job>>` automatically,
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
/// Provider 2a — the currently selected LOCATION filter dropdown value.
///
/// Now typed as `LocationType?` — an enum with a nullable "not selected"
/// state — rather than a stringly-typed "All"/"Remote" label. Two wins:
/// the compiler rules out typos and invalid values, and `null` cleanly
/// represents "no filter applied" so the dropdown's "All locations" item
/// doesn't need a magic string.
///
/// StateProvider is still the right tool: a single, directly-overwritable
/// value with no derivation of its own.
/// ---------------------------------------------------------------------
final locationFilterProvider =
    StateProvider<LocationType?>((ref) => null);

/// The set of employment-type labels the Job Type dropdown exposes. Kept
/// as a String because employmentType on Job is already a String (that's
/// the API shape, from Assignment 1.1), so filter equality is a direct
/// string compare with no derived tag in the middle.
enum JobTypeFilter {
  fullTime('Full-time'),
  partTime('Part-time'),
  contract('Contract'),
  internship('Internship');

  final String label;
  const JobTypeFilter(this.label);
}

/// ---------------------------------------------------------------------
/// Provider 2b — the currently selected JOB TYPE filter dropdown value.
/// Same reasoning as [locationFilterProvider] — nullable enum, null == All.
/// ---------------------------------------------------------------------
final jobTypeFilterProvider =
    StateProvider<JobTypeFilter?>((ref) => null);

/// ---------------------------------------------------------------------
/// Provider 3 — the filtered job list, now derived from THREE inputs:
/// the raw jobs plus the two independent dropdown filters.
///
/// Plain Provider still the right tool: nothing ever "sets" this value
/// directly — it's a pure computation over the providers above, so
/// Riverpod recomputes it automatically the instant any one input
/// changes. Two null-guards mean each dropdown filter contributes ONLY
/// when the user has picked a non-null value.
/// ---------------------------------------------------------------------
final filteredJobsProvider = Provider<AsyncValue<List<Job>>>((ref) {
  final jobsAsync = ref.watch(jobsProvider);
  final locationFilter = ref.watch(locationFilterProvider);
  final jobTypeFilter = ref.watch(jobTypeFilterProvider);

  return jobsAsync.whenData((jobs) {
    return jobs.where((job) {
      if (locationFilter != null && job.locationType != locationFilter) {
        return false;
      }
      if (jobTypeFilter != null && job.employmentType != jobTypeFilter.label) {
        return false;
      }
      return true;
    }).toList();
  });
});

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

/// ---------------------------------------------------------------------
/// Assignment 1.4 — the set of job ids the user has saved.
///
/// Backs the "Saved" NavigationBar tab. A `Set<int>` of ids (not a
/// `List<Job>`) for the same reason the URL keys on id: the saved state
/// must survive re-fetches of the job list and never pin a stale copy of
/// a job's fields.
/// ---------------------------------------------------------------------
final savedJobIdsProvider = StateProvider<Set<int>>((ref) => <int>{});

/// The saved jobs as a derived list, resolved against the raw job list.
final savedJobsProvider = Provider<AsyncValue<List<Job>>>((ref) {
  final jobsAsync = ref.watch(jobsProvider);
  final savedIds = ref.watch(savedJobIdsProvider);
  return jobsAsync.whenData(
    (jobs) => jobs.where((job) => savedIds.contains(job.id)).toList(),
  );
});

/// ---------------------------------------------------------------------
/// Stretch C — authentication state.
///
/// A single boolean the GoRouter redirect reads to decide whether to send
/// the user to /login. Defaults to false: out of the box the app opens on
/// the login screen. See README Stretch C for how refreshListenable turns
/// a change here into an automatic redirect with no context.go() call.
/// ---------------------------------------------------------------------
final isLoggedInProvider = StateProvider<bool>((ref) => false);

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
/// IDs are assigned explicitly and are stable — they are NOT the list
/// position. The list happens to be authored in id order here, but nothing
/// downstream may assume that: filtering, sorting and searching all reorder
/// this list, and only `job.id` survives those transformations intact. This
/// is the invariant that makes `/jobs/:id` reliable (README Q3).
final List<Job> _mockJobs = [
  Job(
    id: 1,
    title: 'Senior Flutter Developer',
    company: 'Bitcube',
    location: 'Cape Town, ZA',
    locationType: LocationType.onSite,
    salary: 'R55 000 – R75 000 per month',
    employmentType: 'Full-time',
    closingDate: DateTime(2026, 8, 15),
    description:
        'Build production-ready cross-platform apps with a mentoring '
        'team and a real project backlog.',
    isOpen: true,
  ),
  Job(
    id: 2,
    title: 'Junior Backend Engineer',
    company: 'Nimbus Systems',
    location: 'Johannesburg, ZA',
    locationType: LocationType.onSite,
    employmentType: 'Full-time',
    isOpen: true,
  ),
  Job.closed(
    id: 3,
    title: 'Product Designer',
    company: 'Loop Studio',
    location: 'Durban, ZA',
    locationType: LocationType.onSite,
    salary: 'R40 000 per month',
    employmentType: 'Contract',
    closingDate: DateTime(2026, 5, 1),
    description: 'This role has closed for new applications.',
  ),
  Job.remote(
    id: 4,
    title: 'DevOps Engineer',
    company: 'Skyforge',
    salary: 'R60 000 – R80 000 per month',
    employmentType: 'Full-time',
    closingDate: DateTime(2026, 9, 30),
    description: 'Fully remote infrastructure role across CI/CD pipelines.',
    isOpen: true,
  ),
  Job(
    id: 5,
    title: 'UX Researcher',
    company: 'Meridian Labs',
    location: 'Pretoria, ZA',
    locationType: LocationType.onSite,
    salary: 'R48 000 – R58 000 per month',
    employmentType: 'Full-time',
    closingDate: DateTime(2026, 10, 1),
    description:
        'Lead user research sessions and translate findings into '
        'product decisions.',
    isOpen: true,
  ),
  Job.remote(
    id: 6,
    title: 'Technical Support Engineer',
    company: 'Fathom Analytics',
    employmentType: 'Contract',
    closingDate: DateTime(2026, 8, 20),
    isOpen: true,
  ),
  // Added with the two-dropdown filter change so every dropdown option has
  // matching data — one hybrid Part-time role...
  Job(
    id: 7,
    title: 'Content Writer',
    company: 'Northwind Media',
    location: 'Cape Town, ZA',
    locationType: LocationType.hybrid,
    salary: 'R25 000 per month',
    employmentType: 'Part-time',
    closingDate: DateTime(2026, 9, 10),
    description:
        'Split your week between the studio and home — write long-form '
        'features on the future of work.',
    isOpen: true,
  ),
  // ...and one on-site Internship.
  Job(
    id: 8,
    title: 'Marketing Intern',
    company: 'Bright Ventures',
    location: 'Sandton, ZA',
    locationType: LocationType.onSite,
    salary: 'R8 000 per month stipend',
    employmentType: 'Internship',
    closingDate: DateTime(2026, 7, 30),
    description:
        'Six-month on-site internship supporting the growth team on '
        'campaigns and events.',
    isOpen: true,
  ),
];
