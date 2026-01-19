import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wingtip/core/failed_scans_directory.dart';
import 'database.dart';
import 'database_provider.dart';

class FailedScansRepository {
  final AppDatabase _database;

  FailedScansRepository(this._database);

  Future<void> saveFailedScan({
    required String jobId,
    required String imagePath,
    required String errorMessage,
    Duration retentionPeriod = const Duration(days: 7),
  }) async {
    await _database.saveFailedScan(
      jobId: jobId,
      imagePath: imagePath,
      errorMessage: errorMessage,
      retentionPeriod: retentionPeriod,
    );
  }

  Stream<List<FailedScan>> getAllFailedScans() {
    return _database.select(_database.failedScans).watch();
  }

  Future<void> deleteFailedScan(int id) async {
    // Get the failed scan to retrieve the jobId for image deletion
    final scan = await (_database.select(_database.failedScans)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();

    if (scan != null) {
      // Delete the image file
      await FailedScansDirectory.deleteImage(scan.jobId);

      // Delete the database entry
      await (_database.delete(_database.failedScans)
            ..where((t) => t.id.equals(id)))
          .go();
    }
  }

  Future<FailedScan?> retryFailedScan(int id) async {
    final scan = await (_database.select(_database.failedScans)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();

    return scan;
  }

  /// Get the total number of failed scans
  Future<int> getFailedScansCount() async {
    final count = await _database.select(_database.failedScans).get();
    return count.length;
  }

  /// Get the total storage size of all failed scan images
  Future<int> getFailedScansStorageSize() async {
    final scans = await _database.select(_database.failedScans).get();
    int totalSize = 0;

    for (final scan in scans) {
      final file = File(scan.imagePath);
      if (await file.exists()) {
        totalSize += await file.length();
      }
    }

    return totalSize;
  }

  /// Clear all failed scans (both database entries and image files)
  Future<void> clearAllFailedScans() async {
    final scans = await _database.select(_database.failedScans).get();

    // Delete all image files
    for (final scan in scans) {
      await FailedScansDirectory.deleteImage(scan.jobId);
    }

    // Delete all database entries
    await _database.delete(_database.failedScans).go();
  }
}

final failedScansRepositoryProvider = Provider<FailedScansRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return FailedScansRepository(database);
});

final watchFailedScansProvider = StreamProvider<List<FailedScan>>((ref) {
  final repository = ref.watch(failedScansRepositoryProvider);
  return repository.getAllFailedScans();
});
