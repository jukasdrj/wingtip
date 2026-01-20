import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wingtip/data/database.dart';
import 'package:wingtip/data/failed_scans_repository.dart';

void main() {
  late AppDatabase database;
  late FailedScansRepository repository;

  setUpAll(() {
    // Initialize Flutter binding for path_provider
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    database = AppDatabase.test(NativeDatabase.memory());
    repository = FailedScansRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('FailedScansRepository', () {
    group('saveFailedScan', () {
      test('should save a failed scan with default retention period', () async {
        final beforeSave = DateTime.now().millisecondsSinceEpoch;

        await repository.saveFailedScan(
          jobId: 'job-123',
          imagePath: '/tmp/test_image.jpg',
          errorMessage: 'OCR processing failed',
        );

        final afterSave = DateTime.now().millisecondsSinceEpoch;

        final scans = await database.select(database.failedScans).get();
        expect(scans.length, 1);

        final scan = scans.first;
        expect(scan.jobId, 'job-123');
        expect(scan.imagePath, '/tmp/test_image.jpg');
        expect(scan.errorMessage, 'OCR processing failed');

        expect(scan.createdAt, greaterThanOrEqualTo(beforeSave));
        expect(scan.createdAt, lessThanOrEqualTo(afterSave));

        final expectedExpiresAt = scan.createdAt + const Duration(days: 7).inMilliseconds;
        expect(scan.expiresAt, expectedExpiresAt);
      });

      test('should save a failed scan with custom retention period', () async {
        await repository.saveFailedScan(
          jobId: 'job-456',
          imagePath: '/tmp/another_image.jpg',
          errorMessage: 'Network timeout',
          retentionPeriod: const Duration(days: 14),
        );

        final scans = await database.select(database.failedScans).get();
        expect(scans.length, 1);

        final scan = scans.first;
        expect(scan.jobId, 'job-456');

        final expectedExpiresAt = scan.createdAt + const Duration(days: 14).inMilliseconds;
        expect(scan.expiresAt, expectedExpiresAt);
      });

      test('should save multiple failed scans', () async {
        await repository.saveFailedScan(
          jobId: 'job-1',
          imagePath: '/tmp/image1.jpg',
          errorMessage: 'Error 1',
        );

        await repository.saveFailedScan(
          jobId: 'job-2',
          imagePath: '/tmp/image2.jpg',
          errorMessage: 'Error 2',
        );

        await repository.saveFailedScan(
          jobId: 'job-3',
          imagePath: '/tmp/image3.jpg',
          errorMessage: 'Error 3',
        );

        final scans = await database.select(database.failedScans).get();
        expect(scans.length, 3);

        expect(scans[0].jobId, 'job-1');
        expect(scans[1].jobId, 'job-2');
        expect(scans[2].jobId, 'job-3');
      });
    });

    group('getAllFailedScans', () {
      test('should return empty stream when no failed scans exist', () async {
        final stream = repository.getAllFailedScans();
        final scans = await stream.first;

        expect(scans.isEmpty, true);
      });

      test('should return all failed scans as a stream', () async {
        await repository.saveFailedScan(
          jobId: 'job-1',
          imagePath: '/tmp/image1.jpg',
          errorMessage: 'Error 1',
        );

        await repository.saveFailedScan(
          jobId: 'job-2',
          imagePath: '/tmp/image2.jpg',
          errorMessage: 'Error 2',
        );

        final stream = repository.getAllFailedScans();
        final scans = await stream.first;

        expect(scans.length, 2);
        expect(scans[0].jobId, 'job-1');
        expect(scans[1].jobId, 'job-2');
      });

      test('should emit updated data when a new scan is added', () async {
        final stream = repository.getAllFailedScans();

        var scans = await stream.first;
        expect(scans.isEmpty, true);

        await repository.saveFailedScan(
          jobId: 'job-new',
          imagePath: '/tmp/new_image.jpg',
          errorMessage: 'New error',
        );

        scans = await stream.first;
        expect(scans.length, 1);
        expect(scans.first.jobId, 'job-new');
      });
    });

    group('deleteFailedScan', () {
      test('should delete a failed scan by id', () async {
        await repository.saveFailedScan(
          jobId: 'job-to-delete',
          imagePath: '/tmp/delete_me.jpg',
          errorMessage: 'Will be deleted',
        );

        var scans = await database.select(database.failedScans).get();
        expect(scans.length, 1);

        final scanId = scans.first.id;
        await repository.deleteFailedScan(scanId);

        scans = await database.select(database.failedScans).get();
        expect(scans.isEmpty, true);
      });

      test('should only delete the specified scan', () async {
        await repository.saveFailedScan(
          jobId: 'job-1',
          imagePath: '/tmp/image1.jpg',
          errorMessage: 'Error 1',
        );

        await repository.saveFailedScan(
          jobId: 'job-2',
          imagePath: '/tmp/image2.jpg',
          errorMessage: 'Error 2',
        );

        await repository.saveFailedScan(
          jobId: 'job-3',
          imagePath: '/tmp/image3.jpg',
          errorMessage: 'Error 3',
        );

        var scans = await database.select(database.failedScans).get();
        expect(scans.length, 3);

        final secondScanId = scans[1].id;
        await repository.deleteFailedScan(secondScanId);

        scans = await database.select(database.failedScans).get();
        expect(scans.length, 2);
        expect(scans[0].jobId, 'job-1');
        expect(scans[1].jobId, 'job-3');
      });

      test('should handle deleting non-existent scan gracefully', () async {
        await repository.deleteFailedScan(999);

        final scans = await database.select(database.failedScans).get();
        expect(scans.isEmpty, true);
      });
    });

    group('retryFailedScan', () {
      test('should return the failed scan by id', () async {
        await repository.saveFailedScan(
          jobId: 'job-retry',
          imagePath: '/tmp/retry_me.jpg',
          errorMessage: 'Retry this scan',
        );

        final scans = await database.select(database.failedScans).get();
        expect(scans.length, 1);

        final scanId = scans.first.id;
        final retrievedScan = await repository.retryFailedScan(scanId);

        expect(retrievedScan, isNotNull);
        expect(retrievedScan!.id, scanId);
        expect(retrievedScan.jobId, 'job-retry');
        expect(retrievedScan.imagePath, '/tmp/retry_me.jpg');
        expect(retrievedScan.errorMessage, 'Retry this scan');
      });

      test('should return null for non-existent scan id', () async {
        final retrievedScan = await repository.retryFailedScan(999);

        expect(retrievedScan, isNull);
      });

      test('should not delete the scan when retrying', () async {
        await repository.saveFailedScan(
          jobId: 'job-persist',
          imagePath: '/tmp/persist.jpg',
          errorMessage: 'Should remain after retry',
        );

        final scans = await database.select(database.failedScans).get();
        final scanId = scans.first.id;

        await repository.retryFailedScan(scanId);

        final scansAfterRetry = await database.select(database.failedScans).get();
        expect(scansAfterRetry.length, 1);
        expect(scansAfterRetry.first.id, scanId);
      });

      test('should return the correct scan when multiple exist', () async {
        await repository.saveFailedScan(
          jobId: 'job-1',
          imagePath: '/tmp/image1.jpg',
          errorMessage: 'Error 1',
        );

        await repository.saveFailedScan(
          jobId: 'job-2',
          imagePath: '/tmp/image2.jpg',
          errorMessage: 'Error 2',
        );

        await repository.saveFailedScan(
          jobId: 'job-3',
          imagePath: '/tmp/image3.jpg',
          errorMessage: 'Error 3',
        );

        final scans = await database.select(database.failedScans).get();
        final secondScanId = scans[1].id;

        final retrievedScan = await repository.retryFailedScan(secondScanId);

        expect(retrievedScan, isNotNull);
        expect(retrievedScan!.id, secondScanId);
        expect(retrievedScan.jobId, 'job-2');
      });
    });
  });
}
