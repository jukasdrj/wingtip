import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:wingtip/features/camera/image_processing_metrics_provider.dart';

/// Parameters for image processing in isolate
class ImageProcessingParams {
  final String sourcePath;
  final String outputDir;
  final int maxDimension;
  final int quality;

  ImageProcessingParams({
    required this.sourcePath,
    required this.outputDir,
    required this.maxDimension,
    required this.quality,
  });
}

/// Result of image processing
class ImageProcessingResult {
  final String outputPath;
  final int processingTimeMs;
  final int originalSize;
  final int processedSize;

  ImageProcessingResult({
    required this.outputPath,
    required this.processingTimeMs,
    required this.originalSize,
    required this.processedSize,
  });
}

/// Service for processing images in background isolate
class ImageProcessor {
  /// Process an image: resize and compress in background isolate
  ///
  /// This method uses compute() to spawn an isolate for image manipulation,
  /// ensuring the UI thread never janks during processing.
  ///
  /// - Resizes image to max 1920px on longest dimension
  /// - Compresses to JPEG quality 85
  /// - Saves to platform temp directory
  /// - Logs performance metrics
  static Future<ImageProcessingResult> processImage(
    String sourcePath, {
    WidgetRef? ref,
  }) async {
    final startTime = DateTime.now();

    // Get file size before processing
    final sourceFile = File(sourcePath);
    final originalSize = await sourceFile.length();

    debugPrint('[ImageProcessor] Starting image processing for: $sourcePath');
    debugPrint('[ImageProcessor] Original file size: ${(originalSize / 1024).toStringAsFixed(2)} KB');

    // Get temp directory for output (done in main isolate to avoid plugin issues)
    final tempDir = await getTemporaryDirectory();

    // Process image in background isolate
    final params = ImageProcessingParams(
      sourcePath: sourcePath,
      outputDir: tempDir.path,
      maxDimension: 1920,
      quality: 85,
    );

    final outputPath = await compute(_processImageInIsolate, params);

    // Get processed file size
    final processedFile = File(outputPath);
    final processedSize = await processedFile.length();

    final endTime = DateTime.now();
    final processingTimeMs = endTime.difference(startTime).inMilliseconds;

    debugPrint('[ImageProcessor] Image processed in ${processingTimeMs}ms');
    debugPrint('[ImageProcessor] Processed file size: ${(processedSize / 1024).toStringAsFixed(2)} KB');
    debugPrint('[ImageProcessor] Compression ratio: ${((1 - processedSize / originalSize) * 100).toStringAsFixed(1)}%');

    // Verify processing time is under 500ms
    if (processingTimeMs >= 500) {
      debugPrint('[ImageProcessor] WARNING: Processing time exceeded 500ms threshold');
    }

    // Record metrics if ref is provided
    if (ref != null) {
      ref
          .read(imageProcessingMetricsNotifierProvider.notifier)
          .recordProcessingTime(processingTimeMs);
    }

    return ImageProcessingResult(
      outputPath: outputPath,
      processingTimeMs: processingTimeMs,
      originalSize: originalSize,
      processedSize: processedSize,
    );
  }

  /// Process image in isolate (top-level function for compute())
  ///
  /// This function runs in a separate isolate and performs:
  /// 1. Decoding the image from file
  /// 2. Resizing to max dimension on longest side
  /// 3. Encoding to JPEG with quality 85
  /// 4. Saving to temp directory
  static Future<String> _processImageInIsolate(ImageProcessingParams params) async {
    // Read image file
    final imageBytes = await File(params.sourcePath).readAsBytes();

    // Decode image
    final image = img.decodeImage(imageBytes);
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    // Resize image if needed
    img.Image processedImage = image;
    final maxDim = image.width > image.height ? image.width : image.height;

    if (maxDim > params.maxDimension) {
      if (image.width > image.height) {
        // Landscape or square - resize based on width
        processedImage = img.copyResize(
          image,
          width: params.maxDimension,
          interpolation: img.Interpolation.linear,
        );
      } else {
        // Portrait - resize based on height
        processedImage = img.copyResize(
          image,
          height: params.maxDimension,
          interpolation: img.Interpolation.linear,
        );
      }
    }

    // Encode to JPEG with quality 85
    final encodedBytes = img.encodeJpg(processedImage, quality: params.quality);

    // Save file to output directory
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final outputPath = p.join(params.outputDir, 'processed_$timestamp.jpg');

    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(encodedBytes);

    return outputPath;
  }
}
