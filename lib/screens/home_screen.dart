import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/job.dart';
import '../providers/application_drafts_notifier.dart';
import '../providers/auth_notifier.dart';
import '../providers/connectivity_provider.dart';
import '../providers/filter_notifier.dart';
import '../providers/job_providers.dart';
import '../providers/jobs_notifier.dart';
import '../router/app_router.dart';
import '../widgets/empty_jobs_widget.dart';
import '../widgets/job_card.dart';
import '../widgets/jobs_shimmer.dart';

/// Assignment 3.1, Part 3–4 — the jobs list screen after widget
/// extraction and `RepaintBoundary` isolation.
///
/// **Class-level checkpoint (Part 3.4 + Part 8.2):**
///   - `HomeScreen.build` calls `ref.watch` **zero** times. Every
///     provider subscription lives inside `_FilterChips`, `_JobList`,
///     `_JobSortAction`, or `_JobsAppBar` — all private const
///     `ConsumerWidget` classes below.
///   - `ref.read` is used inside the logout button's `onPressed` and
///     inside `ref.listen`'s callback — Part 3.4 explicitly permits
///     both. Neither creates a subscription that rebuilds this class.
///   - `ref.listen<bool>(isOfflineProvider, ...)` is registered once
///     at first mount and survives every subsequent rebuild without
///     re-registering; it does NOT count as a `ref.watch`. It drives
///     the Stretch C reconnect-drain of the application-draft queue.
///
/// **Body shape (Part 3.4 checkpoint, literally verbatim):**
///
/// ```dart
/// body: const Column(
///   crossAxisAlignment: CrossAxisAlignment.start,
///   children: [
///     _FilterChips(),
///     Expanded(child: _JobList()),
///   ],
/// ),
/// ```
///
/// The offline banner from Assignment 2.3 and the pending-drafts
/// banner from Stretch C are rendered at the top of `_JobList`, NOT
/// as a sibling of `_FilterChips`, so the mandated const-Column body
/// shape stays literal.
///
/// **Features preserved from earlier assignments** — moved to the
/// AppBar as private const `ConsumerWidget` children so the screen
/// class stays subscription-free: keyword search (opens
/// `_JobSearchDelegate`), sort order menu, and logout. The
/// job-type dropdown and the grid layout from 2.3 are dropped — the
/// filter chip row already covers location; job-type filtering can
/// live in a later assignment.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Assignment 3.1 Stretch C — on the offline → online transition,
    // drain any pending application drafts. `ref.listen` registers a
    // subscription on first build; because this widget never
    // rebuilds (the body below is a const Column with private const
    // consumers), the listener stays alive for the lifetime of the
    // screen with no risk of accumulating duplicates.
    ref.listen<bool>(isOfflineProvider, (previous, next) {
      if (previous == true && next == false) {
        // Fire-and-forget — the controller handles its own errors
        // and the banner disappears when Isar drops the drained
        // rows.
        ref.read(applicationDraftsControllerProvider).syncPending();
      }
    });

    return const Scaffold(
      appBar: _JobsAppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FilterChips(),
          Expanded(child: _JobList()),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// AppBar — search / sort / logout actions live here as private const
// ConsumerWidgets so the screen class above stays subscription-free.
// ═══════════════════════════════════════════════════════════════════════════

class _JobsAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const _JobsAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBar(
      title: const Text('CareerHub'),
      centerTitle: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: 'Search jobs',
          onPressed: () async {
            // showSearch owns its own Navigator route. The returned
            // String is the delegate's `close(context, value)`
            // argument — unused here.
            await showSearch<String>(
              context: context,
              delegate: _JobSearchDelegate(),
            );
          },
        ),
        const _JobSortAction(),
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Sign out',
          onPressed: () {
            // Assignment 2.4, Part 9.3 — invalidate user-scoped
            // providers FIRST, then flip auth state. Order matters
            // (see README 2.4 Q4).
            ref.invalidate(jobsProvider);
            ref.invalidate(savedJobIdsProvider);
            ref.read(authProvider.notifier).logout();
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

/// Sort order menu — kept as a private const ConsumerWidget so its
/// ref.watch on `sortOrderProvider` does not bubble to
/// `_JobsAppBar` or `HomeScreen`. The screen class must retain zero
/// watches (Part 3.4 checkpoint).
class _JobSortAction extends ConsumerWidget {
  const _JobSortAction();

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

// ═══════════════════════════════════════════════════════════════════════════
// Part 3.2 — _FilterChips.
//
// A private const ConsumerWidget with a no-arg constructor. Owns the
// single `ref.watch(filterProvider)` and the four horizontally
// scrollable FilterChips. `onSelected` calls
// `ref.read(filterProvider.notifier).select(...)` — the standard
// widget-level `watch` for reads / `read` for mutations rule.
// ═══════════════════════════════════════════════════════════════════════════

/// The four options exposed by the filter chip row. Kept as a
/// top-level const list so the FilterChip labels and the persisted
/// `filterProvider` string values live in one place.
///
/// Values match the strings the location `filterProvider` writes to
/// SharedPreferences — `'All'` is `kFilterAll`, and the three
/// `LocationType.name` strings (`'onSite'`, `'remote'`, `'hybrid'`)
/// are the exact tokens `_locationTypeFromFilter` in
/// `job_providers.dart` compares against.
const List<({String value, String label})> _kFilterOptions = [
  (value: 'All', label: 'All'),
  (value: 'onSite', label: 'On-site'),
  (value: 'remote', label: 'Remote'),
  (value: 'hybrid', label: 'Hybrid'),
];

class _FilterChips extends ConsumerWidget {
  const _FilterChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(filterProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          for (final option in _kFilterOptions) ...[
            FilterChip(
              label: Text(option.label),
              selected: selected == option.value,
              onSelected: (_) =>
                  ref.read(filterProvider.notifier).select(option.value),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Part 3.3 + Part 4.1 — _JobList.
//
// Owns:
//   - `ref.watch(filteredJobsProvider)` — the one subscription this
//     class carries.
//   - The complete `when()` block with all three arms.
//   - The `RepaintBoundary` (Part 4.1) that wraps ONLY the ListView
//     inside the data arm — not the whole when(), not the loading
//     arm, not the error arm.
//   - The top banners (offline / pending-drafts) rendered above the
//     scroll view. Placing them here keeps `HomeScreen`'s body
//     literal to the Part 3.4 checkpoint.
// ═══════════════════════════════════════════════════════════════════════════

class _JobList extends ConsumerWidget {
  const _JobList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(filteredJobsProvider);

    return Column(
      children: [
        const _TopBanners(),
        Expanded(
          child: async.when(
            // Part 6.2 — the loading arm is now the shimmer skeleton.
            loading: () => const JobsShimmer(),
            error: (error, stackTrace) => _ErrorState(
              onRetry: () => ref.read(jobsProvider.notifier).refresh(),
            ),
            data: (jobs) {
              if (jobs.isEmpty) {
                return const EmptyJobsWidget(
                  icon: Icons.filter_alt_off_outlined,
                  title: 'No jobs match your filter',
                  message: 'Try a different filter chip.',
                );
              }
              // Part 4.1 — RepaintBoundary wraps ONLY the ListView.
              // Not the whole when(), not the empty state, not the
              // loading or error arms. See README 3.1 Q2 on layer
              // isolation.
              return RepaintBoundary(
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: jobs.length,
                  itemBuilder: (context, index) {
                    final job = jobs[index];
                    return InkWell(
                      onTap: () =>
                          context.push(AppRoutes.jobDetail(job.id)),
                      child: JobCard(job: job),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Top banners — offline + pending drafts (Stretch C).
//
// Two banners share a slot at the very top of the list area. Offline
// takes precedence (it's the more urgent state); the drafts banner
// shows only when the app is online and drafts remain undrained.
// ═══════════════════════════════════════════════════════════════════════════

class _TopBanners extends ConsumerWidget {
  const _TopBanners();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOffline = ref.watch(isOfflineProvider);
    if (isOffline) return const _OfflineBanner();

    // Stretch C — persistent banner while drafts remain in Isar.
    final hasDrafts = ref.watch(hasPendingDraftsProvider);
    if (hasDrafts) return const _PendingDraftsBanner();

    return const SizedBox.shrink();
  }
}

class _OfflineBanner extends ConsumerWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
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

/// Assignment 3.1 Stretch C — the persistent "drafts pending" banner.
class _PendingDraftsBanner extends ConsumerWidget {
  const _PendingDraftsBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final count = ref.watch(pendingDraftsCountProvider);

    return Container(
      width: double.infinity,
      color: scheme.tertiaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(
            Icons.upload_file_outlined,
            color: scheme.onTertiaryContainer,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              count == 1
                  ? 'You have 1 application draft waiting to sync.'
                  : 'You have $count application drafts waiting to sync.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onTertiaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Search delegate — invoked from the AppBar search action.
// ═══════════════════════════════════════════════════════════════════════════

class _JobSearchDelegate extends SearchDelegate<String> {
  @override
  List<Widget>? buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear),
            tooltip: 'Clear',
            onPressed: () => query = '',
          ),
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: 'Back',
        onPressed: () => close(context, ''),
      );

  @override
  Widget buildResults(BuildContext context) => _buildResults();

  @override
  Widget buildSuggestions(BuildContext context) => _buildResults();

  Widget _buildResults() {
    return Consumer(
      builder: (context, ref, _) {
        final async = ref.watch(jobsProvider);
        return async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(
            child: Text("Couldn't load jobs. Please try again."),
          ),
          data: (List<Job> jobs) {
            final q = query.trim();
            final filtered =
                q.isEmpty ? jobs : jobs.where((j) => j.matches(q)).toList();
            if (filtered.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'No matching jobs.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final job = filtered[index];
                return InkWell(
                  onTap: () {
                    close(context, '');
                    context.push(AppRoutes.jobDetail(job.id));
                  },
                  child: JobCard(job: job),
                );
              },
            );
          },
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Error state — retained from Assignment 2.3.
// ═══════════════════════════════════════════════════════════════════════════

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
