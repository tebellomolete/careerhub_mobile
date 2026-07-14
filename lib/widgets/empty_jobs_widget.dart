import 'package:flutter/material.dart';

/// Stretch C (Assignment 1.1) — shown instead of the job list/grid when
/// there are no jobs to display.
///
/// Assignment 1.3 change: icon/title/message are now optional
/// parameters, defaulting to the original Assignment 1.1 copy so nothing
/// about existing call sites changes. HomeScreen now needs this widget
/// for TWO distinct empty cases — "no jobs exist at all" and "jobs
/// exist, but none match the current filter" (README Q3's fourth
/// condition) — and those deserve different copy: telling a user to
/// "check back soon" when the real fix is "try a different filter" is
/// actively misleading.
class EmptyJobsWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const EmptyJobsWidget({
    super.key,
    this.icon = Icons.work_off_outlined,
    this.title = 'No jobs available',
    this.message = 'Check back soon — new listings are added regularly.',
  });

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
              icon,
              size: 64,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              title,
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
          ],
        ),
      ),
    );
  }
}
