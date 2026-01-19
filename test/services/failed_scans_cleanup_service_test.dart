import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:wingtip/core/failed_scans_directory.dart';
import 'package:wingtip/data/database.dart';
import 'package:wingtip/services/failed_scans_cleanup_service.dart';
import 'package:drift/native.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:path/path.dart' as p;

// Mock for PathProvider
class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  String? _tempPath;

  void setTempPath(String path) {
    _tempPath = path;
  }

  @override
  Future<String?> getApplicationDocumentsPath() async {
    return _tempPath;
  }
}

void main() {
  late AppDatabase database;
  late FailedScansCleanupService cleanupService;
  late MockPathProviderPlatform mockPathProvider;
  late Directory tempDir;

  setUp(() async {
    // Create a temporary directory for test files
    tempDir = await Directory.systemTemp.createTemp('wingtip_test_');

    // Setup mock path provider
    mockPathProvider = MockPathProviderPlatform();
    mockPathProvider.setTempPath(tempDir.path);
    PathProviderPlatform.instance = mockPathProvider;

    // Create test database
    database = AppDatabase.test(NativeDatabase.memory());

    // Create cleanup service
    cleanupService = FailedScansCleanupService(database);
  });

  tearDown(() async {
    await database.close();
    // Clean up temp directory
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('FailedScansCleanupService', () {
    test('cleanupExpiredScans removes expired scans', () async {
      // Create expired scan (expiresAt in the past)
      // Insert directly with a past expiresAt
      final now = DateTime.now().millisecondsSinceEpoch;
      final expiredTime = now - const Duration(days: 1).inMilliseconds;

      await database.into(database.failedScans).insert(
        FailedScansCompanion.insert(
          jobId: 'expired-job-1',
          imagePath: '/path/to/expired1.jpg',
          errorMessage: 'Test error',
          createdAt: expiredTime,
          expiresAt: expiredTime,
        ),
      );

      // Create future scan (expiresAt in the future)
      await database.saveFailedScan(
        jobId: 'future-job-1',
        imagePath: '/path/to/future1.jpg',
        errorMessage: 'Test error',
        retentionPeriod: const Duration(days: 7),
      );

      // Verify both scans exist
      final allScansBeforeCleanup = await database.select(database.failedScans).get();
      expect(allScansBeforeCleanup.length, equals(2));

      // Run cleanup
      final deletedCount = await cleanupService.cleanupExpiredScans();

      // Verify one scan was deleted
      expect(deletedCount, equals(1));

      // Verify only the future scan remains
      final allScansAfterCleanup = await database.select(database.failedScans).get();
      expect(allScansAfterCleanup.length, equals(1));
      expect(allScansAfterCleanup.first.jobId, equals('future-job-1'));
    });

    test('cleanupExpiredScans handles no expired scans', () async {
      // Create only future scans
      await database.saveFailedScan(
        jobId: 'future-job-1',
        imagePath: '/path/to/future1.jpg',
        errorMessage: 'Test error',
        retentionPeriod: const Duration(days: 7),
      );

      // Run cleanup
      final deletedCount = await cleanupService.cleanupExpiredScans();

      // Verify nothing was deleted
      expect(deletedCount, equals(0));

      // Verify scan still exists
      final allScans = await database.select(database.failedScans).get();
      expect(allScans.length, equals(1));
    });

    test('cleanupExpiredScans handles multiple expired scans', () async {
      // Create multiple expired scans
      final now = DateTime.now().millisecondsSinceEpoch;
      final expiredTime = now - const Duration(days: 1).inMilliseconds;

      for (int i = 0; i < 5; i++) {
        await database.into(database.failedScans).insert(
          FailedScansCompanion.insert(
            jobId: 'expired-job-$i',
            imagePath: '/path/to/expired$i.jpg',
            errorMessage: 'Test error',
            createdAt: expiredTime,
            expiresAt: expiredTime,
          ),
        );
      }

      // Run cleanup
      final deletedCount = await cleanupService.cleanupExpiredScans();

      // Verify all 5 scans were deleted
      expect(deletedCount, equals(5));

      // Verify no scans remain
      final allScans = await database.select(database.failedScans).get();
      expect(allScans.length, equals(0));
    });

    test('cleanupOrphanedImages removes orphaned files', () async {
      // Create failed scans directory
      final failedScansDir = await FailedScansDirectory.getDirectory();

      // Create some orphaned image files (no database entries)
      final orphanedFile1 = File(p.join(failedScansDir.path, 'orphaned-1.jpg'));
      await orphanedFile1.writeAsString('test image data');

      final orphanedFile2 = File(p.join(failedScansDir.path, 'orphaned-2.jpg'));
      await orphanedFile2.writeAsString('test image data');

      // Create a valid scan with matching image file
      await database.saveFailedScan(
        jobId: 'valid-job',
        imagePath: p.join(failedScansDir.path, 'valid-job.jpg'),
        errorMessage: 'Test error',
      );
      final validFile = File(p.join(failedScansDir.path, 'valid-job.jpg'));
      await validFile.writeAsString('test image data');

      // Verify files exist
      expect(await orphanedFile1.exists(), isTrue);
      expect(await orphanedFile2.exists(), isTrue);
      expect(await validFile.exists(), isTrue);

      // Run cleanup
      final deletedCount = await cleanupService.cleanupOrphanedImages();

      // Verify 2 orphaned files were deleted
      expect(deletedCount, equals(2));

      // Verify orphaned files are gone
      expect(await orphanedFile1.exists(), isFalse);
      expect(await orphanedFile2.exists(), isFalse);

      // Verify valid file still exists
      expect(await validFile.exists(), isTrue);
    });

    test('runFullCleanup performs both expired and orphaned cleanup', () async {
      // Create expired scan
      final now = DateTime.now().millisecondsSinceEpoch;
      final expiredTime = now - const Duration(days: 1).inMilliseconds;

      await database.into(database.failedScans).insert(
        FailedScansCompanion.insert(
          jobId: 'expired-job',
          imagePath: '/path/to/expired.jpg',
          errorMessage: 'Test error',
          createdAt: expiredTime,
          expiresAt: expiredTime,
        ),
      );

      // Create orphaned image file
      final failedScansDir = await FailedScansDirectory.getDirectory();
      final orphanedFile = File(p.join(failedScansDir.path, 'orphaned.jpg'));
      await orphanedFile.writeAsString('test image data');

      // Run full cleanup
      final totalCount = await cleanupService.runFullCleanup();

      // Verify cleanup occurred (at least the expired scan)
      expect(totalCount, greaterThan(0));

      // Verify expired scan is gone
      final allScans = await database.select(database.failedScans).get();
      expect(allScans.where((s) => s.jobId == 'expired-job').isEmpty, isTrue);
    });

    test('cleanupExpiredScans handles empty database', () async {
      // Run cleanup on empty database
      final deletedCount = await cleanupService.cleanupExpiredScans();

      // Verify nothing was deleted
      expect(deletedCount, equals(0));
    });

    test('cleanupOrphanedImages handles no orphaned files', () async {
      // Create a valid scan
      await database.saveFailedScan(
        jobId: 'valid-job',
        imagePath: '/path/to/valid.jpg',
        errorMessage: 'Test error',
      );

      // Create matching image file
      final failedScansDir = await FailedScansDirectory.getDirectory();
      final validFile = File(p.join(failedScansDir.path, 'valid-job.jpg'));
      await validFile.writeAsString('test image data');

      // Run cleanup
      final deletedCount = await cleanupService.cleanupOrphanedImages();

      // Verify nothing was deleted
      expect(deletedCount, equals(0));

      // Verify file still exists
      expect(await validFile.exists(), isTrue);
    });
  });
}
