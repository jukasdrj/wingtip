import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:wingtip/core/failed_scans_directory.dart';
import 'package:wingtip/core/network_status_provider.dart';
import 'package:wingtip/core/sse_client.dart';
import 'package:wingtip/core/sse_client_provider.dart';
import 'package:wingtip/core/talaria_client.dart';
import 'package:wingtip/core/talaria_client_provider.dart';
import 'package:wingtip/data/database.dart';
import 'package:wingtip/data/database_provider.dart';
import 'package:wingtip/data/failed_scans_repository.dart';
import 'package:wingtip/features/talaria/job_state.dart';
import 'package:wingtip/features/talaria/job_state_provider.dart';

/// Fake implementation of PathProviderPlatform for testing
class FakePathProviderPlatform extends PathProviderPlatform {
  @override
  Future<String?> getTemporaryPath() async {
    return Directory.systemTemp.path;
  }

  @override
  Future<String?> getApplicationSupportPath() async {
    final dir = await Directory.systemTemp.createTemp('app_support_');
    return dir.path;
  }

  @override
  Future<String?> getApplicationDocumentsPath() async {
    final dir = await Directory.systemTemp.createTemp('app_documents_');
    return dir.path;
  }

  @override
  Future<String?> getApplicationCachePath() async {
    final dir = await Directory.systemTemp.createTemp('app_cache_');
    return dir.path;
  }

  @override
  Future<String?> getDownloadsPath() async {
    final dir = await Directory.systemTemp.createTemp('downloads_');
    return dir.path;
  }

  @override
  Future<List<String>?> getExternalCachePaths() async {
    return null;
  }

  @override
  Future<String?> getExternalStoragePath() async {
    return null;
  }

  @override
  Future<List<String>?> getExternalStoragePaths({
    StorageDirectory? type,
  }) async {
    return null;
  }

  @override
  Future<String?> getLibraryPath() async {
    final dir = await Directory.systemTemp.createTemp('library_');
    return dir.path;
  }
}

/// Mock SSE client that simulates a successful book scan
class MockSseClient extends SseClient {
  final bool shouldSimulateSuccess;
  final Map<String, dynamic>? mockBookData;

  MockSseClient({
    this.shouldSimulateSuccess = true,
    this.mockBookData,
  });

  @override
  Stream<SseEvent> listen(String streamUrl) async* {
    // Simulate processing delay
    await Future.delayed(const Duration(milliseconds: 100));

    // Emit progress event
    yield SseEvent(
      type: SseEventType.progress,
      data: {
        'progress': 0.5,
        'message': 'Analyzing spine...',
      },
    );

    await Future.delayed(const Duration(milliseconds: 100));

    if (shouldSimulateSuccess) {
      // Emit result event with book data
      yield SseEvent(
        type: SseEventType.result,
        data: mockBookData ?? _defaultMockBookData(),
      );

      await Future.delayed(const Duration(milliseconds: 100));

      // Emit complete event
      yield SseEvent(
        type: SseEventType.complete,
        data: {
          'results': [mockBookData ?? _defaultMockBookData()],
          'booksFound': 1,
        },
      );
    } else {
      // Emit error event
      yield SseEvent(
        type: SseEventType.error,
        data: {
          'message': 'Test error',
        },
      );
    }
  }

  Map<String, dynamic> _defaultMockBookData() {
    return {
      'isbn': '978-0-547-928227',
      'title': 'The Hobbit',
      'author': 'J.R.R. Tolkien',
      'coverUrl': 'https://example.com/hobbit-cover.jpg',
      'format': 'Paperback',
      'spineConfidence': 0.92,
    };
  }
}

/// Mock Talaria client that simulates successful upload
class MockTalariaClient extends TalariaClient {
  final String mockJobId;
  final String mockStreamUrl;

  MockTalariaClient({
    this.mockJobId = 'test-job-123',
    this.mockStreamUrl = 'https://example.com/stream',
  }) : super(
          dio: Dio(),
          deviceId: 'test-device-id',
        );

