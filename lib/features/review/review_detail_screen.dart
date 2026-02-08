import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import 'package:wingtip/core/theme.dart';
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

  // Source image dimensions for bounding box scaling
  Size? _imageSize;

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

    // Auto-populate fields from ML text blocks if backend hasn't responded
    if (_mlData != null && widget.item.backendResult == null) {
      _populateFromMLTextBlocks();
    }

    // Load image size for bounding box scaling
    _loadImageSize();
  }

  Future<void> _loadImageSize() async {
    try {
      final file = File(widget.item.imagePath);
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final decoded = frame.image;
      if (mounted) {
        setState(() {
          _imageSize = Size(decoded.width.toDouble(), decoded.height.toDouble());
        });
      }
    } catch (e) {
      debugPrint('Error loading image size: $e');
      if (mounted) {
        setState(() {
          _imageSize = const Size(1920, 1080); // Fallback
        });
      }
    }
  }

  void _populateFromMLTextBlocks() {
    final textBlocks = _mlData!['textBlocks'] as List<dynamic>? ?? [];
    if (textBlocks.isNotEmpty) {
      // Sort by text length descending - longest likely title, second likely author
      final sortedBlocks = List<Map<String, dynamic>>.from(textBlocks)
        ..sort((a, b) =>
          (b['text'] as String).length.compareTo((a['text'] as String).length));

      if (sortedBlocks.isNotEmpty) {
        _titleController.text = sortedBlocks[0]['text'] as String? ?? '';
      }
      if (sortedBlocks.length > 1) {
        _authorController.text = sortedBlocks[1]['text'] as String? ?? '';
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
        const SnackBar(content: Text('Please fill in all fields'), backgroundColor: AppTheme.borderGray),
      );
      return;
    }

    final database = ref.read(databaseProvider);

    try {
      // Extract enrichment fields from backend result if available
      String? coverUrl;
      String? format;
      double? spineConfidence;
      if (widget.item.backendResult != null) {
        try {
          final backendData = jsonDecode(widget.item.backendResult!);
          coverUrl = backendData['coverUrl'] as String?;
          format = backendData['format'] as String?;
          final rawConfidence = backendData['spineConfidence'];
          if (rawConfidence is num) {
            spineConfidence = rawConfidence.toDouble();
          }
        } catch (e) {
          debugPrint('Error extracting enrichment data: $e');
        }
      }

      // 1. Insert into Books table
      final book = BooksCompanion.insert(
        isbn: isbn,
        title: title,
        author: author,
        addedDate: DateTime.now().millisecondsSinceEpoch,
        spineImagePath: Value(widget.item.imagePath),
        coverUrl: coverUrl != null && coverUrl.isNotEmpty
            ? Value(coverUrl)
            : const Value.absent(),
        format: format != null && format.isNotEmpty
            ? Value(format)
            : const Value.absent(),
        spineConfidence: spineConfidence != null
            ? Value(spineConfidence)
            : const Value.absent(),
      );

      await database.into(database.books).insertOnConflictUpdate(book);

      // 2. Delete from Review Queue
      await database.deleteReviewQueueItem(widget.item.id);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Book added to library'), backgroundColor: AppTheme.borderGray));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding book: $e'), backgroundColor: AppTheme.borderGray));
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
                  if (_mlData != null && _imageSize != null)
                    CustomPaint(
                      painter: BoundingBoxPainter(
                        mlData: _mlData!,
                        imageSize: _imageSize!,
                      ),
                    ),
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
                    style: AppTheme.monoStyle(),
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
  final Size imageSize; // Source image pixel dimensions

  BoundingBoxPainter({required this.mlData, required this.imageSize});

  @override
  void paint(Canvas canvas, Size canvasSize) {
    // Calculate BoxFit.contain scaling
    final imageAspect = imageSize.width / imageSize.height;
    final canvasAspect = canvasSize.width / canvasSize.height;

    double scale;
    double offsetX = 0;
    double offsetY = 0;

    if (imageAspect > canvasAspect) {
      // Image is wider - fit to width
      scale = canvasSize.width / imageSize.width;
      offsetY = (canvasSize.height - imageSize.height * scale) / 2;
    } else {
      // Image is taller - fit to height
      scale = canvasSize.height / imageSize.height;
      offsetX = (canvasSize.width - imageSize.width * scale) / 2;
    }

    // Paint for object bounding boxes - Swiss Utility International Orange
    final objectPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = const Color(0xFFFF3B30); // International Orange

    // Paint for text blocks - lighter opacity
    final textPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = const Color(0x80FF3B30); // 50% opacity

    final textStyle = TextStyle(
      color: const Color(0xFFFF3B30),
      fontSize: 10,
      fontFamily: 'JetBrainsMono',
      backgroundColor: const Color(0xB3000000), // 70% opacity black
    );

    // Draw bounding boxes for detected objects
    final objects = mlData['objects'] as List<dynamic>? ?? [];
    for (final obj in objects) {
      final bbox = obj['boundingBox'] as Map<String, dynamic>?;
      if (bbox == null) continue;

      // Scale absolute pixel coordinates to display coordinates
      final left = (bbox['left'] as num).toDouble();
      final top = (bbox['top'] as num).toDouble();
      final width = (bbox['width'] as num).toDouble();
      final height = (bbox['height'] as num).toDouble();

      final scaledRect = Rect.fromLTWH(
        left * scale + offsetX,
        top * scale + offsetY,
        width * scale,
        height * scale,
      );

      canvas.drawRect(scaledRect, objectPaint);

      // Draw label with confidence
      final labels = obj['labels'] as List<dynamic>? ?? [];
      if (labels.isNotEmpty) {
        final label = labels.first;
        final text = label['text'] as String? ?? '';
        final confidence = (label['confidence'] as num?)?.toDouble() ?? 0;
        final labelText = '$text ${(confidence * 100).toInt()}%';

        final textSpan = TextSpan(text: labelText, style: textStyle);
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        )..layout();

        textPainter.paint(
          canvas,
          Offset(scaledRect.left, scaledRect.top - textPainter.height - 2),
        );
      }
    }

    // Draw bounding boxes for text blocks
    final textBlocks = mlData['textBlocks'] as List<dynamic>? ?? [];
    for (final block in textBlocks) {
      final bbox = block['boundingBox'] as Map<String, dynamic>?;
      if (bbox == null) continue;

      final left = (bbox['left'] as num).toDouble();
      final top = (bbox['top'] as num).toDouble();
      final width = (bbox['width'] as num).toDouble();
      final height = (bbox['height'] as num).toDouble();

      final scaledRect = Rect.fromLTWH(
        left * scale + offsetX,
        top * scale + offsetY,
        width * scale,
        height * scale,
      );

      canvas.drawRect(scaledRect, textPaint);
    }
  }

  @override
  bool shouldRepaint(covariant BoundingBoxPainter oldDelegate) {
    return oldDelegate.mlData != mlData || oldDelegate.imageSize != imageSize;
  }
}
