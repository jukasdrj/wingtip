import 'dart:io';
import 'dart:ui';
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

  void dispose() {
    _textRecognizer.close();
    _objectDetector.close();
  }
}
