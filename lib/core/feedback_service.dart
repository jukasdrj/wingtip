import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Service for collecting app feedback with logs
class FeedbackService {
  /// Generates a feedback email with device info and recent logs
  Future<void> sendFeedback({
    required String deviceId,
    String? userMessage,
  }) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final deviceInfo = await _collectDeviceInfo(packageInfo, deviceId);
      final logs = await _collectRecentLogs();

      final emailBody = _buildEmailBody(
        deviceInfo: deviceInfo,
        logs: logs,
        userMessage: userMessage,
      );

      final emailUri = Uri(
        scheme: 'mailto',
        path: 'feedback@ooheynerds.com',
        query: _encodeQueryParameters({
          'subject': 'Wingtip Beta Feedback (v${packageInfo.version})',
          'body': emailBody,
        }),
      );

      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        throw Exception('Could not launch email client');
      }
    } catch (e) {
      debugPrint('[FeedbackService] Error sending feedback: $e');
      rethrow;
    }
  }

  Future<Map<String, String>> _collectDeviceInfo(
    PackageInfo packageInfo,
    String deviceId,
  ) async {
    return {
      'App Version': packageInfo.version,
      'Build Number': packageInfo.buildNumber,
      'Device ID': deviceId,
      'Platform': Platform.operatingSystem,
      'OS Version': Platform.operatingSystemVersion,
      'Dart Version': Platform.version.split(' ').first,
    };
  }

  Future<List<String>> _collectRecentLogs() async {
    // In production, this would read from a log file or buffer
    // For now, return a placeholder indicating logs would be attached
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final logFile = File('${appDir.path}/app_logs.txt');

      if (await logFile.exists()) {
        final allLogs = await logFile.readAsLines();
        // Get last 50 lines
        final recentLogs = allLogs.length > 50
            ? allLogs.sublist(allLogs.length - 50)
            : allLogs;
        return recentLogs;
      }
    } catch (e) {
      debugPrint('[FeedbackService] Error reading logs: $e');
    }

    return [
      '--- Recent Logs ---',
      '(Logs are automatically captured by Sentry)',
      'This feedback will be correlated with crash reports',
    ];
  }

  String _buildEmailBody({
    required Map<String, String> deviceInfo,
    required List<String> logs,
    String? userMessage,
  }) {
    final buffer = StringBuffer();

    // User message section
    buffer.writeln('=== FEEDBACK ===\n');
    if (userMessage != null && userMessage.isNotEmpty) {
      buffer.writeln(userMessage);
    } else {
      buffer.writeln('[Describe the issue or feedback here]\n');
    }

    buffer.writeln('\n${'=' * 40}\n');

    // Device info section
    buffer.writeln('=== DEVICE INFO ===\n');
    deviceInfo.forEach((key, value) {
      buffer.writeln('$key: $value');
    });

    buffer.writeln('\n${'=' * 40}\n');

    // Logs section
    buffer.writeln('=== RECENT LOGS ===\n');
    buffer.writeln(logs.join('\n'));

    return buffer.toString();
  }

  String _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }
}

/// Provider for the feedback service
final feedbackServiceProvider = FeedbackService();
