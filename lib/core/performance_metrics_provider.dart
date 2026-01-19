import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wingtip/core/performance_metrics.dart';
import 'package:wingtip/core/performance_metrics_service.dart';
import 'package:wingtip/services/failed_scan_retention_service.dart';

/// Provider for PerformanceMetricsService
final performanceMetricsServiceProvider = Provider<PerformanceMetricsService>((ref) {
  final prefsAsync = ref.watch(sharedPreferencesProvider);

  return prefsAsync.when(
    data: (prefs) => PerformanceMetricsService(prefs),
    loading: () => throw StateError('SharedPreferences not loaded yet'),
    error: (error, stack) => throw error,
  );
});

/// Provider for current performance metrics
final performanceMetricsProvider = Provider<PerformanceMetrics>((ref) {
  final service = ref.watch(performanceMetricsServiceProvider);
  return service.getMetrics();
});
