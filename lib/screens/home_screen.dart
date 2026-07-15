import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/job.dart';
import '../providers/job_providers.dart';
import '../router/app_router.dart';
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
        actions: [
          // Assignment 1.4 added a third action (the notification simulator),
          // which overflows the AppBar's trailing slot on a ~400px-wide phone
          // at the default 48px tap target. Shrink-wrapping the tap targets
          // and using compact density keeps all three icons within the slot
          // on narrow devices without hiding any behind an overflow menu (the
          // 1.3 tests tap these icons directly).
          Theme(
            data: Theme.of(context).copyWith(
              iconButtonTheme: IconButtonThemeData(
                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SimulateNotificationButton(),
                _SortButton(),
                _FailToggleButton(),
                SizedBox(width: 4),
              ],
            ),
          ),
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

          const _FilterDropdownRow(),

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
  ///
  /// Assignment 1.4: the card is now tappable. It navigates with
  /// `job.id` — NEVER `index` — via context.push, so the detail screen
  /// slides in over the list and the back button returns here with the
  /// filter/sort/search state untouched. Using `index` here would be the
  /// exact bug README Q3 warns about: the same index means different jobs
  /// under different filters.
  static Widget _buildCard(BuildContext context, int index, List<Job> jobs) {
    final job = jobs[index];
    return InkWell(
      onTap: () => context.push(AppRoutes.jobDetail(job.id)),
      child: JobCard(job: job),
    );
  }
}

/// Stretch B — simulates a push notification tap. A notification IS a URL:
/// this button jumps straight to /jobs/3 with context.go, bypassing the
/// card tap entirely, proving the detail screen can render from an id alone
/// regardless of the list's filter, scroll, or which tab was last active.
/// See README Stretch B.
class _SimulateNotificationButton extends StatelessWidget {
  const _SimulateNotificationButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.notifications_outlined),
      tooltip: 'Simulate a notification for job #3',
      onPressed: () => context.go(AppRoutes.jobDetail(3)),
    );
  }
}

/// Two side-by-side dropdown filters above the job list/grid — Location
/// and Job type — replacing the chip row from Assignments 1.2/1.3.
///
/// Same architectural reason it was a chip row before, still a
/// ConsumerWidget now: each dropdown reads and writes its own provider
/// directly. HomeScreen doesn't have to know these providers exist, so
/// its single ref.watch call still watches only visibleJobsProvider.
///
/// The two dropdowns are independent — a user can pick Remote + Full-time
/// to narrow along both dimensions at once, and null on either dropdown
/// means "any". filteredJobsProvider composes the two.
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

/// A tiny wrapper: label above the dropdown, so the label doesn't have to
/// share the field's horizontal space with the selected value + arrow.
/// This keeps the two dropdowns from overflowing at narrow widths.
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

/// Location dropdown — On-site / Remote / Hybrid, plus a null "All".
class _LocationFilterDropdown extends ConsumerWidget {
  const _LocationFilterDropdown();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(locationFilterProvider);

    return DropdownButtonFormField<LocationType?>(
      // `initialValue` (not the deprecated `value`) is Flutter 3.44+ API for
      // seeding the current selection of DropdownButtonFormField.
      initialValue: selected,
      // isExpanded lets the field take all available width — without it,
      // the internal Row tries to size to its content and overflows a
      // narrow Expanded parent.
      isExpanded: true,
      isDense: true,
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      // A null value is a first-class item (the "All locations" option),
      // not a placeholder — so the Set-Notifier state is a real
      // LocationType? that the filter provider understands directly.
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

/// Job type dropdown — Full-time / Part-time / Contract / Internship,
/// plus a null "All".
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
