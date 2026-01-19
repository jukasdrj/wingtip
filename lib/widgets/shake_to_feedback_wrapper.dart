import 'package:flutter/material.dart';
import 'package:wingtip/core/shake_detector.dart';
import 'package:wingtip/widgets/feedback_dialog.dart';

/// Wraps a widget tree with shake detection to show feedback dialog
class ShakeToFeedbackWrapper extends StatefulWidget {
  const ShakeToFeedbackWrapper({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<ShakeToFeedbackWrapper> createState() => _ShakeToFeedbackWrapperState();
}

class _ShakeToFeedbackWrapperState extends State<ShakeToFeedbackWrapper>
    with WidgetsBindingObserver {
  final ShakeDetector _shakeDetector = ShakeDetector();
  bool _isDialogOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _shakeDetector.startListening(_onShakeDetected);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _shakeDetector.stopListening();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause shake detection when app is in background
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _shakeDetector.stopListening();
    } else if (state == AppLifecycleState.resumed) {
      if (!_shakeDetector.isListening) {
        _shakeDetector.startListening(_onShakeDetected);
      }
    }
  }

  void _onShakeDetected() {
    // Prevent multiple dialogs from opening
    if (_isDialogOpen || !mounted) return;

    setState(() {
      _isDialogOpen = true;
    });

    showFeedbackDialog(context);

    // Reset flag after dialog is dismissed
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isDialogOpen = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
