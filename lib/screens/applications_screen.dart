import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/application.dart';
import '../providers/application_hub_provider.dart';
import '../providers/applications_notifier.dart';

/// Assignment 3.3 scaffolding + Part 6.4 — the JobSeeker's
/// applications screen.
///
/// The FIRST statement in `build()` is `ref.watch(applicationHubProvider)`
/// per Part 6.4. That single watch is what wires the hub connection
/// lifecycle to this screen: opening the tab starts the connection,
/// leaving it (via `ref.autoDispose`, or via a full ProviderScope
/// disposal) tears it down. The value it returns is discarded — the
/// side-effect of the subscription is the whole point.
class ApplicationsScreen extends ConsumerWidget {
  const ApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Assignment 3.3, Part 6.4 — MUST be the first statement in
    // build(). Watching the hub provider is what starts the
    // connection (via the provider factory's `connect()` call) and
    // registers the `onApplicationUpdated` callback that
    // invalidates `applicationsProvider` on every ApplicationStatusUpdated
    // push. See lib/providers/application_hub_provider.dart.
    ref.watch(applicationHubProvider);

    final applicationsAsync = ref.watch(applicationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My applications'),
      ),
      body: applicationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ApplicationsError(
          message: error.toString().replaceFirst('Exception: ', ''),
          onRetry: () => ref.invalidate(applicationsProvider),
        ),
        data: (applications) {
          if (applications.isEmpty) {
            return const _ApplicationsEmpty();
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(applicationsProvider);
              await ref.read(applicationsProvider.future);
            },
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: applications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, index) => _ApplicationTile(
                application: applications[index],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ApplicationTile extends StatelessWidget {
  final Application application;

  const _ApplicationTile({required this.application});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        title: Text(application.jobTitle ?? 'Untitled listing'),
        subtitle: Text(
          'Submitted ${_formatDate(application.submittedAt)}',
        ),
        // Assignment 3.3, Part 8.2 — semanticsLabel on the status
        // indicator so a screen reader announces the status name.
        // The Chip alone conveys state through colour + label
        // text, both of which are inaccessible to TalkBack /
        // VoiceOver without an explicit Semantics wrapper.
        trailing: _StatusChip(status: application.status),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}

/// Assignment 3.3, Part 8.2 — the status indicator, with a
/// `Semantics` wrapper carrying the status name as its label. Without
/// the wrapper, TalkBack would announce "chip" (or nothing at all) on
/// a Chip whose label is a colour + a short word; with it, TalkBack
/// says "Interviewing" out loud, which is the actual information the
/// widget conveys.
class _StatusChip extends StatelessWidget {
  final ApplicationStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (Color background, Color foreground) = switch (status) {
      ApplicationStatus.submitted => (scheme.surfaceContainerHighest, scheme.onSurface),
      ApplicationStatus.underReview => (scheme.secondaryContainer, scheme.onSecondaryContainer),
      ApplicationStatus.interviewing => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
      ApplicationStatus.offered => (scheme.primaryContainer, scheme.onPrimaryContainer),
      ApplicationStatus.hired => (scheme.primary, scheme.onPrimary),
      ApplicationStatus.rejected => (scheme.errorContainer, scheme.onErrorContainer),
    };

    return Semantics(
      label: 'Application status: ${status.displayName}',
      // Container is a leaf; child text is decorative from the
      // reader's perspective (the label above is what will be
      // announced).
      container: true,
      child: ExcludeSemantics(
        child: Chip(
          label: Text(
            status.displayName,
            style: TextStyle(color: foreground),
          ),
          backgroundColor: background,
          side: BorderSide.none,
        ),
      ),
    );
  }
}

class _ApplicationsEmpty extends StatelessWidget {
  const _ApplicationsEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox_outlined, size: 64),
            const SizedBox(height: 16),
            Text(
              "You haven't submitted any applications yet.",
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Applications you submit will appear here.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ApplicationsError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ApplicationsError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
