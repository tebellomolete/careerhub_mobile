import 'package:flutter/material.dart';

/// Stretch C — shown instead of the job list/grid when there are no
/// jobs to display.
///
/// Purely presentational: HomeScreen decides *when* to show it (based on
/// `_jobs.isEmpty`); this widget only knows how to render the empty
/// state itself. In Week 2, the same widget will render for the
/// "loaded successfully, zero results" case of `AsyncValue<List<Job>>` —
/// see README, Stretch C.
class EmptyJobsWidget extends StatelessWidget {
  const EmptyJobsWidget({super.key});

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
              Icons.work_off_outlined,
              size: 64,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No jobs available',
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back soon — new listings are added regularly.',
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
