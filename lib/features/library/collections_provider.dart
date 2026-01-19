import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database.dart';
import '../../data/database_provider.dart';

// Provider for watching all collections with book counts
final collectionsWithCountsProvider = StreamProvider<List<CollectionWithCount>>((ref) {
  final database = ref.watch(databaseProvider);
  return database.watchCollectionsWithCounts();
});

// Provider for selected collection ID (null means "All Books" view)
class SelectedCollectionNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void setCollection(int? collectionId) {
    state = collectionId;
  }

  void clear() {
    state = null;
  }
}

final selectedCollectionProvider = NotifierProvider<SelectedCollectionNotifier, int?>(
  SelectedCollectionNotifier.new,
);

// Provider for books in selected collection
final collectionBooksProvider = StreamProvider<List<Book>>((ref) {
  final database = ref.watch(databaseProvider);
  final selectedCollectionId = ref.watch(selectedCollectionProvider);

  // If no collection is selected, return an empty stream (will use main booksProvider)
  if (selectedCollectionId == null) {
    return Stream.value([]);
  }

  return database.watchBooksInCollection(selectedCollectionId);
});

// Provider for getting collections for a specific book
final bookCollectionsProvider = FutureProvider.family<List<Collection>, String>((ref, isbn) async {
  final database = ref.watch(databaseProvider);
  return database.getCollectionsForBook(isbn);
});

// Notifier for managing collection operations
class CollectionOperationsNotifier extends Notifier<void> {
  @override
  void build() {}

  AppDatabase get _database => ref.read(databaseProvider);

  Future<int?> createCollection(String name) async {
    try {
      final id = await _database.createCollection(name);
      return id;
    } catch (e) {
      return null;
    }
  }

  Future<void> addBookToCollection(String isbn, int collectionId) async {
    await _database.addBookToCollection(isbn, collectionId);
  }

  Future<void> removeBookFromCollection(String isbn, int collectionId) async {
    await _database.removeBookFromCollection(isbn, collectionId);
  }

  Future<void> deleteCollection(int collectionId) async {
    await _database.deleteCollection(collectionId);
    // Clear selected collection if it was deleted
    if (ref.read(selectedCollectionProvider) == collectionId) {
      ref.read(selectedCollectionProvider.notifier).clear();
    }
  }

  Future<void> renameCollection(int collectionId, String newName) async {
    await _database.renameCollection(collectionId, newName);
  }
}

final collectionOperationsProvider = NotifierProvider<CollectionOperationsNotifier, void>(
  CollectionOperationsNotifier.new,
);
