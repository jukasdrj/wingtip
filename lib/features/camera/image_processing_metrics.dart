/// Metrics for image processing performance
class ImageProcessingMetrics {
  final int totalProcessed;
  final int totalTimeMs;
  final int minTimeMs;
  final int maxTimeMs;
  final List<int> recentTimesMs; // Last 10 processing times

  const ImageProcessingMetrics({
    required this.totalProcessed,
    required this.totalTimeMs,
    required this.minTimeMs,
    required this.maxTimeMs,
    required this.recentTimesMs,
  });

  /// Average processing time in milliseconds
  double get averageTimeMs =>
      totalProcessed > 0 ? totalTimeMs / totalProcessed : 0.0;

  /// Average of recent processing times (more relevant for current performance)
  double get recentAverageTimeMs {
    if (recentTimesMs.isEmpty) return 0.0;
    return recentTimesMs.reduce((a, b) => a + b) / recentTimesMs.length;
  }

  /// Check if processing meets performance target (< 500ms average)
  bool get meetsTargetPerformance => averageTimeMs < 500;

  ImageProcessingMetrics copyWith({
    int? totalProcessed,
    int? totalTimeMs,
    int? minTimeMs,
    int? maxTimeMs,
    List<int>? recentTimesMs,
  }) {
    return ImageProcessingMetrics(
      totalProcessed: totalProcessed ?? this.totalProcessed,
      totalTimeMs: totalTimeMs ?? this.totalTimeMs,
      minTimeMs: minTimeMs ?? this.minTimeMs,
      maxTimeMs: maxTimeMs ?? this.maxTimeMs,
      recentTimesMs: recentTimesMs ?? this.recentTimesMs,
    );
  }

  static const empty = ImageProcessingMetrics(
    totalProcessed: 0,
    totalTimeMs: 0,
    minTimeMs: 0,
    maxTimeMs: 0,
    recentTimesMs: [],
  );
}
