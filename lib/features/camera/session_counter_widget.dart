import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wingtip/core/theme.dart';
import 'package:wingtip/features/camera/session_counter_provider.dart';

/// Session counter widget with milestone animations
class SessionCounterWidget extends ConsumerStatefulWidget {
  const SessionCounterWidget({super.key});

  @override
  ConsumerState<SessionCounterWidget> createState() => _SessionCounterWidgetState();
}

class _SessionCounterWidgetState extends ConsumerState<SessionCounterWidget>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulseController;
  Animation<double>? _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _setupPulseAnimation();
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    super.dispose();
  }

  void _setupPulseAnimation() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.3)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.3, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_pulseController!);

    _pulseController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Clear milestone flag after animation completes
        ref.read(sessionCounterProvider.notifier).clearMilestone();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final counterState = ref.watch(sessionCounterProvider);

    // Trigger pulse animation on milestone
    ref.listen<SessionCounterState>(sessionCounterProvider, (previous, next) {
      if (next.lastMilestone != null && _pulseController != null) {
        _pulseController!.forward(from: 0.0);
      }
    });

    if (counterState.count == 0) {
      return const SizedBox.shrink();
    }

    final text = _getCounterText(counterState.count);

    return AnimatedBuilder(
      animation: _pulseAnimation ?? const AlwaysStoppedAnimation(1.0),
      builder: (context, child) {
        final scale = _pulseAnimation?.value ?? 1.0;
        return Transform.scale(
          scale: scale,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.oledBlack,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.textPrimary,
                width: 1,
              ),
            ),
            child: Text(
              text,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ),
        );
      },
    );
  }

  String _getCounterText(int count) {
    if (count >= 100) {
      return '$count books scanned!';
    } else if (count >= 50) {
      return '$count books scanned!';
    } else if (count >= 25) {
      return '$count books scanned!';
    } else if (count >= 10) {
      return '$count books scanned!';
    } else {
      return '$count books scanned...';
    }
  }
}
