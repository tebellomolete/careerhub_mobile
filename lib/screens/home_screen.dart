import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Needed for .notifier/.state on selectedFilterProvider — see the note
// in job_providers.dart on why StateProvider needs this import as of
// Riverpod 3.0.
import 'package:flutter_riverpod/legacy.dart';

import '../models/job.dart';
import '../providers/job_providers.dart';
import '../widgets/job_card.dart';
import '../widgets/empty_jobs_widget.dart';

/// CareerHub's main screen.
///
/// Assignment 1.3 changes from 1.2:
/// - HomeScreen is now a ConsumerWidget instead of StatelessWidget. It
///   still has no state of its own — it just needs `ref` to watch
///   providers.
/// - The static `_jobs` field is gone entirely. Job data now lives in
///   lib/providers/job_providers.dart, loaded asynchronously.
/// - build() watches a single provider — filteredJobsProvider — and
///   uses AsyncValue.when() to render one of three states: loading,
///   error, or the (possibly filtered, possibly empty) job list.
/// - The LayoutBuilder / ListView.builder / GridView.builder / _buildCard
///   logic is otherwise untouched from Assignment 1.2 — only its data
///   source changed from a static field to a `jobs` parameter.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  /// Unchanged from Assignment 1.2 — still just chip labels. The values
  /// that matter for filtering now live in job_providers.dart's
  /// `_matchesFilter`.
  static const List<String> _filters = [
    'All',
    'Remote',
    'Full-time',
    'Contract',
  ];

  // Unchanged from Assignment 1.2.
  static const double _gridBreakpoint = 600;
  static const double _threeColumnBreakpoint = 840;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The ONLY provider HomeScreen itself watches. It already carries
    // both the loading/error state of the jobs fetch AND the current
    // filter selection, composed for us — HomeScreen doesn't need to
    // know two separate providers exist underneath it.
    final filteredJobsAsync = ref.watch(filteredJobsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CareerHub'),
        centerTitle: false,
      ),
      body: Column(
        children: [
          const _FilterChipRow(filters: _filters),

          Expanded(
            child: filteredJobsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stackTrace) => _ErrorState(
                onRetry: () => ref.invalidate(jobsProvider),
              ),
              data: (jobs) {
                // README Q3's fourth condition: loaded successfully, but
                // zero jobs matched the current filter. Not an error,
                // not "no jobs exist" — needs its own message so the
                // user knows to try a different filter rather than
                // assuming the app is broken.
                if (jobs.isEmpty) {
                  return const EmptyJobsWidget(
                    icon: Icons.filter_alt_off_outlined,
                    title: 'No jobs match this filter',
                    message: 'Try a different filter to see more listings.',
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;

                    // Tier 1: single column below 600px.
                    if (width < _gridBreakpoint) {
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: jobs.length,
                        itemBuilder: (context, index) =>
                            _buildCard(context, index, jobs),
                      );
                    }

                    // Tier 2 (600–839px): two columns.
                    // Tier 3 (≥840px): three columns.
                    final crossAxisCount =
                        width >= _threeColumnBreakpoint ? 3 : 2;
                    final childAspectRatio =
                        width >= _threeColumnBreakpoint ? 1.05 : 1.2;

                    return GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: childAspectRatio,
                      ),
                      itemCount: jobs.length,
                      itemBuilder: (context, index) =>
                          _buildCard(context, index, jobs),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Assignment 1.2's shared builder, unchanged in spirit: one function
  /// so ListView.builder and GridView.builder never duplicate itemBuilder
  /// logic. It now takes `jobs` explicitly since there's no static field
  /// left to close over.
  static Widget _buildCard(BuildContext context, int index, List<Job> jobs) {
    return JobCard(job: jobs[index]);
  }
}

/// The pinned, horizontally-scrolling filter row above the job
/// list/grid.
///
/// Assignment 1.3 change: this is now its OWN ConsumerWidget rather than
/// a StatelessWidget fed by HomeScreen. That's deliberate, not
/// incidental — the brief disallows passing callback functions down
/// through widget constructors. The reason that restriction matters is
/// the same mechanism behind README Q1: a callback threaded down through
/// a constructor is still just a callback, so calling ref.watch inside
/// it would be exactly as meaningless as calling it inside onSelected
/// directly. Instead, _FilterChipRow reads and writes
/// selectedFilterProvider itself — HomeScreen never even needs to know
/// that provider exists.
class _FilterChipRow extends ConsumerWidget {
  final List<String> filters;

  const _FilterChipRow({required this.filters});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // build() -> ref.watch: this row must rebuild whenever the selection
    // changes so the correct chip highlights.
    final selectedFilter = ref.watch(selectedFilterProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          for (final filter in filters)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(filter),
                selected: filter == selectedFilter,
                onSelected: (_) {
                  // callback -> ref.read: this runs once, at the moment
                  // of the tap. It only needs to fire off an update, not
                  // subscribe to anything.
                  ref.read(selectedFilterProvider.notifier).state = filter;
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Shown when jobsProvider's AsyncValue is in the error state.
/// Deliberately generic and friendly — CareerHub never surfaces a raw
/// exception string to a job seeker.
class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: scheme.error),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "We couldn't load the job listings. Please try again.",
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
