import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../models/auth_state.dart';
import '../providers/auth_notifier.dart';

/// Assignment 3.1, Part 5 — LoginScreen as a HookConsumerWidget.
///
/// **What changed vs Assignment 2.4.**
///   - The class hierarchy collapsed from `ConsumerStatefulWidget` +
///     `ConsumerState` down to a single class extending
///     `HookConsumerWidget`. `createState()`, the entire `_LoginScreenState`
///     subclass, the `TextEditingController` field declarations, the
///     `initState`/`dispose` overrides, and the `_submit()` instance
///     method are all gone.
///   - Both controllers are now returned by `useTextEditingController()`
///     — the hooks framework's `HookState.dispose()` runs the
///     controller's `dispose()` automatically when the element
///     unmounts (see README 3.1 Q3 on the disposal guarantee).
///   - `submit` is a **local function inside `build()`**. It closes
///     over the two controller locals, so it takes no parameters.
///
/// **Import change.** This file imports `hooks_riverpod` and
/// `flutter_hooks` instead of `flutter_riverpod`. `hooks_riverpod`
/// re-exports the entire Riverpod 3 API surface — `ProviderScope`,
/// `ConsumerWidget`, `WidgetRef`, `ref.watch/read/listen` — so no
/// other file that continues to use `ConsumerWidget` needs to change.
/// Both packages run against the same `ProviderScope` in `main.dart`.
class LoginScreen extends HookConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Hooks — order matters. Both allocated on first build, returned
    // as the same instances on every subsequent build. Disposed by
    // the hook framework on unmount — no manual dispose here.
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();

    final auth = ref.watch(authProvider);

    // Derive two view-model values from the watched AsyncValue.
    // `isLoading` here means the AsyncData wraps Authenticating
    // (the login mutator sets that BEFORE any await, so we
    // don't need to consult `auth.isLoading` — that would only
    // be true during cold-boot build()).
    final resolved = auth.value;
    final bool loading = resolved is Authenticating;

    // Pattern-match on the AuthError variant to extract the message.
    // `null` in every other case; the widget below treats `null` as
    // "no error to show".
    final String? errorMessage = switch (resolved) {
      AuthError(:final message) => message,
      _ => null,
    };

    // Local closure — captures the controller locals from the enclosing
    // `build()` call frame, so it needs no parameters. Called by the
    // password field's `onSubmitted` and the Sign-in button's
    // `onPressed`.
    void submit() {
      final email = emailController.text.trim();
      final password = passwordController.text;
      ref.read(authProvider.notifier).login(email, password);
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.work_history_outlined,
                  size: 72,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  'CareerHub',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to browse and save jobs.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => loading ? null : submit(),
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    errorMessage,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: loading ? null : submit,
                  child: loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Sign in'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
