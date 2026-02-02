import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

class BarcodeOverlayPainter extends CustomPainter {
  final List<Map<String, dynamic>> barcodes;
  final Size absoluteImageSize;
  final InputImageRotation rotation;

  BarcodeOverlayPainter({
    required this.barcodes,
    required this.absoluteImageSize,
    required this.rotation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = const Color(0xFF00BCD4); // Cyan

    for (final barcode in barcodes) {
      final boundingBox = barcode['boundingBox'] as Rect;
      final isbn = barcode['isbn'] as String;

      final scaledRect = _scaleRect(
        rect: boundingBox,
        imageSize: absoluteImageSize,
        widgetSize: size,
        rotation: rotation,
      );

      // Draw dashed border
      _drawDashedRect(
        canvas: canvas,
        rect: scaledRect,
        paint: paint,
        dashWidth: 8.0,
        dashSpace: 4.0,
      );

      // Draw ISBN text above the bounding box
      final textSpan = TextSpan(
        text: isbn,
        style: const TextStyle(
          color: Color(0xFF00BCD4), // Cyan
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontFamily: 'JetBrains Mono',
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      // Background for text
      final labelRect = Rect.fromLTWH(
        scaledRect.left,
        scaledRect.top - textPainter.height - 8,
        textPainter.width + 12,
        textPainter.height + 6,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(labelRect, const Radius.circular(4)),
        Paint()..color = Colors.black.withValues(alpha: 0.8),
      );

      // Paint text
      textPainter.paint(
        canvas,
        Offset(scaledRect.left + 6, scaledRect.top - textPainter.height - 5),
      );
    }
  }

  void _drawDashedRect({
    required Canvas canvas,
    required Rect rect,
    required Paint paint,
    required double dashWidth,
    required double dashSpace,
  }) {
    // Top edge
    _drawDashedLine(
      canvas: canvas,
      p1: rect.topLeft,
      p2: rect.topRight,
      paint: paint,
      dashWidth: dashWidth,
      dashSpace: dashSpace,
    );

    // Right edge
    _drawDashedLine(
      canvas: canvas,
      p1: rect.topRight,
      p2: rect.bottomRight,
      paint: paint,
      dashWidth: dashWidth,
      dashSpace: dashSpace,
    );

    // Bottom edge
    _drawDashedLine(
      canvas: canvas,
      p1: rect.bottomRight,
      p2: rect.bottomLeft,
      paint: paint,
      dashWidth: dashWidth,
      dashSpace: dashSpace,
    );

    // Left edge
    _drawDashedLine(
      canvas: canvas,
      p1: rect.bottomLeft,
      p2: rect.topLeft,
      paint: paint,
      dashWidth: dashWidth,
      dashSpace: dashSpace,
    );
  }

  void _drawDashedLine({
    required Canvas canvas,
    required Offset p1,
    required Offset p2,
    required Paint paint,
    required double dashWidth,
    required double dashSpace,
  }) {
    final path = ui.Path();
    final distance = (p2 - p1).distance;
    final normalizedVector = Offset(
      (p2.dx - p1.dx) / distance,
      (p2.dy - p1.dy) / distance,
    );

    double currentDistance = 0.0;
    while (currentDistance < distance) {
      final start = Offset(
        p1.dx + normalizedVector.dx * currentDistance,
        p1.dy + normalizedVector.dy * currentDistance,
      );

      currentDistance += dashWidth;
      final end = Offset(
        p1.dx + normalizedVector.dx * currentDistance.clamp(0, distance),
        p1.dy + normalizedVector.dy * currentDistance.clamp(0, distance),
      );

      path.moveTo(start.dx, start.dy);
      path.lineTo(end.dx, end.dy);

      currentDistance += dashSpace;
    }

    canvas.drawPath(path, paint);
  }

  Rect _scaleRect({
    required Rect rect,
    required Size imageSize,
    required Size widgetSize,
    required InputImageRotation rotation,
  }) {
    // For portrait mode (common in mobile), image source is usually rotated 90deg
    // The imageSize we get from CameraImage is effectively width/height swapped relative to UI
    double scaleX = widgetSize.width / imageSize.height;
    double scaleY = widgetSize.height / imageSize.width;

    // Check if we need to swap dimensions based on rotation
    if (rotation == InputImageRotation.rotation0deg ||
        rotation == InputImageRotation.rotation180deg) {
      scaleX = widgetSize.width / imageSize.width;
      scaleY = widgetSize.height / imageSize.height;
    }

    return Rect.fromLTRB(
      rect.left * scaleX,
      rect.top * scaleY,
      rect.right * scaleX,
      rect.bottom * scaleY,
    );
  }

  @override
  bool shouldRepaint(BarcodeOverlayPainter oldDelegate) {
    return oldDelegate.barcodes != barcodes ||
        oldDelegate.absoluteImageSize != absoluteImageSize ||
        oldDelegate.rotation != rotation;
  }
}
