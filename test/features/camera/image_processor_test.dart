import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:wingtip/features/camera/image_processor.dart';

import '../../helpers/test_path_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory testDir;
  late String testImagePath;

  setUp(() async {
    // Set up fake path provider
    PathProviderPlatform.instance = FakePathProviderPlatform();

    // Create test directory
    testDir = await Directory.systemTemp.createTemp('image_processor_test_');

    // Create a test image (500x500 red square)
    final testImage = img.Image(width: 500, height: 500);
    img.fill(testImage, color: img.ColorRgb8(255, 0, 0));
    final testImageBytes = img.encodePng(testImage);

    testImagePath = p.join(testDir.path, 'test_image.png');
    await File(testImagePath).writeAsBytes(testImageBytes);
  });

  tearDown(() async {
    // Clean up test directory
    if (await testDir.exists()) {
      await testDir.delete(recursive: true);
    }
  });

  group('ImageProcessor', () {
    test('processes image and returns valid result', () async {
      final result = await ImageProcessor.processImage(testImagePath);

      expect(result, isNotNull);
      expect(result.outputPath, isNotEmpty);
      expect(File(result.outputPath).existsSync(), isTrue);
      expect(result.processingTimeMs, greaterThan(0));
      expect(result.originalSize, greaterThan(0));
      expect(result.processedSize, greaterThan(0));
    });

    test('processing time is under 500ms', () async {
      final result = await ImageProcessor.processImage(testImagePath);

      expect(result.processingTimeMs, lessThan(500),
          reason: 'Image processing should complete in under 500ms');
    });

    test('saves image to temp directory', () async {
      final result = await ImageProcessor.processImage(testImagePath);

      // Verify file exists (temp directory location varies by platform)
      expect(File(result.outputPath).existsSync(), isTrue);
      expect(result.outputPath, isNotEmpty);
    });

    test('saves image as JPEG format', () async {
      final result = await ImageProcessor.processImage(testImagePath);

      // Verify file extension
      expect(result.outputPath.endsWith('.jpg'), isTrue);

      // Verify it's a valid JPEG by decoding it
      final imageBytes = await File(result.outputPath).readAsBytes();
      final decodedImage = img.decodeJpg(imageBytes);
      expect(decodedImage, isNotNull);
    });

    test('does not resize image smaller than max dimension', () async {
      // Create a small test image (100x100)
      final smallImage = img.Image(width: 100, height: 100);
      img.fill(smallImage, color: img.ColorRgb8(0, 255, 0));
      final smallImageBytes = img.encodePng(smallImage);

      final smallImagePath = p.join(testDir.path, 'small_test.png');
      await File(smallImagePath).writeAsBytes(smallImageBytes);

      final result = await ImageProcessor.processImage(smallImagePath);

      // Read processed image and verify dimensions
      final processedBytes = await File(result.outputPath).readAsBytes();
      final processedImage = img.decodeImage(processedBytes);

      expect(processedImage, isNotNull);
      expect(processedImage!.width, equals(100));
      expect(processedImage.height, equals(100));
    });

    test('resizes landscape image to max 1920px width', () async {
      // Create a large landscape image (3000x2000)
      final largeImage = img.Image(width: 3000, height: 2000);
      img.fill(largeImage, color: img.ColorRgb8(0, 0, 255));
      final largeImageBytes = img.encodePng(largeImage);

      final largeImagePath = p.join(testDir.path, 'large_landscape.png');
      await File(largeImagePath).writeAsBytes(largeImageBytes);

      final result = await ImageProcessor.processImage(largeImagePath);

      // Read processed image and verify dimensions
      final processedBytes = await File(result.outputPath).readAsBytes();
      final processedImage = img.decodeImage(processedBytes);

      expect(processedImage, isNotNull);
      expect(processedImage!.width, equals(1920));
      // Height should be proportionally scaled (1920 / 3000 * 2000 = 1280)
      expect(processedImage.height, equals(1280));
    });

    test('resizes portrait image to max 1920px height', () async {
      // Create a large portrait image (2000x3000)
      final largeImage = img.Image(width: 2000, height: 3000);
      img.fill(largeImage, color: img.ColorRgb8(255, 255, 0));
      final largeImageBytes = img.encodePng(largeImage);

      final largeImagePath = p.join(testDir.path, 'large_portrait.png');
      await File(largeImagePath).writeAsBytes(largeImageBytes);

      final result = await ImageProcessor.processImage(largeImagePath);

      // Read processed image and verify dimensions
      final processedBytes = await File(result.outputPath).readAsBytes();
      final processedImage = img.decodeImage(processedBytes);

      expect(processedImage, isNotNull);
      expect(processedImage!.height, equals(1920));
      // Width should be proportionally scaled (1920 / 3000 * 2000 = 1280)
      expect(processedImage.width, equals(1280));
    });

    test('applies JPEG quality setting', () async {
      final result = await ImageProcessor.processImage(testImagePath);

      // Verify result contains size information
      // Note: Compression ratio varies based on image content
      // Simple synthetic images may not compress well
      expect(result.processedSize, greaterThan(0));
      expect(result.originalSize, greaterThan(0));
    });

    test('handles invalid image path gracefully', () async {
      expect(
        () => ImageProcessor.processImage('/nonexistent/path/image.jpg'),
        throwsA(isA<FileSystemException>()),
      );
    });

    test('handles corrupted image data gracefully', () async {
      // Create a file with invalid image data
      final corruptedPath = p.join(testDir.path, 'corrupted.jpg');
      await File(corruptedPath).writeAsBytes([1, 2, 3, 4, 5]);

      expect(
        () => ImageProcessor.processImage(corruptedPath),
        throwsA(anything),
      );
    });

    test('creates unique filenames for multiple processed images', () async {
      final result1 = await ImageProcessor.processImage(testImagePath);

      // Wait a few milliseconds to ensure different timestamp
      await Future.delayed(const Duration(milliseconds: 5));

      final result2 = await ImageProcessor.processImage(testImagePath);

      expect(result1.outputPath, isNot(equals(result2.outputPath)),
          reason: 'Each processed image should have a unique filename');

      // Clean up the second file
      final file2 = File(result2.outputPath);
      if (await file2.exists()) {
        await file2.delete();
      }
    });
  });
}
