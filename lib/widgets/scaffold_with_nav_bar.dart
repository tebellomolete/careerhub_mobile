import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Assignment 1.4 — the persistent shell that hosts the NavigationBar.
///
/// This is the `builder` of the StatefulShellRoute.indexedStack. It is a
/// plain StatelessWidget on purpose: the selected tab is NOT local widget
/// state — it is `navigationShell.currentIndex`, which comes straight from
/// the router. The URL is the source of truth. If the app deep-links to
/// /saved, this widget rebuilds with currentIndex == 1 and the correct tab
/// is highlighted, with no setState anywhere.
class ScaffoldWithNavBar extends StatelessWidget {
  /// The shell provided by StatefulShellRoute.indexedStack. It both renders
  /// the active branch (as `body`) and tells us which branch is active.
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  void _onDestinationSelected(int index) {
    // goBranch switches to the branch at `index`. `initialLocation: index ==
    // navigationShell.currentIndex` is the double-tap-to-reset behaviour
    // (Stretch A): when the user taps the tab they are ALREADY on, we pass
    // initialLocation: true, which tells GoRouter to reset that branch back
    // to its root route (popping any detail screen off its stack). Tapping a
    // DIFFERENT tab passes false, which preserves that branch's existing
    // stack. See README Stretch A.
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The active branch's navigator. indexedStack keeps every branch built
      // and alive underneath, so switching tabs is instant and stateful.
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        // Selected index is read from the router, never from a StatefulWidget.
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.work_outline),
            selectedIcon: Icon(Icons.work),
            label: 'Jobs',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_border),
            selectedIcon: Icon(Icons.bookmark),
            label: 'Saved',
          ),
          // W2D3 in-class challenge, Part 5.1 — the Applications tab.
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Applications',
          ),
        ],
      ),
    );
  }
}
