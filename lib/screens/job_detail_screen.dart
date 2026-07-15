import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/job.dart';
import '../providers/job_providers.dart';
import '../widgets/icon_line.dart';
import '../widgets/job_status_badge.dart';

/// Assignment 1.4 — the full detail view for a single job.
///
/// It receives only a [jobId] extracted from the URL path parameter — never
/// a Job object injected through the constructor. That is the whole point of
/// URL-based navigation: the screen must be able to render from nothing but
/// an id, because it can be reached from a push notification or a shared
/// link with no in-memory Job to hand it. It resolves the id against the
/// job list itself.
class JobDetailScreen extends ConsumerWidget {
  /// Nullable because the URL segment may not parse to an int (e.g.
  /// /jobs/abc). A null id is handled as "not found", never a crash.
  final int? jobId;

  const JobDetailScreen({super.key, required this.jobId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the RAW, unfiltered jobsProvider — not visibleJobsProvider or
    // filteredJobsProvider — because a job's identity must not depend on
    // whether it currently passes the list screen's active filter/search:
    // /jobs/3 has to resolve even when the "Remote" chip is hiding job 3
    // from the list the user navigated away from.
    final jobsAsync = ref.watch(jobsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job details'),
      ),
      // Handle all three AsyncValue states explicitly.
      body: jobsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _DetailError(
          onRetry: () => ref.invalidate(jobsProvider),
        ),
        data: (jobs) {
          // Resolve the id to a job. firstWhere with orElse avoids throwing;
          // a missing match yields null and the graceful "not found" state
          // below — an invalid or stale link must never crash the app.
          final Job? job = _findById(jobs, jobId);
          if (job == null) {
            return _JobNotFound(jobId: jobId);
          }
          return _JobDetailBody(job: job);
        },
      ),
    );
  }

  static Job? _findById(List<Job> jobs, int? id) {
    if (id == null) return null;
    for (final job in jobs) {
      if (job.id == id) return job;
    }
    return null;
  }
}

/// The populated detail body — renders EVERY meaningful field on the model,
/// including ones the card omits (id, description, closing date, the
/// derived canApply rule), not just the card's summary subset.
class _JobDetailBody extends ConsumerWidget {
  final Job job;

  const _JobDetailBody({required this.job});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final savedIds = ref.watch(savedJobIdsProvider);
    final isSaved = savedIds.contains(job.id);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Title + open/closed badge.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                job.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            JobStatusBadge(isOpen: job.canApply),
          ],
        ),
        const SizedBox(height: 8),

        // Company.
        Text(
          job.company,
          style: theme.textTheme.titleMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),

        // Core facts, every field spelled out.
        IconLine(icon: Icons.place_outlined, text: job.location),
        const SizedBox(height: 8),
        IconLine(icon: Icons.work_outline, text: job.employmentType),
        const SizedBox(height: 8),
        IconLine(icon: Icons.payments_outlined, text: job.displaySalary),
        const SizedBox(height: 8),
        IconLine(
          icon: Icons.event_outlined,
          text: job.closingDate != null
              ? 'Closes: ${_formatDate(job.closingDate!)}'
              : 'No closing date — open until filled',
        ),
        const SizedBox(height: 8),
        IconLine(
          icon: job.canApply ? Icons.how_to_reg_outlined : Icons.block,
          text: job.canApply
              ? 'Accepting applications'
              : 'Applications closed',
        ),
        const SizedBox(height: 8),
        // The stable id — surfaced so the URL/deep-link story is visible.
        IconLine(icon: Icons.tag, text: 'Listing ID: ${job.id}'),

        const SizedBox(height: 24),

        // Description — full text, or an honest placeholder when absent.
        Text(
          'About this role',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          (job.description != null && job.description!.trim().isNotEmpty)
              ? job.description!
              : 'No description was provided for this listing yet.',
          style: theme.textTheme.bodyLarge,
        ),

        const SizedBox(height: 28),

        // Save / apply actions.
        FilledButton.icon(
          onPressed: job.canApply
              ? () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Application started for ${job.title}'),
                    ),
                  );
                }
              : null,
          icon: const Icon(Icons.send_outlined),
          label: Text(job.canApply ? 'Apply now' : 'Applications closed'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {
            final notifier = ref.read(savedJobIdsProvider.notifier);
            final next = Set<int>.from(savedIds);
            if (isSaved) {
              next.remove(job.id);
            } else {
              next.add(job.id);
            }
            notifier.state = next;
          },
          icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
          label: Text(isSaved ? 'Saved' : 'Save this job'),
        ),
      ],
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

/// Shown when the id in the URL matches no job — an invalid or stale link.
/// Graceful, not a crash: the user gets a clear message and a way back.
class _JobNotFound extends StatelessWidget {
  final int? jobId;

  const _JobNotFound({required this.jobId});

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
            Icon(Icons.search_off, size: 64, color: scheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'Job not found',
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              jobId == null
                  ? "That link doesn't point to a valid job."
                  : "We couldn't find a job with ID $jobId. It may have been "
                      'removed.',
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

/// The error state for the detail screen's async load.
class _DetailError extends StatelessWidget {
  final VoidCallback onRetry;

  const _DetailError({required this.onRetry});

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
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "We couldn't load this job. Please try again.",
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
