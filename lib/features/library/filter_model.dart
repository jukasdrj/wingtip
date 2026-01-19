/// Model class representing the current filter state for the library
class FilterState {
  final BookFormat? format;
  final ReviewStatus? reviewStatus;
  final DateRange dateRange;
  final DateTime? customStartDate;
  final DateTime? customEndDate;

  const FilterState({
    this.format,
    this.reviewStatus,
    this.dateRange = DateRange.allTime,
    this.customStartDate,
    this.customEndDate,
  });

  /// Returns true if any filters are active (not default state)
  bool get hasActiveFilters =>
      format != null ||
      reviewStatus != null ||
      dateRange != DateRange.allTime;

  /// Returns the count of active filters for badge display
  int get activeFilterCount {
    int count = 0;
    if (format != null) count++;
    if (reviewStatus != null) count++;
    if (dateRange != DateRange.allTime) count++;
    return count;
  }

  FilterState copyWith({
    BookFormat? format,
    ReviewStatus? reviewStatus,
    DateRange? dateRange,
    DateTime? customStartDate,
    DateTime? customEndDate,
    bool clearFormat = false,
    bool clearReviewStatus = false,
  }) {
    return FilterState(
      format: clearFormat ? null : format ?? this.format,
      reviewStatus: clearReviewStatus ? null : reviewStatus ?? this.reviewStatus,
      dateRange: dateRange ?? this.dateRange,
      customStartDate: customStartDate ?? this.customStartDate,
      customEndDate: customEndDate ?? this.customEndDate,
    );
  }

  /// Resets all filters to default state
  FilterState clear() {
    return const FilterState(
      format: null,
      reviewStatus: null,
      dateRange: DateRange.allTime,
      customStartDate: null,
      customEndDate: null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FilterState &&
          runtimeType == other.runtimeType &&
          format == other.format &&
          reviewStatus == other.reviewStatus &&
          dateRange == other.dateRange &&
          customStartDate == other.customStartDate &&
          customEndDate == other.customEndDate;

  @override
  int get hashCode =>
      format.hashCode ^
      reviewStatus.hashCode ^
      dateRange.hashCode ^
      customStartDate.hashCode ^
      customEndDate.hashCode;
}

/// Book format options for filtering
enum BookFormat {
  hardcover,
  paperback,
  ebook;

  String get label {
    switch (this) {
      case BookFormat.hardcover:
        return 'Hardcover';
      case BookFormat.paperback:
        return 'Paperback';
      case BookFormat.ebook:
        return 'eBook';
    }
  }

  /// Matches database format strings (case-insensitive)
  bool matches(String? dbFormat) {
    if (dbFormat == null) return false;
    final normalized = dbFormat.toLowerCase().trim();
    switch (this) {
      case BookFormat.hardcover:
        return normalized.contains('hard');
      case BookFormat.paperback:
        return normalized.contains('paper') || normalized.contains('soft');
      case BookFormat.ebook:
        return normalized.contains('ebook') ||
            normalized.contains('e-book') ||
            normalized.contains('digital') ||
            normalized.contains('kindle');
    }
  }
}

/// Review status options for filtering
enum ReviewStatus {
  needsReview,
  verified;

  String get label {
    switch (this) {
      case ReviewStatus.needsReview:
        return 'Needs Review';
      case ReviewStatus.verified:
        return 'Verified';
    }
  }

  bool get reviewNeededValue => this == ReviewStatus.needsReview;
}

/// Date range options for filtering
enum DateRange {
  allTime,
  lastWeek,
  lastMonth,
  custom;

  String get label {
    switch (this) {
      case DateRange.allTime:
        return 'All Time';
      case DateRange.lastWeek:
        return 'Last Week';
      case DateRange.lastMonth:
        return 'Last Month';
      case DateRange.custom:
        return 'Custom';
    }
  }

  /// Returns the start timestamp in milliseconds for this date range
  /// Returns null for allTime (no filtering)
  int? getStartTimestamp() {
    final now = DateTime.now();
    switch (this) {
      case DateRange.allTime:
        return null;
      case DateRange.lastWeek:
        return now.subtract(const Duration(days: 7)).millisecondsSinceEpoch;
      case DateRange.lastMonth:
        return now.subtract(const Duration(days: 30)).millisecondsSinceEpoch;
      case DateRange.custom:
        return null; // Custom range uses customStartDate/customEndDate
    }
  }
}
