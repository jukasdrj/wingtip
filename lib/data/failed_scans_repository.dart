import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    await (_database.delete(_database.failedScans)
          ..where((t) => t.id.equals(id)))
        .go();
  }

  Future<FailedScan?> retryFailedScan(int id) async {
    final scan = await (_database.select(_database.failedScans)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();

    return scan;
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
