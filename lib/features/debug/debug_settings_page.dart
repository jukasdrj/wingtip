import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wingtip/core/device_id_provider.dart';
import 'package:wingtip/core/restart_widget.dart';
import 'package:wingtip/core/theme.dart';
import 'package:wingtip/data/failed_scans_repository.dart';
import 'package:wingtip/features/camera/image_processing_metrics_provider.dart';
import 'package:wingtip/services/csv_export_service_provider.dart';
import 'package:wingtip/services/failed_scan_retention_service.dart';
import 'package:wingtip/services/network_reconnect_service.dart';
import 'package:wingtip/widgets/error_snack_bar.dart';

/// Debug settings page with options to view and regenerate the device ID.
class DebugSettingsPage extends ConsumerWidget {
  const DebugSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceIdAsync = ref.watch(deviceIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Device ID',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            deviceIdAsync.when(
              data: (deviceId) => _DeviceIdSection(deviceId: deviceId),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Text(
                'Error: $error',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Export Library',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () async {
                final csvExportService = ref.read(csvExportServiceProvider);

                try {
                  final filePath = await csvExportService.exportLibraryToCsv();

                  if (filePath == null) {
                    if (context.mounted) {
                      ErrorSnackBar.show(
                        context,
                        message: 'No books to export',
                      );
                    }
                    return;
                  }

                  await csvExportService.shareExportedCsv(filePath);
                } catch (e) {
                  if (context.mounted) {
                    ErrorSnackBar.show(
                      context,
                      message: 'Failed to export library: $e',
                    );
                  }
                }
              },
              icon: const Icon(Icons.download),
              label: const Text('Export Library'),
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Test Error Snackbar',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                ErrorSnackBar.show(
                  context,
                  message: 'This is a test error message',
                );
              },
              icon: const Icon(Icons.error_outline),
              label: const Text('Show Error Snackbar'),
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Failed Scan Retention',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const _FailedScanRetentionSection(),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Network Reconnection',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const _NetworkReconnectSection(),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Image Processing Metrics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const _ImageProcessingMetricsSection(),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Image Cache',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _ImageCacheSection(),
          ],
        ),
      ),
    );
  }
}

class _DeviceIdSection extends ConsumerWidget {
  const _DeviceIdSection({required this.deviceId});

  final String deviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    deviceId,
                    style: AppTheme.monoStyle(fontSize: 14),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  tooltip: 'Copy to clipboard',
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: deviceId));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Device ID copied to clipboard'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Regenerate Device ID?'),
                    content: const Text(
                      'This will reset your device identity. Rate limits and analytics will restart. Continue?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Continue'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true && context.mounted) {
                  final service = ref.read(deviceIdServiceProvider);
                  await service.regenerateDeviceId();

                  // Restart the entire app to reinitialize with new device ID
                  if (context.mounted) {
                    RestartWidget.restartApp(context);
                  }
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Regenerate Device ID'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageCacheSection extends ConsumerStatefulWidget {
  const _ImageCacheSection();

  @override
  ConsumerState<_ImageCacheSection> createState() => _ImageCacheSectionState();
}

class _ImageCacheSectionState extends ConsumerState<_ImageCacheSection> {
  String _cacheSize = 'Calculating...';
  bool _isClearing = false;

  @override
  void initState() {
    super.initState();
    _calculateCacheSize();
  }

