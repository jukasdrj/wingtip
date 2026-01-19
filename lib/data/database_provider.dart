import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database.dart';

/// Lazy database provider - database is only initialized when first accessed
/// This prevents blocking the main thread during app startup
final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(() {
    database.close();
  });
  return database;
});
