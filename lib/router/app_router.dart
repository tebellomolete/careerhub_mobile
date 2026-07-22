import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/auth_state.dart';
import '../providers/auth_notifier.dart';
import '../providers/auth_provider.dart';
import '../screens/apply_screen.dart';
import '../screens/home_screen.dart';
import '../screens/job_detail_screen.dart';
import '../screens/login_screen.dart';
import '../screens/saved_screen.dart';
import '../widgets/scaffold_with_nav_bar.dart';

// Assignment 2.4, Part 8.1 — the router is now a code-generated
// provider so it participates in the same dependency graph as
// every other provider in the app. `part 'app_router.g.dart'`
// pulls in the `appRouterProvider` this @riverpod function
// produces.
part 'app_router.g.dart';

/// Path constants — one place to change a URL, referenced
/// everywhere a route is built or navigated to.
class AppRoutes {
  const AppRoutes._();

  static const String jobs = '/jobs';
  static const String saved = '/saved';
  static const String login = '/login';

  static String jobDetail(String id) => '$jobs/$id';
}

/// Assignment 2.4, Part 8.1 — the router provider.
///
/// The redirect callback uses `ref.read`, NOT `ref.watch`,
/// because a `watch` inside the callback would create a fresh
/// subscription on every route resolution and drive the app into
/// the infinite navigation loop analysed in README 2.4, Q2
/// (third bullet). The `ref.watch(authStateListenableProvider)`
/// at the top of this function body is correct because it fires
/// exactly once per router construction and pushes the
/// `Listenable` into GoRouter's `refreshListenable` — a
/// push-based signal that does not consult `ref.watch` at
/// callback time.
@riverpod
GoRouter appRouter(Ref ref) {
  // Register the ChangeNotifier that translates every
  // authProvider change into a GoRouter refresh.
  final authListenable = ref.watch(authStateListenableProvider);

  final rootNavigatorKey = GlobalKey<NavigatorState>();

  return GoRouter(
    initialLocation: AppRoutes.jobs,
    navigatorKey: rootNavigatorKey,
    debugLogDiagnostics: true,
    refreshListenable: authListenable,

    redirect: (context, state) {
      // Read the current auth value at the moment GoRouter is
      // evaluating a route. `ref.read` is deliberate here — see
      // the class-level docstring and README 2.4 Q2 (third
      // bullet) for the rebuild-loop we would otherwise create.
      final auth = ref.read(authProvider);

      // During cold boot the AsyncValue is still loading —
      // return `null` so the current route stands until the
      // notifier's build() resolves. The very next fire of the
      // refreshListenable will re-run this callback with a
      // resolved value.
      if (auth.isLoading) return null;

      // If the async completed in error (unusual for
      // AuthNotifier since login errors surface as AuthError
      // inside AsyncData), treat it as unauthenticated.
      if (auth.hasError) {
        return state.matchedLocation == AppRoutes.login
            ? null
            : AppRoutes.login;
      }

      final resolved = auth.requireValue;
      final isAuthenticated = resolved is Authenticated;
      final onLogin = state.matchedLocation == AppRoutes.login;

      if (!isAuthenticated && !onLogin) return AppRoutes.login;
      if (isAuthenticated && onLogin) return AppRoutes.jobs;
      return null;
    },

    routes: [
      // /login lives OUTSIDE the shell: it is full-screen with
      // no NavigationBar, because an unauthenticated user has
      // no tabs to switch between.
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.jobs,
                builder: (context, state) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) {
                      final rawId = state.pathParameters['id'];
                      return JobDetailScreen(
                        jobId: (rawId == null || rawId.isEmpty) ? null : rawId,
                      );
                    },
                    routes: [
                      // Assignment 3.1, Part 7.1 — the apply
                      // sub-route. Full path `/jobs/:id/apply`.
                      // The literal segment `apply` does not
                      // conflict with the parameterised `:id`
                      // above because `apply` is matched at a
                      // deeper level (as a child of `:id`), not
                      // as a sibling at the same level.
                      GoRoute(
                        path: 'apply',
                        builder: (context, state) {
                          final id = state.pathParameters['id']!;
                          return ApplyScreen(jobId: id);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.saved,
                builder: (context, state) => const SavedScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
