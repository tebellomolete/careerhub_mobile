import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/saved_jobs_repository.dart';
import '../models/job.dart';
import '../providers/job_providers.dart';
import '../providers/saved_jobs_notifier.dart';
import 'job_status_badge.dart';
import 'icon_line.dart';

/// Displays a single [Job] in a scannable card.
///
/// Assignment 2.4 Stretch C rewrite: the bookmark IconButton now
/// routes through `SavedJobsController`. Online saves POST
/// immediately and confirm silently. Offline saves write a
/// pending row to `SavedJobCache` (via the repository) and show
/// a SnackBar. When connectivity returns, `PendingSyncService`
/// drains the queue automatically — no additional wiring here.
class JobCard extends ConsumerWidget {
  final Job job;

  const JobCard({super.key, required this.job});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final savedIds = ref.watch(savedJobIdsProvider);
    final isSaved = savedIds.contains(job.id);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                _SaveJobButton(isSaved: isSaved, jobId: job.id),
                const SizedBox(width: 4),
                JobStatusBadge(isOpen: job.canApply),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              job.company,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            IconLine(icon: Icons.place_outlined, text: job.location),
            const SizedBox(height: 4),
            IconLine(icon: Icons.work_outline, text: job.employmentType),
            const SizedBox(height: 4),
            IconLine(icon: Icons.payments_outlined, text: job.displaySalary),
            if (job.closingDate != null) ...[
              const SizedBox(height: 4),
              IconLine(
                icon: Icons.event_outlined,
                text: 'Closes: ${_formatDate(job.closingDate!)}',
              ),
            ],
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

/// Assignment 2.4 Stretch C — the bookmark IconButton.
///
/// Behaviour:
///   - Tap while **not** saved → `SavedJobsController.save(jobId)`.
///     The controller writes to Isar optimistically (pending),
///     tries the server, and returns an outcome the widget uses
///     to show a SnackBar for the queued/not-found cases.
///   - Tap while **already** saved → `.remove(jobId)`.
class _SaveJobButton extends ConsumerWidget {
  final bool isSaved;
  final String jobId;

  const _SaveJobButton({required this.isSaved, required this.jobId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_outline),
      tooltip: isSaved ? 'Remove from saved' : 'Save this job',
      onPressed: () async {
        final controller = ref.read(savedJobsControllerProvider);
        if (isSaved) {
          await controller.remove(jobId);
          return;
        }
        final outcome = await controller.save(jobId);
        if (!context.mounted) return;
        switch (outcome) {
          case SaveOutcome.saved:
            break;
          case SaveOutcome.queued:
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text('Saved offline — will sync when back online.'),
                duration: Duration(seconds: 2),
              ),
            );
          case SaveOutcome.notFound:
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text('This listing is no longer available on the server.'),
                duration: Duration(seconds: 3),
              ),
            );
        }
      },
    );
  }
}
