import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wingtip/core/performance_metrics.dart';

/// Service for tracking and persisting performance metrics
class PerformanceMetricsService {
  static const String _coldStartKey = 'perf_cold_start_ms';
  static const String _coldStartHistoryKey = 'perf_cold_start_history'; // New: track last 20 cold starts
  static const String _shutterLatenciesKey = 'perf_shutter_latencies';
  static const String _uploadTimesKey = 'perf_upload_times';
  static const String _sseFirstResultTimesKey = 'perf_sse_first_result_times';
  static const String _frameDropCountKey = 'perf_frame_drop_count';

  final SharedPreferences _prefs;

  PerformanceMetricsService(this._prefs);

  /// Record cold start time with historical tracking
  Future<void> recordColdStart(int durationMs) async {
    await _prefs.setInt(_coldStartKey, durationMs);

    // Track historical cold start times
    final history = _getIntList(_coldStartHistoryKey);
    history.add(durationMs);

    // Keep only last 20 measurements
    if (history.length > 20) {
      history.removeRange(0, history.length - 20);
    }

    await _prefs.setString(_coldStartHistoryKey, jsonEncode(history));

    // Calculate statistics
    final avgColdStart = history.isEmpty ? durationMs : _average(history);
    final minColdStart = history.isEmpty ? durationMs : history.reduce((a, b) => a < b ? a : b);
    final maxColdStart = history.isEmpty ? durationMs : history.reduce((a, b) => a > b ? a : b);

    debugPrint('[PerformanceMetrics] Cold start: ${durationMs}ms (avg: ${avgColdStart.toStringAsFixed(0)}ms, min: ${minColdStart}ms, max: ${maxColdStart}ms over ${history.length} launches)');
  }

  /// Record shutter latency
  Future<void> recordShutterLatency(int latencyMs) async {
    final latencies = _getIntList(_shutterLatenciesKey);
    latencies.add(latencyMs);

    // Keep only last 50 measurements
    if (latencies.length > 50) {
      latencies.removeRange(0, latencies.length - 50);
    }

    await _prefs.setString(_shutterLatenciesKey, jsonEncode(latencies));
    debugPrint('[PerformanceMetrics] Shutter latency: ${latencyMs}ms (avg: ${_average(latencies).toStringAsFixed(1)}ms)');
  }

  /// Record upload time
  Future<void> recordUploadTime(int durationMs) async {
    final times = _getIntList(_uploadTimesKey);
    times.add(durationMs);

    // Keep only last 50 measurements
    if (times.length > 50) {
      times.removeRange(0, times.length - 50);
    }

    await _prefs.setString(_uploadTimesKey, jsonEncode(times));
    debugPrint('[PerformanceMetrics] Upload time: ${durationMs}ms (avg: ${_average(times).toStringAsFixed(1)}ms)');
  }

  /// Record SSE first result time
  Future<void> recordSseFirstResultTime(int durationMs) async {
    final times = _getIntList(_sseFirstResultTimesKey);
    times.add(durationMs);

    // Keep only last 50 measurements
    if (times.length > 50) {
      times.removeRange(0, times.length - 50);
    }

    await _prefs.setString(_sseFirstResultTimesKey, jsonEncode(times));
    debugPrint('[PerformanceMetrics] SSE first result: ${durationMs}ms (avg: ${_average(times).toStringAsFixed(1)}ms)');
  }

  /// Increment frame drop counter
  Future<void> recordFrameDrop() async {
    final currentCount = _prefs.getInt(_frameDropCountKey) ?? 0;
    await _prefs.setInt(_frameDropCountKey, currentCount + 1);
  }

  /// Get current metrics
  PerformanceMetrics getMetrics() {
    final coldStart = _prefs.getInt(_coldStartKey) ?? 0;
    final shutterLatencies = _getIntList(_shutterLatenciesKey);
    final uploadTimes = _getIntList(_uploadTimesKey);
    final sseFirstResultTimes = _getIntList(_sseFirstResultTimesKey);
    final frameDropCount = _prefs.getInt(_frameDropCountKey) ?? 0;

    return PerformanceMetrics(
      coldStartTimeMs: coldStart,
      shutterLatencyMs: shutterLatencies.isEmpty ? 0 : _average(shutterLatencies).round(),
      avgUploadTimeMs: uploadTimes.isEmpty ? 0 : _average(uploadTimes).round(),
      avgSseFirstResultTimeMs: sseFirstResultTimes.isEmpty ? 0 : _average(sseFirstResultTimes).round(),
      frameDropCount: frameDropCount,
    );
  }

  /// Reset all metrics
  Future<void> resetMetrics() async {
    await _prefs.remove(_coldStartKey);
    await _prefs.remove(_coldStartHistoryKey);
    await _prefs.remove(_shutterLatenciesKey);
    await _prefs.remove(_uploadTimesKey);
    await _prefs.remove(_sseFirstResultTimesKey);
    await _prefs.remove(_frameDropCountKey);
    debugPrint('[PerformanceMetrics] All metrics reset');
  }

  List<int> _getIntList(String key) {
    final jsonString = _prefs.getString(key);
    if (jsonString == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.cast<int>();
    } catch (e) {
      debugPrint('[PerformanceMetrics] Error decoding $key: $e');
      return [];
    }
  }

  double _average(List<int> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }
}
