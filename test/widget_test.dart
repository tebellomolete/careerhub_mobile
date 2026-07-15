import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:careerhub_mobile/main.dart';
import 'package:careerhub_mobile/models/job.dart';
import 'package:careerhub_mobile/widgets/job_card.dart';
import 'package:careerhub_mobile/widgets/icon_line.dart';
import 'package:careerhub_mobile/widgets/empty_jobs_widget.dart';

/// Assignment 1.3, Question 4 — fixes both failure modes in one place.
///
/// Failure mode 1 (architecture): HomeScreen and its filter chip row are
/// now Consumer(Stateful)Widgets, which require a ProviderScope ancestor.
/// Pumping CareerHubApp bare (as the old tests did) never goes through
/// main() — where ProviderScope is added — so it throws. Fixed by
/// wrapping every pump of CareerHubApp in ProviderScope here.
///
/// Failure mode 2 (async timing): jobsProvider now spends its first
/// ~1.5 simulated seconds in the `loading` state via a real
/// Future.delayed. Asserting on job text immediately after pumpWidget()
/// fails, because that text hasn't been built yet — and if a test ends
/// before the delay resolves, flutter_test can report the still-pending
/// Timer as leaked. Fixed with an explicit, deterministic time jump
/// (`pump(duration)`) past the delay, rather than relying on
/// pumpAndSettle().
Future<void> pumpLoadedApp(WidgetTester tester) async {
  await tester.pumpWidget(const ProviderScope(child: CareerHubApp()));
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
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('CareerHub'), findsWidgets);
    });

    testWidgets('Filter chip row is present and scrollable',
        (WidgetTester tester) async {
      await pumpLoadedApp(tester);
      // All filter chips should exist: All, Remote, Full-time, Contract.
      // Matched via widgetWithText rather than bare find.text: 'Remote',
      // 'Full-time', and 'Contract' are also real Job field values that
      // render inside job cards, so a bare text search is ambiguous
      // once real data is on screen.
      expect(find.byType(ChoiceChip), findsNWidgets(4));
      expect(find.widgetWithText(ChoiceChip, 'All'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Remote'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Full-time'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Contract'), findsOneWidget);
    });
  });

  group('Async Loading State (Assignment 1.3)', () {
    testWidgets('shows a CircularProgressIndicator before data loads',
        (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: CareerHubApp()));
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
      // Default viewport is portrait, narrow
      tester.binding.window.physicalSizeTestValue = const Size(400, 800);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      await pumpLoadedApp(tester);

      // Six jobs total (the four from 1.1 + 2 added for Stretch B of 1.2)
      expect(find.byType(JobCard), findsWidgets);
      // At least one card should be visible in portrait list
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('All four original Job variants render correctly',
        (WidgetTester tester) async {
      // Generous viewport: this test looks for four different jobs
      // spread across the unfiltered six-job grid, and Assignment 1.3
      // added a search field above the chip row, shrinking the space
      // left for the list itself. A wide, tall surface keeps every card
      // comfortably built without depending on how far Flutter's default
      // list/grid cache extent happens to reach.
      tester.binding.window.physicalSizeTestValue = const Size(1200, 2000);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      await pumpLoadedApp(tester);

      // Job 1: Fully populated
      expect(find.text('Senior Flutter Developer'), findsOneWidget);
      expect(find.text('Bitcube'), findsWidgets); // Company + multiple places
      expect(find.text('R55 000 – R75 000 per month'), findsOneWidget);

      // Job 2: No salary, no closing date (uses displaySalary)
      expect(find.text('Junior Backend Engineer'), findsOneWidget);
      expect(find.text('Market-related'), findsOneWidget);

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

    testWidgets('JobCard with no salary shows "Market-related"',
        (WidgetTester tester) async {
      await pumpLoadedApp(tester);

      // Job 2 has no salary and should display "Market-related"
      expect(find.text('Market-related'), findsOneWidget);
    });
  });

  group('Reactive Filtering (Assignment 1.3)', () {
    testWidgets('tapping the Remote chip filters out non-remote jobs',
        (WidgetTester tester) async {
      await pumpLoadedApp(tester);

      // Before filtering: a non-remote job is visible.
      expect(find.text('Senior Flutter Developer'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Remote'));
      await tester.pump();

      // After filtering: only the two remote jobs remain.
      expect(find.text('Senior Flutter Developer'), findsNothing);
      expect(find.text('DevOps Engineer'), findsOneWidget);
      expect(find.text('Technical Support Engineer'), findsOneWidget);
    });

    testWidgets('tapping All restores the full list',
        (WidgetTester tester) async {
      await pumpLoadedApp(tester);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Remote'));
      await tester.pump();
      expect(find.text('Senior Flutter Developer'), findsNothing);

      await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
      await tester.pump();
      expect(find.text('Senior Flutter Developer'), findsOneWidget);
    });
  });

  group('Stretch Goals (Assignment 1.3)', () {
    testWidgets('sort menu reverses job order (Stretch A)',
        (WidgetTester tester) async {
      await pumpLoadedApp(tester);

      // Narrow to the two remote jobs so there are only two candidates
      // to reason about the order of.
      await tester.tap(find.widgetWithText(ChoiceChip, 'Remote'));
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
        title: 'Test Developer',
        company: 'Test Corp',
        location: 'Test City',
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
        title: 'Minimal Job',
        company: 'Company',
        location: 'Somewhere',
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
        title: 'Job with Description',
        company: 'Company',
        location: 'Location',
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
        title: 'Test Job',
        company: 'Test Co',
        location: 'Test Place',
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
        title: 'Test Job',
        company: 'Test Co',
        location: 'Test Place',
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
