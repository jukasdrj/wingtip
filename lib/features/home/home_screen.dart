import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wingtip/features/camera/camera_screen.dart';
import 'package:wingtip/features/library/library_screen.dart';
import 'package:wingtip/data/database_provider.dart';
import '../review/review_queue_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const CameraScreen(),
    const ReviewQueueScreen(),
    const LibraryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Watch review queue count for badge
    final database = ref.watch(databaseProvider);
    final reviewQueueCountStream = database.watchReviewQueue().map(
      (list) => list.length,
    );

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: StreamBuilder<int>(
        stream: reviewQueueCountStream,
        initialData: 0,
        builder: (context, snapshot) {
          final count = snapshot.data ?? 0;
          return BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.camera_alt),
                label: 'Capture',
              ),
              BottomNavigationBarItem(
                icon: Badge(
                  isLabelVisible: count > 0,
                  label: Text('$count'),
                  child: const Icon(Icons.rate_review),
                ),
                label: 'Review',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.library_books),
                label: 'Library',
              ),
            ],
          );
        },
      ),
    );
  }
}
