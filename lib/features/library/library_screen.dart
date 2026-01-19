import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../data/database.dart';
import 'library_provider.dart';
import 'book_detail_bottom_sheet.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final Set<String> _seenBookIsbns = {};
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    ref.read(searchQueryProvider.notifier).setQuery(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(booksProvider);

    return Scaffold(
      backgroundColor: AppTheme.oledBlack,
      appBar: AppBar(
        title: const Text('Library'),
        backgroundColor: AppTheme.oledBlack,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppTheme.borderGray,
            height: 1,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search TextField
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimary,
                  ),
              decoration: InputDecoration(
                hintText: 'Search by title, author, or ISBN...',
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppTheme.textSecondary,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear,
                          color: AppTheme.textSecondary,
                        ),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.borderGray.withValues(alpha: 0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          // Filter and Sort controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            child: Row(
              children: [
                // Needs Review Filter
                Expanded(
                  child: Consumer(
                    builder: (context, ref, child) {
                      final reviewFilter = ref.watch(reviewNeededFilterProvider);
                      return OutlinedButton.icon(
                        onPressed: () {
                          ref.read(reviewNeededFilterProvider.notifier).toggleNeedsReview();
                        },
                        icon: Icon(
                          reviewFilter == true ? Icons.filter_alt : Icons.filter_alt_outlined,
                          size: 16,
                        ),
                        label: const Text('Needs Review'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: reviewFilter == true
                              ? AppTheme.internationalOrange
                              : AppTheme.textSecondary,
                          side: BorderSide(
                            color: reviewFilter == true
                                ? AppTheme.internationalOrange
                                : AppTheme.borderGray,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // Review First Sort
                Expanded(
                  child: Consumer(
                    builder: (context, ref, child) {
                      final sortReviewFirst = ref.watch(sortReviewFirstProvider);
                      return OutlinedButton.icon(
                        onPressed: () {
                          ref.read(sortReviewFirstProvider.notifier).toggle();
                        },
                        icon: Icon(
                          sortReviewFirst ? Icons.sort : Icons.sort_outlined,
                          size: 16,
                        ),
                        label: const Text('Review First'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: sortReviewFirst
                              ? AppTheme.internationalOrange
                              : AppTheme.textSecondary,
                          side: BorderSide(
                            color: sortReviewFirst
                                ? AppTheme.internationalOrange
                                : AppTheme.borderGray,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Books grid
          Expanded(
            child: booksAsync.when(
              data: (books) {
                if (books.isEmpty) {
                  final searchQuery = ref.watch(searchQueryProvider);
                  return Center(
                    child: Text(
                      searchQuery.isEmpty ? 'No books yet' : 'No books found',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  );
                }

                return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1 / 1.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              final isNew = !_seenBookIsbns.contains(book.isbn);

              // Mark this book as seen
              if (isNew) {
                _seenBookIsbns.add(book.isbn);
              }

              return AnimatedBookCard(
                key: ValueKey(book.isbn),
                book: book,
                isNew: isNew,
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: AppTheme.internationalOrange,
          ),
        ),
        error: (error, stack) => Center(
          child: Text(
            'Error loading books',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
        ),
      ),
    ),
        ],
      ),
    );
  }
}

class AnimatedBookCard extends StatefulWidget {
  final Book book;
  final bool isNew;

  const AnimatedBookCard({
    super.key,
    required this.book,
    required this.isNew,
  });

  @override
  State<AnimatedBookCard> createState() => _AnimatedBookCardState();
}

class _AnimatedBookCardState extends State<AnimatedBookCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    // Only animate if this is a new book
    if (widget.isNew) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: BookCard(book: widget.book),
      ),
    );
  }
}

class BookCard extends StatelessWidget {
  final Book book;

  const BookCard({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => BookDetailBottomSheet.show(context, book),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.white,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: AspectRatio(
            aspectRatio: 1 / 1.5,
            child: Stack(
              children: [
                book.coverUrl != null && book.coverUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: book.coverUrl!,
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
                        errorWidget: (context, url, error) => _buildFallbackCard(),
                      )
                    : _buildFallbackCard(),
                // Review needed indicator
                if (book.reviewNeeded)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFCC00), // Yellow
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.warning,
                        size: 14,
                        color: Colors.black,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackCard() {
    return Container(
      color: AppTheme.borderGray,
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              book.title,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
                letterSpacing: 0,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: Text(
              book.author,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                fontWeight: FontWeight.w400,
                color: AppTheme.textSecondary,
                letterSpacing: 0,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
