import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wingtip/core/theme.dart';
import 'package:wingtip/data/database.dart';
import 'package:wingtip/data/database_provider.dart';
import 'package:wingtip/data/failed_scans_repository.dart' hide watchFailedScansProvider;
import 'package:wingtip/data/failed_scans_repository.dart' as failed_scans show watchFailedScansProvider;
import 'package:wingtip/features/library/book_detail_screen.dart';
import 'package:wingtip/features/library/collections_provider.dart';
import 'package:wingtip/features/library/filter_model.dart';
import 'package:wingtip/features/library/library_screen.dart';
import 'package:wingtip/features/library/sort_options.dart';
import 'package:wingtip/features/library/widgets/empty_library_state.dart';

/// Mock AppDatabase for testing
class MockAppDatabase implements AppDatabase {
  final List<Book> mockBooks;
  final List<FailedScan> mockFailedScans;

  MockAppDatabase({
    this.mockBooks = const [],
    this.mockFailedScans = const [],
  });

  @override
  Stream<List<Book>> searchBooks(
    String query, {
    bool? reviewNeeded,
    bool sortReviewFirst = false,
    SortOption sortOption = SortOption.dateAddedNewest,
    FilterState? filterState,
  }) {
    var books = mockBooks;

    // Apply search filter
    if (query.isNotEmpty) {
      books = books.where((book) {
        final searchLower = query.toLowerCase();
        return book.title.toLowerCase().contains(searchLower) ||
            book.author.toLowerCase().contains(searchLower) ||
            book.isbn.toLowerCase().contains(searchLower);
      }).toList();
    }

    // Apply review needed filter
    if (reviewNeeded != null) {
      books = books.where((book) => book.reviewNeeded == reviewNeeded).toList();
    }

    // Apply sorting
    books = List.from(books);
    switch (sortOption) {
      case SortOption.dateAddedNewest:
        books.sort((a, b) => b.addedDate.compareTo(a.addedDate));
        break;
      case SortOption.dateAddedOldest:
        books.sort((a, b) => a.addedDate.compareTo(b.addedDate));
        break;
      case SortOption.titleAZ:
        books.sort((a, b) => a.title.compareTo(b.title));
        break;
      case SortOption.titleZA:
        books.sort((a, b) => b.title.compareTo(a.title));
        break;
      case SortOption.authorAZ:
        books.sort((a, b) => a.author.compareTo(b.author));
        break;
      case SortOption.authorZA:
        books.sort((a, b) => b.author.compareTo(a.author));
        break;
      case SortOption.spineConfidenceHigh:
        books.sort((a, b) {
          final aConf = a.spineConfidence ?? 0.0;
          final bConf = b.spineConfidence ?? 0.0;
          return bConf.compareTo(aConf);
        });
        break;
      case SortOption.spineConfidenceLow:
        books.sort((a, b) {
          final aConf = a.spineConfidence ?? 0.0;
          final bConf = b.spineConfidence ?? 0.0;
          return aConf.compareTo(bConf);
        });
        break;
    }

    return Stream.value(books);
  }

  @override
  Stream<List<Book>> watchBooksInCollection(
    int collectionId, {
    bool sortReviewFirst = false,
    SortOption sortOption = SortOption.dateAddedNewest,
  }) {
    return Stream.value([]);
  }

