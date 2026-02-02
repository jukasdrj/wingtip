import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

class LocalProcessorService {
  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );
  late final ObjectDetector _objectDetector;

  LocalProcessorService() {
    final options = ObjectDetectorOptions(
      mode: DetectionMode.single,
      classifyObjects: true,
      multipleObjects: true,
    );
    _objectDetector = ObjectDetector(options: options);
  }

  Future<Map<String, dynamic>> processImage(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);

    // Run Text Recognition
    final recognizedText = await _textRecognizer.processImage(inputImage);

    // Run Object Detection
    final objects = await _objectDetector.processImage(inputImage);

    // Process Text Blocks
    final textBlocks = recognizedText.blocks.map((block) {
      return {
        'text': block.text,
        'boundingBox': _rectToMap(block.boundingBox),
        'cornerPoints': block.cornerPoints
            .map((p) => {'x': p.x, 'y': p.y})
            .toList(),
      };
    }).toList();

    // Process Objects
    final detectedObjects = objects.map((object) {
      return {
        'trackingId': object.trackingId,
        'labels': object.labels
            .map(
              (l) => {
                'text': l.text,
                'confidence': l.confidence,
                'index': l.index,
              },
            )
            .toList(),
        'boundingBox': _rectToMap(object.boundingBox),
      };
    }).toList();

    return {
      'textBlocks': textBlocks,
      'objects': detectedObjects,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  Map<String, double> _rectToMap(Rect rect) {
    return {
      'left': rect.left,
      'top': rect.top,
      'width': rect.width,
      'height': rect.height,
    };
  }

  Future<Map<String, dynamic>> processCameraImage(
    CameraImage image,
    int sensorOrientation,
    DeviceOrientation deviceOrientation,
  ) async {
    final inputImage = _inputImageFromCameraImage(
      image,
      sensorOrientation,
      deviceOrientation,
    );

    if (inputImage == null) return {};

    // For stream, we prioritize Object Detection (bounding boxes)
    // We can also periodically run text recognition if needed, but let's start with objects
    final objects = await _objectDetector.processImage(inputImage);

    // Process Objects
    final detectedObjects = objects.map((object) {
      return {
        'trackingId': object.trackingId,
        'labels': object.labels
            .map(
              (l) => {
                'text': l.text,
                'confidence': l.confidence,
                'index': l.index,
              },
            )
            .toList(),
        'boundingBox': _rectToMap(object.boundingBox),
      };
    }).toList();

    return {
      'objects': detectedObjects,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  InputImage? _inputImageFromCameraImage(
    CameraImage image,
    int sensorOrientation,
    DeviceOrientation deviceOrientation,
  ) {
    // get image rotation
    // it is used in android to convert the image to bitmap
    // and in ios to rotate the image
    final rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    if (rotation == null) return null;

    // get image format
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    // validate format depending on platform
    // only supported formats:
    // * nv21 for Android
    // * bgra8888 for iOS
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) {
      return null;
    }

    // since we use camera package, we pass the image planes
    if (image.planes.length != 1) return null;
    final plane = image.planes.first;

    // compose InputImage
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation, // used only in Android
        format: format, // used only in iOS
        bytesPerRow: plane.bytesPerRow, // used only in iOS
      ),
    );
  }

  void dispose() {
    _textRecognizer.close();
    _objectDetector.close();
  }
}
