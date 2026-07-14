import 'package:flutter/material.dart';

/// A single icon-prefixed line of text — used for a job's location,
/// employment type, salary, and (conditionally) closing date.
///
/// Extracted from JobCard (Assignment 1.2, Question 4): it already
/// repeats three times inside a single card, it has exactly one job —
/// render an icon next to a line of text — and its correctness never
/// depends on JobCard's state or the Job model at all; it only knows
/// about an IconData and a String. All three extraction criteria are
/// satisfied. Purely presentational: no business logic lives here.
class IconLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const IconLine({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: scheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}
