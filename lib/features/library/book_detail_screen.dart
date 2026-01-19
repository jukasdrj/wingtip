import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../data/database.dart';
import 'edit_book_screen.dart';

/// Full-screen book detail view with hero animation and blurred spine background
class BookDetailScreen extends StatefulWidget {
  final Book book;

  const BookDetailScreen({
    super.key,
    required this.book,
  });

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.oledBlack,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Blurred background from captured spine image
          if (widget.book.spineImagePath != null)
            _buildBlurredBackground(),
          // Main content with hero animation
          SafeArea(
            child: Column(
              children: [
                // Top action buttons
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Edit button (only shown for review_needed books)
                      if (widget.book.reviewNeeded)
                        OutlinedButton.icon(
                          onPressed: () async {
                            HapticFeedback.lightImpact();
                            final navigator = Navigator.of(context);
                            final result = await navigator.push<bool>(
                              MaterialPageRoute(
                                builder: (context) => EditBookScreen(book: widget.book),
                              ),
                            );
                            // If edit was successful, pop back to library
                            if (result == true) {
                              navigator.pop();
                            }
                          },
                          icon: const Icon(
                            Icons.edit,
                            size: 18,
                            color: AppTheme.textPrimary,
                          ),
                          label: Text(
                            'Edit',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: AppTheme.borderGray,
                              width: 1,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 80), // Spacer when no edit button
                      // Close button
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: AppTheme.textPrimary,
                          size: 28,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                // Hero animated book cover
                Expanded(
                  child: Center(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildHeroCover(),
                    ),
                  ),
                ),
                // Book metadata
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildMetadataCard(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlurredBackground() {
    final imageFile = File(widget.book.spineImagePath!);

    if (!imageFile.existsSync()) {
      return Container(color: AppTheme.oledBlack);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Original spine image
        Image.file(
          imageFile,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(color: AppTheme.oledBlack);
          },
        ),
        // Blur filter
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            color: Colors.black.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCover() {
    const coverWidth = 200.0;
    const coverHeight = 300.0;

    return Hero(
      tag: 'book-cover-${widget.book.isbn}',
      child: Container(
        width: coverWidth,
        height: coverHeight,
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.8),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: widget.book.coverUrl != null && widget.book.coverUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: widget.book.coverUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: AppTheme.borderGray,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.internationalOrange,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => _buildFallbackCover(),
                )
              : _buildFallbackCover(),
        ),
      ),
    );
  }

  Widget _buildFallbackCover() {
    return Container(
      color: AppTheme.borderGray,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              widget.book.title,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: Text(
              widget.book.author,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.oledBlack.withValues(alpha: 0.9),
        border: Border.all(
          color: AppTheme.borderGray,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMetadataRow('TITLE', widget.book.title),
          const SizedBox(height: 12),
          _buildMetadataRow('AUTHOR', widget.book.author),
          const SizedBox(height: 12),
          _buildMetadataRow('ISBN', widget.book.isbn, mono: true),
          if (widget.book.format != null) ...[
            const SizedBox(height: 12),
            _buildMetadataRow('FORMAT', widget.book.format!),
          ],
          if (widget.book.spineConfidence != null) ...[
            const SizedBox(height: 12),
            _buildMetadataRow(
              'CONFIDENCE',
              '${(widget.book.spineConfidence! * 100).toStringAsFixed(1)}%',
              mono: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value, {bool mono = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            color: AppTheme.textSecondary,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: mono
              ? GoogleFonts.jetBrainsMono(
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                )
              : const TextStyle(
                  fontSize: 16,
                  color: AppTheme.textPrimary,
                ),
        ),
      ],
    );
  }
}
