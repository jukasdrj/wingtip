import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Matrix-style SSE stream overlay for displaying real-time analysis messages
class StreamOverlay extends StatefulWidget {
  final String? message;
  final VoidCallback? onDismiss;

  const StreamOverlay({
    super.key,
    this.message,
    this.onDismiss,
  });

  @override
  State<StreamOverlay> createState() => _StreamOverlayState();
}

class _StreamOverlayState extends State<StreamOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  Timer? _autoDismissTimer;
  String? _displayedMessage;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic, // iOS-native curve for 120Hz
      reverseCurve: Curves.easeInCubic,
    );

    if (widget.message != null) {
      _displayedMessage = widget.message;
      _animationController.forward();
      _scheduleAutoDismiss();
    }
  }

  @override
  void didUpdateWidget(StreamOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle message changes
    if (widget.message != oldWidget.message) {
      _autoDismissTimer?.cancel();

      if (widget.message != null) {
        // New message arrived
        _displayedMessage = widget.message;
        _animationController.forward();
        _scheduleAutoDismiss();
      } else if (oldWidget.message != null) {
        // Message cleared - fade out
        _animationController.reverse().then((_) {
          if (mounted) {
            setState(() {
              _displayedMessage = null;
            });
          }
        });
      }
    }
  }

  void _scheduleAutoDismiss() {
    _autoDismissTimer?.cancel();
    _autoDismissTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _animationController.reverse().then((_) {
          if (mounted) {
            widget.onDismiss?.call();
          }
        });
      }
    });
  }

  void _handleTap() {
    _autoDismissTimer?.cancel();
    _animationController.reverse().then((_) {
      if (mounted) {
        widget.onDismiss?.call();
      }
    });
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_displayedMessage == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: GestureDetector(
          onTap: _handleTap,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF00FF00).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                _displayedMessage!,
                style: GoogleFonts.jetBrainsMono(
                  color: const Color(0xFF00FF00),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
