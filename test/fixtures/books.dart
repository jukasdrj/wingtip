import 'package:wingtip/data/database.dart';

/// Sample books for testing with varied authors, titles, ISBNs, and formats
final testBooks = [
  Book(
    isbn: '978-0-553-41802-6',
    title: 'The Martian',
    author: 'Andy Weir',
    coverUrl: 'https://covers.openlibrary.org/b/isbn/9780553418026-L.jpg',
    format: 'Paperback',
    addedDate: DateTime(2024, 1, 15).millisecondsSinceEpoch,
    spineConfidence: 0.95,
    reviewNeeded: false,
    spineImagePath: '/test/spines/martian.jpg',
  ),
  Book(
    isbn: '978-0-439-70818-8',
    title: 'Harry Potter and the Philosopher\'s Stone',
    author: 'J.K. Rowling',
    coverUrl: 'https://covers.openlibrary.org/b/isbn/9780439708188-L.jpg',
    format: 'Hardcover',
    addedDate: DateTime(2024, 1, 20).millisecondsSinceEpoch,
    spineConfidence: 0.92,
    reviewNeeded: false,
    spineImagePath: '/test/spines/hp1.jpg',
  ),
  Book(
    isbn: '978-0-7432-7356-5',
    title: '1984',
    author: 'George Orwell',
    coverUrl: 'https://covers.openlibrary.org/b/isbn/9780743273565-L.jpg',
    format: 'Paperback',
    addedDate: DateTime(2024, 2, 5).millisecondsSinceEpoch,
    spineConfidence: 0.88,
    reviewNeeded: false,
    spineImagePath: null,
  ),
  Book(
    isbn: '978-0-06-112008-4',
    title: 'To Kill a Mockingbird',
    author: 'Harper Lee',
    coverUrl: 'https://covers.openlibrary.org/b/isbn/9780061120084-L.jpg',
    format: 'Hardcover',
    addedDate: DateTime(2024, 2, 10).millisecondsSinceEpoch,
    spineConfidence: 0.91,
    reviewNeeded: false,
    spineImagePath: '/test/spines/mockingbird.jpg',
  ),
  Book(
    isbn: '978-0-14-028329-5',
    title: 'The Great Gatsby',
    author: 'F. Scott Fitzgerald',
    coverUrl: 'https://covers.openlibrary.org/b/isbn/9780140283295-L.jpg',
    format: 'Paperback',
    addedDate: DateTime(2024, 2, 15).millisecondsSinceEpoch,
    spineConfidence: 0.78,
    reviewNeeded: true,
    spineImagePath: '/test/spines/gatsby.jpg',
  ),
  Book(
    isbn: '978-1-250-30178-7',
    title: 'Project Hail Mary',
    author: 'Andy Weir',
    coverUrl: 'https://covers.openlibrary.org/b/isbn/9781250301789-L.jpg',
    format: 'Hardcover',
    addedDate: DateTime(2024, 3, 1).millisecondsSinceEpoch,
    spineConfidence: 0.96,
    reviewNeeded: false,
    spineImagePath: '/test/spines/hailmary.jpg',
  ),
  Book(
    isbn: '978-0-316-76948-0',
    title: 'The Catcher in the Rye',
    author: 'J.D. Salinger',
    coverUrl: 'https://covers.openlibrary.org/b/isbn/9780316769488-L.jpg',
    format: 'Paperback',
    addedDate: DateTime(2024, 3, 10).millisecondsSinceEpoch,
    spineConfidence: 0.85,
    reviewNeeded: false,
    spineImagePath: null,
  ),
  Book(
    isbn: '978-0-544-27299-6',
    title: 'The Hobbit',
    author: 'J.R.R. Tolkien',
    coverUrl: 'https://covers.openlibrary.org/b/isbn/9780544272996-L.jpg',
    format: 'Hardcover',
    addedDate: DateTime(2024, 3, 15).millisecondsSinceEpoch,
    spineConfidence: 0.93,
    reviewNeeded: false,
    spineImagePath: '/test/spines/hobbit.jpg',
  ),
  Book(
    isbn: '978-0-06-440328-7',
    title: 'Where the Sidewalk Ends',
    author: 'Shel Silverstein',
    coverUrl: 'https://covers.openlibrary.org/b/isbn/9780064403283-L.jpg',
    format: 'Hardcover',
    addedDate: DateTime(2024, 3, 20).millisecondsSinceEpoch,
    spineConfidence: 0.72,
    reviewNeeded: true,
    spineImagePath: '/test/spines/sidewalk.jpg',
  ),
  Book(
    isbn: '978-0-525-47883-5',
    title: 'Dune',
    author: 'Frank Herbert',
    coverUrl: 'https://covers.openlibrary.org/b/isbn/9780525478836-L.jpg',
    format: 'Paperback',
    addedDate: DateTime(2024, 4, 1).millisecondsSinceEpoch,
    spineConfidence: 0.89,
    reviewNeeded: false,
    spineImagePath: '/test/spines/dune.jpg',
  ),
  Book(
    isbn: '978-1-982-11046-0',
    title: 'The Silent Patient',
    author: 'Alex Michaelides',
    coverUrl: 'https://covers.openlibrary.org/b/isbn/9781982110460-L.jpg',
    format: 'Hardcover',
    addedDate: DateTime(2024, 4, 10).millisecondsSinceEpoch,
    spineConfidence: 0.94,
    reviewNeeded: false,
    spineImagePath: '/test/spines/silent.jpg',
  ),
  Book(
    isbn: '978-0-7434-8773-8',
    title: 'Ender\'s Game',
    author: 'Orson Scott Card',
    coverUrl: 'https://covers.openlibrary.org/b/isbn/9780743487733-L.jpg',
    format: 'Paperback',
    addedDate: DateTime(2024, 4, 15).millisecondsSinceEpoch,
    spineConfidence: 0.87,
    reviewNeeded: false,
    spineImagePath: null,
  ),
  Book(
    isbn: '978-0-00-000000-0',
    title: 'Test Book with No Cover',
    author: 'Unknown Author',
    coverUrl: null,
    format: null,
    addedDate: DateTime(2024, 5, 1).millisecondsSinceEpoch,
    spineConfidence: 0.45,
    reviewNeeded: true,
    spineImagePath: null,
  ),
];

