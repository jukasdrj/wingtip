import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Retention period options for failed scans
enum FailedScanRetention {
  threeDays(3, '3 days'),
  sevenDays(7, '7 days'),
  fourteenDays(14, '14 days'),
  thirtyDays(30, '30 days'),
  never(-1, 'Never');

  const FailedScanRetention(this.days, this.label);

  final int days;
  final String label;

  Duration? get duration {
    if (days == -1) return null;
    return Duration(days: days);
  }

  static FailedScanRetention fromDays(int days) {
    return FailedScanRetention.values.firstWhere(
      (e) => e.days == days,
      orElse: () => FailedScanRetention.sevenDays,
    );
  }
}

/// Service for managing failed scan retention preferences
class FailedScanRetentionService {
  static const String _retentionKey = 'failed_scan_retention_days';

  final SharedPreferences _prefs;

  FailedScanRetentionService(this._prefs);

  /// Get the current retention preference
  FailedScanRetention getRetention() {
    final days = _prefs.getInt(_retentionKey) ?? 7; // Default to 7 days
    return FailedScanRetention.fromDays(days);
  }

  /// Set the retention preference
  Future<void> setRetention(FailedScanRetention retention) async {
    await _prefs.setInt(_retentionKey, retention.days);
  }

  /// Get the retention duration for use in database operations
  Duration getRetentionDuration() {
    final retention = getRetention();
    // If "Never", use a very long duration (10 years)
    return retention.duration ?? const Duration(days: 3650);
  }
}

/// Provider for SharedPreferences instance
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

/// Provider for FailedScanRetentionService
final failedScanRetentionServiceProvider = Provider<FailedScanRetentionService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider).value;
  if (prefs == null) {
    throw Exception('SharedPreferences not initialized');
  }
  return FailedScanRetentionService(prefs);
});

/// Stream provider to watch retention changes
final failedScanRetentionProvider = StreamProvider<FailedScanRetention>((ref) {
  final service = ref.watch(failedScanRetentionServiceProvider);

  // Create a stream that emits the current value immediately
  // In a real app, we'd listen to SharedPreferences changes, but for simplicity
  // we'll just emit the current value
  return Stream.value(service.getRetention());
});
