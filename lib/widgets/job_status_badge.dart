import 'package:flutter/material.dart';

/// Stretch C — a self-contained status indicator.
///
/// Extracting this from JobCard is worthwhile because the open/closed
/// visual language now has one definition: every place a status is shown
/// (cards, detail screens, dashboards in later weeks) renders it
/// identically, and a change to the styling happens in exactly one file.
class JobStatusBadge extends StatelessWidget {
  final bool isOpen;

  const JobStatusBadge({super.key, required this.isOpen});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final Color bg = isOpen ? scheme.primaryContainer : scheme.errorContainer;
    final Color fg =
        isOpen ? scheme.onPrimaryContainer : scheme.onErrorContainer;
    final String label = isOpen ? 'Open' : 'Closed';
    final IconData icon =
        isOpen ? Icons.check_circle_outline : Icons.lock_outline;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
