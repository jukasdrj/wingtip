import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

InputImage? inputImageFromCameraImage(
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
