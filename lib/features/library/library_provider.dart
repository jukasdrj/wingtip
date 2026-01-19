import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database.dart';
import '../../data/database_provider.dart';

// Search query notifier
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

// Books provider that reacts to search query
final booksProvider = StreamProvider<List<Book>>((ref) {
  final database = ref.watch(databaseProvider);
  final searchQuery = ref.watch(searchQueryProvider);

  return database.searchBooks(searchQuery);
});

// Legacy provider for backward compatibility
final allBooksProvider = StreamProvider<List<Book>>((ref) {
  return ref.watch(booksProvider.future).asStream().asyncExpand((books) => Stream.value(books));
});
