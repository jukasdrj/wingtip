import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';
import '../features/library/sort_options.dart';

part 'database.g.dart';

@DataClassName('Book')
class Books extends Table {
  TextColumn get isbn => text()();
  TextColumn get title => text()();
  TextColumn get author => text()();
  TextColumn get coverUrl => text().nullable()();
  TextColumn get format => text().nullable()();
  IntColumn get addedDate => integer()();
  RealColumn get spineConfidence => real().nullable()();
  BoolColumn get reviewNeeded => boolean().withDefault(const Constant(false))();
  TextColumn get spineImagePath => text().nullable()(); // Path to original captured spine image

  @override
  Set<Column> get primaryKey => {isbn};
}

/// Enum for categorizing failed scan reasons
enum FailureReason {
  networkError,
  qualityTooLow,
  noBooksFound,
  serverError,
  rateLimited,
  unknown;

  String get label {
    switch (this) {
      case FailureReason.networkError:
        return 'Network Error';
      case FailureReason.qualityTooLow:
        return 'Quality Too Low';
      case FailureReason.noBooksFound:
        return 'No Books Found';
      case FailureReason.serverError:
        return 'Server Error';
      case FailureReason.rateLimited:
        return 'Rate Limited';
      case FailureReason.unknown:
        return 'Unknown';
    }
  }
}

@DataClassName('FailedScan')
class FailedScans extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get jobId => text()();
  TextColumn get imagePath => text()();
  TextColumn get errorMessage => text()();
  TextColumn get failureReason => textEnum<FailureReason>().withDefault(Constant(FailureReason.unknown.name))();
  IntColumn get createdAt => integer()();
  IntColumn get expiresAt => integer()();
}

