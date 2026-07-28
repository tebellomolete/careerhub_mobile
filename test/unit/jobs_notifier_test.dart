// Assignment 3.2, Part 3 — JobsNotifier unit tests.
//
// These tests verify the notifier's contract with its collaborator,
// `JobsRepository`, using mocktail. The three tests exercise the
// three transitions a real caller cares about:
//   1. loading → data (Success from the network).
//   2. loading → error (Failure from the network, empty cache).
//   3. error → data after refresh() (a retry that succeeds).
//
// See README 3.2 Q1 for why mocktail (not the subclass-override
// pattern) is the right tool: every assertion below is either a
// value assertion on the notifier's state OR a `verify()` on the
// mock's call count. The call-count assertions are what the
// subclass-override pattern cannot see.

import 'package:careerhub_mobile/data/api_result.dart';
import 'package:careerhub_mobile/data/jobs_repository.dart';
import 'package:careerhub_mobile/models/job.dart';
import 'package:careerhub_mobile/providers/jobs_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Part 3.1 — the single-line mock declaration the brief mandates.
// `Mock` from mocktail supplies noSuchMethod; `implements
// JobsRepository` binds the mock's type surface to the real
// repository's methods so `when(() => mock.getJobs())` compiles
// with the correct return type.
class MockJobsRepository extends Mock implements JobsRepository {}

// Part 3.2 — shared fixtures declared at top level.
//
// Compile-time constants would be ideal, but `Job` is a Freezed
// class whose factory constructor is `const` yet requires
// `LocationType` values that only exist at runtime — using
// `final` top-level values gets us the same "declared once,
// referenced by every test" property. If a field is added to
// `Job` tomorrow, every fixture updates in one place; contrast
// with per-test-body construction, which the brief calls out
// as silently diverging under model changes.
final Job _fixtureJob1 = Job(
  id: 'job-eng-1',
  title: 'Senior Flutter Engineer',
  company: 'Bitcube',
  location: 'Cape Town, ZA',
  locationType: LocationType.onSite,
  employmentType: 'Full-time',
  salary: 'R55 000 – R75 000 per month',
);

final Job _fixtureJob2 = Job(
  id: 'job-eng-2',
  title: 'Backend Engineer',
  company: 'Nimbus Systems',
  location: 'Johannesburg, ZA',
  locationType: LocationType.onSite,
  employmentType: 'Full-time',
);

final Job _fixtureJob3 = Job(
  id: 'job-remote-1',
  title: 'Product Designer',
  company: 'Loop Studio',
  location: 'Remote',
  locationType: LocationType.remote,
  employmentType: 'Contract',
);

final List<Job> _fixtureJobs = [_fixtureJob1, _fixtureJob2, _fixtureJob3];

