import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:careerhub_mobile/main.dart';
import 'package:careerhub_mobile/models/job.dart';
import 'package:careerhub_mobile/providers/job_providers.dart';
import 'package:careerhub_mobile/providers/jobs_notifier.dart';
import 'package:careerhub_mobile/widgets/job_card.dart';
import 'package:careerhub_mobile/widgets/icon_line.dart';
import 'package:careerhub_mobile/widgets/empty_jobs_widget.dart';

/// Assignment 2.1, Part 6 — the fake notifier the widget tests use in
/// place of the real, network-backed [JobsNotifier].
///
/// This class exists ONLY in the test file. The production
/// [JobsNotifier] calls `JobsRepository.getJobs()`, which hits the
/// CareerHub API. In `flutter test` no API is available, so `build()`
/// would throw a `DioException` on `SocketException: OS Error:
/// Connection refused` and every widget test would report an
/// unhandled exception (see README, Q4). Overriding
/// `jobsProvider` with a subclass of `_$JobsNotifier` swaps in
/// a deterministic list of jobs, keeping the widget test focused on
/// widget behaviour and NOT network behaviour.
///
/// The 1.5-second delay preserves the loading-state assertion from
/// Assignment 1.3: the spinner must be visible for at least one frame
/// before data arrives.
class _FakeJobsNotifier extends JobsNotifier {
  @override
  Future<List<Job>> build() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    return _fakeJobs;
  }
}

/// The single source of truth for the tests in this file. Same shape
/// and coverage as the pre-2.1 `_mockJobs` (four employment types,
/// two remote roles, one closed role, mixed salary presence, etc.),
/// but with String ids because [Job.id] is now a Guid string.
final List<Job> _fakeJobs = [
  Job(
    id: 'fake-1',
    title: 'Senior Flutter Developer',
    company: 'Bitcube',
    location: 'Cape Town, ZA',
    locationType: LocationType.onSite,
    salary: 'R55 000 – R75 000 per month',
    employmentType: 'Full-time',
    closingDate: DateTime(2026, 8, 15),
    description: 'Build production-ready cross-platform apps.',
    isOpen: true,
  ),
  Job(
    id: 'fake-2',
    title: 'Junior Backend Engineer',
    company: 'Nimbus Systems',
    location: 'Johannesburg, ZA',
    locationType: LocationType.onSite,
    employmentType: 'Full-time',
    isOpen: true,
  ),
  Job.closed(
    id: 'fake-3',
    title: 'Product Designer',
    company: 'Loop Studio',
    location: 'Durban, ZA',
    locationType: LocationType.onSite,
    salary: 'R40 000 per month',
    employmentType: 'Contract',
    closingDate: DateTime(2026, 5, 1),
    description: 'This role has closed for new applications.',
  ),
  Job.remote(
    id: 'fake-4',
    title: 'DevOps Engineer',
    company: 'Skyforge',
    salary: 'R60 000 – R80 000 per month',
    employmentType: 'Full-time',
    closingDate: DateTime(2026, 9, 30),
    description: 'Fully remote infrastructure role.',
    isOpen: true,
  ),
  Job(
    id: 'fake-5',
    title: 'UX Researcher',
    company: 'Meridian Labs',
    location: 'Pretoria, ZA',
    locationType: LocationType.onSite,
    salary: 'R48 000 – R58 000 per month',
    employmentType: 'Full-time',
    closingDate: DateTime(2026, 10, 1),
    description: 'Lead user research sessions.',
    isOpen: true,
  ),
  Job.remote(
    id: 'fake-6',
    title: 'Technical Support Engineer',
    company: 'Fathom Analytics',
    employmentType: 'Contract',
    closingDate: DateTime(2026, 8, 20),
    isOpen: true,
  ),
];

