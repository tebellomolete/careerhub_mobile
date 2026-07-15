import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:careerhub_mobile/main.dart';
import 'package:careerhub_mobile/models/job.dart';
import 'package:careerhub_mobile/providers/job_providers.dart';
import 'package:careerhub_mobile/widgets/job_card.dart';
import 'package:careerhub_mobile/widgets/icon_line.dart';
import 'package:careerhub_mobile/widgets/empty_jobs_widget.dart';

/// Assignment 1.4, Question 4 — the structural test change.
///
/// The app is now MaterialApp.router, not MaterialApp with `home:`. That
/// changes how the widget tree is resolved: instead of the test engine
/// building a fixed `home` widget, GoRouter's RouterDelegate now decides
/// what to build from `initialLocation`. Nothing is on screen until the
/// router resolves a location. Our initialLocation is `/jobs`, so the app
/// lands on the jobs list exactly where the pre-router assertions expect —
/// so the job/spinner/chip assertions below need no rewriting for content,
/// only the wrapper below.
///
/// The one thing initialLocation alone can't satisfy is Stretch C's auth
/// gate: isLoggedInProvider defaults to false, so the redirect would send a
/// freshly-pumped app to /login instead of /jobs. Tests override it to true
/// so we exercise the authenticated app the assertions were written for.
///
/// Assignment 1.3's two fixes still apply and are unchanged in spirit:
///  - ProviderScope wrapper (Consumer widgets need the ancestor), and
///  - a deterministic time jump past jobsProvider's ~1.5s Future.delayed
///    rather than pumpAndSettle().
Widget bootApp() {
  return ProviderScope(
    // Stretch C: start authenticated so the redirect allows /jobs through.
    overrides: [isLoggedInProvider.overrideWith((ref) => true)],
    child: const CareerHubApp(),
  );
}

/// A tall, narrow default surface. Assignment 1.4 adds a persistent bottom
/// NavigationBar, which eats vertical space that the job list used to have.
/// On the small default 800x600 test surface that was enough to push the
/// lower job cards out of the lazy-build window, so text-specific finders
/// (e.g. find.text('Senior Flutter Developer')) saw zero matches even though
/// the data was correct.
///
/// Width 500 keeps the app in the single-column ListView tier (< 600px),
/// where each card is laid out at its natural height — so the richest cards
/// (description + closing date) never overflow a fixed-aspect-ratio grid
/// cell — and 3000px of height keeps all six cards built at once (dpr 1 so
/// logical == physical). Tests that specifically need a grid tier pass their
/// own [surface].
const Size _defaultSurface = Size(500, 3000);

Future<void> pumpLoadedApp(
  WidgetTester tester, {
  Size surface = _defaultSurface,
}) async {
  // Modern, non-deprecated viewport control (replaces window.*TestValue).
  tester.view.physicalSize = surface;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(bootApp());
  await tester.pump(); // build the first (loading) frame
  await tester.pump(const Duration(seconds: 2)); // resolve the 1.5s delay
}

