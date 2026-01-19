import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database.dart';
import '../../data/database_provider.dart';
import 'library_statistics.dart';

/// Provider for library statistics
final libraryStatisticsProvider = FutureProvider<LibraryStatistics>((ref) async {
  final database = ref.watch(databaseProvider);

  // Calculate date ranges
  final now = DateTime.now();
  final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
  final endOfWeek = startOfWeek.add(const Duration(days: 7));
  final startOfMonth = DateTime(now.year, now.month, 1);
  final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

  // Fetch all statistics in parallel
  final results = await Future.wait([
    database.getTotalBooksCount(),
    database.getBooksCountInRange(startOfWeek, endOfWeek),
    database.getBooksCountInRange(startOfMonth, endOfMonth),
    database.getScanningStreak(),
    database.getAverageBooksPerSession(),
    database.getTopAuthors(limit: 5),
    database.getFormatStats(),
  ]);

  return LibraryStatistics(
    totalBooks: results[0] as int,
    booksThisWeek: results[1] as int,
    booksThisMonth: results[2] as int,
    scanningStreak: results[3] as int,
    averageBooksPerSession: results[4] as double,
    topAuthors: results[5] as List<AuthorStats>,
    formatDistribution: results[6] as List<FormatStats>,
  );
});
