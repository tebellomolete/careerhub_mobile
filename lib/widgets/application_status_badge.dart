import 'package:flutter/material.dart';

import '../models/job_application.dart';

/// W2D3 in-class challenge, Part 6.4 — a self-contained status pill.
///
/// Two properties the assessment criteria enforce:
///   1. **Switch EXPRESSION** (not an if/else chain) for the colour +
///      icon mapping. Because the input is a Dart `enum`, the compiler
///      verifies the switch is exhaustive at analysis time — omitting
///      any [ApplicationStatus] value is a **compile error**, not a
///      lurking runtime fallback.
///   2. **Material 3 colour roles only.** Every pair of `bg` / `fg`
///      values comes from `ColorScheme` — no raw hex, no
///      `Colors.grey.shade400`, no theming shortcut. That is what
///      makes the badge match the seed-colour palette in light AND
///      dark mode without a per-mode override.
///
/// The widget is a StatelessWidget with a typed, required, named
/// parameter — no `ref.watch`, no context.read — every input flows in
/// from the parent.
class ApplicationStatusBadge extends StatelessWidget {
  final ApplicationStatus status;

  const ApplicationStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ({Color bg, Color fg, IconData icon}) style = switch (status) {
      ApplicationStatus.submitted => (
          bg: scheme.secondaryContainer,
          fg: scheme.onSecondaryContainer,
          icon: Icons.upload_outlined,
        ),
      ApplicationStatus.underReview => (
          bg: scheme.tertiaryContainer,
          fg: scheme.onTertiaryContainer,
          icon: Icons.visibility_outlined,
        ),
      ApplicationStatus.interviewing => (
          bg: scheme.primaryContainer,
          fg: scheme.onPrimaryContainer,
          icon: Icons.forum_outlined,
        ),
      ApplicationStatus.offered => (
          bg: scheme.primary,
          fg: scheme.onPrimary,
          icon: Icons.local_offer_outlined,
        ),
      ApplicationStatus.hired => (
          bg: scheme.inversePrimary,
          fg: scheme.onSurface,
          icon: Icons.check_circle_outline,
        ),
      ApplicationStatus.rejected => (
          bg: scheme.errorContainer,
          fg: scheme.onErrorContainer,
          icon: Icons.cancel_outlined,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: 14, color: style.fg),
          const SizedBox(width: 4),
          Text(
            status.displayLabel,
            style: TextStyle(
              color: style.fg,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
