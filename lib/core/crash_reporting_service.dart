import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Service for crash reporting and analytics using Sentry.
///
/// Privacy-first implementation:
/// - No PII (personally identifiable information) in logs
/// - IP addresses are anonymized
/// - Device-specific identifiers are hashed
/// - Only essential context is captured
class CrashReportingService {
  /// Initialize Sentry with privacy-safe defaults.
  ///
  /// This should be called at app startup, wrapping the main app.
  static Future<void> initialize({
    required String dsn,
    required String environment,
    required Future<void> Function() appRunner,
  }) async {
    await SentryFlutter.init(
      (options) {
        options.dsn = dsn;
        options.environment = environment;

        // Privacy settings
        options.sendDefaultPii = false; // No PII
        options.attachStacktrace = true; // Helpful for debugging
        options.attachScreenshot = false; // No screenshots (privacy)
        options.attachViewHierarchy = false; // No view hierarchy (privacy)

        // Performance monitoring
        options.tracesSampleRate = 0.1; // 10% of transactions for performance monitoring
        options.profilesSampleRate = 0.1; // 10% profiling

        // Release settings
        options.dist = '1'; // Distribution identifier
        options.release = 'wingtip@1.0.0+1'; // Matches pubspec version

        // Debug settings
        options.debug = kDebugMode; // Only enable debug logging in debug mode

        // Filter out common Flutter framework noise
        options.beforeSend = (event, hint) {
          // Filter out Flutter framework errors that are not actionable
          if (event.exceptions?.any((e) =>
            e.type?.contains('FlutterError') == true ||
            e.type?.contains('PlatformException') == true
          ) == true) {
            // Still send, but mark as low priority
            event = event.copyWith(level: SentryLevel.info);
          }
          return event;
        };
      },
      appRunner: appRunner,
    );
  }

  /// Set custom context for crash reports.
  ///
  /// This context is attached to all subsequent crash reports and helps
  /// with debugging by providing app-specific state.
  static void setCustomContext({
    required String deviceId,
    required int booksCount,
    required int activeJobsCount,
  }) {
    Sentry.configureScope((scope) {
      scope.setContexts('app_state', {
        'device_id': _hashDeviceId(deviceId), // Hash for privacy
        'books_count': booksCount,
        'active_jobs_count': activeJobsCount,
      });
    });
  }

  /// Update a specific context value without replacing the entire context.
  static void updateContext(String key, dynamic value) {
    Sentry.configureScope((scope) {
      scope.setTag(key, value.toString());
    });
  }

  /// Log a custom analytics event.
  ///
  /// Events are sent as Sentry breadcrumbs, which provide context
  /// for crashes and also serve as basic analytics.
  static void logEvent(String eventName, {Map<String, dynamic>? parameters}) {
    Sentry.addBreadcrumb(
      Breadcrumb(
        message: eventName,
        data: parameters,
        category: 'analytics',
        level: SentryLevel.info,
        timestamp: DateTime.now().toUtc(),
      ),
    );
  }

  /// Log an error manually (non-fatal).
  ///
  /// Use this for caught exceptions that you want to track but don't crash the app.
  static void logError(
    dynamic error,
    StackTrace? stackTrace, {
    String? hint,
    Map<String, dynamic>? extra,
  }) {
    Sentry.captureException(
      error,
      stackTrace: stackTrace,
      hint: hint != null ? Hint.withMap({'hint': hint}) : null,
      withScope: (scope) {
        if (extra != null) {
          // Use contexts instead of deprecated setExtra
          scope.setContexts('error_context', extra);
        }
      },
    );
  }

  /// Manually trigger a test crash to verify crash reporting is working.
  ///
  /// This should only be used for testing in debug builds.
  static void testCrash() {
    if (kDebugMode) {
      throw Exception('Test crash from CrashReportingService');
    }
  }

  /// Hash the device ID for privacy.
  ///
  /// We don't want to send the raw device ID (UUID) to Sentry as it's PII.
  /// Instead, we hash it so we can still correlate crashes by device
  /// without exposing the actual device ID.
  static String _hashDeviceId(String deviceId) {
    // Simple hash for privacy - enough to correlate issues without exposing PII
    return deviceId.hashCode.toRadixString(36).padLeft(8, '0');
  }
}
