import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/network_status_provider.dart';
import '../core/theme.dart';
import '../data/failed_scans_repository.dart';
import '../features/talaria/job_state_provider.dart';
import '../services/network_reconnect_service.dart';

/// Widget that listens for network reconnection and prompts retry of failed scans
class NetworkReconnectListener extends ConsumerStatefulWidget {
  final Widget child;

  const NetworkReconnectListener({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<NetworkReconnectListener> createState() => _NetworkReconnectListenerState();
}

class _NetworkReconnectListenerState extends ConsumerState<NetworkReconnectListener> {
  bool _wasOffline = false;
  bool _toastShown = false;

  @override
  Widget build(BuildContext context) {
    // Listen to network status changes
    ref.listen<AsyncValue<bool>>(networkStatusProvider, (previous, next) {
      next.whenData((isOnline) async {
        // Detect offline -> online transition
        if (_wasOffline && isOnline && !_toastShown) {
          debugPrint('[NetworkReconnect] Connection restored, checking for failed scans');

          // Get failed scans count
          final repository = ref.read(failedScansRepositoryProvider);
          final count = await repository.getFailedScansCount();

          if (count > 0) {
            debugPrint('[NetworkReconnect] Found $count failed scans');

            // Check auto-retry setting
            final autoRetry = ref.read(autoRetryProvider);

            if (autoRetry) {
              // Auto-retry all failed scans
              debugPrint('[NetworkReconnect] Auto-retry enabled, retrying all failed scans');
              _retryAllFailedScans(count);
            } else {
              // Show toast prompt
              _showReconnectToast(count);
            }

            // Set flag to prevent showing toast multiple times
            _toastShown = true;
          }
        }

        // Update offline state
        if (!isOnline) {
          _wasOffline = true;
          _toastShown = false; // Reset toast flag when going offline
        }
      });
    });

    return widget.child;
  }

  void _showReconnectToast(int count) {
    if (!mounted) return;

    HapticFeedback.mediumImpact();

    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 8),
        backgroundColor: AppTheme.oledBlack,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2),
          side: const BorderSide(
            color: AppTheme.borderGray,
            width: 1.0,
          ),
        ),
        content: Text(
          'Connection restored. $count failed ${count == 1 ? 'scan' : 'scans'} waiting. Retry all?',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        action: SnackBarAction(
          label: 'Retry All',
          textColor: AppTheme.internationalOrange,
          onPressed: () {
            HapticFeedback.lightImpact();
            _retryAllFailedScans(count);
          },
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _retryAllFailedScans(int count) {
    if (!mounted) return;

    final jobStateNotifier = ref.read(jobStateProvider.notifier);

    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _RetryProgressDialog(
        jobStateNotifier: jobStateNotifier,
        totalCount: count,
      ),
    );
  }
}

/// Dialog showing retry progress
class _RetryProgressDialog extends StatefulWidget {
  final dynamic jobStateNotifier;
  final int totalCount;

  const _RetryProgressDialog({
    required this.jobStateNotifier,
    required this.totalCount,
  });

  @override
  State<_RetryProgressDialog> createState() => _RetryProgressDialogState();
}

class _RetryProgressDialogState extends State<_RetryProgressDialog> {
  int _current = 0;
  int _succeeded = 0;
  int _failed = 0;
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    _startRetry();
  }

  Future<void> _startRetry() async {
    final result = await widget.jobStateNotifier.retryAllFailedScans(
      onProgress: (current, total) {
        if (mounted) {
          setState(() {
            _current = current;
          });
        }
      },
    );

    if (mounted) {
      setState(() {
        _succeeded = result['succeeded'] ?? 0;
        _failed = result['failed'] ?? 0;
        _isComplete = true;
      });

      // Auto-close after showing results
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.oledBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(2),
        side: const BorderSide(
          color: AppTheme.borderGray,
          width: 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_isComplete) ...[
              const CircularProgressIndicator(
                color: AppTheme.internationalOrange,
              ),
              const SizedBox(height: 16),
              Text(
                'Retrying failed scans...',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$_current of ${widget.totalCount}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
            ] else ...[
              const Icon(
                Icons.check_circle_outline,
                color: AppTheme.internationalOrange,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Retry Complete',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$_succeeded succeeded, $_failed failed',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