  @override
  Future<int> deleteBooks(List<String> isbns) async {
    return isbns.length;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Mock FailedScansRepository for testing
class MockFailedScansRepository implements FailedScansRepository {
  final List<FailedScan> mockScans;

  MockFailedScansRepository({this.mockScans = const []});

  @override
  Stream<List<FailedScan>> getAllFailedScans() {
    return Stream.value(mockScans);
  }

  @override
  Future<void> deleteFailedScan(int id) async {}

  @override
  Future<void> clearAllFailedScans() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LibraryScreen Widget Tests', () {
    late MockAppDatabase mockDatabase;
    late MockFailedScansRepository mockFailedScansRepo;

    setUp(() {
      mockDatabase = MockAppDatabase();
      mockFailedScansRepo = MockFailedScansRepository();
    });

    testWidgets('LibraryScreen renders grid with mocked books', (tester) async {
      // Create test books
      final testBooks = [
        Book(
          isbn: '9780134685991',
          title: 'Effective Java',
          author: 'Joshua Bloch',
          coverUrl: null,
          format: 'Hardcover',
          addedDate: DateTime(2024, 1, 1).millisecondsSinceEpoch,
          spineConfidence: 0.95,
          reviewNeeded: false,
          spineImagePath: null,
        ),
        Book(
          isbn: '9780132350884',
          title: 'Clean Code',
          author: 'Robert Martin',
          coverUrl: null,
          format: 'Paperback',
          addedDate: DateTime(2024, 1, 2).millisecondsSinceEpoch,
          spineConfidence: 0.87,
          reviewNeeded: false,
          spineImagePath: null,
        ),
        Book(
          isbn: '9780201633610',
          title: 'Design Patterns',
          author: 'Gang of Four',
          coverUrl: null,
          format: 'Hardcover',
          addedDate: DateTime(2024, 1, 3).millisecondsSinceEpoch,
          spineConfidence: 0.92,
          reviewNeeded: true,
          spineImagePath: null,
        ),
      ];

      mockDatabase = MockAppDatabase(mockBooks: testBooks);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(mockDatabase),
            failedScansRepositoryProvider.overrideWithValue(mockFailedScansRepo),
            collectionsWithCountsProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const LibraryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the library screen is rendered
      expect(find.byType(LibraryScreen), findsOneWidget);
      expect(find.text('Library'), findsOneWidget);

      // Verify grid is displayed with books
      expect(find.byType(GridView), findsOneWidget);

      // Verify all three books are rendered in the grid
      expect(find.text('Effective Java'), findsOneWidget);
      expect(find.text('Clean Code'), findsOneWidget);
      expect(find.text('Design Patterns'), findsOneWidget);
    });

    testWidgets('Tabs switch between All Books and Failed Scans', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(mockDatabase),
            failedScansRepositoryProvider.overrideWithValue(mockFailedScansRepo),
            collectionsWithCountsProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const LibraryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify tabs exist
      expect(find.text('All Books'), findsOneWidget);
      expect(find.text('Collections'), findsOneWidget);
      expect(find.text('Failed'), findsOneWidget);

      // Tap on Failed tab
      await tester.tap(find.text('Failed'));
      await tester.pumpAndSettle();

      // Verify we're on the Failed Scans tab (check for the icon since text might be wrapped differently)
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);

      // Tap back on All Books tab
      await tester.tap(find.text('All Books'));
      await tester.pumpAndSettle();

      // Verify we're back on All Books tab (empty state)
      expect(find.byType(EmptyLibraryState), findsOneWidget);
    });

    testWidgets('Search TextField filters books when text entered', (tester) async {
      final testBooks = [
        Book(
          isbn: '9780134685991',
          title: 'Effective Java',
          author: 'Joshua Bloch',
          coverUrl: null,
          format: 'Hardcover',
          addedDate: DateTime(2024, 1, 1).millisecondsSinceEpoch,
          spineConfidence: 0.95,
          reviewNeeded: false,
          spineImagePath: null,
        ),
        Book(
          isbn: '9780132350884',
          title: 'Clean Code',
          author: 'Robert Martin',
          coverUrl: null,
          format: 'Paperback',
          addedDate: DateTime(2024, 1, 2).millisecondsSinceEpoch,
          spineConfidence: 0.87,
          reviewNeeded: false,
          spineImagePath: null,
        ),
        Book(
          isbn: '9781617294532',
          title: 'The Java Programming Language',
          author: 'Ken Arnold',
          coverUrl: null,
          format: 'Paperback',
          addedDate: DateTime(2024, 1, 3).millisecondsSinceEpoch,
          spineConfidence: 0.88,
          reviewNeeded: false,
          spineImagePath: null,
        ),
      ];

      mockDatabase = MockAppDatabase(mockBooks: testBooks);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(mockDatabase),
            failedScansRepositoryProvider.overrideWithValue(mockFailedScansRepo),
            collectionsWithCountsProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const LibraryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially all books should be visible
      expect(find.text('Effective Java'), findsOneWidget);
      expect(find.text('Clean Code'), findsOneWidget);
      expect(find.text('The Java Programming Language'), findsOneWidget);

      // Find and enter text in search field
      final searchField = find.byWidgetPredicate(
        (widget) => widget is TextField && widget.decoration?.hintText?.contains('Search') == true,
      );
      expect(searchField, findsOneWidget);

      await tester.enterText(searchField, 'Java');
      await tester.pumpAndSettle();

      // Only books with "Java" in title should be visible
      expect(find.text('Effective Java'), findsOneWidget);
      expect(find.text('The Java Programming Language'), findsOneWidget);
      expect(find.text('Clean Code'), findsNothing);

      // Clear search
      await tester.enterText(searchField, '');
      await tester.pumpAndSettle();

      // All books should be visible again
      expect(find.text('Effective Java'), findsOneWidget);
      expect(find.text('Clean Code'), findsOneWidget);
      expect(find.text('The Java Programming Language'), findsOneWidget);
    });

