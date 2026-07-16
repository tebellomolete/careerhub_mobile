import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/job.dart';
import '../providers/job_providers.dart';
import '../providers/jobs_notifier.dart';
import '../router/app_router.dart';
import '../widgets/job_card.dart';
import '../widgets/empty_jobs_widget.dart';

/// CareerHub's main screen.
///
/// Assignment 2.1 changes from 1.4:
///   - watches [visibleJobsProvider], which now sits on top of
///     [jobsProvider] (the generated AsyncNotifier), not the
///     old hardcoded FutureProvider;
///   - the retry button and pull-to-refresh both call
///     `jobsProvider.notifier.refresh()` — one code path,
///     one loading spinner, one error surface;
///   - the `_SimulateNotificationButton` and `_FailToggleButton` from
///     1.4 are removed: with runtime Guid IDs there is no meaningful
///     "job #3" to jump to, and the error state is now tested by
///     stopping the API (see README Q4 and Part 5's verification
///     checklist).
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final TextEditingController _searchController;

  static const double _gridBreakpoint = 600;
  static const double _threeColumnBreakpoint = 840;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleJobsAsync = ref.watch(visibleJobsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CareerHub'),
        centerTitle: false,
        actions: const [
          _SortButton(),
          SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchController,
              onChanged: (value) =>
                  ref.read(searchQueryProvider.notifier).state = value,
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search job titles…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: 'Clear search',
                        onPressed: () {
                          _searchController.clear();
                          ref.read(searchQueryProvider.notifier).state = '';
                        },
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const _FilterDropdownRow(),

          Expanded(
            child: visibleJobsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stackTrace) => _ErrorState(
                onRetry: () =>
                    ref.read(jobsProvider.notifier).refresh(),
              ),
              data: (jobs) {
                if (jobs.isEmpty) {
                  return const EmptyJobsWidget(
                    icon: Icons.filter_alt_off_outlined,
                    title: 'No jobs match your filters',
                    message: 'Try a different filter or search term.',
                  );
                }

                // Stretch A — pull-to-refresh. RefreshIndicator's
                // Future determines how long the spinner stays on
                // screen; JobsNotifier.refresh() awaits the fresh
                // fetch, so the animation ends exactly when the new
                // data (or an error) arrives. See README Stretch A.
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(jobsProvider.notifier).refresh(),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;

                      if (width < _gridBreakpoint) {
                        return ListView.builder(
                          // A scrollable is required for RefreshIndicator
                          // to receive drag events even when the list is
                          // short; AlwaysScrollable makes a single-card
                          // list still refreshable.
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: jobs.length,
                          itemBuilder: (context, index) =>
                              _buildCard(context, index, jobs),
                        );
                      }

                      final crossAxisCount =
                          width >= _threeColumnBreakpoint ? 3 : 2;
                      final childAspectRatio =
                          width >= _threeColumnBreakpoint ? 1.05 : 1.2;

                      return GridView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(8),
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
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
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildCard(BuildContext context, int index, List<Job> jobs) {
    final job = jobs[index];
    return InkWell(
      onTap: () => context.push(AppRoutes.jobDetail(job.id)),
      child: JobCard(job: job),
    );
  }
}

/// Two side-by-side dropdown filters above the job list/grid.
class _FilterDropdownRow extends StatelessWidget {
  const _FilterDropdownRow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: _FilterField(
              label: 'Location',
              child: _LocationFilterDropdown(),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _FilterField(
              label: 'Job type',
              child: _JobTypeFilterDropdown(),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterField extends StatelessWidget {
  final String label;
  final Widget child;

  const _FilterField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}

class _LocationFilterDropdown extends ConsumerWidget {
  const _LocationFilterDropdown();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(locationFilterProvider);

    return DropdownButtonFormField<LocationType?>(
      initialValue: selected,
      isExpanded: true,
      isDense: true,
      decoration: InputDecoration(
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: const [
        DropdownMenuItem<LocationType?>(
          value: null,
          child: Text('All locations'),
        ),
        DropdownMenuItem<LocationType?>(
          value: LocationType.onSite,
          child: Text('On-site'),
        ),
        DropdownMenuItem<LocationType?>(
          value: LocationType.remote,
          child: Text('Remote'),
        ),
        DropdownMenuItem<LocationType?>(
          value: LocationType.hybrid,
          child: Text('Hybrid'),
        ),
      ],
      onChanged: (value) =>
          ref.read(locationFilterProvider.notifier).state = value,
    );
  }
}

class _JobTypeFilterDropdown extends ConsumerWidget {
  const _JobTypeFilterDropdown();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(jobTypeFilterProvider);

    return DropdownButtonFormField<JobTypeFilter?>(
      initialValue: selected,
      isExpanded: true,
      isDense: true,
      decoration: InputDecoration(
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: [
        const DropdownMenuItem<JobTypeFilter?>(
          value: null,
          child: Text('All types'),
        ),
        for (final type in JobTypeFilter.values)
          DropdownMenuItem<JobTypeFilter?>(
            value: type,
            child: Text(type.label),
          ),
      ],
      onChanged: (value) =>
          ref.read(jobTypeFilterProvider.notifier).state = value,
    );
  }
}

class _SortButton extends ConsumerWidget {
  const _SortButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sortOrder = ref.watch(sortOrderProvider);

    return PopupMenuButton<SortOrder>(
      icon: const Icon(Icons.sort_by_alpha),
      tooltip: 'Sort by title',
      onSelected: (value) =>
          ref.read(sortOrderProvider.notifier).state = value,
      itemBuilder: (context) => [
        CheckedPopupMenuItem(
          value: SortOrder.aToZ,
          checked: sortOrder == SortOrder.aToZ,
          child: const Text('Title: A–Z'),
        ),
        CheckedPopupMenuItem(
          value: SortOrder.zToA,
          checked: sortOrder == SortOrder.zToA,
          child: const Text('Title: Z–A'),
        ),
      ],
    );
  }
}

/// Shown when visibleJobsProvider's AsyncValue is in the error state.
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
