import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../core/performance_overlay_provider.dart';
import '../../data/database.dart';
import '../../data/database_provider.dart';
import '../../data/failed_scans_repository.dart';
import '../../features/talaria/job_state_provider.dart';
import 'library_provider.dart';
import 'book_detail_screen.dart';
import 'widgets/empty_library_state.dart';
import 'widgets/failed_scan_card.dart' as failed_card;

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with SingleTickerProviderStateMixin {
  final Set<String> _seenBookIsbns = {};
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    ref.read(searchQueryProvider.notifier).setQuery(_searchController.text);
  }

  Future<void> _showDeleteConfirmation(BuildContext context, int count) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.borderGray,
        title: Text(
          'Delete $count ${count == 1 ? 'book' : 'books'}?',
          style: const TextStyle(color: AppTheme.textPrimary),
        ),
        content: Text(
          'This action cannot be undone.',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppTheme.internationalOrange),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final selectedBooks = ref.read(selectedBooksProvider);
      final database = ref.read(databaseProvider);

      await database.deleteBooks(selectedBooks.toList());

      ref.read(selectModeProvider.notifier).disable();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted $count ${count == 1 ? 'book' : 'books'}'),
            backgroundColor: AppTheme.borderGray,
          ),
        );
      }
    }
  }

  Future<void> _showDeleteFailedScansConfirmation(BuildContext context, int count, List<FailedScan> allScans) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.borderGray,
        title: Text(
          'Delete $count failed ${count == 1 ? 'scan' : 'scans'}?',
          style: const TextStyle(color: AppTheme.textPrimary),
        ),
        content: Text(
          'This action cannot be undone.',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppTheme.internationalOrange),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final selectedJobIds = ref.read(selectedFailedScansProvider);

      // Find scans to delete based on selected job IDs
      final scansToDelete = allScans.where((scan) => selectedJobIds.contains(scan.jobId)).toList();

      final repository = ref.read(failedScansRepositoryProvider);

      // Delete each failed scan
      for (final scan in scansToDelete) {
        await repository.deleteFailedScan(scan.id);
      }

      ref.read(failedScanSelectModeProvider.notifier).disable();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted $count failed ${count == 1 ? 'scan' : 'scans'}'),
            backgroundColor: AppTheme.borderGray,
          ),
        );
      }
    }
  }

  Future<void> _showClearAllFailedScansConfirmation(BuildContext context, int count) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.borderGray,
        title: Text(
          'Delete all $count failed ${count == 1 ? 'scan' : 'scans'}?',
          style: const TextStyle(color: AppTheme.textPrimary),
        ),
        content: Text(
          'This action cannot be undone.',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppTheme.internationalOrange),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final repository = ref.read(failedScansRepositoryProvider);
      await repository.clearAllFailedScans();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted all $count failed ${count == 1 ? 'scan' : 'scans'}'),
            backgroundColor: AppTheme.borderGray,
          ),
        );
      }
    }
  }

  Future<void> _retryAllFailedScans(BuildContext context, int total) async {
    if (total == 0) return;

    // Show initial progress snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Retrying 0 of $total...'),
        backgroundColor: AppTheme.borderGray,
        duration: const Duration(days: 1), // Keep it visible until we dismiss it
      ),
    );

    // Start the batch retry process
    final result = await ref.read(jobStateProvider.notifier).retryAllFailedScans(
      onProgress: (current, total) {
        // Update progress toast
        if (context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Retrying $current of $total...'),
              backgroundColor: AppTheme.borderGray,
              duration: const Duration(days: 1), // Keep it visible
            ),
          );
        }
      },
    );

    // Hide progress toast
    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Show summary toast
      final succeeded = result['succeeded'] ?? 0;
      final failed = result['failed'] ?? 0;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$succeeded succeeded, $failed failed'),
          backgroundColor: AppTheme.borderGray,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(booksProvider);
    final failedScansAsync = ref.watch(watchFailedScansProvider);
    final selectMode = ref.watch(selectModeProvider);
    final selectedBooks = ref.watch(selectedBooksProvider);
    final failedScanSelectMode = ref.watch(failedScanSelectModeProvider);
    final selectedFailedScans = ref.watch(selectedFailedScansProvider);

    final failedScansCount = failedScansAsync.maybeWhen(
      data: (scans) => scans.length,
      orElse: () => 0,
    );

    // Determine which mode is active and show appropriate title/actions
    final String appBarTitle;
    final Widget? appBarLeading;
    final List<Widget>? appBarActions;

    if (selectMode) {
      appBarTitle = '${selectedBooks.length} selected';
      appBarLeading = IconButton(
        icon: const Icon(Icons.close),
        onPressed: () {
          ref.read(selectModeProvider.notifier).disable();
        },
      );
      appBarActions = selectedBooks.isNotEmpty
          ? [
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _showDeleteConfirmation(context, selectedBooks.length),
              ),
            ]
          : null;
    } else if (failedScanSelectMode) {
      appBarTitle = '${selectedFailedScans.length} selected';
      appBarLeading = IconButton(
        icon: const Icon(Icons.close),
        onPressed: () {
          ref.read(failedScanSelectModeProvider.notifier).disable();
        },
      );
      appBarActions = selectedFailedScans.isNotEmpty
          ? [
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  // Get the current scans from the async value
                  failedScansAsync.whenData((scans) {
                    _showDeleteFailedScansConfirmation(context, selectedFailedScans.length, scans);
                  });
                },
              ),
            ]
          : null;
    } else {
      appBarTitle = 'Library';
      appBarLeading = null;
      appBarActions = null;
    }

    return Scaffold(
      backgroundColor: AppTheme.oledBlack,
      appBar: AppBar(
        title: GestureDetector(
          // Long press on title to toggle performance overlay
          onLongPress: () {
            HapticFeedback.mediumImpact();
            ref.read(performanceOverlayProvider.notifier).toggle();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  ref.read(performanceOverlayProvider)
                      ? 'Performance overlay enabled'
                      : 'Performance overlay disabled',
                ),
                backgroundColor: AppTheme.borderGray,
                duration: const Duration(seconds: 1),
              ),
            );
          },
          child: Text(appBarTitle),
        ),
        backgroundColor: AppTheme.oledBlack,
        elevation: 0,
        leading: appBarLeading,
        actions: appBarActions,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(49),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.internationalOrange,
                labelColor: AppTheme.textPrimary,
                unselectedLabelColor: AppTheme.textSecondary,
                tabs: [
                  const Tab(text: 'All Books'),
                  Tab(
                    text: failedScansCount > 0
                        ? 'Failed ($failedScansCount)'
                        : 'Failed',
                  ),
                ],
              ),
              Container(
                color: AppTheme.borderGray,
                height: 1,
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // All Books Tab
          _buildBooksTab(context, booksAsync),
          // Failed Scans Tab
          _buildFailedScansTab(context, failedScansAsync),
        ],
      ),
    );
  }

  Widget _buildBooksTab(BuildContext context, AsyncValue<List<Book>> booksAsync) {
    return Column(
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
                  // Show empty state only when no search is active
                  if (searchQuery.isEmpty) {
                    return const EmptyLibraryState();
                  }
                  // Show "No books found" for search results
                  return Center(
                    child: Text(
                      'No books found',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  );
                }

                return GridView.builder(
            padding: const EdgeInsets.all(16),
            // Enable iOS ProMotion scroll physics
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
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

              // Wrap each item in RepaintBoundary for 120fps scroll
              return RepaintBoundary(
                child: AnimatedBookCard(
                  key: ValueKey(book.isbn),
                  book: book,
                  isNew: isNew,
                ),
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
    );
  }

  Widget _buildFailedScansTab(BuildContext context, AsyncValue<List<FailedScan>> failedScansAsync) {
    return failedScansAsync.when(
      data: (scans) {
        if (scans.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  'No failed scans',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ],
            ),
          );
        }

        final failedScanSelectMode = ref.watch(failedScanSelectModeProvider);

        return Column(
          children: [
            // Batch action buttons at top (hidden in select mode)
            if (!failedScanSelectMode)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Retry All button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          HapticFeedback.lightImpact();
                          await _retryAllFailedScans(context, scans.length);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.internationalOrange,
                          foregroundColor: AppTheme.textPrimary,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            side: const BorderSide(
                              color: AppTheme.internationalOrange,
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Retry All'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Clear All Failed button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          HapticFeedback.lightImpact();
                          await _showClearAllFailedScansConfirmation(context, scans.length);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textSecondary,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          side: const BorderSide(
                            color: AppTheme.borderGray,
                            width: 1.0,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Clear All Failed'),
                      ),
                    ),
                  ],
                ),
              ),
            // Failed scans list
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                // Enable iOS ProMotion scroll physics
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                itemCount: scans.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final scan = scans[index];
                  // Wrap each item in RepaintBoundary for 120fps scroll
                  return RepaintBoundary(
                    child: failed_card.FailedScanCard(
                      failedScan: scan,
                      onRetry: () async {
                        // Trigger retry via JobStateNotifier
                        await ref.read(jobStateProvider.notifier).retryFailedScan(scan.jobId);
                      },
                      onDelete: () async {
                        // Delete the failed scan
                        await ref.read(failedScansRepositoryProvider).deleteFailedScan(scan.id);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(
          color: AppTheme.internationalOrange,
        ),
      ),
      error: (error, stack) => Center(
        child: Text(
          'Error loading failed scans',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textSecondary,
              ),
        ),
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
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic, // iOS-native cubic bezier for 120Hz
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic, // iOS-native cubic bezier for 120Hz
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
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: BookCard(book: widget.book),
      ),
    );
  }
}

