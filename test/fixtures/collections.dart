import 'package:wingtip/data/database.dart';

/// Sample collections for testing
final testCollections = [
  Collection(
    id: 1,
    name: 'To Read',
    createdAt: DateTime(2024, 1, 1).millisecondsSinceEpoch,
  ),
  Collection(
    id: 2,
    name: 'Favorites',
    createdAt: DateTime(2024, 1, 5).millisecondsSinceEpoch,
  ),
  Collection(
    id: 3,
    name: 'Sci-Fi',
    createdAt: DateTime(2024, 1, 10).millisecondsSinceEpoch,
  ),
  Collection(
    id: 4,
    name: 'Classics',
    createdAt: DateTime(2024, 1, 15).millisecondsSinceEpoch,
  ),
  Collection(
    id: 5,
    name: 'Summer Reading 2024',
    createdAt: DateTime(2024, 1, 20).millisecondsSinceEpoch,
  ),
];

/// Sample book-collection associations for testing many-to-many relationships
/// These map test books (by ISBN) to collections
final testBookCollections = [
  // The Martian in Sci-Fi and Favorites
  BookCollection(
    isbn: '978-0-553-41802-6',
    collectionId: 2, // Favorites
    addedAt: DateTime(2024, 1, 16).millisecondsSinceEpoch,
  ),
  BookCollection(
    isbn: '978-0-553-41802-6',
    collectionId: 3, // Sci-Fi
    addedAt: DateTime(2024, 1, 16).millisecondsSinceEpoch,
  ),
  // Harry Potter in To Read and Favorites
  BookCollection(
    isbn: '978-0-439-70818-8',
    collectionId: 1, // To Read
    addedAt: DateTime(2024, 1, 21).millisecondsSinceEpoch,
  ),
  BookCollection(
    isbn: '978-0-439-70818-8',
    collectionId: 2, // Favorites
    addedAt: DateTime(2024, 1, 21).millisecondsSinceEpoch,
  ),
  // 1984 in Classics and To Read
  BookCollection(
    isbn: '978-0-7432-7356-5',
    collectionId: 1, // To Read
    addedAt: DateTime(2024, 2, 6).millisecondsSinceEpoch,
  ),
  BookCollection(
    isbn: '978-0-7432-7356-5',
    collectionId: 4, // Classics
    addedAt: DateTime(2024, 2, 6).millisecondsSinceEpoch,
  ),
  // To Kill a Mockingbird in Classics
  BookCollection(
    isbn: '978-0-06-112008-4',
    collectionId: 4, // Classics
    addedAt: DateTime(2024, 2, 11).millisecondsSinceEpoch,
  ),
  // The Great Gatsby in Classics and Summer Reading
  BookCollection(
    isbn: '978-0-14-028329-5',
    collectionId: 4, // Classics
    addedAt: DateTime(2024, 2, 16).millisecondsSinceEpoch,
  ),
  BookCollection(
    isbn: '978-0-14-028329-5',
    collectionId: 5, // Summer Reading 2024
    addedAt: DateTime(2024, 2, 16).millisecondsSinceEpoch,
  ),
  // Project Hail Mary in Sci-Fi and Favorites
  BookCollection(
    isbn: '978-1-250-30178-7',
    collectionId: 2, // Favorites
    addedAt: DateTime(2024, 3, 2).millisecondsSinceEpoch,
  ),
  BookCollection(
    isbn: '978-1-250-30178-7',
    collectionId: 3, // Sci-Fi
    addedAt: DateTime(2024, 3, 2).millisecondsSinceEpoch,
  ),
  // Dune in Sci-Fi
  BookCollection(
    isbn: '978-0-525-47883-5',
    collectionId: 3, // Sci-Fi
    addedAt: DateTime(2024, 4, 2).millisecondsSinceEpoch,
  ),
  // The Catcher in the Rye in Classics
  BookCollection(
    isbn: '978-0-316-76948-0',
    collectionId: 4, // Classics
    addedAt: DateTime(2024, 3, 11).millisecondsSinceEpoch,
  ),
];

/// Individual collections for specific test scenarios
final toReadCollection = testCollections[0];
final favoritesCollection = testCollections[1];
final sciFiCollection = testCollections[2];
final classicsCollection = testCollections[3];
final summerReadingCollection = testCollections[4];

/// Collections with expected book counts for testing
final collectionsWithCounts = [
  CollectionWithCount(
    id: 1,
    name: 'To Read',
    createdAt: DateTime(2024, 1, 1).millisecondsSinceEpoch,
    bookCount: 2, // Harry Potter, 1984
  ),
  CollectionWithCount(
    id: 2,
    name: 'Favorites',
    createdAt: DateTime(2024, 1, 5).millisecondsSinceEpoch,
    bookCount: 3, // The Martian, Harry Potter, Project Hail Mary
  ),
  CollectionWithCount(
    id: 3,
    name: 'Sci-Fi',
    createdAt: DateTime(2024, 1, 10).millisecondsSinceEpoch,
    bookCount: 3, // The Martian, Project Hail Mary, Dune
  ),
  CollectionWithCount(
    id: 4,
    name: 'Classics',
    createdAt: DateTime(2024, 1, 15).millisecondsSinceEpoch,
    bookCount: 4, // 1984, To Kill a Mockingbird, The Great Gatsby, The Catcher in the Rye
  ),
  CollectionWithCount(
    id: 5,
    name: 'Summer Reading 2024',
    createdAt: DateTime(2024, 1, 20).millisecondsSinceEpoch,
    bookCount: 1, // The Great Gatsby
  ),
];

/// Books in the Sci-Fi collection (for testing collection filtering)
final sciFiBookISBNs = [
  '978-0-553-41802-6', // The Martian
  '978-1-250-30178-7', // Project Hail Mary
  '978-0-525-47883-5', // Dune
];

/// Books in the Classics collection (for testing collection filtering)
final classicsBookISBNs = [
  '978-0-7432-7356-5', // 1984
  '978-0-06-112008-4', // To Kill a Mockingbird
  '978-0-14-028329-5', // The Great Gatsby
  '978-0-316-76948-0', // The Catcher in the Rye
];

/// Books in multiple collections (for testing many-to-many relationships)
final booksInMultipleCollections = [
  '978-0-553-41802-6', // The Martian (Favorites, Sci-Fi)
  '978-0-439-70818-8', // Harry Potter (To Read, Favorites)
  '978-0-7432-7356-5', // 1984 (To Read, Classics)
  '978-0-14-028329-5', // The Great Gatsby (Classics, Summer Reading)
  '978-1-250-30178-7', // Project Hail Mary (Favorites, Sci-Fi)
];

/// Helper function to create a new collection for testing
Collection createCollection({
  required int id,
  required String name,
  DateTime? createdAt,
}) {
  return Collection(
    id: id,
    name: name,
    createdAt: (createdAt ?? DateTime.now()).millisecondsSinceEpoch,
  );
}

/// Helper function to create a book-collection association for testing
BookCollection createBookCollection({
  required String isbn,
  required int collectionId,
  DateTime? addedAt,
}) {
  return BookCollection(
    isbn: isbn,
    collectionId: collectionId,
    addedAt: (addedAt ?? DateTime.now()).millisecondsSinceEpoch,
  );
}
