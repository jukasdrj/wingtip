import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wingtip/features/camera/camera_service.dart';

final cameraServiceProvider = Provider<CameraService>((ref) {
  return CameraService();
});
