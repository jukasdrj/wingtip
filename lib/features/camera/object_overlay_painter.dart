import 'package:flutter/material.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

class ObjectOverlayPainter extends CustomPainter {
  final List<Map<String, dynamic>> objects;
  final Size absoluteImageSize;
  final InputImageRotation rotation;

  ObjectOverlayPainter({
    required this.objects,
    required this.absoluteImageSize,
    required this.rotation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = const Color(0xFFFF4500); // International Orange

    final Paint fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFFF4500).withValues(alpha: 0.2);

    for (final object in objects) {
      final boundingBox = object['boundingBox'] as Map<String, dynamic>;

      final left = boundingBox['left'] as double;
      final top = boundingBox['top'] as double;
      final width = boundingBox['width'] as double;
      final height = boundingBox['height'] as double;

      final rect = Rect.fromLTWH(left, top, width, height);
      final scaledRect = _scaleRect(
        rect: rect,
        imageSize: absoluteImageSize,
        widgetSize: size,
        rotation: rotation,
      );

      canvas.drawRect(scaledRect, paint);
      canvas.drawRect(scaledRect, fillPaint);

      // Draw label background
      final labelText = "Book"; // Or use object labels
      final textSpan = TextSpan(
        text: labelText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      final labelRect = Rect.fromLTWH(
        scaledRect.left,
        scaledRect.top - textPainter.height - 4,
        textPainter.width + 8,
        textPainter.height + 4,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(labelRect, const Radius.circular(4)),
        Paint()..color = const Color(0xFFFF4500),
      );

      textPainter.paint(
        canvas,
        Offset(scaledRect.left + 4, scaledRect.top - textPainter.height - 2),
      );
    }
  }

  // TODO: Fix rotation logic for iOS/Android specifics if needed
  // This is a simplified scaling assuming portrait mode for now
  Rect _scaleRect({
    required Rect rect,
    required Size imageSize,
    required Size widgetSize,
    required InputImageRotation rotation,
  }) {
    // For portrait mode (common in mobile), image source is usually rotated 90deg
    // The imageSize we get from CameraImage is effectively width/height swapped relative to UI
    // But we need to check the rotation.

    double scaleX = widgetSize.width / imageSize.height;
    double scaleY = widgetSize.height / imageSize.width;

    // Check if we need to swap dimensions based on rotation
    if (rotation == InputImageRotation.rotation0deg ||
        rotation == InputImageRotation.rotation180deg) {
      scaleX = widgetSize.width / imageSize.width;
      scaleY = widgetSize.height / imageSize.height;
    }

    // Scale to fit (cover)
    // Actually for camera preview, it's usually "cover"
    // Let's assume aspect ratios match for now or use simplified scaling

    return Rect.fromLTRB(
      rect.left * scaleX,
      rect.top * scaleY,
      rect.right * scaleX,
      rect.bottom * scaleY,
    );
  }

  @override
  bool shouldRepaint(ObjectOverlayPainter oldDelegate) {
    return oldDelegate.objects != objects ||
        oldDelegate.absoluteImageSize != absoluteImageSize ||
        oldDelegate.rotation != rotation;
  }
}
