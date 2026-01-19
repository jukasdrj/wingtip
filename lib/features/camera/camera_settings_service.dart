import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing camera settings and preferences
class CameraSettingsService {
  static const String _nightModePreferenceKey = 'camera_night_mode_enabled';
  static const String _autoNightModeKey = 'camera_auto_night_mode';

  final SharedPreferences _prefs;

  CameraSettingsService(this._prefs);

  /// Get Night Mode preference
  bool get nightModeEnabled {
    return _prefs.getBool(_nightModePreferenceKey) ?? false;
  }

  /// Set Night Mode preference
  Future<void> setNightModeEnabled(bool enabled) async {
    await _prefs.setBool(_nightModePreferenceKey, enabled);
    debugPrint('[CameraSettings] Night Mode preference: $enabled');
  }

  /// Get Auto Night Mode preference
  bool get autoNightModeEnabled {
    return _prefs.getBool(_autoNightModeKey) ?? true; // Default to enabled
  }

  /// Set Auto Night Mode preference
  Future<void> setAutoNightModeEnabled(bool enabled) async {
    await _prefs.setBool(_autoNightModeKey, enabled);
    debugPrint('[CameraSettings] Auto Night Mode: $enabled');
  }
}
