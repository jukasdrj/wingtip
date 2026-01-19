import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wingtip/data/database_provider.dart';
import 'package:wingtip/services/csv_export_service.dart';

/// Provider for the CSV export service.
final csvExportServiceProvider = Provider<CsvExportService>((ref) {
  final database = ref.watch(databaseProvider);
  return CsvExportService(database);
});
