import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:wingtip/core/ml_kit_image_converter.dart';

/// Result of an ISBN barcode scan.
class IsbnResult {
  final String isbn;
  final Rect boundingBox;
  final String rawValue;
  final BarcodeFormat format;

  IsbnResult({
    required this.isbn,
    required this.boundingBox,
    required this.rawValue,
    required this.format,
  });

  @override
  String toString() =>
      'IsbnResult(isbn: $isbn, format: $format, rawValue: $rawValue)';
}

/// Service for detecting ISBN barcodes using ML Kit.
///
/// Supports EAN-13 (standard ISBN) and EAN-8 formats.
/// Validates ISBN-13 checksums before returning results.
class BarcodeService {
  final BarcodeScanner _barcodeScanner;

  /// Creates a BarcodeService.
  ///
  /// [scanner] can be provided for testing. If null, uses ML Kit's
  /// BarcodeScanner configured for EAN-13 and EAN-8 formats.
  BarcodeService({BarcodeScanner? scanner})
      : _barcodeScanner = scanner ??
            BarcodeScanner(formats: [
              BarcodeFormat.ean13,
              BarcodeFormat.ean8,
            ]);

  /// Scans for ISBN barcodes from a file image.
  ///
  /// Returns a list of validated ISBN results found in the image.
  Future<List<IsbnResult>> scanFromFile(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    return _processInputImage(inputImage);
  }

  /// Scans for ISBN barcodes from a camera stream image.
  ///
  /// Uses the shared [inputImageFromCameraImage] converter.
  /// Returns a list of validated ISBN results found in the image.
  Future<List<IsbnResult>> scanFromCameraImage(
    CameraImage image,
    int sensorOrientation,
    DeviceOrientation deviceOrientation,
  ) async {
    final inputImage = inputImageFromCameraImage(
      image,
      sensorOrientation,
      deviceOrientation,
    );

    if (inputImage == null) return [];

    return _processInputImage(inputImage);
  }

  /// Processes an InputImage and returns validated ISBN results.
  Future<List<IsbnResult>> _processInputImage(InputImage inputImage) async {
    final barcodes = await _barcodeScanner.processImage(inputImage);

    final results = <IsbnResult>[];
    for (final barcode in barcodes) {
      // Only process EAN-13 and EAN-8 formats
      if (barcode.format != BarcodeFormat.ean13 &&
          barcode.format != BarcodeFormat.ean8) {
        continue;
      }

      final rawValue = barcode.rawValue;
      if (rawValue == null || rawValue.isEmpty) continue;

      // Validate ISBN-13 checksum
      if (barcode.format == BarcodeFormat.ean13) {
        if (!isValidIsbn13(rawValue)) continue;
      }

      // Extract bounding box
      final boundingBox = barcode.boundingBox;

      results.add(IsbnResult(
        isbn: rawValue,
        boundingBox: boundingBox,
        rawValue: rawValue,
        format: barcode.format,
      ));
    }

    return results;
  }

  /// Validates an ISBN-13 checksum.
  ///
  /// Returns true if the checksum is valid, false otherwise.
  static bool isValidIsbn13(String isbn) {
    if (isbn.length != 13) return false;
    int sum = 0;
    for (int i = 0; i < 12; i++) {
      final digit = int.tryParse(isbn[i]);
      if (digit == null) return false;
      sum += (i.isEven) ? digit : digit * 3;
    }
    final checkDigit = (10 - (sum % 10)) % 10;
    return checkDigit == int.tryParse(isbn[12]);
  }

  /// Disposes of the barcode scanner.
  ///
  /// Call this when the service is no longer needed.
  void dispose() {
    _barcodeScanner.close();
  }
}
