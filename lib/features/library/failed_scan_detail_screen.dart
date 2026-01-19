import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../data/database.dart';
import '../../data/failed_scans_repository.dart';
import '../talaria/job_state_provider.dart';

class FailedScanDetailScreen extends ConsumerStatefulWidget {
  final FailedScan failedScan;

  const FailedScanDetailScreen({
    super.key,
    required this.failedScan,
  });

  @override
  ConsumerState<FailedScanDetailScreen> createState() => _FailedScanDetailScreenState();
}

class _FailedScanDetailScreenState extends ConsumerState<FailedScanDetailScreen> {
  bool _isHelpExpanded = false;

  String _formatFullTimestamp(int timestampMs) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestampMs);
    final formatter = DateFormat('MMM d, y \'at\' h:mm a');
    return 'Failed on ${formatter.format(dateTime)}';
  }

  String _getContextualHelp(String errorMessage) {
    final lowerError = errorMessage.toLowerCase();

    // Check for common error patterns
    if (lowerError.contains('rate limit') || lowerError.contains('429')) {
      return 'Rate Limit Error\n\n'
          'You\'ve sent too many requests in a short period. The server enforces rate limits to ensure fair usage.\n\n'
          'What to try:\n'
          '• Wait a few minutes before retrying\n'
          '• Avoid scanning multiple books rapidly\n'
          '• Check your network connection';
    } else if (lowerError.contains('blur') || lowerError.contains('quality')) {
      return 'Image Quality Issue\n\n'
          'The image was too blurry or low quality for the AI to analyze reliably.\n\n'
          'What to try:\n'
          '• Ensure good lighting when scanning\n'
          '• Hold the camera steady\n'
          '• Move closer to the book spine\n'
          '• Clean your camera lens';
    } else if (lowerError.contains('network') || lowerError.contains('connection') || lowerError.contains('timeout')) {
      return 'Network Connection Error\n\n'
          'Unable to reach the server. This could be due to poor connectivity or the server being temporarily unavailable.\n\n'
          'What to try:\n'
          '• Check your internet connection\n'
          '• Try switching between WiFi and cellular data\n'
          '• Wait a moment and retry\n'
          '• Check if you can access other websites';
    } else if (lowerError.contains('no books') || lowerError.contains('not found')) {
      return 'No Books Detected\n\n'
          'The AI couldn\'t identify any books in the image. This could happen if the spine text isn\'t visible or the image doesn\'t contain books.\n\n'
          'What to try:\n'
          '• Ensure book spines are clearly visible\n'
          '• Make sure spine text is readable\n'
          '• Avoid extreme angles or perspectives\n'
          '• Try scanning fewer books at once';
    } else if (lowerError.contains('server') || lowerError.contains('500') || lowerError.contains('503')) {
      return 'Server Error\n\n'
          'The server encountered an error while processing your scan. This is usually temporary.\n\n'
          'What to try:\n'
          '• Wait a few minutes and retry\n'
          '• If the issue persists, try a different image\n'
          '• Check if the service is experiencing downtime';
    } else if (lowerError.contains('unauthorized') || lowerError.contains('401') || lowerError.contains('403')) {
      return 'Authorization Error\n\n'
          'There was an issue with your device authentication. This is unusual and may indicate a configuration problem.\n\n'
          'What to try:\n'
          '• Restart the app\n'
          '• Check your device settings\n'
          '• If the issue persists, you may need to reinstall the app';
    } else {
      return 'Scan Failed\n\n'
          'The scan couldn\'t be completed. This could be due to various reasons including image quality, network issues, or server problems.\n\n'
          'What to try:\n'
          '• Review the error message above for specific details\n'
          '• Ensure good lighting and a clear view of book spines\n'
          '• Check your network connection\n'
          '• Wait a moment and retry';
    }
  }

  Future<void> _handleRetry() async {
    HapticFeedback.lightImpact();

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          color: AppTheme.internationalOrange,
        ),
      ),
    );

    try {
      await ref.read(jobStateProvider.notifier).retryFailedScan(widget.failedScan.jobId);

      if (mounted) {
        Navigator.of(context).pop(); // Dismiss loading
        Navigator.of(context).pop(); // Go back to list

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Retrying scan...'),
            backgroundColor: AppTheme.borderGray,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Dismiss loading

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to retry: $e'),
            backgroundColor: AppTheme.borderGray,
          ),
        );
      }
    }
  }

  Future<void> _handleDelete() async {
    HapticFeedback.lightImpact();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.borderGray,
        title: const Text(
          'Delete failed scan?',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: const Text(
          'This action cannot be undone.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppTheme.internationalOrange),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      HapticFeedback.mediumImpact();

      try {
        await ref.read(failedScansRepositoryProvider).deleteFailedScan(widget.failedScan.id);

        if (mounted) {
          Navigator.of(context).pop(); // Go back to list

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed scan deleted'),
              backgroundColor: AppTheme.borderGray,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete: $e'),
              backgroundColor: AppTheme.borderGray,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.oledBlack,
      appBar: AppBar(
        title: const Text('Failed Scan Details'),
        backgroundColor: AppTheme.oledBlack,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Full-size image
                  if (File(widget.failedScan.imagePath).existsSync())
                    Image.file(
                      File(widget.failedScan.imagePath),
                      width: double.infinity,
                      fit: BoxFit.contain,
                    )
                  else
                    Container(
                      width: double.infinity,
                      height: 300,
                      color: AppTheme.borderGray,
                      child: const Center(
                        child: Icon(
                          Icons.broken_image,
                          color: AppTheme.textSecondary,
                          size: 64,
                        ),
                      ),
                    ),

                  // Content section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Full timestamp
                        Text(
                          _formatFullTimestamp(widget.failedScan.createdAt),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                        ),
                        const SizedBox(height: 16),

                        // Error message label
                        Text(
                          'Error Message',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 8),

                        // Full error message (not truncated)
                        Text(
                          widget.failedScan.errorMessage,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.internationalOrange,
                              ),
                        ),
                        const SizedBox(height: 24),

                        // Expandable help section
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppTheme.borderGray,
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              InkWell(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  setState(() {
                                    _isHelpExpanded = !_isHelpExpanded;
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.help_outline,
                                        color: AppTheme.textPrimary,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Why did this fail?',
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                color: AppTheme.textPrimary,
                                              ),
                                        ),
                                      ),
                                      Icon(
                                        _isHelpExpanded
                                            ? Icons.expand_less
                                            : Icons.expand_more,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (_isHelpExpanded)
                                Container(
                                  width: double.infinity,
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      top: BorderSide(
                                        color: AppTheme.borderGray,
                                        width: 1.0,
                                      ),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Text(
                                      _getContextualHelp(widget.failedScan.errorMessage),
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: AppTheme.textSecondary,
                                            height: 1.5,
                                          ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom action buttons
          Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: AppTheme.borderGray,
                  width: 1.0,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Delete button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _handleDelete,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textSecondary,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        side: const BorderSide(
                          color: AppTheme.borderGray,
                          width: 1.0,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Delete'),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Retry button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _handleRetry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.internationalOrange,
                        foregroundColor: AppTheme.textPrimary,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(
                            color: AppTheme.internationalOrange,
                            width: 1.0,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Retry Scan'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
