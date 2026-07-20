import 'dart:io';

import 'package:careerhub_mobile/data/applications_repository.dart';
import 'package:careerhub_mobile/data/job_application_isar.dart';
import 'package:careerhub_mobile/models/job_application.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';

/// W2D3 in-class challenge, stretch — unit test for the repository's
/// cache-read method, using a real Isar instance opened in a
/// temporary directory. No mocks: this is an integration test at the
/// repository boundary because that is where the "did Isar actually
/// round-trip the row correctly" bug lives.
///
/// The Dio dependency is a placeholder — [readCache] never touches it,
/// so a bare `Dio()` with no interceptors and no base URL is fine.
void main() {
  late Directory tempDir;
  late Isar isar;
  late ApplicationsRepository repo;

  setUpAll(() async {
    // Isar's native binaries have to be discoverable from the test
    // isolate. `Isar.initializeIsarCore(download: true)` fetches the
    // right binary for the current platform on first run and caches it
    // under the current directory — CI-friendly, developer-friendly,
    // and no manual per-platform setup.
    await Isar.initializeIsarCore(download: true);
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('careerhub_isar_test_');
    isar = await Isar.open(
      [JobApplicationIsarSchema],
      directory: tempDir.path,
    );
    repo = ApplicationsRepository(dio: Dio(), isar: isar);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('readCache returns an empty list on a fresh Isar instance', () async {
    final result = await repo.readCache();
    expect(result, isEmpty);
  });

  test('readCache returns rows written via seedCacheForDemo, sorted '
      'newest-first', () async {
    await repo.seedCacheForDemo();
    final result = await repo.readCache();

    expect(result, isNotEmpty);
    // The seed spans several months — the first row must be the most
    // recent submittedAt.
    for (var i = 0; i < result.length - 1; i++) {
      expect(
        result[i].submittedAt.isAfter(result[i + 1].submittedAt) ||
            result[i].submittedAt.isAtSameMomentAs(result[i + 1].submittedAt),
        isTrue,
        reason: 'row $i must be >= row ${i + 1} by submittedAt',
      );
    }
  });

  test('readCache round-trips every domain field (id, status, dates)',
      () async {
    await repo.seedCacheForDemo();
    final result = await repo.readCache();

    // Pick the "hired" seed row — it exercises the enum round-trip.
    final hired = result.firstWhere(
      (a) => a.status == ApplicationStatus.hired,
      orElse: () => throw StateError('seed missing a hired row'),
    );
    expect(hired.companyName, 'Meridian Labs');
    expect(hired.jobTitle, 'UX Researcher');
    expect(hired.id, JobApplication.compositeId('me', 'seed-5'));
    expect(hired.submittedAt, DateTime(2026, 6, 10));
  });
}
