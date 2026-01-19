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

// Review needed filter notifier
class ReviewNeededFilterNotifier extends Notifier<bool?> {
  @override
  bool? build() => null;

  void setFilter(bool? filter) {
    state = filter;
  }

  void toggleNeedsReview() {
    state = state == true ? null : true;
  }
}

final reviewNeededFilterProvider = NotifierProvider<ReviewNeededFilterNotifier, bool?>(
  ReviewNeededFilterNotifier.new,
);

// Sort by review first notifier
class SortReviewFirstNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setSortReviewFirst(bool sort) {
    state = sort;
  }

  void toggle() {
    state = !state;
  }
}

final sortReviewFirstProvider = NotifierProvider<SortReviewFirstNotifier, bool>(
  SortReviewFirstNotifier.new,
);

// Books provider that reacts to search query, filter, and sort
final booksProvider = StreamProvider<List<Book>>((ref) {
  final database = ref.watch(databaseProvider);
  final searchQuery = ref.watch(searchQueryProvider);
  final reviewNeededFilter = ref.watch(reviewNeededFilterProvider);
  final sortReviewFirst = ref.watch(sortReviewFirstProvider);

  return database.searchBooks(
    searchQuery,
    reviewNeeded: reviewNeededFilter,
    sortReviewFirst: sortReviewFirst,
  );
});

// Legacy provider for backward compatibility
final allBooksProvider = StreamProvider<List<Book>>((ref) {
  return ref.watch(booksProvider.future).asStream().asyncExpand((books) => Stream.value(books));
});
