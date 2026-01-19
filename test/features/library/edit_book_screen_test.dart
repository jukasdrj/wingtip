import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wingtip/core/theme.dart';
import 'package:wingtip/data/database.dart';
import 'package:wingtip/data/database_provider.dart';
import 'package:wingtip/features/library/edit_book_screen.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.test(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  testWidgets('should display book data in form fields', (tester) async {
    final book = Book(
      isbn: '978-0-123456-78-9',
      title: 'Test Book',
      author: 'Test Author',
      coverUrl: null,
      format: 'Hardcover',
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
          home: EditBookScreen(book: book),
        ),
      ),
    );

    // Wait for the widget to settle
    await tester.pumpAndSettle();

    // Verify form fields are populated
    expect(find.text('Test Book'), findsOneWidget);
    expect(find.text('Test Author'), findsOneWidget);
    expect(find.text('978-0-123456-78-9'), findsOneWidget);
    expect(find.text('Hardcover'), findsOneWidget);
  });

  testWidgets('should show validation errors for empty required fields',
      (tester) async {
    final book = Book(
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
          home: EditBookScreen(book: book),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Clear title field
    final titleField = find.widgetWithText(TextFormField, 'Test Book');
    await tester.enterText(titleField, '');

    // Tap save button
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Verify validation error is shown
    expect(find.text('Title is required'), findsOneWidget);
  });

  testWidgets('should update book and navigate back on successful save',
      (tester) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    // Insert test book
    await database.into(database.books).insert(
          BooksCompanion(
            isbn: const Value('978-0-123456-78-9'),
            title: const Value('Original Title'),
            author: const Value('Original Author'),
            format: const Value('Hardcover'),
            addedDate: Value(now),
            reviewNeeded: const Value(true),
          ),
        );

    final book = Book(
      isbn: '978-0-123456-78-9',
      title: 'Original Title',
      author: 'Original Author',
      coverUrl: null,
      format: 'Hardcover',
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
          home: EditBookScreen(book: book),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Update title
    final titleField = find.widgetWithText(TextFormField, 'Original Title');
    await tester.enterText(titleField, 'Updated Title');
    await tester.pumpAndSettle();

    // Tap save
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Verify book was updated in database
    final books = await database.select(database.books).get();
    expect(books.length, 1);
    expect(books.first.title, 'Updated Title');
    expect(books.first.reviewNeeded, false);
  });

  testWidgets('should handle optional format field', (tester) async {
    final now = DateTime.now().millisecondsSinceEpoch;

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
          home: EditBookScreen(book: book),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Leave format empty and save
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Verify book was saved with null format
    final books = await database.select(database.books).get();
    expect(books.first.format, isNull);
  });

  testWidgets('should display Edit Book title', (tester) async {
    final book = Book(
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
          home: EditBookScreen(book: book),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Edit Book'), findsOneWidget);
  });

  testWidgets('should close screen when close button is tapped', (tester) async {
    final book = Book(
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
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EditBookScreen(book: book),
                    ),
                  );
                },
                child: const Text('Open Edit'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Open edit screen
    await tester.tap(find.text('Open Edit'));
    await tester.pumpAndSettle();

    // Tap close button
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    // Verify we're back to the original screen
    expect(find.text('Open Edit'), findsOneWidget);
    expect(find.text('Edit Book'), findsNothing);
  });
}
