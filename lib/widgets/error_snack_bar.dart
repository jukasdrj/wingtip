import 'package:flutter/material.dart';
import 'package:wingtip/core/theme.dart';

/// Custom SnackBar widget matching Swiss Utility design.
///
/// Features:
/// - Black background with white text
/// - Red left border (4px width, #FF3B30)
/// - Displays at bottom of screen, floating above content
/// - Auto-dismisses after 4 seconds
/// - Tap to dismiss
class ErrorSnackBar extends SnackBar {
  ErrorSnackBar({
    super.key,
    required String message,
  }) : super(
          content: _ErrorSnackBarContent(message: message),
          backgroundColor: AppTheme.oledBlack,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          margin: const EdgeInsets.all(16),
          padding: EdgeInsets.zero,
        );

  /// Helper method to show the error snackbar.
  ///
  /// Usage:
  /// ```dart
  /// ErrorSnackBar.show(
  ///   context,
  ///   message: 'An error occurred',
  /// );
  /// ```
  static void show(
    BuildContext context, {
    required String message,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      ErrorSnackBar(message: message),
    );
  }
}

class _ErrorSnackBarContent extends StatelessWidget {
  final String message;

  const _ErrorSnackBarContent({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.oledBlack,
        border: Border(
          left: BorderSide(
            color: AppTheme.internationalOrange,
            width: 4.0,
          ),
        ),
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 14.0,
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textPrimary,
            ),
      ),
    );
  }
}
