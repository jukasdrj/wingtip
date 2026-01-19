import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/database.dart';
import '../../data/database_provider.dart';
import 'sort_options.dart';
import 'sort_service.dart';
import 'filter_model.dart';

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

// Filter state notifier - persists during session only
class FilterStateNotifier extends Notifier<FilterState> {
  @override
  FilterState build() => const FilterState();

  void setFormat(BookFormat? format) {
    state = state.copyWith(
      format: format,
      clearFormat: format == null,
    );
  }

  void setReviewStatus(ReviewStatus? reviewStatus) {
    state = state.copyWith(
      reviewStatus: reviewStatus,
      clearReviewStatus: reviewStatus == null,
    );
  }

  void setDateRange(DateRange dateRange, {DateTime? customStart, DateTime? customEnd}) {
    state = state.copyWith(
      dateRange: dateRange,
      customStartDate: customStart,
      customEndDate: customEnd,
    );
  }

  void clearFilters() {
    state = state.clear();
  }
}

final filterStateProvider = NotifierProvider<FilterStateNotifier, FilterState>(
  FilterStateNotifier.new,
);

// Sort service provider
final sortServiceProvider = FutureProvider<SortService>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return SortService(prefs);
});

// Sort option notifier
class SortOptionNotifier extends AsyncNotifier<SortOption> {
  @override
  Future<SortOption> build() async {
    final sortService = await ref.watch(sortServiceProvider.future);
    return sortService.sortOption;
  }

  Future<void> setSortOption(SortOption option) async {
    final sortService = await ref.read(sortServiceProvider.future);
    await sortService.setSortOption(option);
    state = AsyncValue.data(option);
  }
}

final sortOptionProvider = AsyncNotifierProvider<SortOptionNotifier, SortOption>(
  SortOptionNotifier.new,
);

// Books provider that reacts to search query, filter, and sort
final booksProvider = StreamProvider<List<Book>>((ref) {
  final database = ref.watch(databaseProvider);
  final searchQuery = ref.watch(searchQueryProvider);
  final reviewNeededFilter = ref.watch(reviewNeededFilterProvider);
  final sortReviewFirst = ref.watch(sortReviewFirstProvider);
  final sortOptionAsync = ref.watch(sortOptionProvider);
  final filterState = ref.watch(filterStateProvider);

  // Use the sort option value when available, otherwise use default
  final sortOption = sortOptionAsync.when(
    data: (option) => option,
    loading: () => SortOption.dateAddedNewest,
    error: (_, stack) => SortOption.dateAddedNewest,
  );

  return database.searchBooks(
    searchQuery,
    reviewNeeded: reviewNeededFilter,
    sortReviewFirst: sortReviewFirst,
    sortOption: sortOption,
    filterState: filterState,
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

// Failed scan select mode notifier
class FailedScanSelectModeNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void enable() {
    state = true;
  }

  void disable() {
    state = false;
    // Clear selected failed scans when exiting select mode
    ref.read(selectedFailedScansProvider.notifier).clear();
  }

  void toggle() {
    state = !state;
    if (!state) {
      ref.read(selectedFailedScansProvider.notifier).clear();
    }
  }
}

final failedScanSelectModeProvider = NotifierProvider<FailedScanSelectModeNotifier, bool>(
  FailedScanSelectModeNotifier.new,
);

// Selected failed scans notifier (uses jobId as identifier)
class SelectedFailedScansNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void toggle(String jobId) {
    if (state.contains(jobId)) {
      state = {...state}..remove(jobId);
    } else {
      state = {...state, jobId};
    }
  }

  void clear() {
    state = {};
  }

  void selectAll(List<String> jobIds) {
    state = {...jobIds};
  }
}

final selectedFailedScansProvider = NotifierProvider<SelectedFailedScansNotifier, Set<String>>(
  SelectedFailedScansNotifier.new,
);
