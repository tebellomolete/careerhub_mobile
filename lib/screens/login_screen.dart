import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/job_providers.dart';

/// Stretch C — a minimal login screen, rendered OUTSIDE the shell (no
/// NavigationBar).
///
/// The "Log In" button does exactly one thing: flip isLoggedInProvider to
/// true. It never calls context.go(). The router's refreshListenable is
/// wired to that provider, so the flip alone re-runs the redirect, which
/// then sends the now-authenticated user to /jobs automatically. See README
/// Stretch C.
class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.work_history_outlined,
                size: 72,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Welcome to CareerHub',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to browse and save jobs.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                // No context.go here — flipping the provider is enough.
                onPressed: () =>
                    ref.read(isLoggedInProvider.notifier).state = true,
                icon: const Icon(Icons.login),
                label: const Text('Log In'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
