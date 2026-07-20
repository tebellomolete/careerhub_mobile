import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/job_application.dart';
import '../providers/applications_notifier.dart';
import '../widgets/application_status_badge.dart';

/// W2D3 in-class challenge, stretch — the application detail screen.
///
/// Reads the applications list from the notifier (already cached, so
/// this is a synchronous lookup once the list is loaded) and finds the
/// row by composite id. The route uses a `:id` path parameter (see
/// `AppRoutes.applicationDetail`) so the URL is deep-linkable.
///
/// Sits inside the Applications branch of the shell, so tapping back
/// preserves the list scroll position and the selected filter — the
/// state lives in the notifier, which the branch keeps alive.
class ApplicationDetailScreen extends ConsumerWidget {
  final String? applicationId;

  const ApplicationDetailScreen({super.key, required this.applicationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(applicationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Application')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load: $e')),
        data: (apps) {
          if (applicationId == null) {
            return const _NotFound(reason: 'No application id in the URL.');
          }
          final match = apps.where((a) => a.id == applicationId).firstOrNull;
          if (match == null) {
            return _NotFound(reason: 'No application with id "$applicationId".');
          }
          return _DetailBody(app: match);
        },
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  final JobApplication app;

  const _DetailBody({required this.app});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            app.jobTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            app.companyName,
            style: theme.textTheme.titleMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          ApplicationStatusBadge(status: app.status),
          const SizedBox(height: 24),
          _DetailRow(label: 'Submitted', value: _formatDate(app.submittedAt)),
          _DetailRow(label: 'Application id', value: app.id),
        ],
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

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(value, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _NotFound extends StatelessWidget {
  final String reason;
  const _NotFound({required this.reason});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 64),
            const SizedBox(height: 12),
            Text(reason, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
