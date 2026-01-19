import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wingtip/data/database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.test(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  group('Books table', () {
    test('should insert and retrieve a book', () async {
      final book = BooksCompanion(
        isbn: const Value('978-0-123456-78-9'),
        title: const Value('Test Book'),
        author: const Value('Test Author'),
        coverUrl: const Value('https://example.com/cover.jpg'),
        format: const Value('Hardcover'),
        addedDate: Value(DateTime.now().millisecondsSinceEpoch),
        spineConfidence: const Value(0.95),
      );

      await database.into(database.books).insert(book);

      final books = await database.select(database.books).get();
      expect(books.length, 1);
      expect(books.first.isbn, '978-0-123456-78-9');
      expect(books.first.title, 'Test Book');
      expect(books.first.author, 'Test Author');
      expect(books.first.spineConfidence, 0.95);
    });

    test('should enforce primary key constraint on isbn', () async {
      final book1 = BooksCompanion(
        isbn: const Value('978-0-123456-78-9'),
        title: const Value('Test Book 1'),
        author: const Value('Test Author'),
        addedDate: Value(DateTime.now().millisecondsSinceEpoch),
      );

      final book2 = BooksCompanion(
        isbn: const Value('978-0-123456-78-9'),
        title: const Value('Test Book 2'),
        author: const Value('Another Author'),
        addedDate: Value(DateTime.now().millisecondsSinceEpoch),
      );

      await database.into(database.books).insert(book1);

      expect(
        () => database.into(database.books).insert(book2),
        throwsA(isA<SqliteException>()),
      );
    });

    test('should handle nullable fields', () async {
      final book = BooksCompanion(
        isbn: const Value('978-0-123456-78-9'),
        title: const Value('Test Book'),
        author: const Value('Test Author'),
        addedDate: Value(DateTime.now().millisecondsSinceEpoch),
      );

      await database.into(database.books).insert(book);

      final books = await database.select(database.books).get();
      expect(books.first.coverUrl, isNull);
      expect(books.first.format, isNull);
      expect(books.first.spineConfidence, isNull);
    });

    test('should sort by addedDate descending using index', () async {
      final now = DateTime.now().millisecondsSinceEpoch;

      final book1 = BooksCompanion(
        isbn: const Value('978-0-111111-11-1'),
        title: const Value('Older Book'),
        author: const Value('Author 1'),
        addedDate: Value(now - 86400000), // 1 day ago
      );

      final book2 = BooksCompanion(
        isbn: const Value('978-0-222222-22-2'),
        title: const Value('Newer Book'),
        author: const Value('Author 2'),
        addedDate: Value(now),
      );

      await database.into(database.books).insert(book1);
      await database.into(database.books).insert(book2);

      final books = await (database.select(database.books)
            ..orderBy([(t) => OrderingTerm.desc(t.addedDate)]))
          .get();

      expect(books.length, 2);
      expect(books.first.title, 'Newer Book');
      expect(books.last.title, 'Older Book');
    });
  });

  group('FailedScans table', () {
    test('should insert and retrieve a failed scan', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final failedScan = FailedScansCompanion(
        jobId: const Value('job-123'),
        imagePath: const Value('/path/to/image.jpg'),
        errorMessage: const Value('OCR failed'),
        createdAt: Value(now),
        expiresAt: Value(now + 86400000), // 1 day later
      );

      await database.into(database.failedScans).insert(failedScan);

      final scans = await database.select(database.failedScans).get();
      expect(scans.length, 1);
      expect(scans.first.jobId, 'job-123');
      expect(scans.first.imagePath, '/path/to/image.jpg');
      expect(scans.first.errorMessage, 'OCR failed');
    });

    test('should auto-increment id', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final scan1 = FailedScansCompanion(
        jobId: const Value('job-1'),
        imagePath: const Value('/path/1.jpg'),
        errorMessage: const Value('Error 1'),
        createdAt: Value(now),
        expiresAt: Value(now + 86400000),
      );

      final scan2 = FailedScansCompanion(
        jobId: const Value('job-2'),
        imagePath: const Value('/path/2.jpg'),
        errorMessage: const Value('Error 2'),
        createdAt: Value(now),
        expiresAt: Value(now + 86400000),
      );

      await database.into(database.failedScans).insert(scan1);
      await database.into(database.failedScans).insert(scan2);

      final scans = await database.select(database.failedScans).get();
      expect(scans.length, 2);
      expect(scans.first.id, 1);
      expect(scans.last.id, 2);
    });

    test('should save failed scan with default retention period', () async {
      final beforeSave = DateTime.now().millisecondsSinceEpoch;

      await database.saveFailedScan(
        jobId: 'server-job-123',
        imagePath: '/tmp/test_image.jpg',
        errorMessage: 'OCR processing failed',
      );

      final afterSave = DateTime.now().millisecondsSinceEpoch;

      final scans = await database.select(database.failedScans).get();
      expect(scans.length, 1);

      final scan = scans.first;
      expect(scan.jobId, 'server-job-123');
      expect(scan.imagePath, '/tmp/test_image.jpg');
      expect(scan.errorMessage, 'OCR processing failed');

      // Check createdAt is within reasonable range
      expect(scan.createdAt, greaterThanOrEqualTo(beforeSave));
      expect(scan.createdAt, lessThanOrEqualTo(afterSave));

      // Check expiresAt is 7 days after createdAt (default retention period)
      final expectedExpiresAt = scan.createdAt + const Duration(days: 7).inMilliseconds;
      expect(scan.expiresAt, expectedExpiresAt);
    });

    test('should save failed scan with custom retention period', () async {
      await database.saveFailedScan(
        jobId: 'server-job-456',
        imagePath: '/tmp/another_image.jpg',
        errorMessage: 'Network timeout',
        retentionPeriod: const Duration(days: 14),
      );

      final scans = await database.select(database.failedScans).get();
      expect(scans.length, 1);

      final scan = scans.first;
      expect(scan.jobId, 'server-job-456');

      // Check expiresAt is 14 days after createdAt
      final expectedExpiresAt = scan.createdAt + const Duration(days: 14).inMilliseconds;
      expect(scan.expiresAt, expectedExpiresAt);
    });

    test('should save multiple failed scans', () async {
      await database.saveFailedScan(
        jobId: 'job-1',
        imagePath: '/tmp/image1.jpg',
        errorMessage: 'Error 1',
      );

      await database.saveFailedScan(
        jobId: 'job-2',
        imagePath: '/tmp/image2.jpg',
        errorMessage: 'Error 2',
      );

      await database.saveFailedScan(
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

  group('FTS5 Search', () {
    setUp(() async {
      // Add test books
      final now = DateTime.now().millisecondsSinceEpoch;

      final books = [
        BooksCompanion(
          isbn: const Value('978-0-123456-78-9'),
          title: const Value('The Great Gatsby'),
          author: const Value('F. Scott Fitzgerald'),
          addedDate: Value(now),
        ),
        BooksCompanion(
          isbn: const Value('978-0-987654-32-1'),
          title: const Value('To Kill a Mockingbird'),
          author: const Value('Harper Lee'),
          addedDate: Value(now - 1000),
        ),
        BooksCompanion(
          isbn: const Value('978-1-111111-11-1'),
          title: const Value('1984'),
          author: const Value('George Orwell'),
          addedDate: Value(now - 2000),
        ),
        BooksCompanion(
          isbn: const Value('978-2-222222-22-2'),
          title: const Value('Pride and Prejudice'),
          author: const Value('Jane Austen'),
          addedDate: Value(now - 3000),
        ),
      ];

      for (final book in books) {
        await database.into(database.books).insert(book);
      }
    });

    test('should search by title', () async {
      final results = await database.searchBooksOnce('Gatsby');
      expect(results.length, 1);
      expect(results.first.title, 'The Great Gatsby');
    });

    test('should search by author', () async {
      final results = await database.searchBooksOnce('Orwell');
      expect(results.length, 1);
      expect(results.first.author, 'George Orwell');
    });

    test('should search by ISBN', () async {
      final results = await database.searchBooksOnce('978-0-987654');
      expect(results.length, 1);
      expect(results.first.isbn, '978-0-987654-32-1');
    });

    test('should support prefix matching', () async {
      final results = await database.searchBooksOnce('Prid');
      expect(results.length, 1);
      expect(results.first.title, 'Pride and Prejudice');
    });

    test('should be case insensitive', () async {
      final results = await database.searchBooksOnce('gatsby');
      expect(results.length, 1);
      expect(results.first.title, 'The Great Gatsby');
    });

    test('should return all books when query is empty', () async {
      final results = await database.searchBooksOnce('');
      expect(results.length, 4);
    });

    test('should return empty list for no matches', () async {
      final results = await database.searchBooksOnce('NonexistentBook');
      expect(results.isEmpty, true);
    });

    test('should handle partial author name', () async {
      final results = await database.searchBooksOnce('Harper');
      expect(results.length, 1);
      expect(results.first.author, 'Harper Lee');
    });

    test('should search across multiple fields', () async {
      // Search for "Jane" which is in the author field
      final results = await database.searchBooksOnce('Jane');
      expect(results.length, 1);
      expect(results.first.author, 'Jane Austen');
    });

    test('should maintain sort order by added date descending', () async {
      final results = await database.searchBooksOnce('');
      expect(results.length, 4);
      expect(results[0].title, 'The Great Gatsby'); // Most recent
      expect(results[1].title, 'To Kill a Mockingbird');
      expect(results[2].title, '1984');
      expect(results[3].title, 'Pride and Prejudice'); // Oldest
    });

    test('should stream search results', () async {
      final stream = database.searchBooks('Gatsby');
      final results = await stream.first;
      expect(results.length, 1);
      expect(results.first.title, 'The Great Gatsby');
    });

    test('should update stream when data changes', () async {
      final stream = database.searchBooks('Test');

      // Initially no results
      var results = await stream.first;
      expect(results.isEmpty, true);

      // Add a book with "Test" in title
      final now = DateTime.now().millisecondsSinceEpoch;
      await database.into(database.books).insert(
        BooksCompanion(
          isbn: const Value('978-9-999999-99-9'),
          title: const Value('Test Book'),
          author: const Value('Test Author'),
          addedDate: Value(now),
        ),
      );

      // Should now have results
      results = await stream.first;
      expect(results.length, 1);
      expect(results.first.title, 'Test Book');
    });
  });
}

