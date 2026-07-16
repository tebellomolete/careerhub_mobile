import 'package:flutter_riverpod/flutter_riverpod.dart';
// StateProvider moved out of the main flutter_riverpod.dart import as of
// Riverpod 3.0 (it's now "legacy" — discouraged in favour of Notifier,
// but fully supported). We use it deliberately here anyway: see the
// justification on each StateProvider below and README Q2.
import 'package:flutter_riverpod/legacy.dart';

import '../models/job.dart';
import 'jobs_notifier.dart';

/// Assignment 2.1 — this file used to own the `_mockJobs` list, the
/// hardcoded `jobsProvider` FutureProvider, AND the fail-simulation
/// toggle. Part 5 explicitly instructs us to remove all three:
///   - the hardcoded list moves to a `_FakeJobsNotifier` inside the
///     widget test (test/widget_test.dart), where the tests can
///     depend on it deterministically without a running API;
///   - `jobsProvider` is replaced by [jobsProvider] (generated
///     from `JobsNotifier` in jobs_notifier.dart);
///   - the fail toggle is dropped — the brief tests the error state by
///     stopping the API, and a manual failure toggle would add a
///     second, redundant path.
///
/// What remains here is exactly the SLICE OF UI STATE the screens own:
/// which filter is selected, which sort order, what's in the search box,
/// which jobs the user has saved. None of it fetches data.

/// ---------------------------------------------------------------------
/// Provider 2a — the currently selected LOCATION filter dropdown value.
/// ---------------------------------------------------------------------
final locationFilterProvider =
    StateProvider<LocationType?>((ref) => null);

/// The set of employment-type labels the Job Type dropdown exposes. Kept
/// as a String because employmentType on Job is already a String — after
/// `Job.fromDto` normalises the API's `FullTime` to `Full-time`, filter
/// equality is a direct string compare with no derived tag in the middle.
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
/// ---------------------------------------------------------------------
final jobTypeFilterProvider =
    StateProvider<JobTypeFilter?>((ref) => null);

/// ---------------------------------------------------------------------
/// Provider 3 — the filtered job list, derived from the async job list
/// plus the two dropdown filters.
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
/// Stretch A (Assignment 1.3) — sort order.
/// ---------------------------------------------------------------------
enum SortOrder { aToZ, zToA }

final sortOrderProvider = StateProvider<SortOrder>((ref) => SortOrder.aToZ);

/// ---------------------------------------------------------------------
/// Stretch B (Assignment 2.1) / Stretch C (Assignment 1.3) — search box text.
/// ---------------------------------------------------------------------
final searchQueryProvider = StateProvider<String>((ref) => '');

/// The single provider HomeScreen watches for job data — filtered,
/// sorted, AND searched.
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
/// ---------------------------------------------------------------------
final savedJobIdsProvider = StateProvider<Set<String>>((ref) => <String>{});

/// The saved jobs as a derived list, resolved against the raw job list
/// via the notifier.
final savedJobsProvider = Provider<AsyncValue<List<Job>>>((ref) {
  final jobsAsync = ref.watch(jobsProvider);
  final savedIds = ref.watch(savedJobIdsProvider);
  return jobsAsync.whenData(
    (jobs) => jobs.where((job) => savedIds.contains(job.id)).toList(),
  );
});

/// ---------------------------------------------------------------------
/// Stretch C (Assignment 1.4) — authentication state. Unchanged from 1.4.
/// ---------------------------------------------------------------------
final isLoggedInProvider = StateProvider<bool>((ref) => false);

/// ---------------------------------------------------------------------
/// Stretch B (Assignment 2.2) — the user's IN-PROGRESS edited copy of
/// the currently-viewed job.
///
/// The value is a `Job?` — `null` when no note has been typed for the
/// current detail-screen visit, otherwise a `Job` produced by
/// `original.copyWith(userNote: text)`.
///
/// The IMPORTANT thing about this provider is what it does NOT do:
/// it does NOT replace the job in the list. The [jobsProvider]'s
/// `List<Job>` remains untouched — Freezed's `copyWith` returns a NEW
/// `Job` instance, and we store that new instance HERE rather than
/// mutating the original. The list is source-of-truth for what the
/// server sent; this provider is source-of-truth for what the user
/// has typed. See README 2.2, Stretch B.
///
/// Simple key-off-of-id contract: the detail screen only treats the
/// value as "mine" when `edited.id == job.id`. Navigating to a
/// different job renders the original API `Job` until the user types.
final editedJobProvider = StateProvider<Job?>((ref) => null);