void main() {
  group('CareerHub App Shell', () {
    testWidgets('CareerHubApp builds without error',
        (WidgetTester tester) async {
      await pumpLoadedApp(tester);
      expect(find.byType(CareerHubApp), findsOneWidget);
      expect(find.text('CareerHub'), findsWidgets);
    });

    testWidgets('App bar displays on HomeScreen', (WidgetTester tester) async {
      await pumpLoadedApp(tester);
      // Still findsOneWidget: StatefulShellRoute.indexedStack builds branches
      // lazily, so the Saved branch (and its AppBar) is not instantiated
      // until it is first visited — only the Jobs AppBar exists on launch.
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('CareerHub'), findsWidgets);
    });

    testWidgets('NavigationBar with Jobs and Saved destinations is visible',
        (WidgetTester tester) async {
      await pumpLoadedApp(tester);

      // Assignment 1.4: the persistent shell renders a NavigationBar whose
      // two destination labels are new text in the tree. These labels were
      // chosen to NOT collide with any existing assertion — 'Jobs' and
      // 'Saved' are not Job field values, filter labels, or card text — so
      // no findsNWidgets count elsewhere needed adjusting.
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.widgetWithText(NavigationDestination, 'Jobs'), findsOneWidget);
      expect(
          find.widgetWithText(NavigationDestination, 'Saved'), findsOneWidget);
    });

    testWidgets('Two filter dropdowns (Location and Job type) are present',
        (WidgetTester tester) async {
      await pumpLoadedApp(tester);
      // The tutor-requested change: chips replaced with two typed
      // dropdowns. Each is a DropdownButtonFormField, so we should find
      // exactly two — and each shows its labelText as the field label
      // in the tree (Location / Job type).
      expect(find.byType(DropdownButtonFormField<LocationType?>),
          findsOneWidget);
      expect(find.byType(DropdownButtonFormField<JobTypeFilter?>),
          findsOneWidget);
      expect(find.text('Location'), findsOneWidget);
      expect(find.text('Job type'), findsOneWidget);
    });
  });

  group('Async Loading State (Assignment 1.3)', () {
    testWidgets('shows a CircularProgressIndicator before data loads',
        (WidgetTester tester) async {
      await tester.pumpWidget(bootApp());
      await tester.pump(); // first frame only — jobsProvider still loading

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(JobCard), findsNothing);

      // Drain the pending timer so flutter_test doesn't report it as
      // leaked when this test tears down.
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('CircularProgressIndicator is gone once data has loaded',
        (WidgetTester tester) async {
      await pumpLoadedApp(tester);

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(JobCard), findsWidgets);
    });
  });

  group('Job List Rendering', () {
    testWidgets('ListView.builder renders job cards in portrait',
        (WidgetTester tester) async {
      // Narrow (single-column ListView tier) but tall enough to build cards.
      await pumpLoadedApp(tester, surface: const Size(400, 2000));

      // Six jobs total (the four from 1.1 + 2 added for Stretch B of 1.2)
      expect(find.byType(JobCard), findsWidgets);
      // At least one card should be visible in portrait list
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('All four original Job variants render correctly',
        (WidgetTester tester) async {
      // The default tall single-column surface keeps all six cards built at
      // once, so every one of the four variant jobs below is findable.
      await pumpLoadedApp(tester);

      // Job 1: Fully populated
      expect(find.text('Senior Flutter Developer'), findsOneWidget);
      expect(find.text('Bitcube'), findsWidgets); // Company + multiple places
      expect(find.text('R55 000 – R75 000 per month'), findsOneWidget);

      // Job 2: No salary, no closing date (uses displaySalary).
      expect(find.text('Junior Backend Engineer'), findsOneWidget);
      // Two jobs disclose no salary — Junior Backend Engineer AND Technical
      // Support Engineer — so "Market-related" renders twice now that the
      // tall surface builds every card at once. (Pre-1.4 this passed only
      // because the smaller grid viewport left the second card unbuilt.)
      expect(find.text('Market-related'), findsNWidgets(2));

      // Job 3: Closed job
      expect(find.text('Product Designer'), findsOneWidget);
      expect(find.text('Closed'), findsOneWidget);

      // Job 4: Remote job
      expect(find.text('DevOps Engineer'), findsOneWidget);
      expect(find.text('Remote'), findsWidgets); // Location + multiple places
    });

    testWidgets('Open badge shows "Open" for open jobs',
        (WidgetTester tester) async {
      await pumpLoadedApp(tester);

      // At least 4 open jobs should show "Open" badges
      expect(find.text('Open'), findsWidgets);
    });

    testWidgets('Closed badge shows "Closed" for closed jobs',
        (WidgetTester tester) async {
      await pumpLoadedApp(tester);

      // The closed job should show one "Closed" badge
      expect(find.text('Closed'), findsOneWidget);
    });

    testWidgets('jobs with no salary show "Market-related"',
        (WidgetTester tester) async {
      await pumpLoadedApp(tester);

      // Both no-salary jobs (Junior Backend Engineer, Technical Support
      // Engineer) display "Market-related" via displaySalary.
      expect(find.text('Market-related'), findsNWidgets(2));
    });
  });

  group('Reactive Filtering (dropdowns)', () {
    // Helper: grab the running ProviderContainer so tests can drive filter
    // state directly without having to open dropdown menus (which are an
    // overlay-based interaction that's flaky to script). The dropdown UI
    // wiring is proved by a dedicated "opens dropdown and picks Remote"
    // test below; these two focus on the reactive filter behaviour.
    ProviderContainer containerFor(WidgetTester tester) =>
        ProviderScope.containerOf(tester.element(find.byType(CareerHubApp)));

    testWidgets('selecting a location filters out non-matching jobs',
        (WidgetTester tester) async {
      await pumpLoadedApp(tester);

      // Before filtering: a non-remote job is visible.
      expect(find.text('Senior Flutter Developer'), findsOneWidget);

      containerFor(tester).read(locationFilterProvider.notifier).state =
          LocationType.remote;
      await tester.pump();

      // After filtering: only the two remote jobs remain.
      expect(find.text('Senior Flutter Developer'), findsNothing);
      expect(find.text('DevOps Engineer'), findsOneWidget);
      expect(find.text('Technical Support Engineer'), findsOneWidget);
    });

    testWidgets('clearing the location filter restores the full list',
        (WidgetTester tester) async {
      await pumpLoadedApp(tester);

      final container = containerFor(tester);
      container.read(locationFilterProvider.notifier).state =
          LocationType.remote;
      await tester.pump();
      expect(find.text('Senior Flutter Developer'), findsNothing);

      // null == "All locations" — the dropdown's null-valued item.
      container.read(locationFilterProvider.notifier).state = null;
      await tester.pump();
      expect(find.text('Senior Flutter Developer'), findsOneWidget);
    });

    testWidgets('the two dropdowns compose (Remote + Full-time narrows to '
        'the intersection)', (WidgetTester tester) async {
      await pumpLoadedApp(tester);
      final container = containerFor(tester);

      container.read(locationFilterProvider.notifier).state =
          LocationType.remote;
      container.read(jobTypeFilterProvider.notifier).state =
          JobTypeFilter.fullTime;
      await tester.pump();

      // Only DevOps Engineer is BOTH remote AND full-time — Technical
      // Support Engineer is remote but contract, so it drops out.
      expect(find.text('DevOps Engineer'), findsOneWidget);
      expect(find.text('Technical Support Engineer'), findsNothing);
      expect(find.text('Senior Flutter Developer'), findsNothing);
    });

    testWidgets(
        'tapping the Location dropdown opens the menu and picking Remote '
        'updates the provider', (WidgetTester tester) async {
      await pumpLoadedApp(tester);
      final container = containerFor(tester);
      expect(container.read(locationFilterProvider), isNull);

      // Open the Location dropdown (typed generically so it matches
      // regardless of which item is currently selected).
      await tester
          .tap(find.byType(DropdownButtonFormField<LocationType?>));
      await tester.pumpAndSettle();

      // Now the menu is in an overlay. Tap the "Remote" menu item. The
      // overlay is inserted at the END of the tree, so `.last` targets
      // the menu row rather than a job-card location text.
      await tester.tap(find.text('Remote').last);
      await tester.pumpAndSettle();

      expect(container.read(locationFilterProvider), LocationType.remote);
      expect(find.text('Senior Flutter Developer'), findsNothing);
    });
  });

  group('Stretch Goals (Assignment 1.3)', () {
    testWidgets('sort menu reverses job order (Stretch A)',
        (WidgetTester tester) async {
      // This test reasons about horizontal position (dx), so it needs the
      // two-column GRID tier, not the single-column list. Width 800 sits in
      // the 2-column band (600–839px) and gives cells wide enough that the
      // richest card doesn't overflow its fixed-ratio cell.
      await pumpLoadedApp(tester, surface: const Size(800, 1400));

      // Narrow to the two remote jobs so there are only two candidates
      // to reason about the order of. Drive the filter provider directly
      // (dropdown UI is exercised in the Reactive Filtering group).
      final container = ProviderScope.containerOf(
          tester.element(find.byType(CareerHubApp)));
      container.read(locationFilterProvider.notifier).state =
          LocationType.remote;
      await tester.pump();

      double dxOf(String title) => tester.getTopLeft(find.text(title)).dx;

      // Default sort is A -> Z: "DevOps Engineer" sorts before
      // "Technical Support Engineer", landing in the earlier grid cell
      // (smaller dx).
      expect(dxOf('DevOps Engineer'),
          lessThan(dxOf('Technical Support Engineer')));

      await tester.tap(find.byIcon(Icons.sort_by_alpha));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Title: Z–A'));
      await tester.pumpAndSettle();

      expect(dxOf('Technical Support Engineer'),
          lessThan(dxOf('DevOps Engineer')));
    });

    testWidgets(
        'failure toggle shows the error state; tapping again recovers '
        '(Stretch B)', (WidgetTester tester) async {
      await pumpLoadedApp(tester);
      expect(find.byType(JobCard), findsWidgets);

      // First tap: turns the simulated failure ON and retries.
      await tester.tap(find.byIcon(Icons.wifi));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.byType(JobCard), findsNothing);

      // Second tap (on the now-different icon): turns the simulated
      // failure back OFF and retries again — this is the attempt that
      // succeeds.
      await tester.tap(find.byIcon(Icons.wifi_off));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Something went wrong'), findsNothing);
      expect(find.byType(JobCard), findsWidgets);
    });

    testWidgets('search field filters jobs by title (Stretch C)',
        (WidgetTester tester) async {
      await pumpLoadedApp(tester);

      expect(find.text('Senior Flutter Developer'), findsOneWidget);
      expect(find.text('UX Researcher'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'ux');
      await tester.pump();

      expect(find.text('UX Researcher'), findsOneWidget);
      expect(find.text('Senior Flutter Developer'), findsNothing);
    });
  });

  group('JobCard Widget', () {
    testWidgets('JobCard renders all required fields',
        (WidgetTester tester) async {
      final testJob = Job(
        id: 101,
        title: 'Test Developer',
        company: 'Test Corp',
        location: 'Test City',
        locationType: LocationType.onSite,
        employmentType: 'Full-time',
        isOpen: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: JobCard(job: testJob),
          ),
        ),
      );

      expect(find.text('Test Developer'), findsOneWidget);
      expect(find.text('Test Corp'), findsOneWidget);
      expect(find.text('Test City'), findsOneWidget);
      expect(find.text('Full-time'), findsOneWidget);
      expect(find.text('Market-related'), findsOneWidget); // No salary provided
      expect(find.text('Open'), findsOneWidget); // Status badge
    });

    testWidgets('JobCard handles nullable fields gracefully',
        (WidgetTester tester) async {
      // Job with all nullable fields absent
      final minimalJob = Job(
        id: 102,
        title: 'Minimal Job',
        company: 'Company',
        location: 'Somewhere',
        locationType: LocationType.onSite,
        employmentType: 'Part-time',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: JobCard(job: minimalJob),
          ),
        ),
      );

      expect(find.text('Minimal Job'), findsOneWidget);
      // No crash, no "null" text, closing date line should not appear
      expect(find.text('Closes:'), findsNothing);
    });

    testWidgets('JobCard shows description when present',
        (WidgetTester tester) async {
      final jobWithDesc = Job(
        id: 103,
        title: 'Job with Description',
        company: 'Company',
        location: 'Location',
        locationType: LocationType.onSite,
        employmentType: 'Full-time',
        description: 'This is a test description.',
        isOpen: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: JobCard(job: jobWithDesc),
          ),
        ),
      );

      expect(find.text('This is a test description.'), findsOneWidget);
    });
  });

  group('Icon Line Widget', () {
    testWidgets('IconLine renders icon and text correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IconLine(
              icon: Icons.place_outlined,
              text: 'Test Location',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.place_outlined), findsOneWidget);
      expect(find.text('Test Location'), findsOneWidget);
    });
  });

  group('Empty State', () {
    testWidgets('EmptyJobsWidget renders correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyJobsWidget(),
          ),
        ),
      );

      expect(find.byIcon(Icons.work_off_outlined), findsOneWidget);
      expect(find.text('No jobs available'), findsOneWidget);
      expect(find.text('Check back soon — new listings are added regularly.'),
          findsOneWidget);
    });

    testWidgets('EmptyJobsWidget renders custom copy when provided',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyJobsWidget(
              icon: Icons.filter_alt_off_outlined,
              title: 'No jobs match this filter',
              message: 'Try a different filter to see more listings.',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.filter_alt_off_outlined), findsOneWidget);
      expect(find.text('No jobs match this filter'), findsOneWidget);
      expect(find.text('Try a different filter to see more listings.'),
          findsOneWidget);
    });
  });

  group('Dark Mode', () {
    testWidgets('App respects system theme setting',
        (WidgetTester tester) async {
      await pumpLoadedApp(tester);

      // The app should have both light and dark themes defined
      final materialApp = find.byType(MaterialApp).evaluate().first.widget
          as MaterialApp;
      expect(materialApp.theme, isNotNull);
      expect(materialApp.darkTheme, isNotNull);
      expect(materialApp.themeMode, ThemeMode.system);
    });

    testWidgets('JobCard renders correctly in light mode',
        (WidgetTester tester) async {
      final testJob = Job(
        id: 104,
        title: 'Test Job',
        company: 'Test Co',
        location: 'Test Place',
        locationType: LocationType.onSite,
        employmentType: 'Full-time',
        isOpen: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(useMaterial3: true),
          home: Scaffold(
            body: JobCard(job: testJob),
          ),
        ),
      );

      expect(find.text('Test Job'), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);
    });

    testWidgets('JobCard renders correctly in dark mode',
        (WidgetTester tester) async {
      final testJob = Job(
        id: 105,
        title: 'Test Job',
        company: 'Test Co',
        location: 'Test Place',
        locationType: LocationType.onSite,
        employmentType: 'Full-time',
        isOpen: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: Scaffold(
            body: JobCard(job: testJob),
          ),
        ),
      );

      expect(find.text('Test Job'), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);
    });
  });
}
