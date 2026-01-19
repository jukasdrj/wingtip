import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../data/database.dart';
import '../library_provider.dart';

class FailedScanCard extends ConsumerWidget {
  final FailedScan failedScan;
  final VoidCallback onRetry;
  final VoidCallback onDelete;

  const FailedScanCard({
    super.key,
    required this.failedScan,
    required this.onRetry,
    required this.onDelete,
  });

  String _formatRelativeTimestamp(int timestampMs) {
    final now = DateTime.now();
    final scanTime = DateTime.fromMillisecondsSinceEpoch(timestampMs);
    final difference = now.difference(scanTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectMode = ref.watch(failedScanSelectModeProvider);
    final selectedScans = ref.watch(selectedFailedScansProvider);
    final isSelected = selectedScans.contains(failedScan.jobId);

    return GestureDetector(
      onTap: selectMode
          ? () {
              HapticFeedback.lightImpact();
              ref.read(selectedFailedScansProvider.notifier).toggle(failedScan.jobId);
            }
          : null,
      onLongPress: selectMode
          ? null
          : () {
              HapticFeedback.lightImpact();
              ref.read(failedScanSelectModeProvider.notifier).enable();
              ref.read(selectedFailedScansProvider.notifier).toggle(failedScan.jobId);
            },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.oledBlack,
          border: Border.all(
            color: selectMode && isSelected ? AppTheme.internationalOrange : AppTheme.internationalOrange,
            width: selectMode && isSelected ? 2.0 : 1.0,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(7),
                topRight: Radius.circular(7),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  children: [
                    File(failedScan.imagePath).existsSync()
                        ? Image.file(
                            File(failedScan.imagePath),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          )
                        : Container(
                            color: AppTheme.borderGray,
                            child: const Center(
                              child: Icon(
                                Icons.broken_image,
                                color: AppTheme.textSecondary,
                                size: 48,
                              ),
                            ),
                          ),
                    // Checkbox in select mode
                    if (selectMode)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.internationalOrange : AppTheme.borderGray,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ),
                  ],
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Error message
                Text(
                  failedScan.errorMessage,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textPrimary,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Timestamp
                Text(
                  _formatRelativeTimestamp(failedScan.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
                const SizedBox(height: 12),

                // Action buttons (hidden in select mode)
                if (!selectMode)
                  Row(
                    children: [
                      // Retry button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            onRetry();
                          },
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
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Retry'),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Delete button
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            onDelete();
                          },
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
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Delete'),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}
