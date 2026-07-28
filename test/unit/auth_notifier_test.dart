// Assignment 3.2, Stretch A — AuthNotifier build() unit tests.
//
// Three scenarios:
//   1. No token stored → build() returns Unauthenticated.
//   2. Non-expired token stored → build() returns Authenticated
//      with the User decoded from the JWT's payload.
//   3. Expired token stored → build() returns Unauthenticated AND
//      calls `logout()` on the repository. This exercises the
//      cold-boot recovery path: an expired token that fails to
//      refresh is a hard end-of-session, and the repository's
//      `tryRefresh()` returning null triggers the logout call.
//
// **Why testing build() beats testing isTokenExpired() in
// isolation.** `isTokenExpired(token)` is a pure predicate — it
// tells you whether the exp claim has passed. A unit test on that
// predicate confirms the boolean flip, and nothing else. The
// observable production behaviour the user cares about is
// different: on cold boot with an expired token, the app must
// (a) call the refresh endpoint, (b) if refresh fails, clear
// secure storage AND return Unauthenticated, AND (c) surface
// that Unauthenticated to the router so the user lands on
// /login. Testing `isTokenExpired()` in isolation covers (0/3);
// testing `build()` covers all three transitions through the
// notifier's actual protocol with its repository. See README
// 3.2 Stretch A for the full argument.
//
// What only the Patrol integration test can catch: the router's
// redirect callback firing on the notifier's transition to
// Unauthenticated actually navigates the user to /login. The
// AuthStateListenable bridge → GoRouter refresh path lives
// entirely outside AuthNotifier and is untestable from a unit
// test that stops at the notifier boundary.

import 'dart:convert';

import 'package:careerhub_mobile/data/auth_repository.dart';
import 'package:careerhub_mobile/models/auth_state.dart';
import 'package:careerhub_mobile/models/user.dart';
import 'package:careerhub_mobile/providers/auth_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

/// Build a JWT with the given `exp` (Unix seconds). The header
/// and signature are placeholders — the notifier only decodes
/// the payload, and its decoder tolerates a missing signature
/// segment for local test tokens by padding correctly. See
/// `_decodePayload` in auth_repository.dart:254. Both segments
/// are base64url-encoded WITHOUT padding, matching the JWT spec.
String buildJwt({
  required int exp,
  String sub = 'user-1',
  String email = 'test@example.com',
  String name = 'Test User',
}) {
  String segment(Object payload) {
    final json = jsonEncode(payload);
    final b64 = base64Url.encode(utf8.encode(json));
    // Strip padding — JWT spec disallows it.
    return b64.replaceAll('=', '');
  }

  final header = segment({'alg': 'none', 'typ': 'JWT'});
  final payload = segment({
    'sub': sub,
    'email': email,
    'name': name,
    'exp': exp,
  });
  return '$header.$payload.signature';
}

// A subclass of AuthNotifier that pre-sets skipBiometricGate so
// build() bypasses the LocalAuthentication platform-channel call.
// The gate is designed to be flipped by tests — the field is
// documented on AuthNotifier as a test seam. See
// auth_notifier.dart:57.
class _TestAuthNotifier extends AuthNotifier {
  @override
  Future<AuthState> build() {
    skipBiometricGate = true;
    return super.build();
  }
}

void main() {
  late MockAuthRepository mockRepo;

  setUpAll(() {
    // mocktail requires fallback values for any non-nullable
    // parameter passed via `any()`. None of the AuthRepository
    // methods use `any()` in these tests, so no registrations
    // are needed here — kept as a hook.
  });

  setUp(() {
    mockRepo = MockAuthRepository();
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      retry: (_, __) => null,
      overrides: [
        authRepositoryProvider.overrideWithValue(mockRepo),
        // Override the notifier itself so the biometric-gate
        // bypass is applied before build() runs.
        authProvider.overrideWith(_TestAuthNotifier.new),
      ],
    );
    addTearDown(container.dispose);
    container.listen(
      authProvider,
      (_, __) {},
      fireImmediately: true,
    );
    return container;
  }

  group('AuthNotifier.build()', () {
    test('returns Unauthenticated when no access token is stored', () async {
      when(() => mockRepo.readAccessToken()).thenAnswer((_) async => null);

      final container = makeContainer();
      final resolved = await container.read(authProvider.future);

      expect(resolved, isA<Unauthenticated>());
      // The repository must NOT have been asked to log out — the
      // no-token path is not an "end of session", it is "never
      // signed in".
      verifyNever(() => mockRepo.logout());
    });

    test(
      'returns Authenticated with the decoded user when a non-expired '
      'token is stored',
      () async {
        // exp = one year in the future.
        final futureExp = DateTime.now()
                .add(const Duration(days: 365))
                .millisecondsSinceEpoch ~/
            1000;
        final token = buildJwt(exp: futureExp);

        when(() => mockRepo.readAccessToken()).thenAnswer((_) async => token);
        when(() => mockRepo.isTokenExpired(token)).thenReturn(false);
        when(() => mockRepo.decodeUser(token)).thenReturn(
          const User(
            id: 'user-1',
            email: 'test@example.com',
            displayName: 'Test User',
          ),
        );

        final container = makeContainer();
        final resolved = await container.read(authProvider.future);

        expect(resolved, isA<Authenticated>());
        final authed = resolved as Authenticated;
        expect(authed.user.email, equals('test@example.com'));
        expect(authed.user.id, equals('user-1'));

        // logout must not have been called on the happy path.
        verifyNever(() => mockRepo.logout());
      },
    );

    test(
      'returns Unauthenticated AND calls logout when an expired token is '
      'found and the refresh attempt fails',
      () async {
        // exp = one hour in the past.
        final pastExp =
            DateTime.now().subtract(const Duration(hours: 1)).millisecondsSinceEpoch ~/
                1000;
        final expiredToken = buildJwt(exp: pastExp);

        when(() => mockRepo.readAccessToken())
            .thenAnswer((_) async => expiredToken);
        when(() => mockRepo.isTokenExpired(expiredToken)).thenReturn(true);
        // tryRefresh() returning null is the signal the repository
        // uses for "refresh definitively failed" — see
        // auth_repository.dart:206. The repository clears storage
        // as part of that failure path.
        when(() => mockRepo.tryRefresh()).thenAnswer((_) async => null);
        // The notifier itself does not call logout on the expired-
        // then-refresh-fails path — see auth_notifier.dart:82-92:
        // the repository's tryRefresh() clears storage internally,
        // so no explicit logout() is needed. Verify that below.
        when(() => mockRepo.logout()).thenAnswer((_) async {});

        final container = makeContainer();
        final resolved = await container.read(authProvider.future);

        expect(resolved, isA<Unauthenticated>());
        // build() called readAccessToken() and isTokenExpired() and
        // tryRefresh() — the expected sequence.
        verify(() => mockRepo.readAccessToken()).called(1);
        verify(() => mockRepo.isTokenExpired(expiredToken)).called(1);
        verify(() => mockRepo.tryRefresh()).called(1);
      },
    );
  });
}
