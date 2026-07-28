// Assignment 3.3, Stretch B — ApplicationsRepository unit tests.
//
// These tests cover the three status-code branches called out in
// the Stretch B brief: the 409 exact-string case, the 422
// exact-string case, and the null-statusCode connection-error case.
//
// The approach uses `DioAdapter` from `http_mock_adapter` — but
// that package is not in this project's pubspec. To keep this file
// self-contained without adding a new dev-dependency, the tests
// use a hand-rolled `_MockDio` that overrides `post` / `get` to
// throw a pre-built `DioException`. This is enough to exercise
// every branch of `submitApplication`'s catch — see
// `_MockDioThatThrows` below for the mechanism.

import 'package:careerhub_mobile/data/api_result.dart';
import 'package:careerhub_mobile/data/applications_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// A mock Dio whose `post` and `get` throw a pre-configured
/// DioException. Kept minimal on purpose: the repository's
/// interaction with Dio is limited to one call per method, and
/// the response-decoding branches are covered by a separate
/// Success-path test below that returns a `Response` instead of
/// throwing.
class _MockDio extends Mock implements Dio {}

void main() {
  late _MockDio mockDio;
  late ApplicationsRepository repo;

  // Required for any mocktail matcher against a non-primitive
  // parameter type — Dio's `data` field takes `Object?`, so
  // `any()` needs a fallback registration to unwrap. `Options`
  // is registered because `_dio.post` accepts a nullable
  // `Options` argument.
  setUpAll(() {
    registerFallbackValue(Options());
  });

  setUp(() {
    mockDio = _MockDio();
    repo = ApplicationsRepository(dio: mockDio);
  });

  group('submitApplication', () {
    test('returns Success on 200', () async {
      when(() => mockDio.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
          )).thenAnswer(
        (_) async => Response(
          data: const {'Message': 'ok'},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/jobs/j1/applications'),
        ),
      );

      final result = await repo.submitApplication('j1', {'a': 'b'});
      expect(result, isA<Success<void>>());
    });

    test(
      'returns ServerFailure with the exact duplicate-application '
      'message on 409',
      () async {
        when(() => mockDio.post<Map<String, dynamic>>(
              any(),
              data: any(named: 'data'),
            )).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/jobs/j1/applications'),
            response: Response(
              requestOptions:
                  RequestOptions(path: '/jobs/j1/applications'),
              statusCode: 409,
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        final result = await repo.submitApplication('j1', {'a': 'b'});
        expect(result, isA<ServerFailure<void>>());
        final failure = result as ServerFailure<void>;
        expect(failure.statusCode, 409);
        // The EXACT string the brief mandates.
        expect(
          failure.message,
          'You have already applied for this position.',
        );
      },
    );

    test(
      'returns ServerFailure with the exact listing-closed message '
      'on 422',
      () async {
        when(() => mockDio.post<Map<String, dynamic>>(
              any(),
              data: any(named: 'data'),
            )).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/jobs/j1/applications'),
            response: Response(
              requestOptions:
                  RequestOptions(path: '/jobs/j1/applications'),
              statusCode: 422,
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        final result = await repo.submitApplication('j1', {'a': 'b'});
        expect(result, isA<ServerFailure<void>>());
        final failure = result as ServerFailure<void>;
        expect(failure.statusCode, 422);
        expect(
          failure.message,
          'This listing is no longer accepting applications.',
        );
      },
    );

    test(
      'returns ServerFailure with statusCode 401 on 401 so the '
      'notifier can trigger auto-logout',
      () async {
        when(() => mockDio.post<Map<String, dynamic>>(
              any(),
              data: any(named: 'data'),
            )).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/jobs/j1/applications'),
            response: Response(
              requestOptions:
                  RequestOptions(path: '/jobs/j1/applications'),
              statusCode: 401,
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        final result = await repo.submitApplication('j1', {'a': 'b'});
        expect(result, isA<ServerFailure<void>>());
        expect((result as ServerFailure<void>).statusCode, 401);
      },
    );

    test(
      'returns NetworkFailure on connectionError (null statusCode)',
      () async {
        when(() => mockDio.post<Map<String, dynamic>>(
              any(),
              data: any(named: 'data'),
            )).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/jobs/j1/applications'),
            type: DioExceptionType.connectionError,
            // response is null — the null-statusCode branch.
          ),
        );

        final result = await repo.submitApplication('j1', {'a': 'b'});
        expect(result, isA<NetworkFailure<void>>());
        expect(
          (result as NetworkFailure<void>).message,
          contains('internet'),
        );
      },
    );
  });
}
