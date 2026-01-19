import '../../data/database.dart';

/// Model class for library statistics
class LibraryStatistics {
  final int totalBooks;
  final int booksThisWeek;
  final int booksThisMonth;
  final int scanningStreak;
  final double averageBooksPerSession;
  final List<AuthorStats> topAuthors;
  final List<FormatStats> formatDistribution;

  LibraryStatistics({
    required this.totalBooks,
    required this.booksThisWeek,
    required this.booksThisMonth,
    required this.scanningStreak,
    required this.averageBooksPerSession,
    required this.topAuthors,
    required this.formatDistribution,
  });

  factory LibraryStatistics.empty() {
    return LibraryStatistics(
      totalBooks: 0,
      booksThisWeek: 0,
      booksThisMonth: 0,
      scanningStreak: 0,
      averageBooksPerSession: 0.0,
      topAuthors: [],
      formatDistribution: [],
    );
  }
}
