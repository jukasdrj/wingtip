import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wingtip/core/device_id_provider.dart';
import 'package:wingtip/services/csv_export_service_provider.dart';
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
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontFamily: 'monospace',
                        ),
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
                      'This will generate a new device ID. This action is irreversible and should only be used for debugging.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Regenerate'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true && context.mounted) {
                  final service = ref.read(deviceIdServiceProvider);
                  await service.regenerateDeviceId();
                  // Invalidate the provider to fetch the new ID
                  ref.invalidate(deviceIdProvider);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Device ID regenerated'),
                        duration: Duration(seconds: 2),
                      ),
                    );
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
