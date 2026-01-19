import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:wingtip/core/failed_scans_directory.dart';
import 'package:wingtip/data/database.dart';

/// Service for cleaning up expired failed scans
class FailedScansCleanupService {
  final AppDatabase _database;

  FailedScansCleanupService(this._database);

  /// Clean up expired failed scans
  /// Returns the number of scans cleaned up
  Future<int> cleanupExpiredScans() async {
    final now = DateTime.now().millisecondsSinceEpoch;

    // Find all expired scans using customSelect for less than comparison
    final expiredScans = await _database.customSelect(
      'SELECT * FROM failed_scans WHERE expires_at < ?',
      variables: [Variable.withInt(now)],
      readsFrom: {_database.failedScans},
    ).map((row) => _database.failedScans.map(row.data)).get();

    if (expiredScans.isEmpty) {
      debugPrint('[FailedScansCleanup] No expired failed scans found');
      return 0;
    }

    int deletedCount = 0;

    // Delete each expired scan's image file and database entry
    for (final scan in expiredScans) {
      try {
        // Delete the image file
        await FailedScansDirectory.deleteImage(scan.jobId);

        // Delete the database entry
        await (_database.delete(_database.failedScans)
              ..where((t) => t.id.equals(scan.id)))
            .go();

        deletedCount++;
      } catch (e) {
        debugPrint('[FailedScansCleanup] Error deleting scan ${scan.jobId}: $e');
        // Continue with next scan even if this one fails
      }
    }

    debugPrint('[FailedScansCleanup] Cleaned up $deletedCount expired failed scans');

    return deletedCount;
  }

  /// Clean up orphaned image files that don't have database entries
  /// Returns the number of orphaned files cleaned up
  Future<int> cleanupOrphanedImages() async {
    try {
      final failedScansDir = await FailedScansDirectory.getDirectory();
      final allImages = await failedScansDir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.jpg'))
          .cast<File>()
          .toList();

      if (allImages.isEmpty) {
        return 0;
      }

      // Get all job IDs from the database
      final allScans = await _database.select(_database.failedScans).get();
      final validJobIds = allScans.map((scan) => scan.jobId).toSet();

      int deletedCount = 0;

      // Delete images that don't have a corresponding database entry
      for (final imageFile in allImages) {
        final fileName = imageFile.uri.pathSegments.last;
        final jobId = fileName.replaceAll('.jpg', '');

        if (!validJobIds.contains(jobId)) {
          try {
            await imageFile.delete();
            deletedCount++;
          } catch (e) {
            debugPrint('[FailedScansCleanup] Error deleting orphaned image $fileName: $e');
          }
        }
      }

      if (deletedCount > 0) {
        debugPrint('[FailedScansCleanup] Cleaned up $deletedCount orphaned image files');
      }

      return deletedCount;
    } catch (e) {
      debugPrint('[FailedScansCleanup] Error during orphaned image cleanup: $e');
      return 0;
    }
  }

  /// Run full cleanup: expired scans + orphaned images
  /// Returns total number of items cleaned up
  Future<int> runFullCleanup() async {
    final expiredCount = await cleanupExpiredScans();
    final orphanedCount = await cleanupOrphanedImages();
    final totalCount = expiredCount + orphanedCount;

    if (totalCount > 0) {
      debugPrint('[FailedScansCleanup] Full cleanup complete: $totalCount items removed');
    }

    return totalCount;
  }
}
