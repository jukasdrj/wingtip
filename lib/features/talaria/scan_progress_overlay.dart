import 'package:flutter/material.dart';
import 'package:wingtip/core/theme.dart';

/// Progress overlay for multi-book scans
///
/// Displays a progress bar and "Processing book N of M..." text
/// when the backend sends totalBooks metadata in progress events.
///
/// Swiss Utility design: OLED black background, white text, 1px border.
class ScanProgressOverlay extends StatelessWidget {
  final int currentBook;
  final int totalBooks;

  const ScanProgressOverlay({
    required this.currentBook,
    required this.totalBooks,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final progressPercent = currentBook / totalBooks;

    return Positioned(
      left: 24,
      right: 24,
      bottom: 120, // Above shutter button (positioned at ~80 from bottom)
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        opacity: 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.8), // Semi-transparent OLED black
            border: Border.all(color: AppTheme.borderGray, width: 1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress text
              Text(
                'Processing book $currentBook of $totalBooks...',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 8),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: SizedBox(
                  height: 4,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    child: LinearProgressIndicator(
                      value: progressPercent,
                      backgroundColor: AppTheme.borderGray,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.internationalOrange,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
