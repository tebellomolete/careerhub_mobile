import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Needed for .notifier/.state on the StateProviders below — see the note
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
/// - HomeScreen watches live Riverpod state instead of a static field.
/// - The LayoutBuilder / ListView.builder / GridView.builder / _buildCard
///   logic is otherwise untouched from Assignment 1.2 — only its data
///   source changed from a static field to a `jobs` parameter.
///
/// Stretch C promotes this from ConsumerWidget to ConsumerStatefulWidget
/// — see _HomeScreenState and README, Stretch C, for why: it's the
/// TextEditingController's lifecycle, not a UI complexity threshold,
/// that forces this change.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  /// Owned here, not by any provider, specifically because it has an
  /// imperative lifecycle (create once, dispose once) that Riverpod's
  /// snapshot-based state model isn't built to express. See README,
  /// Stretch C.
  late final TextEditingController _searchController;

  static const List<String> _filters = [
    'All',
    'Remote',
    'Full-time',
    'Contract',
  ];

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
    // ConsumerState exposes `ref` as a property (not a build() parameter
    // the way ConsumerWidget does). This is still the ONLY provider
    // HomeScreen watches directly — the same single ref.watch call as
    // before Stretch A/B/C existed. Every new dimension of state (sort,
    // the failure toggle, search) was added one layer below, inside
    // visibleJobsProvider or a sibling ConsumerWidget — never as an
    // extra watch call here. See README, Stretch A.
    final visibleJobsAsync = ref.watch(visibleJobsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CareerHub'),
        centerTitle: false,
        actions: const [
          _SortButton(),
          _FailToggleButton(),
          SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Stretch C — search box, above the filter chips as specified.
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

          const _FilterChipRow(filters: _filters),

          Expanded(
            child: visibleJobsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stackTrace) => _ErrorState(
                onRetry: () => ref.invalidate(jobsProvider),
              ),
              data: (jobs) {
                // README Q3's fourth condition: loaded successfully, but
                // zero jobs matched the current filter/search. Not an
                // error, not "no jobs exist" — needs its own message so
                // the user knows to adjust their filter or search rather
                // than assuming the app is broken.
                if (jobs.isEmpty) {
                  return const EmptyJobsWidget(
                    icon: Icons.filter_alt_off_outlined,
                    title: 'No jobs match your filters',
                    message: 'Try a different filter or search term.',
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
/// Its own ConsumerWidget rather than a plain one fed by HomeScreen —
/// deliberate, not incidental. The brief disallows passing callback
/// functions down through widget constructors, and the reason that
/// matters is the same mechanism behind README Q1: a callback threaded
/// down through a constructor is still just a callback, so putting
/// ref.watch inside it would be exactly as meaningless as putting it in
/// onSelected directly. Instead, _FilterChipRow reads and writes
/// selectedFilterProvider itself — HomeScreen never even needs to know
/// that provider exists.
class _FilterChipRow extends ConsumerWidget {
  final List<String> filters;

  const _FilterChipRow({required this.filters});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  ref.read(selectedFilterProvider.notifier).state = filter;
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Stretch A — sort control. Its own ConsumerWidget for the same reason
/// as _FilterChipRow: it owns its slice of state end-to-end, so
/// HomeScreen's watch count never grows when a new stretch goal is
/// added.
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

/// Stretch B — toggles the simulated network failure AND retries in one
/// tap, exactly as the brief specifies. Tapping it while a failure is
/// already active flips the flag back off before invalidating, so the
/// second tap is what actually recovers — see README, Stretch B, for
/// the full documented sequence.
class _FailToggleButton extends ConsumerWidget {
  const _FailToggleButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shouldFail = ref.watch(shouldFailProvider);

    return IconButton(
      icon: Icon(shouldFail ? Icons.wifi_off : Icons.wifi),
      tooltip: shouldFail
          ? 'Simulated failure is ON — tap to fix and retry'
          : 'Simulate a failed fetch',
      onPressed: () {
        ref.read(shouldFailProvider.notifier).state = !shouldFail;
        ref.invalidate(jobsProvider);
      },
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