  Future<void> _calculateCacheSize() async {
    try {
      // Get the temporary directory where cache is stored
      final tempDir = await getTemporaryDirectory();
      final cacheDir = Directory('${tempDir.path}/libCachedImageData');

      int totalSize = 0;

      // Calculate total size of all files in cache directory
      if (await cacheDir.exists()) {
        await for (final entity in cacheDir.list(recursive: true, followLinks: false)) {
          if (entity is File) {
            try {
              final fileSize = await entity.length();
              totalSize += fileSize;
            } catch (e) {
              // Skip files we can't read
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _cacheSize = _formatBytes(totalSize);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cacheSize = 'Error calculating';
        });
      }
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Future<void> _clearCache() async {
    setState(() {
      _isClearing = true;
    });

    try {
      final cacheManager = DefaultCacheManager();
      await cacheManager.emptyCache();

      await _calculateCacheSize();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image cache cleared'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackBar.show(
          context,
          message: 'Failed to clear cache: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isClearing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cache Size',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                Text(
                  _cacheSize,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isClearing ? null : _clearCache,
                icon: _isClearing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_outline),
                label: Text(_isClearing ? 'Clearing...' : 'Clear Image Cache'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FailedScanRetentionSection extends ConsumerStatefulWidget {
  const _FailedScanRetentionSection();

  @override
  ConsumerState<_FailedScanRetentionSection> createState() =>
      _FailedScanRetentionSectionState();
}

class _FailedScanRetentionSectionState
    extends ConsumerState<_FailedScanRetentionSection> {
  String _scanInfo = 'Calculating...';
  bool _isClearing = false;

  @override
  void initState() {
    super.initState();
    _calculateScanInfo();
  }

  Future<void> _calculateScanInfo() async {
    try {
      final repository = ref.read(failedScansRepositoryProvider);
      final count = await repository.getFailedScansCount();
      final size = await repository.getFailedScansStorageSize();

      if (mounted) {
        setState(() {
          _scanInfo = 'Failed Scans: $count (using ${_formatBytes(size)})';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _scanInfo = 'Error calculating';
        });
      }
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Future<void> _clearAllFailedScans() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Failed Scans?'),
        content: const Text(
          'This will permanently delete all failed scan images and records. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isClearing = true;
    });

    try {
      final repository = ref.read(failedScansRepositoryProvider);
      await repository.clearAllFailedScans();

      await _calculateScanInfo();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All failed scans cleared'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackBar.show(
          context,
          message: 'Failed to clear scans: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isClearing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final retentionService = ref.watch(failedScanRetentionServiceProvider);
    final currentRetention = retentionService.getRetention();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Retention Period',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                DropdownButton<FailedScanRetention>(
                  value: currentRetention,
                  items: FailedScanRetention.values.map((retention) {
                    return DropdownMenuItem(
                      value: retention,
                      child: Text(retention.label),
                    );
                  }).toList(),
                  onChanged: (value) async {
                    if (value != null) {
                      await retentionService.setRetention(value);
                      setState(() {});
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _scanInfo,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isClearing ? null : _clearAllFailedScans,
                icon: _isClearing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_outline),
                label: Text(
                    _isClearing ? 'Clearing...' : 'Clear All Failed Scans Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NetworkReconnectSection extends ConsumerWidget {
  const _NetworkReconnectSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final autoRetry = ref.watch(autoRetryProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Auto-retry on reconnect',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Automatically retry failed scans when connection is restored',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: autoRetry,
                  onChanged: (value) async {
                    HapticFeedback.lightImpact();
                    await ref.read(autoRetryProvider.notifier).setAutoRetry(value);
                  },
                  activeTrackColor: AppTheme.internationalOrange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageProcessingMetricsSection extends ConsumerWidget {
  const _ImageProcessingMetricsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(imageProcessingMetricsNotifierProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (metrics.totalProcessed > 0) ...[
              _MetricRow(
                label: 'Images Processed',
                value: '${metrics.totalProcessed}',
              ),
              const SizedBox(height: 12),
              _MetricRow(
                label: 'Average Time',
                value: '${metrics.averageTimeMs.toStringAsFixed(1)}ms',
                isHighlighted: !metrics.meetsTargetPerformance,
              ),
              const SizedBox(height: 12),
              _MetricRow(
                label: 'Recent Average (last 10)',
                value: '${metrics.recentAverageTimeMs.toStringAsFixed(1)}ms',
              ),
              const SizedBox(height: 12),
              _MetricRow(
                label: 'Min / Max',
                value: '${metrics.minTimeMs}ms / ${metrics.maxTimeMs}ms',
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Target: < 500ms',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                  Icon(
                    metrics.meetsTargetPerformance
                        ? Icons.check_circle
                        : Icons.warning,
                    color: metrics.meetsTargetPerformance
                        ? Colors.green
                        : AppTheme.internationalOrange,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ref
                        .read(imageProcessingMetricsNotifierProvider.notifier)
                        .reset();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset Metrics'),
                ),
              ),
            ] else ...[
              Text(
                'No images processed yet',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Metrics will appear here after capturing images',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.label,
    required this.value,
    this.isHighlighted = false,
  });

  final String label;
  final String value;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          value,
          style: AppTheme.monoStyle(fontSize: 14).copyWith(
            fontWeight: FontWeight.bold,
            color: isHighlighted
                ? AppTheme.internationalOrange
                : AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
