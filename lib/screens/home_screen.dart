import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/job.dart';
import '../providers/connectivity_provider.dart';
import '../providers/filter_notifier.dart';
import '../providers/job_providers.dart';
import '../providers/jobs_notifier.dart';
import '../router/app_router.dart';
import '../widgets/job_card.dart';
import '../widgets/empty_jobs_widget.dart';

/// CareerHub's main screen.
///
/// Assignment 2.3 changes from 2.2:
///   - The Location dropdown now reads and writes `filterProvider`
///     (persisted to SharedPreferences), NOT the old ephemeral
///     `locationFilterProvider` `StateProvider<LocationType?>` — the
///     brief's Part 7 requires the filter selection to survive
///     force-close. See README 2.3, Part 7.
///   - A new offline banner (Part 9.1) sits above the search field
///     when `isOfflineProvider` returns `true`. Uses
///     `colorScheme.errorContainer` / `onErrorContainer` and shows
///     the cache-age string from `cacheAgeProvider` (Stretch A)
///     when available, with a generic fallback otherwise.
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
    // Assignment 2.3, Part 9.1 — the offline flag drives the banner
    // above the search field. Cold-boot behaviour explained in
    // README 2.3, Q4: `isOfflineProvider` is `false` on the very
    // first frame (the connectivity stream hasn't emitted yet) even
    // when the device is actually offline, then flips to `true`
    // within under a second when the first change event arrives.
    final isOffline = ref.watch(isOfflineProvider);

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
          // Part 9.1 — the offline banner. Rendered conditionally
          // (not always-present with an animation) because a hidden
          // banner should not consume vertical space above the list.
          if (isOffline) const _OfflineBanner(),

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

/// Assignment 2.3, Part 9.1 — the offline banner.
///
/// - background: `colorScheme.errorContainer`
/// - foreground: `colorScheme.onErrorContainer`
/// - icon: `Icons.cloud_off_outlined`
/// - text: `cacheAgeProvider` (Stretch A) when available, otherwise
///   the generic fallback "You're offline — showing cached jobs."
///
/// Appears and disappears automatically without any user interaction —
/// the parent widget's `if (isOffline)` guard is the only visibility
/// switch.
class _OfflineBanner extends ConsumerWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    // Stretch A — the age string; `null` when the app has never had
    // a successful network response. See README 2.3, Stretch A.
    final ageString = ref.watch(cacheAgeProvider);
    final message = ageString ?? "You're offline — showing cached jobs.";

    return Container(
      width: double.infinity,
      color: scheme.errorContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(
            Icons.cloud_off_outlined,
            color: scheme.onErrorContainer,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onErrorContainer,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
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

/// Assignment 2.3, Part 7 (Step 7.3) — the Location dropdown now reads
/// the persisted `filterProvider` (String) and writes via
/// `.select(String)` so the selection survives force-close.
///
/// The dropdown items are `LocationType?` values (unchanged from 2.2);
/// two small conversions bridge to the String world:
///   - read:  `_dropdownValueFromFilter(String)` → `LocationType?`
///   - write: `_filterFromDropdownValue(LocationType?)` → `String`
///
/// The dropdown items themselves are unchanged; the filter predicate
/// in `filteredJobsProvider` uses the same String conversion.
class _LocationFilterDropdown extends ConsumerWidget {
  const _LocationFilterDropdown();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Part 7 — a subscription: rebuild whenever the persisted filter
    // changes (e.g. on cold boot after `build()` reads the stored
    // value). See README 2.3, Part 7.
    final filter = ref.watch(filterProvider);
    final selected = _dropdownValueFromFilter(filter);

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
      // Part 7 — a mutation. `ref.read` inside `onChanged` matches the
      // widget-level `watch`-vs-`read` rule from Assignment 1.3 Q1.
      // `.notifier` resolves to the `FilterNotifier` instance so we
      // can call `.select(...)`, which handles both the
      // SharedPreferences write and the state update.
      onChanged: (value) => ref
          .read(filterProvider.notifier)
          .select(_filterFromDropdownValue(value)),
    );
  }

  static LocationType? _dropdownValueFromFilter(String filter) {
    if (filter == kFilterAll) return null;
    for (final value in LocationType.values) {
      if (value.name == filter) return value;
    }
    return null;
  }

  static String _filterFromDropdownValue(LocationType? value) {
    return value?.name ?? kFilterAll;
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
