import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:wingtip/core/sse_client.dart';
import 'package:wingtip/core/sse_client_provider.dart';
import 'package:wingtip/core/talaria_client.dart';
import 'package:wingtip/core/talaria_client_provider.dart';
import 'package:wingtip/data/database.dart';
import 'package:wingtip/data/database_provider.dart';
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
}
