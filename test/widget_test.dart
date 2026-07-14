import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:careerhub_mobile/main.dart';
import 'package:careerhub_mobile/models/job.dart';
import 'package:careerhub_mobile/widgets/job_card.dart';
import 'package:careerhub_mobile/widgets/icon_line.dart';
import 'package:careerhub_mobile/widgets/empty_jobs_widget.dart';

void main() {
  group('CareerHub App Shell', () {
    testWidgets('CareerHubApp builds without error', (WidgetTester tester) async {
      await tester.pumpWidget(const CareerHubApp());
      expect(find.byType(CareerHubApp), findsOneWidget);
      expect(find.text('CareerHub'), findsWidgets);
    });

    testWidgets('App bar displays on HomeScreen', (WidgetTester tester) async {
      await tester.pumpWidget(const CareerHubApp());
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('CareerHub'), findsWidgets);
    });

    testWidgets('Filter chip row is present and scrollable',
        (WidgetTester tester) async {
      await tester.pumpWidget(const CareerHubApp());
      // All filter chips should exist: All, Remote, Full-time, Contract
      expect(find.byType(ChoiceChip), findsWidgets);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Remote'), findsOneWidget);
      expect(find.text('Full-time'), findsOneWidget);
      expect(find.text('Contract'), findsOneWidget);
    });
  });

  group('Job List Rendering', () {
    testWidgets('ListView.builder renders job cards in portrait',
        (WidgetTester tester) async {
      // Default viewport is portrait, narrow
      tester.binding.window.physicalSizeTestValue = const Size(400, 800);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      await tester.pumpWidget(const CareerHubApp());
      await tester.pumpAndSettle();

      // Six jobs total (the four from 1.1 + 2 added for Stretch B)
      expect(find.byType(JobCard), findsWidgets);
      // At least one card should be visible in portrait list
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('All four original Job variants render correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(const CareerHubApp());
      await tester.pumpAndSettle();

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
      await tester.pumpWidget(const CareerHubApp());
      await tester.pumpAndSettle();

      // At least 4 open jobs should show "Open" badges
      expect(find.text('Open'), findsWidgets);
    });

    testWidgets('Closed badge shows "Closed" for closed jobs',
        (WidgetTester tester) async {
      await tester.pumpWidget(const CareerHubApp());
      await tester.pumpAndSettle();

      // The closed job should show one "Closed" badge
      expect(find.text('Closed'), findsOneWidget);
    });

    testWidgets('JobCard with no salary shows "Market-related"',
        (WidgetTester tester) async {
      await tester.pumpWidget(const CareerHubApp());
      await tester.pumpAndSettle();

      // Job 2 has no salary and should display "Market-related"
      expect(find.text('Market-related'), findsOneWidget);
    });
  });

  group('JobCard Widget', () {
    testWidgets('JobCard renders all required fields', (WidgetTester tester) async {
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
  });

  group('Dark Mode', () {
    testWidgets('App respects system theme setting',
        (WidgetTester tester) async {
      await tester.pumpWidget(const CareerHubApp());

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