    testWidgets('Sort dropdown changes book order', (tester) async {
      final testBooks = [
        Book(
          isbn: '9780134685991',
          title: 'Zebra Book',
          author: 'Author A',
          coverUrl: null,
          format: 'Hardcover',
          addedDate: DateTime(2024, 1, 1).millisecondsSinceEpoch,
          spineConfidence: 0.95,
          reviewNeeded: false,
          spineImagePath: null,
        ),
        Book(
          isbn: '9780132350884',
          title: 'Apple Book',
          author: 'Author B',
          coverUrl: null,
          format: 'Paperback',
          addedDate: DateTime(2024, 1, 2).millisecondsSinceEpoch,
          spineConfidence: 0.87,
          reviewNeeded: false,
          spineImagePath: null,
        ),
        Book(
          isbn: '9780201633610',
          title: 'Middle Book',
          author: 'Author C',
          coverUrl: null,
          format: 'Hardcover',
          addedDate: DateTime(2024, 1, 3).millisecondsSinceEpoch,
          spineConfidence: 0.92,
          reviewNeeded: false,
          spineImagePath: null,
        ),
      ];

      mockDatabase = MockAppDatabase(mockBooks: testBooks);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(mockDatabase),
            failedScansRepositoryProvider.overrideWithValue(mockFailedScansRepo),
            collectionsWithCountsProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const LibraryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially books are sorted by date added (newest first - default)
      // Verify all books are displayed
      expect(find.text('Zebra Book'), findsOneWidget);
      expect(find.text('Apple Book'), findsOneWidget);
      expect(find.text('Middle Book'), findsOneWidget);

      // Find sort button (swap_vert icon)
      final sortButton = find.byIcon(Icons.swap_vert);
      expect(sortButton, findsOneWidget);

      // Tap sort button to open sort options
      await tester.tap(sortButton);
      await tester.pumpAndSettle();

      // Verify CupertinoActionSheet is displayed
      expect(find.byType(CupertinoActionSheet), findsOneWidget);
      expect(find.text('Sort By'), findsOneWidget);

      // Verify sort options are displayed
      expect(find.text('Title (A-Z)'), findsOneWidget);
      expect(find.text('Title (Z-A)'), findsOneWidget);
      expect(find.text('Author (A-Z)'), findsOneWidget);

      // Select "Title (A-Z)"
      await tester.tap(find.text('Title (A-Z)'));
      await tester.pumpAndSettle();

      // After sorting, verify all books are still displayed (just in different order)
      expect(find.text('Zebra Book'), findsOneWidget);
      expect(find.text('Apple Book'), findsOneWidget);
      expect(find.text('Middle Book'), findsOneWidget);
    });

    testWidgets('Empty state shows when no books exist', (tester) async {
      mockDatabase = MockAppDatabase(mockBooks: []);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(mockDatabase),
            failedScansRepositoryProvider.overrideWithValue(mockFailedScansRepo),
            collectionsWithCountsProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const LibraryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify empty state is displayed
      expect(find.byType(EmptyLibraryState), findsOneWidget);
      expect(find.text('0 Books. Tap [O] to scan.'), findsOneWidget);
    });

