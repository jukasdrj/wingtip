import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wingtip/core/crash_reporting_service.dart';
import 'package:wingtip/core/device_id_provider.dart';
import 'package:wingtip/data/database_provider.dart';
import 'package:wingtip/features/talaria/job_state_provider.dart';

/// Provider that monitors app state and updates Sentry crash context.
///
/// This provider watches:
/// - Device ID
/// - Books count (from database)
/// - Active jobs count (from job state)
///
/// Whenever any of these values change, it updates the Sentry context
/// so that crash reports include this critical debugging information.
final crashContextProvider = Provider<void>((ref) {
  // Watch device ID
  final deviceIdAsync = ref.watch(deviceIdProvider);

  // Watch job state for active jobs count
  final jobState = ref.watch(jobStateProvider);
  final activeJobsCount = jobState.activeJobs.length;

  // Watch database for books count
  final database = ref.watch(databaseProvider);

  // When device ID is available, set up context monitoring
  deviceIdAsync.whenData((deviceId) {
    // Get books count asynchronously
    database.getTotalBooksCount().then((booksCount) {
      // Update Sentry context with latest values
      CrashReportingService.setCustomContext(
        deviceId: deviceId,
        booksCount: booksCount,
        activeJobsCount: activeJobsCount,
      );
    }).catchError((error) {
      // If we can't get books count, still update with what we have
      CrashReportingService.setCustomContext(
        deviceId: deviceId,
        booksCount: -1, // -1 indicates error fetching count
        activeJobsCount: activeJobsCount,
      );
    });
  });
});
