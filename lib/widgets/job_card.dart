import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/job.dart';
import '../providers/connectivity_provider.dart';
import '../providers/job_providers.dart';
import 'job_status_badge.dart';
import 'icon_line.dart';

/// Displays a single [Job] in a scannable card.
///
/// Assignment 1.2 change: the inline icon+text rows use the extracted
/// [IconLine] widget instead of a private class defined in this file.
///
/// Assignment 2.3 change (Stretch C — Offline action gating): the card
/// gains a bookmark IconButton in its top row. Behaviour:
///   - Online: tapping toggles the job's id in [savedJobIdsProvider]
///     (the same provider the Saved tab reads).
///   - Offline (`isOfflineProvider` returns `true`): `onPressed` is
///     `null`, which makes Material 3 render the button in its
///     built-in disabled appearance automatically. A `GestureDetector`
///     wrapper still catches the tap and shows a `SnackBar` reading
///     "You are offline. Saving is not available."
///
/// The online/offline state comes exclusively from `isOfflineProvider`
/// and updates automatically without any user interaction — the
/// `ref.watch` in `build` re-runs the moment connectivity flips.
///
/// The card was migrated from `StatelessWidget` to `ConsumerWidget`
/// for this stretch — no other change was needed to the layout.
class JobCard extends ConsumerWidget {
  final Job job;

  const JobCard({super.key, required this.job});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Stretch C — the offline flag and the saved-set are both read at
    // build time so the button reflects current state on every
    // rebuild.
    final isOffline = ref.watch(isOfflineProvider);
    final savedIds = ref.watch(savedJobIdsProvider);
    final isSaved = savedIds.contains(job.id);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + save button + status badge on one row.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    job.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                _SaveJobButton(
                  isOffline: isOffline,
                  isSaved: isSaved,
                  jobId: job.id,
                ),
                const SizedBox(width: 4),
                // Uses the model's canApply, not a hardcoded value.
                JobStatusBadge(isOpen: job.canApply),
              ],
            ),
            const SizedBox(height: 4),

            // Company.
            Text(
              job.company,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),

            // Location.
            IconLine(icon: Icons.place_outlined, text: job.location),
            const SizedBox(height: 4),

            // Employment type.
            IconLine(icon: Icons.work_outline, text: job.employmentType),
            const SizedBox(height: 4),

            // Salary — always via displaySalary, never the raw field.
            IconLine(icon: Icons.payments_outlined, text: job.displaySalary),

            // Closing date — collection-if: rendered ONLY when present.
            if (job.closingDate != null) ...[
              const SizedBox(height: 4),
              IconLine(
                icon: Icons.event_outlined,
                text: 'Closes: ${_formatDate(job.closingDate!)}',
              ),
            ],

            // Description — collection-if: rendered ONLY when present.
            if (job.description != null &&
                job.description!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                job.description!,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

/// Assignment 2.3, Stretch C — the save-job bookmark IconButton.
///
/// Split out so the offline-vs-online logic is inspectable in one
/// place. Two mutually exclusive branches:
///
///   - **Offline** (`isOffline == true`): `IconButton.onPressed` is
///     `null`, which triggers Material 3's built-in disabled
///     appearance (icon at 38% opacity on `onSurface`). A
///     `GestureDetector` wraps the disabled button with
///     `HitTestBehavior.opaque` so the ignored `IconButton` tap is
///     still received by the outer detector, which shows a
///     `SnackBar` with the offline-specific copy.
///   - **Online**: `IconButton.onPressed` toggles the job's id in
///     [savedJobIdsProvider] — the same provider the Saved tab reads.
///     The `GestureDetector` wrapping is still present but its
///     `onTap` is `null`, so taps pass through to the enabled
///     `IconButton`.
///
/// The visual/interactive state comes ENTIRELY from `isOfflineProvider`
/// — a connectivity flip re-runs the parent's `build`, this widget
/// rebuilds with the new value, and the branch swaps automatically
/// without user interaction. See README 2.3, Stretch C.
class _SaveJobButton extends ConsumerWidget {
  final bool isOffline;
  final bool isSaved;
  final String jobId;

  const _SaveJobButton({
    required this.isOffline,
    required this.isSaved,
    required this.jobId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isOffline) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You are offline. Saving is not available.'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        // `onPressed: null` renders the disabled Material 3 style
        // automatically. No manual grey styling required.
        child: const IconButton(
          onPressed: null,
          icon: Icon(Icons.bookmark_outline),
          tooltip: 'Save (offline — unavailable)',
        ),
      );
    }

    return IconButton(
      icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_outline),
      tooltip: isSaved ? 'Remove from saved' : 'Save this job',
      onPressed: () {
        // Toggle the id in the immutable Set. `ref.read` because this
        // is a mutation handler, not a build method.
        final notifier = ref.read(savedJobIdsProvider.notifier);
        final current = ref.read(savedJobIdsProvider);
        final next = Set<String>.from(current);
        if (isSaved) {
          next.remove(jobId);
        } else {
          next.add(jobId);
        }
        notifier.state = next;
      },
    );
  }
}
