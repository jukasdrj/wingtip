import 'package:wingtip/data/database.dart';

/// Sample failed scans covering all error types
final testFailedScans = [
  FailedScan(
    id: 1,
    jobId: 'job-network-error-001',
    imagePath: '/test/failed_scans/network_error_1.jpg',
    errorMessage: 'Unable to connect to server. Please check your network connection.',
    failureReason: FailureReason.networkError,
    createdAt: DateTime(2024, 1, 10).millisecondsSinceEpoch,
    expiresAt: DateTime(2024, 1, 17).millisecondsSinceEpoch,
  ),
  FailedScan(
    id: 2,
    jobId: 'job-quality-low-001',
    imagePath: '/test/failed_scans/blurry_spine.jpg',
    errorMessage: 'Image quality too low. Please ensure good lighting and focus.',
    failureReason: FailureReason.qualityTooLow,
    createdAt: DateTime(2024, 1, 12).millisecondsSinceEpoch,
    expiresAt: DateTime(2024, 1, 19).millisecondsSinceEpoch,
  ),
  FailedScan(
    id: 3,
    jobId: 'job-no-books-001',
    imagePath: '/test/failed_scans/empty_shelf.jpg',
    errorMessage: 'No book spines detected in the image.',
    failureReason: FailureReason.noBooksFound,
    createdAt: DateTime(2024, 1, 15).millisecondsSinceEpoch,
    expiresAt: DateTime(2024, 1, 22).millisecondsSinceEpoch,
  ),
  FailedScan(
    id: 4,
    jobId: 'job-server-error-001',
    imagePath: '/test/failed_scans/server_error_1.jpg',
    errorMessage: 'Server encountered an error. Please try again later.',
    failureReason: FailureReason.serverError,
    createdAt: DateTime(2024, 1, 18).millisecondsSinceEpoch,
    expiresAt: DateTime(2024, 1, 25).millisecondsSinceEpoch,
  ),
  FailedScan(
    id: 5,
    jobId: 'job-rate-limited-001',
    imagePath: '/test/failed_scans/rate_limited_1.jpg',
    errorMessage: 'Rate limit exceeded. Please wait 30 seconds before trying again.',
    failureReason: FailureReason.rateLimited,
    createdAt: DateTime(2024, 1, 20).millisecondsSinceEpoch,
    expiresAt: DateTime(2024, 1, 27).millisecondsSinceEpoch,
  ),
  FailedScan(
    id: 6,
    jobId: 'job-unknown-001',
    imagePath: '/test/failed_scans/unknown_error.jpg',
    errorMessage: 'An unexpected error occurred.',
    failureReason: FailureReason.unknown,
    createdAt: DateTime(2024, 1, 22).millisecondsSinceEpoch,
    expiresAt: DateTime(2024, 1, 29).millisecondsSinceEpoch,
  ),
  FailedScan(
    id: 7,
    jobId: 'job-network-error-002',
    imagePath: '/test/failed_scans/timeout_error.jpg',
    errorMessage: 'Request timed out. Please check your connection.',
    failureReason: FailureReason.networkError,
    createdAt: DateTime(2024, 1, 25).millisecondsSinceEpoch,
    expiresAt: DateTime(2024, 2, 1).millisecondsSinceEpoch,
  ),
  FailedScan(
    id: 8,
    jobId: 'job-quality-low-002',
    imagePath: '/test/failed_scans/dark_image.jpg',
    errorMessage: 'Image too dark to process. Please use better lighting.',
    failureReason: FailureReason.qualityTooLow,
    createdAt: DateTime(2024, 1, 28).millisecondsSinceEpoch,
    expiresAt: DateTime(2024, 2, 4).millisecondsSinceEpoch,
  ),
];

/// Failed scan for network error testing
final networkErrorScan = testFailedScans[0];

/// Failed scan for quality issues testing
final qualityLowScan = testFailedScans[1];

/// Failed scan for no books found testing
final noBooksFoundScan = testFailedScans[2];

/// Failed scan for server error testing
final serverErrorScan = testFailedScans[3];

/// Failed scan for rate limiting testing
final rateLimitedScan = testFailedScans[4];

/// Failed scan for unknown error testing
final unknownErrorScan = testFailedScans[5];

/// Failed scans grouped by failure reason for analytics testing
Map<FailureReason, List<FailedScan>> get failedScansByReason {
  final grouped = <FailureReason, List<FailedScan>>{};
  for (final reason in FailureReason.values) {
    grouped[reason] = testFailedScans
        .where((scan) => scan.failureReason == reason)
        .toList();
  }
  return grouped;
}

/// Expected analytics result from testFailedScans
Map<FailureReason, int> get expectedFailedScansAnalytics {
  return {
    FailureReason.networkError: 2,
    FailureReason.qualityTooLow: 2,
    FailureReason.noBooksFound: 1,
    FailureReason.serverError: 1,
    FailureReason.rateLimited: 1,
    FailureReason.unknown: 1,
  };
}

/// Create a new failed scan with custom properties for testing
FailedScan createFailedScan({
  required String jobId,
  required String imagePath,
  required String errorMessage,
  FailureReason failureReason = FailureReason.unknown,
  DateTime? createdAt,
  Duration retentionPeriod = const Duration(days: 7),
}) {
  final created = createdAt ?? DateTime.now();
  final createdMs = created.millisecondsSinceEpoch;
  final expiresMs = createdMs + retentionPeriod.inMilliseconds;

  return FailedScan(
    id: 999, // Test ID
    jobId: jobId,
    imagePath: imagePath,
    errorMessage: errorMessage,
    failureReason: failureReason,
    createdAt: createdMs,
    expiresAt: expiresMs,
  );
}