class BookCard extends ConsumerStatefulWidget {
  final Book book;

  const BookCard({super.key, required this.book});

  @override
  ConsumerState<BookCard> createState() => _BookCardState();
}

class _BookCardState extends ConsumerState<BookCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _coverAnimationController;
  late Animation<double> _coverFadeAnimation;
  late Animation<double> _coverScaleAnimation;
  bool _imageLoaded = false;

  @override
  void initState() {
    super.initState();

    _coverAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _coverFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _coverAnimationController,
      curve: Curves.easeOutCubic, // iOS-native cubic bezier for 120Hz
    ));

    _coverScaleAnimation = Tween<double>(
      begin: 0.92,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _coverAnimationController,
      curve: Curves.easeOutCubic, // iOS-native cubic bezier for 120Hz
    ));

    // Start animation immediately if no cover URL
    if (widget.book.coverUrl == null || widget.book.coverUrl!.isEmpty) {
      _coverAnimationController.value = 1.0;
      _imageLoaded = true;
    }
  }

  @override
  void dispose() {
    _coverAnimationController.dispose();
    super.dispose();
  }

  void _onImageLoaded() {
    if (!_imageLoaded && mounted) {
      setState(() {
        _imageLoaded = true;
      });
      _coverAnimationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectMode = ref.watch(selectModeProvider);
    final selectedBooks = ref.watch(selectedBooksProvider);
    final isSelected = selectedBooks.contains(widget.book.isbn);

    return GestureDetector(
      onTap: () {
        if (selectMode) {
          ref.read(selectedBooksProvider.notifier).toggle(widget.book.isbn);
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => BookDetailScreen(book: widget.book),
            ),
          );
        }
      },
      onLongPress: () {
        if (!selectMode) {
          ref.read(selectModeProvider.notifier).enable();
          ref.read(selectedBooksProvider.notifier).toggle(widget.book.isbn);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: selectMode && isSelected ? AppTheme.internationalOrange : Colors.white,
            width: selectMode && isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: AspectRatio(
            aspectRatio: 1 / 1.5,
            child: Stack(
              children: [
                Hero(
                  tag: 'book-cover-${widget.book.isbn}',
                  child: widget.book.coverUrl != null && widget.book.coverUrl!.isNotEmpty
                      ? FadeTransition(
                          opacity: _coverFadeAnimation,
                          child: ScaleTransition(
                            scale: _coverScaleAnimation,
                            child: CachedNetworkImage(
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
                              errorWidget: (context, url, error) => _buildFallbackCard(),
                              imageBuilder: (context, imageProvider) {
                                // Trigger animation when image loads
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  _onImageLoaded();
                                });
                                return Image(
                                  image: imageProvider,
                                  fit: BoxFit.cover,
                                );
                              },
                            ),
                          ),
                        )
                      : _buildFallbackCard(),
                ),
                // Review needed indicator
                if (widget.book.reviewNeeded && !selectMode)
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
                // Checkbox in select mode
                if (selectMode)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.internationalOrange : AppTheme.borderGray,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
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
              widget.book.title,
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
              widget.book.author,
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

