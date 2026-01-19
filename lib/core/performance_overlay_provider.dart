import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for toggling Flutter Performance Overlay
/// Enables visual debugging of frame rendering and rasterization
/// on ProMotion displays
final performanceOverlayProvider = NotifierProvider<PerformanceOverlayNotifier, bool>(
  PerformanceOverlayNotifier.new,
);

class PerformanceOverlayNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() {
    state = !state;
  }

  void enable() {
    state = true;
  }

  void disable() {
    state = false;
  }
}
