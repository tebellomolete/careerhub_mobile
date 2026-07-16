import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/job_providers.dart';
import '../screens/home_screen.dart';
import '../screens/job_detail_screen.dart';
import '../screens/saved_screen.dart';
import '../screens/login_screen.dart';
import '../screens/applications_screen.dart';
import '../widgets/scaffold_with_nav_bar.dart';

/// ---------------------------------------------------------------------
/// Assignment 1.4 — the single source of routing truth.
///
/// The router is exposed as a Riverpod Provider rather than a bare global
/// so that it can read other providers (isLoggedInProvider for the auth
/// redirect) and be torn down cleanly in tests. See README Q1 for the
/// full route tree this mirrors, and Stretch C for the redirect.
/// ---------------------------------------------------------------------

/// Path constants — one place to change a URL, referenced everywhere a
/// route is built or navigated to, so a typo can't silently create a
/// dead link.
class AppRoutes {
  const AppRoutes._();

  static const String jobs = '/jobs';
  static const String saved = '/saved';
  static const String login = '/login';
  static const String applications = '/applications';

  /// Builds the canonical detail URL for a job id — the ONLY way the app
  /// constructs `/jobs/:id`, so `job.id` (never a list index) is always
  /// what ends up in the URL.
  ///
  /// Assignment 2.1: `int` → `String`. `Job.id` is now a Guid string
  /// (see `Job.fromDto`), and Guids are safe to drop directly into a
  /// URL path segment — they contain only hex digits and hyphens, all
  /// of which are unreserved characters, so no percent-encoding is
  /// required at the call site.
  static String jobDetail(String id) => '$jobs/$id';
}

final goRouterProvider = Provider<GoRouter>((ref) {
  // Stretch C — bridge Riverpod's auth state to GoRouter's Listenable-based
  // refreshListenable. A ValueNotifier that we push new auth values into
  // whenever isLoggedInProvider changes; GoRouter re-runs `redirect` every
  // time it fires. This is why the login screen never calls context.go():
  // flipping the provider is enough to bounce the user to /jobs.
  final authListenable = ValueNotifier<bool>(ref.read(isLoggedInProvider));
  ref.onDispose(authListenable.dispose);
  ref.listen<bool>(
    isLoggedInProvider,
    (previous, next) => authListenable.value = next,
  );

  final rootNavigatorKey = GlobalKey<NavigatorState>();

  return GoRouter(
    // The app boots on the jobs tab root (the redirect below may still send
    // an unauthenticated user to /login first — see Stretch C).
    initialLocation: AppRoutes.jobs,
    navigatorKey: rootNavigatorKey,
    debugLogDiagnostics: true,
    refreshListenable: authListenable,

    // Stretch C — the auth gate. Returning a path reroutes; returning null
    // allows the requested navigation through.
    redirect: (context, state) {
      final loggedIn = ref.read(isLoggedInProvider);
      final goingToLogin = state.matchedLocation == AppRoutes.login;

      // Not authenticated: force everything to /login (except /login).
      if (!loggedIn) {
        return goingToLogin ? null : AppRoutes.login;
      }
      // Authenticated but sitting on /login: send them into the app.
      if (goingToLogin) {
        return AppRoutes.jobs;
      }
      // Otherwise let the requested route render.
      return null;
    },

    routes: [
      // /login lives OUTSIDE the shell: it is full-screen with no
      // NavigationBar, because an unauthenticated user has no tabs to
      // switch between.
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),

      // The persistent two-tab shell. indexedStack keeps BOTH branches'
      // navigators alive at once, so each tab remembers its own stack and
      // scroll position when you switch away and back.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0 — Jobs. The detail route is nested INSIDE this branch
          // (not a top-level route), which is what makes the tab-state
          // checkpoint work: the branch navigator holds [jobs, jobs/:id],
          // and indexedStack preserves that whole stack across tab
          // switches. See README Q1.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.jobs,
                builder: (context, state) => const HomeScreen(),
                routes: [
                  GoRoute(
                    // Relative path -> full URL is /jobs/:id.
                    path: ':id',
                    builder: (context, state) {
                      // Assignment 2.1: Job.id is a Guid string, so we
                      // pass the raw path segment straight through. An
                      // empty segment (impossible via canonical routing
                      // but possible via a malformed URL) resolves to
                      // null and the detail screen renders the graceful
                      // "not found" state.
                      final rawId = state.pathParameters['id'];
                      return JobDetailScreen(
                        jobId: (rawId == null || rawId.isEmpty) ? null : rawId,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          // Branch 1 — Saved.
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
});