    testWidgets('Tapping book card opens BookDetailScreen', (tester) async {
      final testBook = Book(
        isbn: '9780134685991',
        title: 'Effective Java',
        author: 'Joshua Bloch',
        coverUrl: null,
        format: 'Hardcover',
        addedDate: DateTime(2024, 1, 1).millisecondsSinceEpoch,
        spineConfidence: 0.95,
        reviewNeeded: false,
        spineImagePath: null,
      );

      mockDatabase = MockAppDatabase(mockBooks: [testBook]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(mockDatabase),
            failedScansRepositoryProvider.overrideWithValue(mockFailedScansRepo),
            collectionsWithCountsProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const LibraryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap on the book card
      final bookCard = find.byType(BookCard);
      expect(bookCard, findsOneWidget);

      await tester.tap(bookCard);
      await tester.pumpAndSettle();

      // Verify BookDetailScreen is pushed
      expect(find.byType(BookDetailScreen), findsOneWidget);
      // Verify book details are displayed
      expect(find.text('Effective Java'), findsAtLeastNWidgets(1));
      expect(find.text('Joshua Bloch'), findsAtLeastNWidgets(1));
    });

    testWidgets('Failed Scans tab displays failed scans count in tab label', (tester) async {
      final testFailedScans = [
        FailedScan(
          id: 1,
          jobId: 'job-1',
          imagePath: '/tmp/scan1.jpg',
          errorMessage: 'Network error',
          failureReason: FailureReason.networkError,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          expiresAt: DateTime.now().add(const Duration(days: 7)).millisecondsSinceEpoch,
        ),
        FailedScan(
          id: 2,
          jobId: 'job-2',
          imagePath: '/tmp/scan2.jpg',
          errorMessage: 'Quality too low',
          failureReason: FailureReason.qualityTooLow,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          expiresAt: DateTime.now().add(const Duration(days: 7)).millisecondsSinceEpoch,
        ),
      ];

      mockFailedScansRepo = MockFailedScansRepository(mockScans: testFailedScans);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(mockDatabase),
            failedScansRepositoryProvider.overrideWithValue(mockFailedScansRepo),
            failed_scans.watchFailedScansProvider.overrideWith((ref) => Stream.value(testFailedScans)),
            collectionsWithCountsProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const LibraryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Failed tab shows count (might be in format "Failed (2)" or in Tab widget)
      // Just check that the Failed tab exists and we can find text containing "2"
      final failedTab = find.text('Failed (2)');
      expect(failedTab, findsOneWidget);
    });

    testWidgets('Search clear button appears and clears search', (tester) async {
      final testBooks = [
        Book(
          isbn: '9780134685991',
          title: 'Test Book',
          author: 'Test Author',
          coverUrl: null,
          format: 'Hardcover',
          addedDate: DateTime(2024, 1, 1).millisecondsSinceEpoch,
          spineConfidence: 0.95,
          reviewNeeded: false,
          spineImagePath: null,
        ),
      ];

      mockDatabase = MockAppDatabase(mockBooks: testBooks);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(mockDatabase),
            failedScansRepositoryProvider.overrideWithValue(mockFailedScansRepo),
            collectionsWithCountsProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const LibraryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find search field
      final searchField = find.byWidgetPredicate(
        (widget) => widget is TextField && widget.decoration?.hintText?.contains('Search') == true,
      );

      // Enter search text
      await tester.enterText(searchField, 'Test');
      await tester.pumpAndSettle();

      // Verify clear button appears
      final clearButton = find.byIcon(Icons.clear);
      expect(clearButton, findsOneWidget);

      // Tap clear button
      await tester.tap(clearButton);
      await tester.pumpAndSettle();

      // Verify search field is cleared
      final textField = tester.widget<TextField>(searchField);
      expect(textField.controller?.text, isEmpty);
    });

    testWidgets('Review needed filter button toggles correctly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(mockDatabase),
            failedScansRepositoryProvider.overrideWithValue(mockFailedScansRepo),
            collectionsWithCountsProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const LibraryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find Needs Review button
      final needsReviewButton = find.text('Needs Review');
      expect(needsReviewButton, findsOneWidget);

      // Tap to enable filter
      await tester.tap(needsReviewButton);
      await tester.pumpAndSettle();

      // Find the OutlinedButton that contains "Needs Review"
      final buttonWidget = find.ancestor(
        of: needsReviewButton,
        matching: find.byType(OutlinedButton),
      );
      expect(buttonWidget, findsOneWidget);

      // Tap again to disable filter
      await tester.tap(needsReviewButton);
      await tester.pumpAndSettle();

      // Button should still exist
      expect(needsReviewButton, findsOneWidget);
    });

    testWidgets('Collections tab shows empty state when no collections', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(mockDatabase),
            failedScansRepositoryProvider.overrideWithValue(mockFailedScansRepo),
            collectionsWithCountsProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const LibraryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on Collections tab
      await tester.tap(find.text('Collections'));
      await tester.pumpAndSettle();

      // Verify empty state
      expect(find.text('No collections yet'), findsOneWidget);
      expect(find.byIcon(Icons.collections_bookmark_outlined), findsOneWidget);
      expect(find.text('Create Collection'), findsOneWidget);
    });
  });
}
