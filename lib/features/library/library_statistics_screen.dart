import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../data/database.dart';
import 'library_statistics_provider.dart';

class LibraryStatisticsScreen extends ConsumerWidget {
  const LibraryStatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statisticsAsync = ref.watch(libraryStatisticsProvider);

    return Scaffold(
      backgroundColor: AppTheme.oledBlack,
      appBar: AppBar(
        title: const Text('Library Statistics'),
        backgroundColor: AppTheme.oledBlack,
      ),
      body: statisticsAsync.when(
        data: (stats) => _buildStatistics(context, stats),
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: AppTheme.internationalOrange,
          ),
        ),
        error: (error, stack) => Center(
          child: Text(
            'Error loading statistics',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatistics(BuildContext context, dynamic stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Key Metrics Section
          _buildSectionHeader(context, 'Key Metrics'),
          const SizedBox(height: 12),
          _buildMetricsGrid(context, stats),
          const SizedBox(height: 32),

          // Top Authors Section
          if (stats.topAuthors.isNotEmpty) ...[
            _buildSectionHeader(context, 'Top Authors'),
            const SizedBox(height: 12),
            _buildTopAuthors(context, stats.topAuthors),
            const SizedBox(height: 32),
          ],

          // Format Distribution Section
          if (stats.formatDistribution.isNotEmpty) ...[
            _buildSectionHeader(context, 'Format Distribution'),
            const SizedBox(height: 12),
            _buildFormatDistribution(context, stats.formatDistribution),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppTheme.textSecondary,
            letterSpacing: 1.2,
          ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context, dynamic stats) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                context,
                'Total Books',
                stats.totalBooks.toString(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                context,
                'This Week',
                stats.booksThisWeek.toString(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                context,
                'This Month',
                stats.booksThisMonth.toString(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                context,
                'Scan Streak',
                '${stats.scanningStreak} ${stats.scanningStreak == 1 ? 'day' : 'days'}',
                valueStyle: AppTheme.monoStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildMetricCard(
          context,
          'Average Books Per Session',
          stats.averageBooksPerSession.toStringAsFixed(1),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String label,
    String value, {
    TextStyle? valueStyle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppTheme.borderGray,
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: valueStyle ??
                AppTheme.monoStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopAuthors(BuildContext context, List<AuthorStats> authors) {
    final maxCount = authors.first.bookCount;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppTheme.borderGray,
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: authors.asMap().entries.map((entry) {
          final index = entry.key;
          final author = entry.value;
          return Padding(
            padding: EdgeInsets.only(
              bottom: index < authors.length - 1 ? 16.0 : 0,
            ),
            child: _buildBarChart(
              context,
              author.author,
              author.bookCount,
              maxCount,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFormatDistribution(BuildContext context, List<FormatStats> formats) {
    final maxCount = formats.first.bookCount;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppTheme.borderGray,
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: formats.asMap().entries.map((entry) {
          final index = entry.key;
          final format = entry.value;
          return Padding(
            padding: EdgeInsets.only(
              bottom: index < formats.length - 1 ? 16.0 : 0,
            ),
            child: _buildBarChart(
              context,
              format.format,
              format.bookCount,
              maxCount,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBarChart(
    BuildContext context,
    String label,
    int count,
    int maxCount,
  ) {
    final percentage = maxCount > 0 ? count / maxCount : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textPrimary,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              count.toString(),
              style: AppTheme.monoStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 4,
          decoration: BoxDecoration(
            border: Border.all(
              color: AppTheme.borderGray,
              width: 1.0,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.internationalOrange,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
