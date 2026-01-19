import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sort_options.dart';

/// Service for managing library sort preferences
class SortService {
  static const String _sortOptionKey = 'library_sort_option';

  final SharedPreferences _prefs;

  SortService(this._prefs);

  /// Get current sort option preference
  SortOption get sortOption {
    final value = _prefs.getString(_sortOptionKey);
    return SortOption.fromJson(value);
  }

  /// Set sort option preference
  Future<void> setSortOption(SortOption option) async {
    await _prefs.setString(_sortOptionKey, option.toJson());
    debugPrint('[SortService] Sort option set to: ${option.label}');
  }
}