@DriftDatabase(tables: [Books, FailedScans])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.test(super.executor);

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();

        // Create index on addedDate descending for default sort
        await customStatement(
          'CREATE INDEX idx_books_added_date ON books(added_date DESC)',
        );

        // Create FTS5 virtual table for full-text search
        await customStatement(
          '''CREATE VIRTUAL TABLE books_fts USING fts5(
            isbn,
            title,
            author,
            content=books,
            content_rowid=rowid
          )''',
        );

        // Create triggers to keep FTS5 table in sync
        await customStatement(
          '''CREATE TRIGGER books_fts_insert AFTER INSERT ON books BEGIN
            INSERT INTO books_fts(rowid, isbn, title, author)
            VALUES (new.rowid, new.isbn, new.title, new.author);
          END''',
        );

        await customStatement(
          '''CREATE TRIGGER books_fts_delete AFTER DELETE ON books BEGIN
            INSERT INTO books_fts(books_fts, rowid, isbn, title, author)
            VALUES('delete', old.rowid, old.isbn, old.title, old.author);
          END''',
        );

        await customStatement(
          '''CREATE TRIGGER books_fts_update AFTER UPDATE ON books BEGIN
            INSERT INTO books_fts(books_fts, rowid, isbn, title, author)
            VALUES('delete', old.rowid, old.isbn, old.title, old.author);
            INSERT INTO books_fts(rowid, isbn, title, author)
            VALUES (new.rowid, new.isbn, new.title, new.author);
          END''',
        );
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // Create FTS5 virtual table for full-text search
          await customStatement(
            '''CREATE VIRTUAL TABLE books_fts USING fts5(
              isbn,
              title,
              author,
              content=books,
              content_rowid=rowid
            )''',
          );

          // Populate FTS table with existing data
          await customStatement(
            '''INSERT INTO books_fts(rowid, isbn, title, author)
            SELECT rowid, isbn, title, author FROM books''',
          );

          // Create triggers to keep FTS5 table in sync
          await customStatement(
            '''CREATE TRIGGER books_fts_insert AFTER INSERT ON books BEGIN
              INSERT INTO books_fts(rowid, isbn, title, author)
              VALUES (new.rowid, new.isbn, new.title, new.author);
            END''',
          );

          await customStatement(
            '''CREATE TRIGGER books_fts_delete AFTER DELETE ON books BEGIN
              INSERT INTO books_fts(books_fts, rowid, isbn, title, author)
              VALUES('delete', old.rowid, old.isbn, old.title, old.author);
            END''',
          );

          await customStatement(
            '''CREATE TRIGGER books_fts_update AFTER UPDATE ON books BEGIN
              INSERT INTO books_fts(books_fts, rowid, isbn, title, author)
              VALUES('delete', old.rowid, old.isbn, old.title, old.author);
              INSERT INTO books_fts(rowid, isbn, title, author)
              VALUES (new.rowid, new.isbn, new.title, new.author);
            END''',
          );
        }
        if (from < 3) {
          // Add review_needed column
          await m.addColumn(books, books.reviewNeeded);
        }
        if (from < 4) {
          // Add failure_reason column to failed_scans
          await m.addColumn(failedScans, failedScans.failureReason);
        }
        if (from < 5) {
          // Add spine_image_path column to books
          await m.addColumn(books, books.spineImagePath);
        }
      },
    );
  }

  // Helper method to build ORDER BY terms based on sort option
  List<OrderingTerm Function($BooksTable)> _buildOrderByTerms({
    required SortOption sortOption,
    bool sortReviewFirst = false,
  }) {
    final terms = <OrderingTerm Function($BooksTable)>[];

    // Add review needed sorting if enabled
    if (sortReviewFirst) {
      terms.add((t) => OrderingTerm.desc(t.reviewNeeded));
    }

    // Add main sort option
    switch (sortOption) {
      case SortOption.dateAddedNewest:
        terms.add((t) => OrderingTerm.desc(t.addedDate));
        break;
      case SortOption.dateAddedOldest:
        terms.add((t) => OrderingTerm.asc(t.addedDate));
        break;
      case SortOption.titleAZ:
        terms.add((t) => OrderingTerm.asc(t.title));
        break;
      case SortOption.titleZA:
        terms.add((t) => OrderingTerm.desc(t.title));
        break;
      case SortOption.authorAZ:
        terms.add((t) => OrderingTerm.asc(t.author));
        break;
      case SortOption.authorZA:
        terms.add((t) => OrderingTerm.desc(t.author));
        break;
      case SortOption.spineConfidenceHigh:
        // NULLS LAST for descending confidence
        terms.add((t) => OrderingTerm(
          expression: t.spineConfidence,
          mode: OrderingMode.desc,
        ));
        break;
      case SortOption.spineConfidenceLow:
        // NULLS LAST for ascending confidence
        terms.add((t) => OrderingTerm(
          expression: t.spineConfidence,
          mode: OrderingMode.asc,
        ));
        break;
    }

    return terms;
  }

  // Helper method to build SQL ORDER BY clause for custom queries
  String _buildSqlOrderByClause({
    required SortOption sortOption,
    bool sortReviewFirst = false,
  }) {
    final clauses = <String>[];

    if (sortReviewFirst) {
      clauses.add('b.review_needed DESC');
    }

    switch (sortOption) {
      case SortOption.dateAddedNewest:
        clauses.add('b.added_date DESC');
        break;
      case SortOption.dateAddedOldest:
        clauses.add('b.added_date ASC');
        break;
      case SortOption.titleAZ:
        clauses.add('b.title COLLATE NOCASE ASC');
        break;
      case SortOption.titleZA:
        clauses.add('b.title COLLATE NOCASE DESC');
        break;
      case SortOption.authorAZ:
        clauses.add('b.author COLLATE NOCASE ASC');
        break;
      case SortOption.authorZA:
        clauses.add('b.author COLLATE NOCASE DESC');
        break;
      case SortOption.spineConfidenceHigh:
        clauses.add('b.spine_confidence DESC NULLS LAST');
        break;
      case SortOption.spineConfidenceLow:
        clauses.add('b.spine_confidence ASC NULLS LAST');
        break;
    }

    return 'ORDER BY ${clauses.join(', ')}';
  }

  // Query all books ordered by added date descending
  Stream<List<Book>> watchAllBooks({
    bool? reviewNeeded,
    bool sortReviewFirst = false,
    SortOption sortOption = SortOption.dateAddedNewest,
  }) {
    final query = select(books);

    if (reviewNeeded != null) {
      query.where((t) => t.reviewNeeded.equals(reviewNeeded));
    }

    query.orderBy(_buildOrderByTerms(
      sortOption: sortOption,
      sortReviewFirst: sortReviewFirst,
    ));

    return query.watch();
  }

  Future<List<Book>> getAllBooks({
    bool? reviewNeeded,
    bool sortReviewFirst = false,
    SortOption sortOption = SortOption.dateAddedNewest,
  }) {
    final query = select(books);

    if (reviewNeeded != null) {
      query.where((t) => t.reviewNeeded.equals(reviewNeeded));
    }

    query.orderBy(_buildOrderByTerms(
      sortOption: sortOption,
      sortReviewFirst: sortReviewFirst,
    ));

    return query.get();
  }

  // Search books using FTS5
  Stream<List<Book>> searchBooks(
    String query, {
    bool? reviewNeeded,
    bool sortReviewFirst = false,
    SortOption sortOption = SortOption.dateAddedNewest,
  }) {
    if (query.isEmpty) {
      return watchAllBooks(
        reviewNeeded: reviewNeeded,
        sortReviewFirst: sortReviewFirst,
        sortOption: sortOption,
      );
    }

    // Escape special FTS5 characters and prepare query
    // Remove hyphens for better ISBN matching
    final escapedQuery = query
        .replaceAll('"', '""')
        .replaceAll('*', '')
        .replaceAll(':', '')
        .replaceAll('-', ' ');

    // Build WHERE clause
    final whereClause = reviewNeeded != null
        ? 'WHERE books_fts MATCH ? AND b.review_needed = ?'
        : 'WHERE books_fts MATCH ?';

    // Build ORDER BY clause
    final orderByClause = _buildSqlOrderByClause(
      sortOption: sortOption,
      sortReviewFirst: sortReviewFirst,
    );

    // Build variables list
    final variables = reviewNeeded != null
        ? [Variable.withString('$escapedQuery*'), Variable.withBool(reviewNeeded)]
        : [Variable.withString('$escapedQuery*')];

    // Use FTS5 MATCH query with prefix matching
    return customSelect(
      '''SELECT b.* FROM books b
         INNER JOIN books_fts fts ON b.rowid = fts.rowid
         $whereClause
         $orderByClause''',
      variables: variables,
      readsFrom: {books},
    ).watch().map((rows) {
      return rows.map((row) => books.map(row.data)).toList();
    });
  }

  Future<List<Book>> searchBooksOnce(
    String query, {
    bool? reviewNeeded,
    bool sortReviewFirst = false,
    SortOption sortOption = SortOption.dateAddedNewest,
  }) {
    if (query.isEmpty) {
      return getAllBooks(
        reviewNeeded: reviewNeeded,
        sortReviewFirst: sortReviewFirst,
        sortOption: sortOption,
      );
    }

    final escapedQuery = query
        .replaceAll('"', '""')
        .replaceAll('*', '')
        .replaceAll(':', '')
        .replaceAll('-', ' ');

    // Build WHERE clause
    final whereClause = reviewNeeded != null
        ? 'WHERE books_fts MATCH ? AND b.review_needed = ?'
        : 'WHERE books_fts MATCH ?';

    // Build ORDER BY clause
    final orderByClause = _buildSqlOrderByClause(
      sortOption: sortOption,
      sortReviewFirst: sortReviewFirst,
    );

    // Build variables list
    final variables = reviewNeeded != null
        ? [Variable.withString('$escapedQuery*'), Variable.withBool(reviewNeeded)]
        : [Variable.withString('$escapedQuery*')];

    return customSelect(
      '''SELECT b.* FROM books b
         INNER JOIN books_fts fts ON b.rowid = fts.rowid
         $whereClause
         $orderByClause''',
      variables: variables,
      readsFrom: {books},
    ).map((row) => books.map(row.data)).get();
  }

  // Delete multiple books by ISBN
  Future<int> deleteBooks(List<String> isbns) async {
    if (isbns.isEmpty) return 0;

    return (delete(books)..where((t) => t.isbn.isIn(isbns))).go();
  }

  // Save a failed scan to the database
  Future<void> saveFailedScan({
    required String jobId,
    required String imagePath,
    required String errorMessage,
    FailureReason failureReason = FailureReason.unknown,
    Duration retentionPeriod = const Duration(days: 7),
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final expiresAt = now + retentionPeriod.inMilliseconds;

    final failedScan = FailedScansCompanion(
      jobId: Value(jobId),
      imagePath: Value(imagePath),
      errorMessage: Value(errorMessage),
      failureReason: Value(failureReason),
      createdAt: Value(now),
      expiresAt: Value(expiresAt),
    );

    await into(failedScans).insert(failedScan);
  }

  // Get a failed scan by job ID
  Future<FailedScan?> getFailedScan(String jobId) async {
    final query = select(failedScans)..where((t) => t.jobId.equals(jobId));
    return query.getSingleOrNull();
  }

  // Delete a failed scan by job ID
  Future<void> deleteFailedScan(String jobId) async {
    await (delete(failedScans)..where((t) => t.jobId.equals(jobId))).go();
  }

  // Get analytics for failed scans
  Future<Map<FailureReason, int>> getFailedScansAnalytics() async {
    final allScans = await select(failedScans).get();

    final analytics = <FailureReason, int>{};
    for (final reason in FailureReason.values) {
      analytics[reason] = 0;
    }

    for (final scan in allScans) {
      analytics[scan.failureReason] = (analytics[scan.failureReason] ?? 0) + 1;
    }

    return analytics;
  }

  // Get total count of failed scans
  Future<int> getFailedScansCount() async {
    final countQuery = selectOnly(failedScans)
      ..addColumns([failedScans.id.count()]);
    final result = await countQuery.getSingle();
    return result.read(failedScans.id.count()) ?? 0;
  }

  // Update book metadata
  Future<bool> updateBook({
    required String isbn,
    required String title,
    required String author,
    String? format,
    bool clearReviewNeeded = true,
  }) async {
    final companion = BooksCompanion(
      isbn: Value(isbn),
      title: Value(title),
      author: Value(author),
      format: Value(format),
      reviewNeeded: Value(clearReviewNeeded ? false : true),
    );

    final updated = await (update(books)..where((t) => t.isbn.equals(isbn))).write(companion);
    return updated > 0;
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final initStart = DateTime.now();

    // Ensure FTS5 is available
    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }

    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'wingtip.db'));

    final db = NativeDatabase(
      file,
      setup: (database) {
        // Performance optimizations for SQLite
        database.execute('PRAGMA journal_mode = WAL'); // Write-Ahead Logging for better concurrency
        database.execute('PRAGMA synchronous = NORMAL'); // Faster commits
        database.execute('PRAGMA temp_store = MEMORY'); // Use memory for temp tables
        database.execute('PRAGMA mmap_size = 30000000'); // 30MB memory-mapped I/O
        database.execute('PRAGMA page_size = 4096'); // Optimal page size for iOS

        // Verify FTS5 is available
        database.execute('PRAGMA compile_options');
      },
    );

    final initDuration = DateTime.now().difference(initStart);
    debugPrint('[Database] Opened database in ${initDuration.inMilliseconds}ms');

    return db;
  });
}