/// Assignment 2.1 — the boot helper.
///
/// Two overrides:
///   1. `jobsProvider` → `_FakeJobsNotifier` so no HTTP call
///      ever leaves the test process (Part 6, and README Q4).
///   2. `isLoggedInProvider` → true so the router's Stretch-C redirect
///      allows the freshly-pumped app onto `/jobs` (unchanged from 1.4).
Widget bootApp() {
  return ProviderScope(
    overrides: [
      // `.overrideWith` on a generated notifier provider takes a
      // notifier-CONSTRUCTOR — Riverpod calls it once per container to
      // build the notifier instance, then invokes the instance's
      // `build()` method to produce the initial value. This replaces
      // ONLY the notifier; every widget, every derived provider
      // ([filteredJobsProvider], [visibleJobsProvider],
      // [savedJobsProvider]) still runs unchanged. See README, Q4.
      jobsProvider.overrideWith(_FakeJobsNotifier.new),
      isLoggedInProvider.overrideWith((ref) => true),
    ],
    child: const CareerHubApp(),
  );
}

const Size _defaultSurface = Size(500, 3000);

Future<void> pumpLoadedApp(
  WidgetTester tester, {
  Size surface = _defaultSurface,
}) async {
  tester.view.physicalSize = surface;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(bootApp());
  await tester.pump(); // first frame — still loading
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

    testWidgets('App bar displays on HomeScreen',
        (WidgetTester tester) async {
      await pumpLoadedApp(tester);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('CareerHub'), findsWidgets);
    });

    testWidgets('NavigationBar with Jobs and Saved destinations is visible',
        (WidgetTester tester) async {
      await pumpLoadedApp(tester);

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.widgetWithText(NavigationDestination, 'Jobs'),
          findsOneWidget);
      expect(find.widgetWithText(NavigationDestination, 'Saved'),
          findsOneWidget);
    });

    testWidgets('Two filter dropdowns (Location and Job type) are present',
        (WidgetTester tester) async {
      await pumpLoadedApp(tester);
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
      await tester.pump(); // still loading (fake delay hasn't elapsed)

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(JobCard), findsNothing);

      // Drain the pending timer so flutter_test doesn't flag it.
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
      await pumpLoadedApp(tester, surface: const Size(400, 2000));
      expect(find.byType(JobCard), findsWidgets);
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('All variant jobs render correctly',
        (WidgetTester tester) async {
      await pumpLoadedApp(tester);

      // Job 1: fully populated
      expect(find.text('Senior Flutter Developer'), findsOneWidget);
      expect(find.text('Bitcube'), findsWidgets);
      expect(find.text('R55 000 – R75 000 per month'), findsOneWidget);

      // Job 2: no salary, no closing date (uses displaySalary).
      expect(find.text('Junior Backend Engineer'), findsOneWidget);
      // Two fake jobs disclose no salary — Junior Backend Engineer AND
      // Technical Support Engineer.
      expect(find.text('Market-related'), findsNWidgets(2));

      // Job 3: closed job
      expect(find.text('Product Designer'), findsOneWidget);
      expect(find.text('Closed'), findsOneWidget);

      // Job 4: remote job
      expect(find.text('DevOps Engineer'), findsOneWidget);
      expect(find.text('Remote'), findsWidgets);
    });

    testWidgets('Open badge shows "Open" for open jobs',
        (WidgetTester tester) async {
      await pumpLoadedApp(tester);
      expect(find.text('Open'), findsWidgets);
    });

    testWidgets('Closed badge shows "Closed" for closed jobs',
        (WidgetTester tester) async {
      await pumpLoadedApp(tester);
      expect(find.text('Closed'), findsOneWidget);
    });

    testWidgets('jobs with no salary show "Market-related"',
        (WidgetTester tester) async {
      await pumpLoadedApp(tester);
      expect(find.text('Market-related'), findsNWidgets(2));
    });
  });

  group('Reactive Filtering (dropdowns)', () {
    ProviderContainer containerFor(WidgetTester tester) =>
        ProviderScope.containerOf(
            tester.element(find.byType(CareerHubApp)));

    testWidgets('selecting a location filters out non-matching jobs',
        (WidgetTester tester) async {
      await pumpLoadedApp(tester);
      expect(find.text('Senior Flutter Developer'), findsOneWidget);

      containerFor(tester).read(locationFilterProvider.notifier).state =
          LocationType.remote;
      await tester.pump();

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

      container.read(locationFilterProvider.notifier).state = null;
      await tester.pump();
      expect(find.text('Senior Flutter Developer'), findsOneWidget);
    });

    testWidgets(
        'the two dropdowns compose (Remote + Full-time narrows to '
        'the intersection)', (WidgetTester tester) async {
      await pumpLoadedApp(tester);
      final container = containerFor(tester);

      container.read(locationFilterProvider.notifier).state =
          LocationType.remote;
      container.read(jobTypeFilterProvider.notifier).state =
          JobTypeFilter.fullTime;
      await tester.pump();

      // Only DevOps Engineer is BOTH remote AND full-time in the fake
      // data — Technical Support Engineer is remote but contract.
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

      await tester
          .tap(find.byType(DropdownButtonFormField<LocationType?>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Remote').last);
      await tester.pumpAndSettle();

      expect(container.read(locationFilterProvider), LocationType.remote);
      expect(find.text('Senior Flutter Developer'), findsNothing);
    });
  });

  group('Sort + Search', () {
    testWidgets('sort menu reverses job order',
        (WidgetTester tester) async {
      await pumpLoadedApp(tester, surface: const Size(800, 1400));

      final container = ProviderScope.containerOf(
          tester.element(find.byType(CareerHubApp)));
      container.read(locationFilterProvider.notifier).state =
          LocationType.remote;
      await tester.pump();

      double dxOf(String title) => tester.getTopLeft(find.text(title)).dx;

      expect(dxOf('DevOps Engineer'),
          lessThan(dxOf('Technical Support Engineer')));

      await tester.tap(find.byIcon(Icons.sort_by_alpha));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Title: Z–A'));
      await tester.pumpAndSettle();

      expect(dxOf('Technical Support Engineer'),
          lessThan(dxOf('DevOps Engineer')));
    });

    testWidgets('search field filters jobs by title',
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

  group('Job.fromDto mapping (Assignment 2.1)', () {
    test('inferLocationType maps "Remote" strings to remote', () {
      expect(Job.inferLocationType('Remote'), LocationType.remote);
      expect(Job.inferLocationType('remote'), LocationType.remote);
      expect(Job.inferLocationType('Fully remote (SA)'),
          LocationType.remote);
    });

    test('inferLocationType maps "Hybrid" strings to hybrid', () {
      expect(Job.inferLocationType('Hybrid'), LocationType.hybrid);
      expect(Job.inferLocationType('Cape Town (Hybrid)'),
          LocationType.hybrid);
    });

    test('inferLocationType defaults to onSite for a plain city string',
        () {
      expect(Job.inferLocationType('Cape Town, ZA'), LocationType.onSite);
      expect(Job.inferLocationType('Johannesburg'), LocationType.onSite);
    });

    test('displaySalary renders "Market-related" when the API sent the '
        '"Salary not specified" sentinel', () {
      // Reproduces what Job.fromDto builds when the API returns
      // "Salary not specified" — salary is mapped to null so
      // displaySalary yields "Market-related".
      final job = Job(
        id: 'x',
        title: 't',
        company: 'c',
        location: 'l',
        locationType: LocationType.onSite,
        employmentType: 'Full-time',
        // salary intentionally omitted (== null)
      );
      expect(job.displaySalary, 'Market-related');
    });
  });

  group('JobCard Widget', () {
    testWidgets('JobCard renders all required fields',
        (WidgetTester tester) async {
      final testJob = Job(
        id: 'j-101',
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
      expect(find.text('Market-related'), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);
    });

    testWidgets('JobCard handles nullable fields gracefully',
        (WidgetTester tester) async {
      final minimalJob = Job(
        id: 'j-102',
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
      expect(find.text('Closes:'), findsNothing);
    });

    testWidgets('JobCard shows description when present',
        (WidgetTester tester) async {
      final jobWithDesc = Job(
        id: 'j-103',
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

      final materialApp = find.byType(MaterialApp).evaluate().first.widget
          as MaterialApp;
      expect(materialApp.theme, isNotNull);
      expect(materialApp.darkTheme, isNotNull);
      expect(materialApp.themeMode, ThemeMode.system);
    });

    testWidgets('JobCard renders correctly in light mode',
        (WidgetTester tester) async {
      final testJob = Job(
        id: 'j-104',
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
        id: 'j-105',
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
