import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

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

  @override
  Set<Column> get primaryKey => {isbn};
}

@DataClassName('FailedScan')
class FailedScans extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get jobId => text()();
  TextColumn get imagePath => text()();
  TextColumn get errorMessage => text()();
  IntColumn get createdAt => integer()();
  IntColumn get expiresAt => integer()();
}

@DriftDatabase(tables: [Books, FailedScans])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.test(super.executor);

  @override
  int get schemaVersion => 3;

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
      },
    );
  }

  // Query all books ordered by added date descending
  Stream<List<Book>> watchAllBooks({bool? reviewNeeded, bool sortReviewFirst = false}) {
    final query = select(books);

    if (reviewNeeded != null) {
      query.where((t) => t.reviewNeeded.equals(reviewNeeded));
    }

    if (sortReviewFirst) {
      query.orderBy([
        (t) => OrderingTerm.desc(t.reviewNeeded),
        (t) => OrderingTerm.desc(t.addedDate),
      ]);
    } else {
      query.orderBy([(t) => OrderingTerm.desc(t.addedDate)]);
    }

    return query.watch();
  }

  Future<List<Book>> getAllBooks({bool? reviewNeeded, bool sortReviewFirst = false}) {
    final query = select(books);

    if (reviewNeeded != null) {
      query.where((t) => t.reviewNeeded.equals(reviewNeeded));
    }

    if (sortReviewFirst) {
      query.orderBy([
        (t) => OrderingTerm.desc(t.reviewNeeded),
        (t) => OrderingTerm.desc(t.addedDate),
      ]);
    } else {
      query.orderBy([(t) => OrderingTerm.desc(t.addedDate)]);
    }

    return query.get();
  }

  // Search books using FTS5
  Stream<List<Book>> searchBooks(String query, {bool? reviewNeeded, bool sortReviewFirst = false}) {
    if (query.isEmpty) {
      return watchAllBooks(reviewNeeded: reviewNeeded, sortReviewFirst: sortReviewFirst);
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
    final orderByClause = sortReviewFirst
        ? 'ORDER BY b.review_needed DESC, b.added_date DESC'
        : 'ORDER BY b.added_date DESC';

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

  Future<List<Book>> searchBooksOnce(String query, {bool? reviewNeeded, bool sortReviewFirst = false}) {
    if (query.isEmpty) {
      return getAllBooks(reviewNeeded: reviewNeeded, sortReviewFirst: sortReviewFirst);
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
    final orderByClause = sortReviewFirst
        ? 'ORDER BY b.review_needed DESC, b.added_date DESC'
        : 'ORDER BY b.added_date DESC';

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
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    // Ensure FTS5 is available
    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }

    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'wingtip.db'));

    return NativeDatabase(
      file,
      setup: (database) {
        // Verify FTS5 is available
        database.execute('PRAGMA compile_options');
      },
    );
  });
}
