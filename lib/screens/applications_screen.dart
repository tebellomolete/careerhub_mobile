import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/job_application.dart';
import '../providers/applications_notifier.dart';
import '../providers/connectivity_provider.dart';
import '../router/app_router.dart';
import '../widgets/application_card.dart';

/// W2D3 in-class challenge, Part 6 — the Applications list screen.
///
/// A ConsumerWidget (no local state) that composes:
///   - the derived `filteredApplicationsProvider` from Part 4.3;
///   - the offline banner driven by `isOfflineProvider` from
///     `connectivity_provider.dart`;
///   - the horizontal filter-chip row from Part 6.5;
///   - the responsive body: single-column `ListView` below 600 logical
///     pixels, two-column `GridView` at 600px and above (Part 6.2).
class ApplicationsScreen extends ConsumerWidget {
  const ApplicationsScreen({super.key});

  static const double _gridBreakpoint = 600;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredAsync = ref.watch(filteredApplicationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Applications'),
        centerTitle: false,
      ),
      body: Column(
        children: [
          const _OfflineBanner(),
          const _FilterChipsRow(),
          Expanded(
            child: filteredAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _ErrorState(
                message: error.toString(),
                onRetry: () =>
                    ref.read(applicationsProvider.notifier).refresh(),
              ),
              data: (apps) => _ApplicationsBody(apps: apps),
            ),
          ),
        ],
      ),
    );
  }
}

/// Part 6.6 — the offline banner. Automatic: no user tap required to
/// show or hide it. Stretch — includes the "Last synced" timestamp so
/// the user knows how fresh the offline cache is.
class _OfflineBanner extends ConsumerWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOffline = ref.watch(isOfflineProvider);
    if (!isOffline) return const SizedBox.shrink();

    final lastSynced = ref.watch(lastSyncedProvider);
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.cloud_off_outlined, color: scheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "You're offline — showing cached applications.",
                    style: TextStyle(
                      color: scheme.onErrorContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (lastSynced != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Last synced ${_relativeTime(lastSynced)}',
                      style: TextStyle(
                        color: scheme.onErrorContainer,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _relativeTime(DateTime then) {
    final delta = DateTime.now().difference(then);
    if (delta.inMinutes < 1) return 'just now';
    if (delta.inMinutes < 60) return '${delta.inMinutes} min ago';
    if (delta.inHours < 24) return '${delta.inHours} h ago';
    return '${delta.inDays} d ago';
  }
}

/// Part 6.5 — horizontally scrollable filter chip row.
class _FilterChipsRow extends ConsumerWidget {
  const _FilterChipsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(applicationFilterProvider);

    // "All" (represented by a null ApplicationFilter) is always the
    // first chip; then one chip per enum value in declaration order,
    // so a new status added to the enum automatically shows up here.
    final chips = <(ApplicationFilter filter, String label)>[
      (null, 'All'),
      ...ApplicationStatus.values.map((s) => (s, s.displayLabel)),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          for (final (filter, label) in chips) ...[
            ChoiceChip(
              label: Text(label),
              selected: selected == filter,
              onSelected: (_) =>
                  ref.read(applicationFilterProvider.notifier).select(filter),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

/// The list/grid body. Responsive at the 600px breakpoint per Part 6.2.
/// Pull-to-refresh (stretch) wraps both layouts.
class _ApplicationsBody extends ConsumerWidget {
  final List<JobApplication> apps;

  const _ApplicationsBody({required this.apps});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (apps.isEmpty) {
      return const _EmptyState();
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(applicationsProvider.notifier).refresh(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          if (width < ApplicationsScreen._gridBreakpoint) {
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: apps.length,
              itemBuilder: (_, i) => _card(context, apps[i]),
            );
          }
          return GridView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.6,
            ),
            itemCount: apps.length,
            itemBuilder: (_, i) => _card(context, apps[i]),
          );
        },
      ),
    );
  }

  Widget _card(BuildContext context, JobApplication app) {
    return ApplicationCard(
      jobTitle: app.jobTitle,
      companyName: app.companyName,
      submittedAt: app.submittedAt,
      status: app.status,
      onTap: () => context.push(AppRoutes.applicationDetail(app.id)),
    );
  }
}

/// Stretch (empty state) — shown when the filter is active but no
/// applications match. Uses a built-in Material icon; no assets.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

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
            Icon(
              Icons.filter_alt_off_outlined,
              size: 64,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'No applications match this filter',
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try the "All" chip to see every application.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Part 6.1 — the error state with a retry button. Only reached when
/// the cache is empty AND the network fetch failed AND the notifier
/// couldn't fall back to the demo seed (i.e. a genuinely broken load).
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

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
              "Couldn't load applications",
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
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
