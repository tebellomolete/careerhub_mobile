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
///
/// Note (Riverpod 3.0): providers now auto-retry on error by default (up
/// to 10 attempts, 200ms doubling to 6.4s) before AsyncValue ever reaches
/// `error`. That's invisible here because this provider never throws in
/// this submission — see README, Assignment 1.3 Stretch B, for where
/// this becomes relevant.
/// ---------------------------------------------------------------------
final jobsProvider = FutureProvider<List<Job>>((ref) async {
  // Simulated network round-trip. Assignment 1.3 Part 2 requires the
  // loading state to be visible for at least one second; the Part 3
  // checkpoint expects "approximately 1.5 seconds."
  await Future.delayed(const Duration(milliseconds: 1500));
  return _mockJobs;
});

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
///
/// The return type is AsyncValue<List<Job>>, not List<Job> — this lets
/// the loading/error state of the underlying fetch flow straight through
/// to HomeScreen with no extra plumbing, so HomeScreen only ever needs to
/// watch ONE provider and hand it to AsyncValue.when().
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
