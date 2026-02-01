import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wingtip/data/database.dart';
import 'package:wingtip/data/database_provider.dart';
import 'review_detail_screen.dart';

class ReviewQueueScreen extends ConsumerWidget {
  const ReviewQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewQueueAsync = ref.watch(reviewQueueStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Review Queue')),
      body: reviewQueueAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No items to review'));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _ReviewItemTile(item: item);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _ReviewItemTile extends StatelessWidget {
  final ReviewQueueItem item;

  const _ReviewItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ReviewDetailScreen(item: item),
          ),
        );
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            File(item.imagePath),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const Center(child: Icon(Icons.broken_image)),
          ),
          if (item.status != 'ready')
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          if (item.status == 'ready')
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 12, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

final reviewQueueStreamProvider = StreamProvider<List<ReviewQueueItem>>((ref) {
  final database = ref.watch(databaseProvider);
  return database.watchReviewQueue();
});
