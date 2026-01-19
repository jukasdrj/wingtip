import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wingtip/features/camera/camera_settings_service.dart';

final cameraSettingsServiceProvider = Provider<CameraSettingsService>((ref) {
  throw UnimplementedError('cameraSettingsServiceProvider not initialized');
});

/// Provider for initializing camera settings service
/// This should be overridden in main.dart with actual SharedPreferences instance
Future<CameraSettingsService> createCameraSettingsService() async {
  final prefs = await SharedPreferences.getInstance();
  return CameraSettingsService(prefs);
}
