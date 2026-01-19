/// Sort options for library books
enum SortOption {
  dateAddedNewest,
  dateAddedOldest,
  titleAZ,
  titleZA,
  authorAZ,
  authorZA,
  spineConfidenceHigh,
  spineConfidenceLow;

  String get label {
    switch (this) {
      case SortOption.dateAddedNewest:
        return 'Date Added (Newest)';
      case SortOption.dateAddedOldest:
        return 'Date Added (Oldest)';
      case SortOption.titleAZ:
        return 'Title (A-Z)';
      case SortOption.titleZA:
        return 'Title (Z-A)';
      case SortOption.authorAZ:
        return 'Author (A-Z)';
      case SortOption.authorZA:
        return 'Author (Z-A)';
      case SortOption.spineConfidenceHigh:
        return 'Confidence (High-Low)';
      case SortOption.spineConfidenceLow:
        return 'Confidence (Low-High)';
    }
  }

  String get shortLabel {
    switch (this) {
      case SortOption.dateAddedNewest:
        return 'Newest First';
      case SortOption.dateAddedOldest:
        return 'Oldest First';
      case SortOption.titleAZ:
        return 'Title A-Z';
      case SortOption.titleZA:
        return 'Title Z-A';
      case SortOption.authorAZ:
        return 'Author A-Z';
      case SortOption.authorZA:
        return 'Author Z-A';
      case SortOption.spineConfidenceHigh:
        return 'High Confidence';
      case SortOption.spineConfidenceLow:
        return 'Low Confidence';
    }
  }

  /// Serialize to string for SharedPreferences
  String toJson() => name;

  /// Deserialize from string
  static SortOption fromJson(String? value) {
    if (value == null) return SortOption.dateAddedNewest;
    return SortOption.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SortOption.dateAddedNewest,
    );
  }
}
