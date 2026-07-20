import 'package:flutter/material.dart';

import '../models/job_application.dart';
import 'application_status_badge.dart';
import 'icon_line.dart';

/// W2D3 in-class challenge, Part 6.3 — the extracted list-row widget.
///
/// Design constraints the assessment criteria enforce:
///   - StatelessWidget (not Consumer, not ConsumerWidget) — the card
///     never reads a provider directly; every value it renders comes
///     in as a typed, required, named parameter.
///   - The `onTap` callback is `VoidCallback?` (nullable) so the same
///     card can be rendered inside a `MaterialApp` unit test without
///     wiring up a router.
///   - Displays: title, company, formatted date, [ApplicationStatusBadge].
class ApplicationCard extends StatelessWidget {
  final String jobTitle;
  final String companyName;
  final DateTime submittedAt;
  final ApplicationStatus status;
  final VoidCallback? onTap;

  const ApplicationCard({
    super.key,
    required this.jobTitle,
    required this.companyName,
    required this.submittedAt,
    required this.status,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
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
                      jobTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ApplicationStatusBadge(status: status),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                companyName,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              IconLine(
                icon: Icons.event_outlined,
                text: 'Applied ${_formatDate(submittedAt)}',
              ),
            ],
          ),
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
