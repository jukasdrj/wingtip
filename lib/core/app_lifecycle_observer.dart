import 'package:flutter/material.dart';
import 'package:wingtip/services/failed_scans_cleanup_service.dart';

/// Observer for app lifecycle events
/// Handles cleanup tasks on app startup and daily background cleanup
class AppLifecycleObserver extends WidgetsBindingObserver {
  final FailedScansCleanupService _cleanupService;
  DateTime? _lastCleanupDate;

  AppLifecycleObserver(this._cleanupService);

  /// Run cleanup on app startup
  Future<void> onAppStartup() async {
    debugPrint('[AppLifecycle] Running startup cleanup');
    await _cleanupService.runFullCleanup();
    _lastCleanupDate = DateTime.now();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Check if we need to run daily cleanup
      _checkDailyCleanup();
    }
  }

  /// Check if daily cleanup is needed and run it
  Future<void> _checkDailyCleanup() async {
    final now = DateTime.now();

    // If we haven't cleaned up yet, or if it's been more than a day
    if (_lastCleanupDate == null ||
        now.difference(_lastCleanupDate!).inHours >= 24) {
      debugPrint('[AppLifecycle] Running daily cleanup check');
      await _cleanupService.runFullCleanup();
      _lastCleanupDate = now;
    }
  }

  /// Dispose the observer
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }
}
