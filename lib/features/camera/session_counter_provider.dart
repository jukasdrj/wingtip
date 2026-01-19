import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Session counter state
class SessionCounterState {
  final int count;
  final DateTime lastScanAt;
  final int? lastMilestone;

  const SessionCounterState({
    this.count = 0,
    required this.lastScanAt,
    this.lastMilestone,
  });

  SessionCounterState copyWith({
    int? count,
    DateTime? lastScanAt,
    int? lastMilestone,
  }) {
    return SessionCounterState(
      count: count ?? this.count,
      lastScanAt: lastScanAt ?? this.lastScanAt,
      lastMilestone: lastMilestone ?? this.lastMilestone,
    );
  }

  /// Check if idle timeout (5 minutes) has been exceeded
  bool get isIdle {
    return DateTime.now().difference(lastScanAt).inMinutes >= 5;
  }
}

/// Notifier for managing session scan counter
class SessionCounterNotifier extends Notifier<SessionCounterState> {
  Timer? _idleCheckTimer;

  @override
  SessionCounterState build() {
    // Start idle check timer
    _startIdleCheckTimer();

    // Clean up timer when notifier is disposed
    ref.onDispose(() {
      _idleCheckTimer?.cancel();
    });

    return SessionCounterState(lastScanAt: DateTime.now());
  }

  /// Start periodic timer to check for idle timeout
  void _startIdleCheckTimer() {
    _idleCheckTimer?.cancel();
    _idleCheckTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (state.isIdle && state.count > 0) {
        debugPrint('[SessionCounter] Idle timeout exceeded, resetting counter');
        reset();
      }
    });
  }

  /// Increment counter on successful scan
  void increment() {
    final newCount = state.count + 1;
    final milestones = [10, 25, 50, 100];
    final lastMilestone = milestones.contains(newCount) ? newCount : null;

    debugPrint('[SessionCounter] Incrementing to $newCount${lastMilestone != null ? ' (MILESTONE!)' : ''}');

    state = state.copyWith(
      count: newCount,
      lastScanAt: DateTime.now(),
      lastMilestone: lastMilestone,
    );
  }

  /// Reset counter (called on app background or idle timeout)
  void reset() {
    debugPrint('[SessionCounter] Resetting counter from ${state.count} to 0');
    state = SessionCounterState(lastScanAt: DateTime.now());
  }

  /// Clear the last milestone flag (after animation completes)
  void clearMilestone() {
    if (state.lastMilestone != null) {
      state = state.copyWith(lastMilestone: null);
    }
  }
}

/// Provider for session counter
final sessionCounterProvider =
    NotifierProvider<SessionCounterNotifier, SessionCounterState>(
  SessionCounterNotifier.new,
);
