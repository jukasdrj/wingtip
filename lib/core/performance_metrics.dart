/// Performance metrics data model
class PerformanceMetrics {
  final int coldStartTimeMs;
  final int shutterLatencyMs;
  final int avgUploadTimeMs;
  final int avgSseFirstResultTimeMs;
  final int frameDropCount;

  const PerformanceMetrics({
    required this.coldStartTimeMs,
    required this.shutterLatencyMs,
    required this.avgUploadTimeMs,
    required this.avgSseFirstResultTimeMs,
    required this.frameDropCount,
  });

  // Targets from PRD
  static const int coldStartTargetMs = 1000;
  static const int shutterLatencyTargetMs = 50;

  bool get meetsColdStartTarget => coldStartTimeMs < coldStartTargetMs;
  bool get meetsShutterLatencyTarget => shutterLatencyMs < shutterLatencyTargetMs;

  factory PerformanceMetrics.empty() {
    return const PerformanceMetrics(
      coldStartTimeMs: 0,
      shutterLatencyMs: 0,
      avgUploadTimeMs: 0,
      avgSseFirstResultTimeMs: 0,
      frameDropCount: 0,
    );
  }

  PerformanceMetrics copyWith({
    int? coldStartTimeMs,
    int? shutterLatencyMs,
    int? avgUploadTimeMs,
    int? avgSseFirstResultTimeMs,
    int? frameDropCount,
  }) {
    return PerformanceMetrics(
      coldStartTimeMs: coldStartTimeMs ?? this.coldStartTimeMs,
      shutterLatencyMs: shutterLatencyMs ?? this.shutterLatencyMs,
      avgUploadTimeMs: avgUploadTimeMs ?? this.avgUploadTimeMs,
      avgSseFirstResultTimeMs: avgSseFirstResultTimeMs ?? this.avgSseFirstResultTimeMs,
      frameDropCount: frameDropCount ?? this.frameDropCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'coldStartTimeMs': coldStartTimeMs,
      'shutterLatencyMs': shutterLatencyMs,
      'avgUploadTimeMs': avgUploadTimeMs,
      'avgSseFirstResultTimeMs': avgSseFirstResultTimeMs,
      'frameDropCount': frameDropCount,
    };
  }

  factory PerformanceMetrics.fromJson(Map<String, dynamic> json) {
    return PerformanceMetrics(
      coldStartTimeMs: json['coldStartTimeMs'] as int? ?? 0,
      shutterLatencyMs: json['shutterLatencyMs'] as int? ?? 0,
      avgUploadTimeMs: json['avgUploadTimeMs'] as int? ?? 0,
      avgSseFirstResultTimeMs: json['avgSseFirstResultTimeMs'] as int? ?? 0,
      frameDropCount: json['frameDropCount'] as int? ?? 0,
    );
  }
}
