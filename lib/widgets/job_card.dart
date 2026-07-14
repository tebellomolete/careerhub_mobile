import 'package:flutter/material.dart';
import '../models/job.dart';
import 'job_status_badge.dart';
import 'icon_line.dart';

/// Displays a single [Job] in a scannable card.
///
/// The card accepts a whole Job — not loose fields — and is
/// const-constructible. Fields that may be absent are rendered with
/// collection-if so a missing value produces no UI at all: no blank
/// label, no "N/A", no empty gap. The card never crashes for any valid
/// Job, including one where every nullable field is null.
///
/// Assignment 1.2 change: the inline icon+text rows now use the
/// extracted [IconLine] widget (see Question 4) instead of a private
/// class defined in this file. Every colour and text style here was
/// already a theme reference in Assignment 1.1 — see README Question 3 —
/// so nothing else in this file needed to change for dark mode.
class JobCard extends StatelessWidget {
  final Job job;

  const JobCard({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + status badge on one row.
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
                const SizedBox(width: 8),
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
