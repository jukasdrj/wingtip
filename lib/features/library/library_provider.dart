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

// Select mode notifier
class SelectModeNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void enable() {
    state = true;
  }

  void disable() {
    state = false;
    // Clear selected books when exiting select mode
    ref.read(selectedBooksProvider.notifier).clear();
  }

  void toggle() {
    state = !state;
    if (!state) {
      ref.read(selectedBooksProvider.notifier).clear();
    }
  }
}

final selectModeProvider = NotifierProvider<SelectModeNotifier, bool>(
  SelectModeNotifier.new,
);

// Selected books notifier
class SelectedBooksNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void toggle(String isbn) {
    if (state.contains(isbn)) {
      state = {...state}..remove(isbn);
    } else {
      state = {...state, isbn};
    }
  }

  void clear() {
    state = {};
  }

  void selectAll(List<String> isbns) {
    state = {...isbns};
  }
}

final selectedBooksProvider = NotifierProvider<SelectedBooksNotifier, Set<String>>(
  SelectedBooksNotifier.new,
);
