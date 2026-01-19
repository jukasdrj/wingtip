import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Detects shake gestures from accelerometer data
class ShakeDetector {
  ShakeDetector({
    this.shakeThreshold = 2.7,
    this.shakeDuration = const Duration(milliseconds: 500),
    this.shakeCount = 3,
  });

  /// Threshold for shake detection (G-force)
  final double shakeThreshold;

  /// Duration window for counting shakes
  final Duration shakeDuration;

  /// Number of shakes required to trigger
  final int shakeCount;

  StreamSubscription<AccelerometerEvent>? _streamSubscription;
  final List<int> _shakeTimestamps = [];
  VoidCallback? _onShake;

  /// Start listening for shake gestures
  void startListening(VoidCallback onShake) {
    _onShake = onShake;

    _streamSubscription = accelerometerEventStream().listen(
      _handleAccelerometerEvent,
      onError: (error) {
        debugPrint('[ShakeDetector] Error: $error');
      },
    );
  }

  /// Stop listening for shake gestures
  void stopListening() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _onShake = null;
    _shakeTimestamps.clear();
  }

  void _handleAccelerometerEvent(AccelerometerEvent event) {
    // Calculate total acceleration magnitude
    final gX = event.x / 9.81;
    final gY = event.y / 9.81;
    final gZ = event.z / 9.81;

    final gForce = sqrt(gX * gX + gY * gY + gZ * gZ);

    // Check if acceleration exceeds threshold
    if (gForce > shakeThreshold) {
      final now = DateTime.now().millisecondsSinceEpoch;
      _shakeTimestamps.add(now);

      // Remove old timestamps outside the shake duration window
      _shakeTimestamps.removeWhere(
        (timestamp) => now - timestamp > shakeDuration.inMilliseconds,
      );

      // Trigger shake callback if enough shakes detected
      if (_shakeTimestamps.length >= shakeCount && _onShake != null) {
        _onShake!();
        _shakeTimestamps.clear(); // Reset after triggering
      }
    }
  }

  /// Check if the detector is currently listening
  bool get isListening => _streamSubscription != null;
}