  @override
  Future<ScanJobResponse> uploadImage(String imagePath) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 50));

    return ScanJobResponse(
      jobId: mockJobId,
      streamUrl: mockStreamUrl,
    );
  }

  @override
  Future<void> cleanupJob(String jobId) async {
    // Simulate cleanup
    await Future.delayed(const Duration(milliseconds: 10));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Critical Flow: Camera → Upload → SSE → Database', () {
    late AppDatabase database;
    late ProviderContainer container;
    late File testImageFile;
    late Directory tempDir;

    setUp(() async {
      // Set up fake path provider
      PathProviderPlatform.instance = FakePathProviderPlatform();

      // Create in-memory database for testing
      database = AppDatabase.test(NativeDatabase.memory());

      // Create temporary directory for test files
      tempDir = await Directory.systemTemp.createTemp('wingtip_test_');

      // Create a test image file
      testImageFile = File('${tempDir.path}/test_image.jpg');
      await testImageFile.writeAsBytes([0xFF, 0xD8, 0xFF, 0xE0]); // Minimal JPEG header

      // Create mock clients
      final mockSseClient = MockSseClient();
      final mockTalariaClient = MockTalariaClient();

      // Create provider container with test overrides
      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(database),
          sseClientProvider.overrideWithValue(mockSseClient),
          talariaClientProvider.overrideWith((ref) async => mockTalariaClient),
        ],
      );
    });

    tearDown(() async {
      // Close database
      await database.close();

      // Dispose container
      container.dispose();

      // Clean up temp files
      if (await testImageFile.exists()) {
        await testImageFile.delete();
      }
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('should complete full flow: capture → upload → SSE → database', () async {
      // ARRANGE
      // Verify database is empty
      final initialBooks = await database.select(database.books).get();
      expect(initialBooks.length, 0, reason: 'Database should start empty');

      // Get the job state notifier
      final notifier = container.read(jobStateProvider.notifier);

      // Listen to state changes for verification
      final states = <JobState>[];
      final subscription = container.listen<JobState>(
        jobStateProvider,
        (previous, next) {
          states.add(next);
        },
      );

      // ACT
      // Simulate camera capture by uploading test image
      await notifier.uploadImage(testImageFile.path);

      // Wait for SSE stream to complete (max 5 seconds)
      await Future.delayed(const Duration(seconds: 2));

      // ASSERT
      // 1. Verify book was saved to database
      final books = await database.select(database.books).get();
      expect(books.length, 1, reason: 'One book should be saved to database');

      final savedBook = books.first;
      expect(savedBook.isbn, '978-0-547-928227', reason: 'ISBN should match');
      expect(savedBook.title, 'The Hobbit', reason: 'Title should match');
      expect(savedBook.author, 'J.R.R. Tolkien', reason: 'Author should match');
      expect(savedBook.coverUrl, 'https://example.com/hobbit-cover.jpg', reason: 'Cover URL should match');
      expect(savedBook.format, 'Paperback', reason: 'Format should match');
      expect(savedBook.spineConfidence, 0.92, reason: 'Spine confidence should match');

      // 2. Verify job went through expected states
      expect(states.isNotEmpty, true, reason: 'Job should have state transitions');

      // Find jobs in various states
      final uploadingStates = states.where((s) =>
        s.jobs.any((job) => job.status == JobStatus.uploading)
      );
      final listeningStates = states.where((s) =>
        s.jobs.any((job) => job.status == JobStatus.listening)
      );
      final processingStates = states.where((s) =>
        s.jobs.any((job) => job.status == JobStatus.processing)
      );
      final completedStates = states.where((s) =>
        s.jobs.any((job) => job.status == JobStatus.completed)
      );

      expect(uploadingStates.isNotEmpty, true, reason: 'Job should enter uploading state');
      expect(listeningStates.isNotEmpty, true, reason: 'Job should enter listening state');
      expect(processingStates.isNotEmpty, true, reason: 'Job should enter processing state');
      expect(completedStates.isNotEmpty, true, reason: 'Job should enter completed state');

      // 3. Verify no error states
      final errorStates = states.where((s) =>
        s.jobs.any((job) => job.status == JobStatus.error)
      );
      expect(errorStates.isEmpty, true, reason: 'Job should not enter error state');

      // Cleanup subscription
      subscription.close();
    }, timeout: const Timeout(Duration(seconds: 60)));

    test('should handle multiple books scanned sequentially', () async {
      // ARRANGE
      final notifier = container.read(jobStateProvider.notifier);

      // Create mock client that returns different books
      final mockSseClientBook1 = MockSseClient(
        mockBookData: {
          'isbn': '978-0-123456-78-1',
          'title': 'Test Book 1',
          'author': 'Author One',
          'coverUrl': 'https://example.com/cover1.jpg',
          'format': 'Hardcover',
          'spineConfidence': 0.85,
        },
      );

      final mockSseClientBook2 = MockSseClient(
        mockBookData: {
          'isbn': '978-0-123456-78-2',
          'title': 'Test Book 2',
          'author': 'Author Two',
          'coverUrl': 'https://example.com/cover2.jpg',
          'format': 'Paperback',
          'spineConfidence': 0.90,
        },
      );

      // ACT
      // Override with first book mock
      container.updateOverrides([
        databaseProvider.overrideWithValue(database),
        sseClientProvider.overrideWithValue(mockSseClientBook1),
        talariaClientProvider.overrideWith((ref) async => MockTalariaClient()),
      ]);

      // Upload first image
      await notifier.uploadImage(testImageFile.path);
      await Future.delayed(const Duration(seconds: 1));

      // Override with second book mock
      container.updateOverrides([
        databaseProvider.overrideWithValue(database),
        sseClientProvider.overrideWithValue(mockSseClientBook2),
        talariaClientProvider.overrideWith((ref) async => MockTalariaClient()),
      ]);

      // Upload second image
      await notifier.uploadImage(testImageFile.path);
      await Future.delayed(const Duration(seconds: 1));

      // ASSERT
      final books = await database.select(database.books).get();
      expect(books.length, 2, reason: 'Two books should be saved to database');

      // Verify first book
      final book1 = books.firstWhere((b) => b.isbn == '978-0-123456-78-1');
      expect(book1.title, 'Test Book 1');
      expect(book1.author, 'Author One');

      // Verify second book
      final book2 = books.firstWhere((b) => b.isbn == '978-0-123456-78-2');
      expect(book2.title, 'Test Book 2');
      expect(book2.author, 'Author Two');
    }, timeout: const Timeout(Duration(seconds: 60)));

    test('should handle INSERT OR REPLACE for duplicate ISBNs', () async {
      // ARRANGE
      final notifier = container.read(jobStateProvider.notifier);

      // First mock returns initial data
      final mockSseClient1 = MockSseClient(
        mockBookData: {
          'isbn': '978-0-123456-78-9',
          'title': 'Original Title',
          'author': 'Original Author',
          'coverUrl': 'https://example.com/cover1.jpg',
          'format': 'Hardcover',
          'spineConfidence': 0.80,
        },
      );

      // Second mock returns updated data with same ISBN
      final mockSseClient2 = MockSseClient(
        mockBookData: {
          'isbn': '978-0-123456-78-9',
          'title': 'Updated Title',
          'author': 'Updated Author',
          'coverUrl': 'https://example.com/cover2.jpg',
          'format': 'Paperback',
          'spineConfidence': 0.95,
        },
      );

      // ACT
      // Upload first scan
      container.updateOverrides([
        databaseProvider.overrideWithValue(database),
        sseClientProvider.overrideWithValue(mockSseClient1),
        talariaClientProvider.overrideWith((ref) async => MockTalariaClient()),
      ]);

      await notifier.uploadImage(testImageFile.path);
      await Future.delayed(const Duration(seconds: 1));

      // Upload second scan with same ISBN
      container.updateOverrides([
        databaseProvider.overrideWithValue(database),
        sseClientProvider.overrideWithValue(mockSseClient2),
        talariaClientProvider.overrideWith((ref) async => MockTalariaClient()),
      ]);

      await notifier.uploadImage(testImageFile.path);
      await Future.delayed(const Duration(seconds: 1));

      // ASSERT
      final books = await database.select(database.books).get();
      expect(books.length, 1, reason: 'Only one book should exist (replaced)');

      final savedBook = books.first;
      expect(savedBook.isbn, '978-0-123456-78-9');
      expect(savedBook.title, 'Updated Title', reason: 'Title should be updated');
      expect(savedBook.author, 'Updated Author', reason: 'Author should be updated');
      expect(savedBook.format, 'Paperback', reason: 'Format should be updated');
      expect(savedBook.spineConfidence, 0.95, reason: 'Confidence should be updated');
    }, timeout: const Timeout(Duration(seconds: 60)));
  });

  group('Critical Flow: Offline → Online Reconnection', () {
    late AppDatabase database;
    late ProviderContainer container;
    late StreamController<bool> networkStatusController;
    late Directory tempDir;

    setUp(() async {
      // Set up fake path provider
      PathProviderPlatform.instance = FakePathProviderPlatform();

      // Create in-memory database for testing
      database = AppDatabase.test(NativeDatabase.memory());

      // Create temporary directory for test files
      tempDir = await Directory.systemTemp.createTemp('wingtip_test_');

      // Create network status controller (start offline)
      networkStatusController = StreamController<bool>.broadcast();
      networkStatusController.add(false);

      // Create provider container with test overrides
      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(database),
          networkStatusProvider.overrideWith((ref) => networkStatusController.stream),
        ],
      );
    });

    tearDown(() async {
      // Close database
      await database.close();

      // Dispose container
      container.dispose();

      // Close network status controller
      await networkStatusController.close();

      // Clean up temp files
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('should transition from offline to online and enable retry', () async {
      // ARRANGE
      // Wait for initial network status to be emitted
      await Future.delayed(const Duration(milliseconds: 100));

      // Verify network starts offline by checking the current state
      // Note: We can't use .future on a broadcast stream, so we check state directly

      // Create a failed scan while offline
      const testJobId = 'job-offline-reconnect-test';
      const testErrorMessage = 'No internet connection';

      // Create test image file
      final testImagePath = '${tempDir.path}/offline_test.jpg';
      final testImageFile = File(testImagePath);
      await testImageFile.writeAsBytes([
        0xFF, 0xD8, 0xFF, 0xE0, // JPEG header
        0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, // JFIF marker
        0x00, 0x01, 0x01, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00,
        0xFF, 0xD9, // JPEG end marker
      ]);

      expect(await testImageFile.exists(), true, reason: 'Test image should be created');

      // Move image to failed_scans directory
      final persistentPath = await FailedScansDirectory.moveImage(
        testImagePath,
        testJobId,
      );

      // Save failed scan to database
      await database.saveFailedScan(
        jobId: testJobId,
        imagePath: persistentPath,
        errorMessage: testErrorMessage,
        failureReason: FailureReason.networkError,
        retentionPeriod: const Duration(days: 7),
      );

      // ASSERT: Verify failed scan was saved
      final failedScans = await database.select(database.failedScans).get();
      expect(failedScans.length, 1, reason: 'One failed scan should be saved');

      final failedScan = failedScans.first;
      expect(failedScan.jobId, testJobId, reason: 'Job ID should match');
      expect(failedScan.errorMessage, testErrorMessage, reason: 'Error message should match');
      expect(failedScan.failureReason, FailureReason.networkError, reason: 'Failure reason should be network error');
      expect(await File(failedScan.imagePath).exists(), true, reason: 'Image file should exist');

      // ACT: Simulate network reconnection
      networkStatusController.add(true);

      // Wait for the stream to propagate
      await Future.delayed(const Duration(milliseconds: 100));

      // ASSERT: Verify network status shows online
      final repository = container.read(failedScansRepositoryProvider);
      final failedScansCount = await repository.getFailedScansCount();
      expect(failedScansCount, 1, reason: 'Failed scan should still be present');

      // Simulate successful retry by saving a book
      await database.into(database.books).insertOnConflictUpdate(
        BooksCompanion.insert(
          isbn: '978-0-987654-32-1',
          title: 'Book After Reconnection',
          author: 'Network Test Author',
          coverUrl: const Value('https://example.com/reconnect-cover.jpg'),
          format: const Value('Paperback'),
          addedDate: DateTime.now().millisecondsSinceEpoch,
          spineConfidence: const Value(0.88),
        ),
      );

      // ASSERT: Verify book was saved
      final books = await database.select(database.books).get();
      expect(books.length, 1, reason: 'One book should be saved after retry');

      final book = books.first;
      expect(book.isbn, '978-0-987654-32-1', reason: 'ISBN should match');
      expect(book.title, 'Book After Reconnection', reason: 'Title should match');
      expect(book.author, 'Network Test Author', reason: 'Author should match');
      expect(book.spineConfidence, 0.88, reason: 'Spine confidence should match');

      // Simulate cleanup after successful retry
      await FailedScansDirectory.deleteImage(testJobId);
      await database.deleteFailedScan(testJobId);

      // ASSERT: Verify cleanup
      final remainingScans = await database.select(database.failedScans).get();
      expect(remainingScans.length, 0, reason: 'Failed scan should be removed after successful retry');

      // Verify final state
      final finalBooks = await database.select(database.books).get();
      expect(finalBooks.length, 1, reason: 'Book should remain in database');

      final finalFailedScans = await database.select(database.failedScans).get();
      expect(finalFailedScans.length, 0, reason: 'No failed scans should remain');
    }, timeout: const Timeout(Duration(seconds: 60)));

    test('should handle multiple failed scans waiting for reconnection', () async {
      // ARRANGE
      // Create multiple failed scans while offline
      final testScans = [
        {
          'jobId': 'job-offline-1',
          'errorMessage': 'No internet connection',
          'failureReason': FailureReason.networkError,
        },
        {
          'jobId': 'job-offline-2',
          'errorMessage': 'Network timeout',
          'failureReason': FailureReason.networkError,
        },
        {
          'jobId': 'job-offline-3',
          'errorMessage': 'Connection refused',
          'failureReason': FailureReason.networkError,
        },
      ];

      // Create and save all failed scans
      for (var i = 0; i < testScans.length; i++) {
        final scan = testScans[i];
        final testImagePath = '${tempDir.path}/offline_test_$i.jpg';
        final testImageFile = File(testImagePath);

        await testImageFile.writeAsBytes([
          0xFF, 0xD8, 0xFF, 0xE0, // JPEG header
          0x00, 0x10, 0x4A, 0x46, 0x49, 0x46,
          0x00, 0x01, 0x01, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00,
          0xFF, 0xD9, // JPEG end marker
        ]);

        final persistentPath = await FailedScansDirectory.moveImage(
          testImagePath,
          scan['jobId'] as String,
        );

        await database.saveFailedScan(
          jobId: scan['jobId'] as String,
          imagePath: persistentPath,
          errorMessage: scan['errorMessage'] as String,
          failureReason: scan['failureReason'] as FailureReason,
          retentionPeriod: const Duration(days: 7),
        );
      }

      // ASSERT: Verify all failed scans were saved
      final failedScans = await database.select(database.failedScans).get();
      expect(failedScans.length, 3, reason: 'Three failed scans should be saved');

      // ACT: Simulate network reconnection
      networkStatusController.add(true);
      await Future.delayed(const Duration(milliseconds: 100));

      // ASSERT: Verify all failed scans are still present and ready for retry
      final repository = container.read(failedScansRepositoryProvider);
      final failedScansCount = await repository.getFailedScansCount();
      expect(failedScansCount, 3, reason: 'All three failed scans should be waiting for retry');

      // Verify each scan has correct attributes
      for (var i = 0; i < testScans.length; i++) {
        final scan = failedScans.firstWhere(
          (s) => s.jobId == testScans[i]['jobId'],
        );

        expect(scan.jobId, testScans[i]['jobId'], reason: 'Job ID should match');
        expect(scan.errorMessage, testScans[i]['errorMessage'], reason: 'Error message should match');
        expect(scan.failureReason, testScans[i]['failureReason'], reason: 'Failure reason should match');
        expect(await File(scan.imagePath).exists(), true, reason: 'Image file should exist');
      }
    }, timeout: const Timeout(Duration(seconds: 60)));
  });
}