/// A single book with high confidence for testing specific scenarios
final highConfidenceBook = testBooks[0]; // The Martian

/// A book that needs review for testing review workflow
final reviewNeededBook = testBooks[4]; // The Great Gatsby

/// A book with no cover URL for testing fallback UI
final noCoverBook = testBooks[12]; // Test Book with No Cover

/// Books by the same author for testing author grouping
final booksByAndyWeir = [testBooks[0], testBooks[5]]; // The Martian, Project Hail Mary

/// Books with different formats for testing format filtering
final hardcoverBooks = testBooks.where((b) => b.format == 'Hardcover').toList();
final paperbackBooks = testBooks.where((b) => b.format == 'Paperback').toList();

/// Books sorted by different criteria for testing sorting
final booksSortedByDateNewest = List<Book>.from(testBooks)
  ..sort((a, b) => b.addedDate.compareTo(a.addedDate));

final booksSortedByTitleAZ = List<Book>.from(testBooks)
  ..sort((a, b) => a.title.compareTo(b.title));

final booksSortedByAuthorAZ = List<Book>.from(testBooks)
  ..sort((a, b) => a.author.compareTo(b.author));

final booksSortedByConfidenceHigh = List<Book>.from(testBooks)
  ..sort((a, b) {
    final confA = a.spineConfidence ?? 0.0;
    final confB = b.spineConfidence ?? 0.0;
    return confB.compareTo(confA);
  });
