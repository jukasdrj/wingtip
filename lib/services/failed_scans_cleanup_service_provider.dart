import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wingtip/data/database_provider.dart';
import 'failed_scans_cleanup_service.dart';

final failedScansCleanupServiceProvider = Provider<FailedScansCleanupService>((ref) {
  final database = ref.watch(databaseProvider);
  return FailedScansCleanupService(database);
});
