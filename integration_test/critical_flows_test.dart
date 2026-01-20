import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wingtip/data/database.dart';
import 'package:wingtip/data/database_provider.dart';
import 'package:wingtip/core/failed_scans_directory.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Critical Flows - Failed Scan Retry', () {
    late AppDatabase database;
    late ProviderContainer container;
    late Directory testFailedScansDir;

    setUp(() async {
      // Create in-memory database for testing
      database = AppDatabase.test(NativeDatabase.memory());

      // Create a temporary directory for failed scan images
      final tempDir = await getTemporaryDirectory();
      testFailedScansDir = Directory(p.join(tempDir.path, 'test_failed_scans'));
      await testFailedScansDir.create(recursive: true);

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

      // Clean up test directory
      if (await testFailedScansDir.exists()) {
        await testFailedScansDir.delete(recursive: true);
      }
    });

    testWidgets(
      'Failed scan → retry → success flow',
      (WidgetTester tester) async {
        // STEP 1: Simulate network failure during upload
        // Create a test image file
        final testImagePath = p.join(testFailedScansDir.path, 'test_scan.jpg');
        final testImageFile = File(testImagePath);

        // Write minimal JPEG data (valid JPEG header)
        await testImageFile.writeAsBytes([
          0xFF, 0xD8, 0xFF, 0xE0, // JPEG header
          0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, // JFIF marker
          0x00, 0x01, 0x01, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00,
          0xFF, 0xD9, // JPEG end marker
        ]);

        expect(await testImageFile.exists(), true);
        debugPrint('[Test] Created test image: $testImagePath');

        // STEP 2: Save failed scan to database (simulating network failure)
        const testJobId = 'test-job-network-failure-123';
        const testErrorMessage = 'No internet connection';

        // Move image to failed_scans directory to simulate the failure handling
        final persistentPath = await FailedScansDirectory.moveImage(
          testImagePath,
          testJobId,
        );
        debugPrint('[Test] Moved image to persistent storage: $persistentPath');

        // Verify image was moved successfully
        final persistentFile = File(persistentPath);
        expect(await persistentFile.exists(), true);

        // Save failed scan to database
        await database.saveFailedScan(
          jobId: testJobId,
          imagePath: persistentPath,
          errorMessage: testErrorMessage,
          failureReason: FailureReason.networkError,
          retentionPeriod: const Duration(days: 7),
        );

        // STEP 3: Verify failed scan was saved with correct fields
        final failedScans = await database.select(database.failedScans).get();
        expect(failedScans.length, 1);

        final failedScan = failedScans.first;
        expect(failedScan.jobId, testJobId);
        expect(failedScan.imagePath, persistentPath);
        expect(failedScan.errorMessage, testErrorMessage);
        expect(failedScan.failureReason, FailureReason.networkError);

        // STEP 4: Verify error state assertions (createdAt, expiresAt populated)
        expect(failedScan.createdAt, greaterThan(0));
        expect(failedScan.expiresAt, greaterThan(failedScan.createdAt));

        // Verify expiresAt is approximately 7 days from createdAt
        final expectedExpiresAt = failedScan.createdAt + const Duration(days: 7).inMilliseconds;
        expect(failedScan.expiresAt, expectedExpiresAt);

        debugPrint('[Test] Failed scan saved correctly:');
        debugPrint('  - Job ID: ${failedScan.jobId}');
        debugPrint('  - Image Path: ${failedScan.imagePath}');
        debugPrint('  - Error Message: ${failedScan.errorMessage}');
        debugPrint('  - Failure Reason: ${failedScan.failureReason}');
        debugPrint('  - Created At: ${failedScan.createdAt}');
        debugPrint('  - Expires At: ${failedScan.expiresAt}');

        // STEP 5: Verify image file is preserved
        expect(await persistentFile.exists(), true);
        final imageSize = await persistentFile.length();
        expect(imageSize, greaterThan(0));
        debugPrint('[Test] Image file preserved: $imageSize bytes');

        // STEP 6: Simulate successful retry
        // Mock successful upload by saving a book result directly
        final mockBook = BooksCompanion.insert(
          isbn: '978-0-123456-78-9',
          title: 'Test Book from Retry',
          author: 'Test Author',
          coverUrl: const Value('https://example.com/cover.jpg'),
          format: const Value('Hardcover'),
          addedDate: DateTime.now().millisecondsSinceEpoch,
          spineConfidence: const Value(0.95),
        );

        await database.into(database.books).insertOnConflictUpdate(mockBook);
        debugPrint('[Test] Simulated successful book save after retry');

        // STEP 7: Verify book was saved
        final books = await database.select(database.books).get();
        expect(books.length, 1);

        final book = books.first;
        expect(book.isbn, '978-0-123456-78-9');
        expect(book.title, 'Test Book from Retry');
        expect(book.author, 'Test Author');
        expect(book.coverUrl, 'https://example.com/cover.jpg');
        expect(book.format, 'Hardcover');
        expect(book.spineConfidence, 0.95);

        debugPrint('[Test] Book saved successfully:');
        debugPrint('  - ISBN: ${book.isbn}');
        debugPrint('  - Title: ${book.title}');
        debugPrint('  - Author: ${book.author}');

        // STEP 8: Simulate cleanup after successful retry
        // Delete the failed scan image
        await FailedScansDirectory.deleteImage(testJobId);

        // Delete the failed scan database entry
        await database.deleteFailedScan(testJobId);

        // STEP 9: Verify failed scan was removed
        final remainingFailedScans = await database.select(database.failedScans).get();
        expect(remainingFailedScans.length, 0);
        debugPrint('[Test] Failed scan removed from database');

        // STEP 10: Verify image file was cleaned up
        expect(await persistentFile.exists(), false);
        debugPrint('[Test] Image file cleaned up successfully');

        // STEP 11: Verify final state
        final finalBooks = await database.select(database.books).get();
        expect(finalBooks.length, 1);

        final finalFailedScans = await database.select(database.failedScans).get();
        expect(finalFailedScans.length, 0);

        debugPrint('[Test] ✅ Failed scan → retry → success flow completed successfully');
      },
    );

    testWidgets(
      'Multiple failed scans with different error types',
      (WidgetTester tester) async {
        // Test that multiple failed scans can coexist and be managed independently

        final testScans = [
          {
            'jobId': 'job-network-error',
            'errorMessage': 'No internet connection',
            'failureReason': FailureReason.networkError,
          },
          {
            'jobId': 'job-quality-low',
            'errorMessage': 'Image quality too low',
            'failureReason': FailureReason.qualityTooLow,
          },
          {
            'jobId': 'job-no-books',
            'errorMessage': 'No books detected in this image',
            'failureReason': FailureReason.noBooksFound,
          },
        ];

        // Create and save multiple failed scans
        for (var i = 0; i < testScans.length; i++) {
          final scan = testScans[i];
          final testImagePath = p.join(testFailedScansDir.path, 'test_scan_$i.jpg');
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

        // Verify all failed scans were saved
        final failedScans = await database.select(database.failedScans).get();
        expect(failedScans.length, 3);

        // Verify each scan has correct attributes
        for (var i = 0; i < testScans.length; i++) {
          final scan = failedScans.firstWhere(
            (s) => s.jobId == testScans[i]['jobId'],
          );

          expect(scan.jobId, testScans[i]['jobId']);
          expect(scan.errorMessage, testScans[i]['errorMessage']);
          expect(scan.failureReason, testScans[i]['failureReason']);
          expect(scan.createdAt, greaterThan(0));
          expect(scan.expiresAt, greaterThan(scan.createdAt));

          // Verify image exists
          final imageFile = File(scan.imagePath);
          expect(await imageFile.exists(), true);
        }

        debugPrint('[Test] ✅ Multiple failed scans with different error types test passed');
      },
    );

    testWidgets(
      'Failed scan cleanup when image missing',
      (WidgetTester tester) async {
        // Test that cleanup handles missing image files gracefully

        const testJobId = 'job-missing-image';
        const fakePath = '/nonexistent/path/image.jpg';

        // Save failed scan with non-existent image path
        await database.saveFailedScan(
          jobId: testJobId,
          imagePath: fakePath,
          errorMessage: 'Network error',
          failureReason: FailureReason.networkError,
        );

        // Verify failed scan was saved
        final failedScans = await database.select(database.failedScans).get();
        expect(failedScans.length, 1);

        // Attempt to delete image (should not throw even if file doesn't exist)
        try {
          await FailedScansDirectory.deleteImage(testJobId);
        } catch (e) {
          // Expected - image doesn't exist
          debugPrint('[Test] Expected error when deleting non-existent image: $e');
        }

        // Delete database entry (should succeed regardless of image)
        await database.deleteFailedScan(testJobId);

        // Verify cleanup succeeded
        final remainingScans = await database.select(database.failedScans).get();
        expect(remainingScans.length, 0);

        debugPrint('[Test] ✅ Failed scan cleanup with missing image test passed');
      },
    );

    testWidgets(
      'Expired failed scans are identifiable',
      (WidgetTester tester) async {
        // Test that expired failed scans can be identified by expiresAt timestamp

        const expiredJobId = 'job-expired';
        const activeJobId = 'job-active';

        final testImagePath1 = p.join(testFailedScansDir.path, 'expired.jpg');
        final testImageFile1 = File(testImagePath1);
        await testImageFile1.writeAsBytes([
          0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46,
          0x00, 0x01, 0x01, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00,
          0xFF, 0xD9,
        ]);

        final testImagePath2 = p.join(testFailedScansDir.path, 'active.jpg');
        final testImageFile2 = File(testImagePath2);
        await testImageFile2.writeAsBytes([
          0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46,
          0x00, 0x01, 0x01, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00,
          0xFF, 0xD9,
        ]);

        final persistentPath1 = await FailedScansDirectory.moveImage(
          testImagePath1,
          expiredJobId,
        );

        final persistentPath2 = await FailedScansDirectory.moveImage(
          testImagePath2,
          activeJobId,
        );

        // Save expired scan (retention period in the past)
        await database.saveFailedScan(
          jobId: expiredJobId,
          imagePath: persistentPath1,
          errorMessage: 'Old network error',
          failureReason: FailureReason.networkError,
          retentionPeriod: const Duration(days: -1), // Already expired
        );

        // Save active scan (retention period in the future)
        await database.saveFailedScan(
          jobId: activeJobId,
          imagePath: persistentPath2,
          errorMessage: 'Recent network error',
          failureReason: FailureReason.networkError,
          retentionPeriod: const Duration(days: 7),
        );

        // Verify both scans were saved
        final allScans = await database.select(database.failedScans).get();
        expect(allScans.length, 2);

        // Identify expired scans
        final now = DateTime.now().millisecondsSinceEpoch;
        final expiredScans = allScans.where((s) => s.expiresAt < now).toList();
        final activeScans = allScans.where((s) => s.expiresAt >= now).toList();

        expect(expiredScans.length, 1);
        expect(expiredScans.first.jobId, expiredJobId);

        expect(activeScans.length, 1);
        expect(activeScans.first.jobId, activeJobId);

        debugPrint('[Test] ✅ Expired failed scans identification test passed');
      },
    );
  });

  group('Critical Flows - Collections Management', () {
    late AppDatabase database;
    late ProviderContainer container;

    setUp(() async {
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

    testWidgets(
      'Collections management flow: create → add books → filter → remove',
      (WidgetTester tester) async {
        // STEP 1: Create test books in the database
        final testBooks = [
          BooksCompanion.insert(
            isbn: '978-0-111111-11-1',
            title: 'The Fellowship of the Ring',
            author: 'J.R.R. Tolkien',
            coverUrl: const Value('https://example.com/lotr1.jpg'),
            format: const Value('Hardcover'),
            addedDate: DateTime.now().millisecondsSinceEpoch,
            spineConfidence: const Value(0.92),
          ),
          BooksCompanion.insert(
            isbn: '978-0-222222-22-2',
            title: 'The Two Towers',
            author: 'J.R.R. Tolkien',
            coverUrl: const Value('https://example.com/lotr2.jpg'),
            format: const Value('Hardcover'),
            addedDate: DateTime.now().millisecondsSinceEpoch,
            spineConfidence: const Value(0.89),
          ),
          BooksCompanion.insert(
            isbn: '978-0-333333-33-3',
            title: 'The Return of the King',
            author: 'J.R.R. Tolkien',
            coverUrl: const Value('https://example.com/lotr3.jpg'),
            format: const Value('Hardcover'),
            addedDate: DateTime.now().millisecondsSinceEpoch,
            spineConfidence: const Value(0.95),
          ),
        ];

        for (final book in testBooks) {
          await database.into(database.books).insertOnConflictUpdate(book);
        }

        // Verify books were saved
        final allBooks = await database.select(database.books).get();
        expect(allBooks.length, 3);
        debugPrint('[Test] Created 3 test books');

        // STEP 2: Create a new collection via database API
        final collectionId = await database.createCollection('LOTR Collection');
        expect(collectionId, greaterThan(0));
        debugPrint('[Test] Created collection with ID: $collectionId');

        // Verify collection was created
        final collections = await database.select(database.collections).get();
        expect(collections.length, 1);
        expect(collections.first.name, 'LOTR Collection');
        expect(collections.first.id, collectionId);
        debugPrint('[Test] ✅ Collection created successfully');

        // STEP 3: Add books to the collection
        await database.addBookToCollection('978-0-111111-11-1', collectionId);
        await database.addBookToCollection('978-0-222222-22-2', collectionId);
        await database.addBookToCollection('978-0-333333-33-3', collectionId);

        // Verify books were added to collection
        final bookCollections = await database.select(database.bookCollections).get();
        expect(bookCollections.length, 3);
        debugPrint('[Test] ✅ Added 3 books to collection');

        // STEP 4: Verify book count badge via watchCollectionsWithCounts
        final collectionsWithCounts = await database.watchCollectionsWithCounts().first;
        expect(collectionsWithCounts.length, 1);
        expect(collectionsWithCounts.first.bookCount, 3);
        expect(collectionsWithCounts.first.name, 'LOTR Collection');
        debugPrint('[Test] ✅ Collection book count badge shows 3 books');

        // STEP 5: Filter library by collection and verify only collection books show
        final booksInCollection = await database.watchBooksInCollection(collectionId).first;
        expect(booksInCollection.length, 3);

        // Verify correct books are in the collection
        final isbnSet = booksInCollection.map((b) => b.isbn).toSet();
        expect(isbnSet.contains('978-0-111111-11-1'), true);
        expect(isbnSet.contains('978-0-222222-22-2'), true);
        expect(isbnSet.contains('978-0-333333-33-3'), true);
        debugPrint('[Test] ✅ Filter by collection shows only collection books');

        // STEP 6: Remove one book from collection
        await database.removeBookFromCollection('978-0-222222-22-2', collectionId);

        // Verify book was removed from collection
        final updatedBookCollections = await database.select(database.bookCollections).get();
        expect(updatedBookCollections.length, 2);
        debugPrint('[Test] ✅ Removed 1 book from collection');

        // STEP 7: Verify updated book count
        final updatedCollectionsWithCounts = await database.watchCollectionsWithCounts().first;
        expect(updatedCollectionsWithCounts.first.bookCount, 2);
        debugPrint('[Test] ✅ Collection book count badge updated to 2 books');

        // STEP 8: Verify updated collection filter results
        final updatedBooksInCollection = await database.watchBooksInCollection(collectionId).first;
        expect(updatedBooksInCollection.length, 2);

        final updatedIsbnSet = updatedBooksInCollection.map((b) => b.isbn).toSet();
        expect(updatedIsbnSet.contains('978-0-111111-11-1'), true);
        expect(updatedIsbnSet.contains('978-0-222222-22-2'), false); // Removed
        expect(updatedIsbnSet.contains('978-0-333333-33-3'), true);
        debugPrint('[Test] ✅ Collection filter shows updated book list');

        // STEP 9: Verify original book still exists in library (not deleted, just removed from collection)
        final finalAllBooks = await database.select(database.books).get();
        expect(finalAllBooks.length, 3); // All books still exist
        debugPrint('[Test] ✅ Book removed from collection but still exists in library');

        // STEP 10: Test multiple collections - create second collection and add one book
        final secondCollectionId = await database.createCollection('Favorites');
        await database.addBookToCollection('978-0-111111-11-1', secondCollectionId);

        // Verify book can belong to multiple collections
        final collectionsForBook = await database.getCollectionsForBook('978-0-111111-11-1');
        expect(collectionsForBook.length, 2);
        debugPrint('[Test] ✅ Book can belong to multiple collections');

        // STEP 11: Verify final state
        final finalCollections = await database.watchCollectionsWithCounts().first;
        expect(finalCollections.length, 2);
        expect(finalCollections[0].name, 'Favorites'); // Newest first (ordered by created_at DESC)
        expect(finalCollections[0].bookCount, 1);
        expect(finalCollections[1].name, 'LOTR Collection');
        expect(finalCollections[1].bookCount, 2);

        debugPrint('[Test] ✅ Collections management flow completed successfully');
        debugPrint('[Test] Summary:');
        debugPrint('  - Created 2 collections');
        debugPrint('  - Added/removed books from collections');
        debugPrint('  - Verified book counts and filtering');
        debugPrint('  - Confirmed many-to-many relationships work correctly');
      },
    );
  });
}
