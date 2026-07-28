// Assignment 3.3, Stretch B — ApplicationsNotifier 401 path test.
//
// Scenario:
//   - The mock ApplicationsRepository returns a
//     `ServerFailure(statusCode: 401, ...)` on `getApplications()`.
//   - The notifier's `build()` must:
//       1. call `authRepo.logout()`,
//       2. throw an Exception so the widget layer flashes an
//          AsyncError until the router redirect fires.
//
// The test verifies (1) by asserting `verify(() => mockAuthRepo.logout())
// .called(1)` and (2) by asserting that awaiting the notifier's
// `future` throws.
//
// **Limitation of this test (README note).** This unit test can
// confirm `logout()` was called on the mock auth repository, and
// that the notifier's future throws. It **cannot** confirm that
// `authProvider` flipped to `Unauthenticated`, that the
// `AuthStateListenable` fired, that GoRouter's redirect callback
// re-ran, and that the user's device landed on `/login`. The
// end-to-end navigation path lives across three layers (notifier
// → auth listenable → GoRouter refresh → widget rebuild) and is
// only observable in a **widget or integration test** with a real
// `ProviderScope` + `MaterialApp.router` mounted. Assignment 3.2
// Stretch A used a Patrol integration test for exactly this
// coverage; a Stretch B test here would duplicate that harness
// without adding coverage this unit test already achieves.

import 'package:careerhub_mobile/data/api_result.dart';
import 'package:careerhub_mobile/data/applications_repository.dart';
import 'package:careerhub_mobile/data/auth_repository.dart';
import 'package:careerhub_mobile/models/application.dart';
import 'package:careerhub_mobile/providers/applications_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApplicationsRepository extends Mock
    implements ApplicationsRepository {}

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockApplicationsRepository mockRepo;
  late _MockAuthRepository mockAuthRepo;
  late ProviderContainer container;

  setUp(() {
    mockRepo = _MockApplicationsRepository();
    mockAuthRepo = _MockAuthRepository();

    // `retry: (_, __) => null` disables Riverpod 3's default
    // automatic retry-on-error, which would otherwise re-run
    // build() repeatedly against the same mock and hang the
    // test isolate waiting for a state transition that never
    // arrives. Same pattern the existing
    // `test/unit/auth_notifier_test.dart` uses.
    container = ProviderContainer(
      retry: (_, __) => null,
      overrides: [
        applicationsRepositoryProvider.overrideWithValue(mockRepo),
        authRepositoryProvider.overrideWithValue(mockAuthRepo),
      ],
    );

    // Default: logout resolves without throwing.
    when(() => mockAuthRepo.logout()).thenAnswer((_) async {});
  });

  // Subscribe to the provider AFTER the per-test stubs are set up so
  // build() sees a stubbed mock, not a bare Mock returning null.
  // Without a listener, `container.read(...future)` waits on a
  // provider that never actually gets scheduled.
  void mount() {
    container.listen(applicationsProvider, (_, __) {}, fireImmediately: true);
  }

  tearDown(() {
    container.dispose();
  });

  test(
    'ApplicationsNotifier.build() calls logout() and throws when '
    'the repository returns a 401 ServerFailure',
    () async {
      when(() => mockRepo.getApplications()).thenAnswer(
        (_) async => const ServerFailure<List<Application>>(
          message: 'Your session has expired. Please sign in again.',
          statusCode: 401,
        ),
      );

      mount();

      // Awaiting the notifier's future MUST throw. `expectLater`
      // with `throwsA` composes with `future` because the
      // AsyncError arm of an AsyncNotifier propagates as a
      // Future rejection.
      await expectLater(
        container.read(applicationsProvider.future),
        throwsA(isA<Exception>()),
      );

      // The auto-logout call MUST have happened exactly once.
      verify(() => mockAuthRepo.logout()).called(1);
    },
  );

  test(
    'ApplicationsNotifier.build() does NOT call logout() when the '
    'repository returns a non-401 ServerFailure',
    () async {
      when(() => mockRepo.getApplications()).thenAnswer(
        (_) async => const ServerFailure<List<Application>>(
          message: 'CareerHub is temporarily unavailable.',
          statusCode: 503,
        ),
      );

      mount();

      // 503 is not suppressed — the notifier's future rejects,
      // but WITHOUT touching auth.
      await expectLater(
        container.read(applicationsProvider.future),
        throwsA(isA<Exception>()),
      );

      verifyNever(() => mockAuthRepo.logout());
    },
  );
}
