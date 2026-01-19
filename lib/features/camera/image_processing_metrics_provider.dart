import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wingtip/features/camera/image_processing_metrics.dart';

/// Provider for the image processing metrics notifier
final imageProcessingMetricsNotifierProvider =
    NotifierProvider<ImageProcessingMetricsNotifier, ImageProcessingMetrics>(
  ImageProcessingMetricsNotifier.new,
);

/// Notifier for managing image processing metrics
class ImageProcessingMetricsNotifier extends Notifier<ImageProcessingMetrics> {
  @override
  ImageProcessingMetrics build() {
    return ImageProcessingMetrics.empty;
  }

  /// Record a new processing time
  void recordProcessingTime(int timeMs) {
    final current = state;

    // Update recent times (keep last 10)
    final updatedRecent = [...current.recentTimesMs, timeMs];
    if (updatedRecent.length > 10) {
      updatedRecent.removeAt(0);
    }

    // Update min/max
    final newMin = current.totalProcessed == 0
        ? timeMs
        : (timeMs < current.minTimeMs ? timeMs : current.minTimeMs);
    final newMax = timeMs > current.maxTimeMs ? timeMs : current.maxTimeMs;

    state = ImageProcessingMetrics(
      totalProcessed: current.totalProcessed + 1,
      totalTimeMs: current.totalTimeMs + timeMs,
      minTimeMs: newMin,
      maxTimeMs: newMax,
      recentTimesMs: updatedRecent,
    );
  }

  /// Reset all metrics
  void reset() {
    state = ImageProcessingMetrics.empty;
  }
}
