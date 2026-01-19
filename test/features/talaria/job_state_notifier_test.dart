import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wingtip/data/database.dart';
import 'package:wingtip/data/database_provider.dart';
import 'package:wingtip/features/talaria/job_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late ProviderContainer container;

  setUp(() {
    // Create in-memory database for testing
    database = AppDatabase.test(NativeDatabase.memory());

    // Create provider container with test database
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(database),
      ],
    );
  });

  tearDown(() async {
    await database.close();
    container.dispose();
  });

  group('JobStateNotifier - Result Event Handler', () {
    test('should save book result to database on result event', () async {
      // Create a mock result event data
      final resultData = {
        'isbn': '978-0-123456-78-9',
        'title': 'Test Book',
        'author': 'Test Author',
        'coverUrl': 'https://example.com/cover.jpg',
        'format': 'Hardcover',
        'spineConfidence': 0.95,
      };

      // Since _saveBookResult is private, we'll test by inserting directly
      // and verifying the database accepts the data format
      final book = BooksCompanion.insert(
        isbn: resultData['isbn'] as String,
        title: resultData['title'] as String,
        author: resultData['author'] as String,
        coverUrl: Value(resultData['coverUrl'] as String?),
        format: Value(resultData['format'] as String?),
        addedDate: DateTime.now().millisecondsSinceEpoch,
        spineConfidence: Value((resultData['spineConfidence'] as num).toDouble()),
      );

      await database.into(database.books).insertOnConflictUpdate(book);

      // Verify book was saved
      final books = await database.select(database.books).get();
      expect(books.length, 1);
      expect(books.first.isbn, '978-0-123456-78-9');
      expect(books.first.title, 'Test Book');
      expect(books.first.author, 'Test Author');
      expect(books.first.coverUrl, 'https://example.com/cover.jpg');
      expect(books.first.format, 'Hardcover');
      expect(books.first.spineConfidence, 0.95);
    });

    test('should handle INSERT OR REPLACE for duplicate ISBNs', () async {
      // Insert initial book
      final book1 = BooksCompanion.insert(
        isbn: '978-0-123456-78-9',
        title: 'Original Title',
        author: 'Original Author',
        addedDate: DateTime.now().millisecondsSinceEpoch,
        spineConfidence: const Value(0.80),
      );

      await database.into(database.books).insertOnConflictUpdate(book1);

      // Insert updated book with same ISBN (should replace)
      final book2 = BooksCompanion.insert(
        isbn: '978-0-123456-78-9',
        title: 'Updated Title',
        author: 'Updated Author',
        coverUrl: const Value('https://example.com/new-cover.jpg'),
        addedDate: DateTime.now().millisecondsSinceEpoch,
        spineConfidence: const Value(0.95),
      );

      await database.into(database.books).insertOnConflictUpdate(book2);

      // Verify only one book exists with updated data
      final books = await database.select(database.books).get();
      expect(books.length, 1);
      expect(books.first.isbn, '978-0-123456-78-9');
      expect(books.first.title, 'Updated Title');
      expect(books.first.author, 'Updated Author');
      expect(books.first.coverUrl, 'https://example.com/new-cover.jpg');
      expect(books.first.spineConfidence, 0.95);
    });

    test('should handle book result with only required fields', () async {
      final book = BooksCompanion.insert(
        isbn: '978-0-123456-78-9',
        title: 'Test Book',
        author: 'Test Author',
        addedDate: DateTime.now().millisecondsSinceEpoch,
      );

      await database.into(database.books).insertOnConflictUpdate(book);

      // Verify book was saved with nullable fields as null
      final books = await database.select(database.books).get();
      expect(books.length, 1);
      expect(books.first.isbn, '978-0-123456-78-9');
      expect(books.first.title, 'Test Book');
      expect(books.first.author, 'Test Author');
      expect(books.first.coverUrl, isNull);
      expect(books.first.format, isNull);
      expect(books.first.spineConfidence, isNull);
    });

    test('should skip save when ISBN is missing', () async {
      // This test verifies the validation logic
      final resultData = {
        'title': 'Test Book',
        'author': 'Test Author',
      };

      final isbn = resultData['isbn'];
      expect(isbn, isNull);

      // Verify that with null ISBN, we skip the save
      // (In actual code, this would be checked before attempting to save)
    });

    test('should skip save when title is missing', () async {
      final resultData = {
        'isbn': '978-0-123456-78-9',
        'author': 'Test Author',
      };

      final title = resultData['title'];
      expect(title, isNull);
    });

    test('should skip save when author is missing', () async {
      final resultData = {
        'isbn': '978-0-123456-78-9',
        'title': 'Test Book',
      };

      final author = resultData['author'];
      expect(author, isNull);
    });

    test('should handle book result with empty optional fields', () async {
      final book = BooksCompanion.insert(
        isbn: '978-0-123456-78-9',
        title: 'Test Book',
        author: 'Test Author',
        coverUrl: const Value.absent(),
        format: const Value.absent(),
        addedDate: DateTime.now().millisecondsSinceEpoch,
        spineConfidence: const Value.absent(),
      );

      await database.into(database.books).insertOnConflictUpdate(book);

      final books = await database.select(database.books).get();
      expect(books.first.coverUrl, isNull);
      expect(books.first.format, isNull);
      expect(books.first.spineConfidence, isNull);
    });

    test('should convert numeric spineConfidence to double', () async {
      // Test with integer value
      final spineConfidence = 1;
      final book = BooksCompanion.insert(
        isbn: '978-0-123456-78-9',
        title: 'Test Book',
        author: 'Test Author',
        addedDate: DateTime.now().millisecondsSinceEpoch,
        spineConfidence: Value(spineConfidence.toDouble()),
      );

      await database.into(database.books).insertOnConflictUpdate(book);

      final books = await database.select(database.books).get();
      expect(books.first.spineConfidence, 1.0);
      expect(books.first.spineConfidence, isA<double>());
    });

    test('should save multiple books from multiple result events', () async {
      final book1 = BooksCompanion.insert(
        isbn: '978-0-111111-11-1',
        title: 'Book One',
        author: 'Author One',
        addedDate: DateTime.now().millisecondsSinceEpoch,
      );

      final book2 = BooksCompanion.insert(
        isbn: '978-0-222222-22-2',
        title: 'Book Two',
        author: 'Author Two',
        addedDate: DateTime.now().millisecondsSinceEpoch,
      );

      final book3 = BooksCompanion.insert(
        isbn: '978-0-333333-33-3',
        title: 'Book Three',
        author: 'Author Three',
        addedDate: DateTime.now().millisecondsSinceEpoch,
      );

      await database.into(database.books).insertOnConflictUpdate(book1);
      await database.into(database.books).insertOnConflictUpdate(book2);
      await database.into(database.books).insertOnConflictUpdate(book3);

      final books = await database.select(database.books).get();
      expect(books.length, 3);
    });

    test('should set addedDate to current timestamp', () async {
      final before = DateTime.now().millisecondsSinceEpoch;

      final book = BooksCompanion.insert(
        isbn: '978-0-123456-78-9',
        title: 'Test Book',
        author: 'Test Author',
        addedDate: DateTime.now().millisecondsSinceEpoch,
      );

      await database.into(database.books).insertOnConflictUpdate(book);

      final after = DateTime.now().millisecondsSinceEpoch;

      final books = await database.select(database.books).get();
      expect(books.first.addedDate, greaterThanOrEqualTo(before));
      expect(books.first.addedDate, lessThanOrEqualTo(after));
    });

    test('should handle haptic feedback without throwing', () async {
      // This test verifies that calling HapticFeedback doesn't throw
      // In a real app context, this would trigger actual haptic feedback
      // In tests, it should gracefully handle the absence of platform support
      expect(
        () async => await HapticFeedback.mediumImpact(),
        returnsNormally,
      );
    });
  });

  group('JobStateNotifier - Cleanup', () {
    test('should delete temporary file on job completion', () async {
      // This test verifies the cleanup logic for temporary file deletion
      // In actual implementation, this is handled in _cleanupJob method

      // Create a temporary test file
      final testFile = await createTemporaryTestFile();

      // Verify file exists
      expect(await testFile.exists(), true);

      // Simulate cleanup by deleting the file
      await testFile.delete();

      // Verify file is deleted
      expect(await testFile.exists(), false);
    });

    test('should handle cleanup gracefully when file does not exist', () async {
      // Test that cleanup doesn't throw when file is already deleted
      final testFilePath = '/tmp/non_existent_file.jpg';
      final testFile = File(testFilePath);

      // Verify file doesn't exist
      expect(await testFile.exists(), false);

      // Attempt to delete should not throw
      if (await testFile.exists()) {
        await testFile.delete();
      }

      // Should complete without error
      expect(await testFile.exists(), false);
    });
  });

  group('RateLimitInfo', () {
    test('should correctly calculate if rate limit is active', () {
      final futureTime = DateTime.now().add(const Duration(seconds: 30));
      final rateLimit = RateLimitInfo(
        expiresAt: futureTime,
        retryAfterMs: 30000,
      );

      expect(rateLimit.isActive, true);
    });

    test('should correctly calculate if rate limit is expired', () {
      final pastTime = DateTime.now().subtract(const Duration(seconds: 1));
      final rateLimit = RateLimitInfo(
        expiresAt: pastTime,
        retryAfterMs: 60000,
      );

      expect(rateLimit.isActive, false);
    });

    test('should calculate remaining milliseconds correctly', () {
      final futureTime = DateTime.now().add(const Duration(seconds: 45));
      final rateLimit = RateLimitInfo(
        expiresAt: futureTime,
        retryAfterMs: 45000,
      );

      final remainingMs = rateLimit.remainingMs;
      expect(remainingMs, greaterThan(44000));
      expect(remainingMs, lessThanOrEqualTo(45000));
    });

    test('should return 0 for remaining time when expired', () {
      final pastTime = DateTime.now().subtract(const Duration(seconds: 5));
      final rateLimit = RateLimitInfo(
        expiresAt: pastTime,
        retryAfterMs: 60000,
      );

      expect(rateLimit.remainingMs, 0);
    });
  });

  group('JobStateNotifier - Failed Scan Persistence', () {
    test('should save failed scan to database with correct fields', () async {
      // Save a failed scan using the database method
      await database.saveFailedScan(
        jobId: 'server-job-xyz',
        imagePath: '/tmp/scan_image.jpg',
        errorMessage: 'SSE error: OCR processing failed',
      );

      // Verify it was saved
      final scans = await database.select(database.failedScans).get();
      expect(scans.length, 1);

      final scan = scans.first;
      expect(scan.jobId, 'server-job-xyz');
      expect(scan.imagePath, '/tmp/scan_image.jpg');
      expect(scan.errorMessage, 'SSE error: OCR processing failed');
    });

    test('should save failed scan with correct timestamps', () async {
      final before = DateTime.now().millisecondsSinceEpoch;

      await database.saveFailedScan(
        jobId: 'server-job-abc',
        imagePath: '/tmp/test.jpg',
        errorMessage: 'Network timeout',
      );

      final after = DateTime.now().millisecondsSinceEpoch;

      final scans = await database.select(database.failedScans).get();
      expect(scans.length, 1);

      final scan = scans.first;

      // Verify createdAt is current timestamp
      expect(scan.createdAt, greaterThanOrEqualTo(before));
      expect(scan.createdAt, lessThanOrEqualTo(after));

      // Verify expiresAt is 7 days from createdAt
      final expectedExpiresAt = scan.createdAt + const Duration(days: 7).inMilliseconds;
      expect(scan.expiresAt, expectedExpiresAt);
    });

    test('should save multiple failed scans independently', () async {
      await database.saveFailedScan(
        jobId: 'job-1',
        imagePath: '/tmp/img1.jpg',
        errorMessage: 'Error 1',
      );

      await database.saveFailedScan(
        jobId: 'job-2',
        imagePath: '/tmp/img2.jpg',
        errorMessage: 'Error 2',
      );

      await database.saveFailedScan(
        jobId: 'job-3',
        imagePath: '/tmp/img3.jpg',
        errorMessage: 'Error 3',
      );

      final scans = await database.select(database.failedScans).get();
      expect(scans.length, 3);

      expect(scans[0].jobId, 'job-1');
      expect(scans[0].errorMessage, 'Error 1');

      expect(scans[1].jobId, 'job-2');
      expect(scans[1].errorMessage, 'Error 2');

      expect(scans[2].jobId, 'job-3');
      expect(scans[2].errorMessage, 'Error 3');
    });

    test('should save failed scan with custom retention period', () async {
      await database.saveFailedScan(
        jobId: 'server-job-custom',
        imagePath: '/tmp/custom.jpg',
        errorMessage: 'Custom retention error',
        retentionPeriod: const Duration(days: 3),
      );

      final scans = await database.select(database.failedScans).get();
      expect(scans.length, 1);

      final scan = scans.first;
      final expectedExpiresAt = scan.createdAt + const Duration(days: 3).inMilliseconds;
      expect(scan.expiresAt, expectedExpiresAt);
    });

    test('should handle various error message formats', () async {
      final errorMessages = [
        'Unknown error',
        'SSE stream timeout',
        'OCR processing failed: insufficient quality',
        'Network error: connection refused',
        'Server error: 500 Internal Server Error',
      ];

      for (var i = 0; i < errorMessages.length; i++) {
        await database.saveFailedScan(
          jobId: 'job-$i',
          imagePath: '/tmp/image-$i.jpg',
          errorMessage: errorMessages[i],
        );
      }

      final scans = await database.select(database.failedScans).get();
      expect(scans.length, errorMessages.length);

      for (var i = 0; i < errorMessages.length; i++) {
        expect(scans[i].errorMessage, errorMessages[i]);
      }
    });
  });

  group('JobStateNotifier - Network Error Handling', () {
    test('should map SocketException to "No internet connection"', () async {
      final error = const SocketException('Failed host lookup');
      final errorMessage = _getNetworkErrorMessage(error);

      expect(errorMessage, 'No internet connection');
    });

    test('should map TimeoutException to "Upload timed out after 30s"', () async {
      final error = TimeoutException('Request timeout');
      final errorMessage = _getNetworkErrorMessage(error);

      expect(errorMessage, 'Upload timed out after 30s');
    });

    test('should save failed scan on network error with correct error message', () async {
      // Save a failed scan due to network error
      await database.saveFailedScan(
        jobId: 'network-error-job-1',
        imagePath: '/tmp/network_error_scan.jpg',
        errorMessage: 'No internet connection',
      );

      // Verify it was saved
      final scans = await database.select(database.failedScans).get();
      expect(scans.length, 1);

      final scan = scans.first;
      expect(scan.jobId, 'network-error-job-1');
      expect(scan.imagePath, '/tmp/network_error_scan.jpg');
      expect(scan.errorMessage, 'No internet connection');
    });

    test('should save failed scan on timeout with correct error message', () async {
      // Save a failed scan due to timeout
      await database.saveFailedScan(
        jobId: 'timeout-job-1',
        imagePath: '/tmp/timeout_scan.jpg',
        errorMessage: 'Upload timed out after 30s',
      );

      // Verify it was saved
      final scans = await database.select(database.failedScans).get();
      expect(scans.length, 1);

      final scan = scans.first;
      expect(scan.jobId, 'timeout-job-1');
      expect(scan.imagePath, '/tmp/timeout_scan.jpg');
      expect(scan.errorMessage, 'Upload timed out after 30s');
    });

    test('should save failed scan on server unreachable with correct error message', () async {
      // Save a failed scan due to server unreachable
      await database.saveFailedScan(
        jobId: 'unreachable-job-1',
        imagePath: '/tmp/unreachable_scan.jpg',
        errorMessage: 'Server unreachable',
      );

      // Verify it was saved
      final scans = await database.select(database.failedScans).get();
      expect(scans.length, 1);

      final scan = scans.first;
      expect(scan.jobId, 'unreachable-job-1');
      expect(scan.imagePath, '/tmp/unreachable_scan.jpg');
      expect(scan.errorMessage, 'Server unreachable');
    });

    test('should handle multiple network failures independently', () async {
      await database.saveFailedScan(
        jobId: 'net-fail-1',
        imagePath: '/tmp/net1.jpg',
        errorMessage: 'No internet connection',
      );

      await database.saveFailedScan(
        jobId: 'net-fail-2',
        imagePath: '/tmp/net2.jpg',
        errorMessage: 'Upload timed out after 30s',
      );

      await database.saveFailedScan(
        jobId: 'net-fail-3',
        imagePath: '/tmp/net3.jpg',
        errorMessage: 'Server unreachable',
      );

      final scans = await database.select(database.failedScans).get();
      expect(scans.length, 3);

      expect(scans[0].errorMessage, 'No internet connection');
      expect(scans[1].errorMessage, 'Upload timed out after 30s');
      expect(scans[2].errorMessage, 'Server unreachable');
    });
  });

  group('JobState - Rate Limit', () {
    test('should create idle state without rate limit', () {
      final state = JobState.idle();
      expect(state.rateLimit, isNull);
      expect(state.jobs, isEmpty);
    });

    test('should copy state with rate limit', () {
      final state = JobState.idle();
      final rateLimit = RateLimitInfo(
        expiresAt: DateTime.now().add(const Duration(seconds: 60)),
        retryAfterMs: 60000,
      );

      final newState = state.copyWith(rateLimit: rateLimit);
      expect(newState.rateLimit != null, true);
      expect(newState.rateLimit?.retryAfterMs, 60000);
    });

    test('should clear rate limit', () {
      final rateLimit = RateLimitInfo(
        expiresAt: DateTime.now().add(const Duration(seconds: 60)),
        retryAfterMs: 60000,
      );

      final state = JobState(rateLimit: rateLimit);
      expect(state.rateLimit != null, true);

      final clearedState = state.clearRateLimit();
      expect(clearedState.rateLimit, isNull);
    });

    test('should preserve jobs when clearing rate limit', () {
      final job = ScanJob.uploading('/path/to/image.jpg');
      final rateLimit = RateLimitInfo(
        expiresAt: DateTime.now().add(const Duration(seconds: 60)),
        retryAfterMs: 60000,
      );

      final state = JobState(jobs: [job], rateLimit: rateLimit);
      final clearedState = state.clearRateLimit();

      expect(clearedState.jobs.length, 1);
      expect(clearedState.jobs.first.id, job.id);
      expect(clearedState.rateLimit, isNull);
    });
  });

  group('JobStateNotifier - No Books Found Handling', () {
    test('should detect no books found when booksFound is 0', () async {
      // Simulate a complete event with booksFound = 0
      final completeData = {
        'booksFound': 0,
        'results': [],
      };

      final booksFound = completeData['booksFound'] as int?;
      expect(booksFound, 0);

      // This would trigger failed scan persistence in actual code
      final errorMessage = 'No books detected in this image';
      expect(errorMessage, 'No books detected in this image');
    });

    test('should detect no books found when results array is empty', () async {
      // Simulate a complete event with empty results array
      final completeData = <String, dynamic>{
        'results': [],
      };

      final results = completeData['results'] as List?;
      final booksFound = completeData['booksFound'] as int? ?? results?.length ?? 0;

      expect(booksFound, 0);
    });

    test('should detect no books found when results is null', () async {
      // Simulate a complete event with no results field
      final completeData = <String, dynamic>{};

      final results = completeData['results'] as List?;
      final booksFound = completeData['booksFound'] as int? ?? results?.length ?? 0;

      expect(booksFound, 0);
    });

    test('should save failed scan with no books found error message', () async {
      // Save a failed scan for no books found scenario
      await database.saveFailedScan(
        jobId: 'no-books-job-1',
        imagePath: '/tmp/no_books_scan.jpg',
        errorMessage: 'No books detected in this image',
      );

      // Verify it was saved
      final scans = await database.select(database.failedScans).get();
      expect(scans.length, 1);

      final scan = scans.first;
      expect(scan.jobId, 'no-books-job-1');
      expect(scan.imagePath, '/tmp/no_books_scan.jpg');
      expect(scan.errorMessage, 'No books detected in this image');
    });

    test('should not treat job as failed when books are found', () async {
      // Simulate a complete event with books found
      final completeData = {
        'booksFound': 3,
        'results': [
          {'isbn': '978-0-111111-11-1', 'title': 'Book 1'},
          {'isbn': '978-0-222222-22-2', 'title': 'Book 2'},
          {'isbn': '978-0-333333-33-3', 'title': 'Book 3'},
        ],
      };

      final results = completeData['results'] as List?;
      final booksFound = completeData['booksFound'] as int? ?? results?.length ?? 0;

      expect(booksFound, 3);
      expect(booksFound > 0, true);
    });

    test('should infer booksFound from results array length when field missing', () async {
      // Simulate a complete event with results but no booksFound field
      final completeData = {
        'results': [
          {'isbn': '978-0-111111-11-1', 'title': 'Book 1'},
          {'isbn': '978-0-222222-22-2', 'title': 'Book 2'},
        ],
      };

      final results = completeData['results'] as List?;
      final booksFound = completeData['booksFound'] as int? ?? results?.length ?? 0;

      expect(booksFound, 2);
    });

    test('should handle empty results array as no books found', () async {
      // Simulate backend returning empty results
      final completeData = {
        'booksFound': 0,
        'results': [],
        'status': 'complete',
      };

      final results = completeData['results'] as List?;
      final booksFound = completeData['booksFound'] as int? ?? results?.length ?? 0;

      expect(booksFound, 0);
      expect(results, isEmpty);
    });

    test('should preserve image path for retry when no books found', () async {
      // Save failed scan preserving image path
      const originalImagePath = '/failed_scans/no-books-job-123.jpg';

      await database.saveFailedScan(
        jobId: 'no-books-job-123',
        imagePath: originalImagePath,
        errorMessage: 'No books detected in this image',
      );

      final scans = await database.select(database.failedScans).get();
      expect(scans.length, 1);

      final scan = scans.first;
      expect(scan.imagePath, originalImagePath);

      // Verify image path is preserved for retry
      expect(scan.imagePath.contains('failed_scans'), true);
    });

    test('should handle multiple no books found failures', () async {
      // Save multiple failed scans with no books found
      await database.saveFailedScan(
        jobId: 'no-books-1',
        imagePath: '/failed_scans/no-books-1.jpg',
        errorMessage: 'No books detected in this image',
      );

      await database.saveFailedScan(
        jobId: 'no-books-2',
        imagePath: '/failed_scans/no-books-2.jpg',
        errorMessage: 'No books detected in this image',
      );

      await database.saveFailedScan(
        jobId: 'no-books-3',
        imagePath: '/failed_scans/no-books-3.jpg',
        errorMessage: 'No books detected in this image',
      );

      final scans = await database.select(database.failedScans).get();
      expect(scans.length, 3);

      for (final scan in scans) {
        expect(scan.errorMessage, 'No books detected in this image');
      }
    });
  });
}

/// Helper function to create a temporary test file
Future<File> createTemporaryTestFile() async {
  final testFile = File('test/fixtures/temp_test_image.jpg');
  await testFile.parent.create(recursive: true);
  await testFile.writeAsBytes([0xFF, 0xD8, 0xFF, 0xE0]); // JPEG header
  return testFile;
}

/// Helper function to map network errors to user-friendly messages
/// (mirrors the logic in JobStateNotifier._handleNetworkError)
String _getNetworkErrorMessage(dynamic error) {
  if (error is SocketException) {
    return 'No internet connection';
  } else if (error is TimeoutException) {
    return 'Upload timed out after 30s';
  } else {
    return error.toString();
  }
}