void main() {
  // Part 3.3 — the shared setup. `late` because the mock is
  // rebuilt for every test to guarantee zero cross-test state.
  late MockJobsRepository mockRepo;

  setUp(() {
    mockRepo = MockJobsRepository();

    // `getCachedJobs()` is called by the notifier's build() BEFORE
    // getJobs() — the cache-then-network flow from Assignment 2.3
    // Part 8. We stub it to return an empty list so the notifier
    // proceeds to the network call and the tests below can assert
    // on the Success / Failure transition directly. See README 3.2
    // assumption 7.
    when(() => mockRepo.getCachedJobs()).thenAnswer((_) async => <Job>[]);
  });

  /// The container-builder helper the brief calls for. Overrides
  /// `jobsRepositoryProvider` with the mock, AND overrides
  /// `cachedJobsStreamProvider` with an empty stream so the
  /// `ref.listen(cachedJobsStreamProvider, ...)` inside
  /// `JobsNotifier.build()` doesn't try to reach the real Isar
  /// instance. Registers `container.dispose` for teardown — see
  /// README 3.2 Q2 (third bullet) on the leak this prevents.
  ///
  /// `jobsProvider` is auto-dispose (see the `isAutoDispose: true`
  /// in `jobs_notifier.g.dart`), so a bare `container.read` closes
  /// the last subscription the moment the read returns, disposing
  /// the provider mid-build and reporting a spurious StateError.
  /// The helper attaches a `container.listen` that never fires its
  /// callback — its only job is to hold the subscription open so
  /// `future` reads and state reads see the same underlying element.
  /// Each test captures the returned subscription and closes it as
  /// part of the container teardown.
  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      // Riverpod 3's default `retry` schedules an exponential-backoff
      // rebuild whenever `build()` throws. That is the correct
      // production behaviour, but in tests it would silently invoke
      // our mock a SECOND time between the initial rejection and our
      // `verify(...).called(1)` assertion — and the second call in
      // test 3's sequence returns Success, which was the exact
      // failure the earlier iterations of this file produced. Disabling
      // retry gives us the deterministic single-call-per-build semantics
      // the assertions rely on. See README 3.2 Q1's discussion of
      // interaction assertions.
      retry: (_, __) => null,
      overrides: [
        jobsRepositoryProvider.overrideWithValue(mockRepo),
        cachedJobsStreamProvider.overrideWith(
          (ref) => const Stream<List<Job>>.empty(),
        ),
      ],
    );
    addTearDown(container.dispose);
    // `fireImmediately: true` guarantees the subscription is
    // registered against a live element before the test body's
    // first read — without it, the initial build starts on the
    // next microtask and can race the .future read.
    container.listen<AsyncValue<List<Job>>>(
      jobsProvider,
      (_, __) {},
      fireImmediately: true,
    );
    return container;
  }

  group('JobsNotifier', () {
    test('transitions from loading to data when getJobsRepository returns Success',
        () async {
      // Arrange — stub Success BEFORE constructing the container.
      // If the stub is registered after the notifier's build() has
      // already started, the mock's default noSuchMethod would
      // return null and the notifier would blow up on the
      // pattern-match.
      when(() => mockRepo.getJobs())
          .thenAnswer((_) async => Success(_fixtureJobs));

      final container = makeContainer();

      // Assert — immediately after construction, the provider is in
      // AsyncLoading. See README 3.2 Q2 (first bullet) — the
      // synchronous read returns the current snapshot; the future
      // has not resolved yet.
      expect(
        container.read(jobsProvider),
        isA<AsyncLoading<List<Job>>>(),
      );

      // Await the future — this is the "read the future first, THEN
      // read the state" pattern that reveals the completed value.
      final resolved = await container.read(jobsProvider.future);
      expect(resolved, equals(_fixtureJobs));

      // The now-synchronous state carries the same list under AsyncData.
      expect(
        container.read(jobsProvider),
        isA<AsyncData<List<Job>>>()
            .having((v) => v.value, 'value', equals(_fixtureJobs)),
      );

      // The interaction assertion — the one the subclass-override
      // pattern cannot see. See README 3.2 Q1 for the specific bug
      // scenario this catches (a merge conflict that resolves the
      // getJobs() call into a duplicate).
      verify(() => mockRepo.getJobs()).called(1);
    });

    test('transitions from loading to error when getJobsRepository returns Failure',
        () async {
      // A NetworkFailure with a message string — the closest single-
      // arg fit to the brief's "Failure with a message string". See
      // README 3.2 assumption 3.
      when(() => mockRepo.getJobs())
          .thenAnswer((_) async => const NetworkFailure('Offline for tests'));

      final container = makeContainer();

      // Same loading assertion as above — the synchronous read
      // returns AsyncLoading before the build's throw has been
      // executed.
      expect(
        container.read(jobsProvider),
        isA<AsyncLoading<List<Job>>>(),
      );

      // Capture the future ONCE and pass the same handle to
      // expectLater. Reading `.future` twice on an auto-dispose
      // AsyncNotifier can produce two separately-completing futures
      // — capturing once binds the assertion to the exact build
      // the state check above observed.
      final rejectedFuture = container.read(jobsProvider.future);

      // The future rejects with the Exception the notifier throws
      // on the Failure-with-empty-cache branch. See
      // lib/providers/jobs_notifier.dart:144.
      await expectLater(
        rejectedFuture,
        throwsA(isA<Exception>()),
      );

      // After the rejection, the synchronous state carries the
      // exception as AsyncError — see README 3.2 Q2 (second
      // bullet) on the AsyncValue subclass name.
      expect(
        container.read(jobsProvider),
        isA<AsyncError<List<Job>>>(),
      );

      // Same call-count guarantee.
      verify(() => mockRepo.getJobs()).called(1);
    });

    test('recovers to data after refresh() following an error', () async {
      // Sequence-of-returns pattern — a counter closes over the
      // call index and picks a different ApiResult per call. This
      // is the mocktail idiom for "first call fails, second call
      // succeeds" without needing to re-stub in the middle of the
      // test.
      var callCount = 0;
      when(() => mockRepo.getJobs()).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          return const NetworkFailure('First call fails');
        }
        return Success(_fixtureJobs);
      });

      final container = makeContainer();

      // Capture the first build's future BEFORE any other read —
      // same reason as test 2. The future for the FIRST build is
      // the one we expect to reject.
      final firstFuture = container.read(jobsProvider.future);
      await expectLater(
        firstFuture,
        throwsA(isA<Exception>()),
      );
      expect(
        container.read(jobsProvider),
        isA<AsyncError<List<Job>>>(),
      );

      // The retry — refresh() calls invalidateSelf() and awaits
      // the fresh future. See lib/providers/jobs_notifier.dart:149
      // for the implementation the brief refers to.
      await container.read(jobsProvider.notifier).refresh();

      // After refresh, the state is AsyncData with the fixture list.
      expect(
        container.read(jobsProvider),
        isA<AsyncData<List<Job>>>()
            .having((v) => v.value, 'value', equals(_fixtureJobs)),
      );

      // Two calls total: the failing one, then the successful one.
      verify(() => mockRepo.getJobs()).called(2);
    });
  });
}
