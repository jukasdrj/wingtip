import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wingtip/core/theme.dart';
import 'package:wingtip/data/database.dart';
import 'package:wingtip/data/database_provider.dart';
import 'package:wingtip/features/library/book_detail_screen.dart';
import 'package:wingtip/features/library/edit_book_screen.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.test(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  testWidgets('should render BookDetailScreen with book data', (tester) async {
    final book = Book(
      isbn: '978-0-123456-78-9',
      title: 'The Martian',
      author: 'Andy Weir',
      coverUrl: null,
      format: 'Hardcover',
      addedDate: DateTime.now().millisecondsSinceEpoch,
      spineConfidence: 0.95,
      reviewNeeded: false,
      spineImagePath: null,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: BookDetailScreen(book: book),
        ),
      ),
    );

    // Wait for animations to complete
    await tester.pumpAndSettle();

    // Verify book metadata is displayed
    // Title may appear in both fallback cover and metadata section
    expect(find.text('The Martian'), findsAtLeastNWidgets(1));
    expect(find.text('Andy Weir'), findsAtLeastNWidgets(1));
    expect(find.text('978-0-123456-78-9'), findsOneWidget);
    expect(find.text('Hardcover'), findsOneWidget);
    expect(find.text('95.0%'), findsOneWidget);

    // Verify metadata labels are displayed
    expect(find.text('TITLE'), findsOneWidget);
    expect(find.text('AUTHOR'), findsOneWidget);
    expect(find.text('ISBN'), findsOneWidget);
    expect(find.text('FORMAT'), findsOneWidget);
    expect(find.text('CONFIDENCE'), findsOneWidget);
  });

  testWidgets('should show edit button only for review_needed books',
      (tester) async {
    final reviewNeededBook = Book(
      isbn: '978-0-123456-78-9',
      title: 'Test Book',
      author: 'Test Author',
      coverUrl: null,
      format: null,
      addedDate: DateTime.now().millisecondsSinceEpoch,
      spineConfidence: null,
      reviewNeeded: true,
      spineImagePath: null,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: BookDetailScreen(book: reviewNeededBook),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Edit button should be visible
    expect(find.text('Edit'), findsOneWidget);
    expect(find.widgetWithIcon(OutlinedButton, Icons.edit), findsOneWidget);

    // Create a verified book (reviewNeeded: false)
    final verifiedBook = Book(
      isbn: '978-0-123456-78-9',
      title: 'Test Book',
      author: 'Test Author',
      coverUrl: null,
      format: null,
      addedDate: DateTime.now().millisecondsSinceEpoch,
      spineConfidence: null,
      reviewNeeded: false,
      spineImagePath: null,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: BookDetailScreen(book: verifiedBook),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Edit button should NOT be visible
    expect(find.text('Edit'), findsNothing);
    expect(find.widgetWithIcon(OutlinedButton, Icons.edit), findsNothing);
  });

  testWidgets('should navigate to EditBookScreen when edit button is tapped',
      (tester) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    // Insert test book into database
    await database.into(database.books).insert(
          BooksCompanion(
            isbn: const Value('978-0-123456-78-9'),
            title: const Value('Test Book'),
            author: const Value('Test Author'),
            addedDate: Value(now),
            reviewNeeded: const Value(true),
          ),
        );

    final book = Book(
      isbn: '978-0-123456-78-9',
      title: 'Test Book',
      author: 'Test Author',
      coverUrl: null,
      format: null,
      addedDate: now,
      spineConfidence: null,
      reviewNeeded: true,
      spineImagePath: null,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: BookDetailScreen(book: book),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap edit button
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    // Verify EditBookScreen is shown
    expect(find.text('Edit Book'), findsOneWidget);
    expect(find.byType(EditBookScreen), findsOneWidget);
  });

  testWidgets('should pop back to library after successful edit',
      (tester) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await database.into(database.books).insert(
          BooksCompanion(
            isbn: const Value('978-0-123456-78-9'),
            title: const Value('Original Title'),
            author: const Value('Test Author'),
            addedDate: Value(now),
            reviewNeeded: const Value(true),
          ),
        );

    final book = Book(
      isbn: '978-0-123456-78-9',
      title: 'Original Title',
      author: 'Test Author',
      coverUrl: null,
      format: null,
      addedDate: now,
      spineConfidence: null,
      reviewNeeded: true,
      spineImagePath: null,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (_) => BookDetailScreen(book: book),
                    ),
                  );
                },
                child: const Text('Open Detail'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Open detail screen
    await tester.tap(find.text('Open Detail'));
    await tester.pumpAndSettle();

    // Tap edit button
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    // Update title in EditBookScreen
    final titleField =
        find.widgetWithText(TextFormField, 'Original Title');
    await tester.enterText(titleField, 'Updated Title');
    await tester.pumpAndSettle();

    // Save changes
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Verify we're back to the library screen (not detail screen)
    expect(find.text('Open Detail'), findsOneWidget);
    expect(find.byType(BookDetailScreen), findsNothing);
  });

  testWidgets('should have correct hero tag for cover image', (tester) async {
    final book = Book(
      isbn: '978-0-123456-78-9',
      title: 'Test Book',
      author: 'Test Author',
      coverUrl: null, // Use null to avoid network requests in test
      format: null,
      addedDate: DateTime.now().millisecondsSinceEpoch,
      spineConfidence: null,
      reviewNeeded: false,
      spineImagePath: null,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: BookDetailScreen(book: book),
        ),
      ),
    );

    // Use pump instead of pumpAndSettle to avoid waiting for async network calls
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Find Hero widget with correct tag
    final heroFinder = find.byWidgetPredicate(
      (widget) =>
          widget is Hero && widget.tag == 'book-cover-${book.isbn}',
    );

    expect(heroFinder, findsOneWidget);
  });

  testWidgets('should show fallback cover when coverUrl is null',
      (tester) async {
    final book = Book(
      isbn: '978-0-123456-78-9',
      title: 'Test Book Without Cover',
      author: 'Test Author',
      coverUrl: null,
      format: null,
      addedDate: DateTime.now().millisecondsSinceEpoch,
      spineConfidence: null,
      reviewNeeded: false,
      spineImagePath: null,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: BookDetailScreen(book: book),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Fallback cover should display title and author in the hero container
    // The title appears twice: once in the fallback cover, once in metadata
    expect(find.text('Test Book Without Cover'), findsAtLeastNWidgets(1));
    expect(find.text('Test Author'), findsAtLeastNWidgets(1));
  });

  testWidgets('should close screen when close button is tapped',
      (tester) async {
    final book = Book(
      isbn: '978-0-123456-78-9',
      title: 'Test Book',
      author: 'Test Author',
      coverUrl: null,
      format: null,
      addedDate: DateTime.now().millisecondsSinceEpoch,
      spineConfidence: null,
      reviewNeeded: false,
      spineImagePath: null,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (_) => BookDetailScreen(book: book),
                    ),
                  );
                },
                child: const Text('Open Detail'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Open detail screen
    await tester.tap(find.text('Open Detail'));
    await tester.pumpAndSettle();

    // Verify we're on detail screen
    expect(find.byType(BookDetailScreen), findsOneWidget);

    // Tap close button
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    // Verify we're back to the original screen
    expect(find.text('Open Detail'), findsOneWidget);
    expect(find.byType(BookDetailScreen), findsNothing);
  });

  testWidgets('should not show format or confidence when null',
      (tester) async {
    final book = Book(
      isbn: '978-0-123456-78-9',
      title: 'Test Book',
      author: 'Test Author',
      coverUrl: null,
      format: null,
      addedDate: DateTime.now().millisecondsSinceEpoch,
      spineConfidence: null,
      reviewNeeded: false,
      spineImagePath: null,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: BookDetailScreen(book: book),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify format and confidence are not displayed
    expect(find.text('FORMAT'), findsNothing);
    expect(find.text('CONFIDENCE'), findsNothing);
  });

  testWidgets('should use spineImagePath when provided', (tester) async {
    // Test that when spineImagePath is provided, the BookDetailScreen
    // uses it (even if the file doesn't exist, it should still attempt to render it)
    final book = Book(
      isbn: '978-0-123456-78-9',
      title: 'Test Book',
      author: 'Test Author',
      coverUrl: null,
      format: null,
      addedDate: DateTime.now().millisecondsSinceEpoch,
      spineConfidence: null,
      reviewNeeded: false,
      spineImagePath: '/some/path/to/spine.jpg',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: BookDetailScreen(book: book),
        ),
      ),
    );

    // Pump once to build the widget
    await tester.pump();

    // Verify the screen renders without crashing
    expect(find.byType(BookDetailScreen), findsOneWidget);
  });

  testWidgets('should handle non-existent spine image gracefully',
      (tester) async {
    final book = Book(
      isbn: '978-0-123456-78-9',
      title: 'Test Book',
      author: 'Test Author',
      coverUrl: null,
      format: null,
      addedDate: DateTime.now().millisecondsSinceEpoch,
      spineConfidence: null,
      reviewNeeded: false,
      spineImagePath: '/non/existent/path/image.jpg',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: BookDetailScreen(book: book),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Should render without crashing
    expect(find.byType(BookDetailScreen), findsOneWidget);
    expect(find.text('Test Book'), findsAtLeastNWidgets(1));
  });
}
