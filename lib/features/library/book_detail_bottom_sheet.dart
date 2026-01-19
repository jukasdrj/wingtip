import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/database.dart';

class BookDetailBottomSheet extends StatelessWidget {
  final Book book;

  const BookDetailBottomSheet({
    super.key,
    required this.book,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            border: Border(
              top: BorderSide(
                color: theme.dividerColor,
                width: 1,
              ),
            ),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(12),
            ),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Passport-style layout
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Large cover image on left
                          _buildCoverImage(context),
                          const SizedBox(width: 24),
                          // Metadata fields on right
                          Expanded(
                            child: _buildMetadataSection(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Edit button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            // TODO: Implement edit functionality in future story
                          },
                          child: const Text('Edit'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCoverImage(BuildContext context) {
    const imageWidth = 120.0;
    const imageHeight = 180.0;

    if (book.coverUrl != null && book.coverUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: imageWidth,
          height: imageHeight,
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.white,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: CachedNetworkImage(
            imageUrl: book.coverUrl!,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[900],
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
            errorWidget: (context, url, error) => _buildFallbackCover(context),
          ),
        ),
      );
    }

    return _buildFallbackCover(context);
  }

  Widget _buildFallbackCover(BuildContext context) {
    const imageWidth = 120.0;
    const imageHeight = 180.0;

    return Container(
      width: imageWidth,
      height: imageHeight,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.white,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            book.title,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            book.author,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataSection(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMetadataField(
          context,
          label: 'ISBN',
          value: book.isbn,
          valueStyle: GoogleFonts.jetBrainsMono(
            fontSize: 14,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        _buildMetadataField(
          context,
          label: 'Title',
          value: book.title,
          valueStyle: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildMetadataField(
          context,
          label: 'Author',
          value: book.author,
          valueStyle: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        _buildMetadataField(
          context,
          label: 'Format',
          value: book.format ?? 'Unknown',
          valueStyle: theme.textTheme.bodyLarge,
        ),
      ],
    );
  }

  Widget _buildMetadataField(
    BuildContext context, {
    required String label,
    required String value,
    TextStyle? valueStyle,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: valueStyle ?? theme.textTheme.bodyMedium,
        ),
      ],
    );
  }

  static Future<void> show(BuildContext context, Book book) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BookDetailBottomSheet(book: book),
    );
  }
}
