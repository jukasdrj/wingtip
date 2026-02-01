import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wingtip/data/database.dart';
import 'package:wingtip/data/database_provider.dart';

class ReviewDetailScreen extends ConsumerStatefulWidget {
  final ReviewQueueItem item;

  const ReviewDetailScreen({super.key, required this.item});

  @override
  ConsumerState<ReviewDetailScreen> createState() => _ReviewDetailScreenState();
}

class _ReviewDetailScreenState extends ConsumerState<ReviewDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _authorController;
  late TextEditingController _isbnController;

  // To store parsed ML results
  Map<String, dynamic>? _mlData;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _authorController = TextEditingController();
    _isbnController = TextEditingController();

    // Parse ML data if available
    if (widget.item.mlResult != null) {
      try {
        _mlData = jsonDecode(widget.item.mlResult!);
        // Basic extraction logic could go here to populate fields automatically
        // For now, we leave fields empty or populate if we improve extraction logic
      } catch (e) {
        debugPrint('Error parsing ML result: $e');
      }
    }

    // Check backend result (if we merge backend results into this item as well)
    if (widget.item.backendResult != null) {
      try {
        final backendData = jsonDecode(widget.item.backendResult!);
        _titleController.text = backendData['title'] ?? '';
        _authorController.text = backendData['author'] ?? '';
        _isbnController.text = backendData['isbn'] ?? '';
      } catch (e) {
        debugPrint('Error parsing backend result: $e');
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _isbnController.dispose();
    super.dispose();
  }

  Future<void> _acceptBook() async {
    final title = _titleController.text.trim();
    final author = _authorController.text.trim();
    final isbn = _isbnController.text.trim();

    if (title.isEmpty || author.isEmpty || isbn.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    final database = ref.read(databaseProvider);

    try {
      // 1. Insert into Books table
      final book = BooksCompanion.insert(
        isbn: isbn,
        title: title,
        author: author,
        addedDate: DateTime.now().millisecondsSinceEpoch,
        // Optionally copy the image to a permanent location if needed
        // For now, assuming we keep using the local path or move it
      );

      await database.into(database.books).insertOnConflictUpdate(book);

      // 2. Delete from Review Queue
      await database.deleteReviewQueueItem(widget.item.id);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Book added to library')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding book: $e')));
      }
    }
  }

  Future<void> _rejectItem() async {
    final database = ref.read(databaseProvider);
    await database.deleteReviewQueueItem(widget.item.id);
    // Optionally delete the file as well
    try {
      final file = File(widget.item.imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error deleting file: $e');
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Item'),
        actions: [
          IconButton(icon: const Icon(Icons.delete), onPressed: _rejectItem),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 300,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(File(widget.item.imagePath), fit: BoxFit.contain),
                  if (_mlData != null)
                    CustomPaint(painter: BoundingBoxPainter(mlData: _mlData!)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  TextField(
                    controller: _authorController,
                    decoration: const InputDecoration(labelText: 'Author'),
                  ),
                  TextField(
                    controller: _isbnController,
                    decoration: const InputDecoration(labelText: 'ISBN'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _acceptBook,
                    child: const Text('Add to Library'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BoundingBoxPainter extends CustomPainter {
  final Map<String, dynamic> mlData;

  BoundingBoxPainter({required this.mlData});

  @override
  void paint(Canvas canvas, Size size) {
    // TODO: Need logic to scale normalized rects to display size
    // Assuming for now we just draw raw if coordinates match
    // Real implementation requires scaling based on image aspect ratio vs display aspect ratio
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
