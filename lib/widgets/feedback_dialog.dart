import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wingtip/core/device_id_provider.dart';
import 'package:wingtip/core/feedback_service.dart';
import 'package:wingtip/core/theme.dart';
import 'package:wingtip/widgets/error_snack_bar.dart';

/// Dialog for collecting user feedback
class FeedbackDialog extends ConsumerStatefulWidget {
  const FeedbackDialog({super.key});

  @override
  ConsumerState<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends ConsumerState<FeedbackDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    final message = _controller.text.trim();

    if (message.isEmpty) {
      ErrorSnackBar.show(
        context,
        message: 'Please enter your feedback',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final deviceIdAsync = ref.read(deviceIdProvider);
      final deviceId = deviceIdAsync.when(
        data: (id) => id,
        loading: () => 'unknown',
        error: (error, stack) => 'unknown',
      );

      await feedbackServiceProvider.sendFeedback(
        deviceId: deviceId,
        userMessage: message,
      );

      if (mounted) {
        // Haptic feedback on success
        HapticFeedback.mediumImpact();

        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you for your feedback!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackBar.show(
          context,
          message: 'Failed to send feedback: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: const BorderSide(color: AppTheme.borderGray, width: 1),
      ),
      title: const Text(
        'Send Feedback',
        style: TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Describe the issue or share your thoughts:',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLines: 5,
            maxLength: 500,
            enabled: !_isSubmitting,
            decoration: InputDecoration(
              hintText: 'What happened? What were you doing?',
              hintStyle: TextStyle(color: AppTheme.textSecondary),
              border: OutlineInputBorder(
                borderSide: const BorderSide(color: AppTheme.borderGray),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: AppTheme.borderGray),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(
                  color: AppTheme.internationalOrange,
                  width: 1,
                ),
              ),
              filled: true,
              fillColor: AppTheme.oledBlack,
            ),
            style: const TextStyle(color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Device info and recent logs will be included automatically.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text(
            'Cancel',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitFeedback,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.internationalOrange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Send'),
        ),
      ],
    );
  }
}

/// Show the feedback dialog
void showFeedbackDialog(BuildContext context) {
  // Haptic feedback when opening
  HapticFeedback.lightImpact();

  showDialog(
    context: context,
    builder: (context) => const FeedbackDialog(),
  );
}
