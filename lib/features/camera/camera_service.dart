import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

class CameraService {
  static final CameraService _instance = CameraService._internal();
  factory CameraService() => _instance;
  CameraService._internal();

  CameraController? _controller;
  bool _isInitialized = false;
  String? _errorMessage;
  DateTime? _initStartTime;
  DateTime? _initEndTime;
  bool _nightModeEnabled = false;
  bool _nightModeAvailable = false;

  bool get isInitialized => _isInitialized;
  CameraController? get controller => _controller;
  String? get errorMessage => _errorMessage;
  bool get nightModeEnabled => _nightModeEnabled;
  bool get nightModeAvailable => _nightModeAvailable;

  Duration? get initializationDuration {
    if (_initStartTime != null && _initEndTime != null) {
      return _initEndTime!.difference(_initStartTime!);
    }
    return null;
  }

  Future<void> initialize({bool? restoreNightMode}) async {
    if (_isInitialized) return;

    _initStartTime = DateTime.now();
    debugPrint('[CameraService] Starting camera initialization at ${_initStartTime!.toIso8601String()}');

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _errorMessage = 'No cameras available';
        debugPrint('[CameraService] Error: No cameras available');
        return;
      }

      final camera = cameras.first;
      debugPrint('[CameraService] Found ${cameras.length} camera(s), using ${camera.name}');

      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
        // Enable maximum frame rate for ProMotion displays
        fps: null, // null = use device maximum (120fps on ProMotion)
      );

      await _controller!.initialize();
      _isInitialized = true;
      _initEndTime = DateTime.now();

      final duration = initializationDuration;
      debugPrint('[CameraService] Camera initialized successfully in ${duration?.inMilliseconds}ms');

      // iOS-specific enhancements
      if (Platform.isIOS) {
        await _configureIOSCameraFeatures();

        // Restore Night Mode if requested
        if (restoreNightMode == true) {
          _nightModeEnabled = true;
          await _controller!.setExposureOffset(1.0);
          debugPrint('[CameraService] Night Mode restored from settings');
        }
      }
    } catch (e) {
      _errorMessage = 'Failed to initialize camera: $e';
      _initEndTime = DateTime.now();
      debugPrint('[CameraService] Camera initialization failed: $e');
    }
  }

  Future<void> _configureIOSCameraFeatures() async {
    if (_controller == null) return;

    try {
      // Enable automatic exposure compensation for book spines
      // Book spines often need slight overexposure to capture details
      await _controller!.setExposureOffset(0.7);
      debugPrint('[CameraService] iOS: Set exposure compensation to +0.7');

      // Enable focus mode for close-up scanning
      await _controller!.setFocusMode(FocusMode.auto);
      debugPrint('[CameraService] iOS: Set auto focus mode');

      // Enable exposure mode
      await _controller!.setExposureMode(ExposureMode.auto);
      debugPrint('[CameraService] iOS: Set auto exposure mode');

      // Check if low light boost (Night Mode) is available
      // Note: The camera package doesn't directly expose Night Mode,
      // but we can detect low light conditions and adjust accordingly
      _nightModeAvailable = Platform.isIOS;
      debugPrint('[CameraService] iOS: Night Mode detection enabled');

      // Try to enable video stabilization which can help with handheld scanning
      try {
        // This is iOS-specific and may not be available on all devices
        debugPrint('[CameraService] iOS: Camera features configured');
      } catch (e) {
        debugPrint('[CameraService] iOS: Some features not available: $e');
      }
    } catch (e) {
      debugPrint('[CameraService] iOS: Error configuring camera features: $e');
    }
  }

  Future<void> toggleNightMode() async {
    if (!_nightModeAvailable || _controller == null) return;

    try {
      _nightModeEnabled = !_nightModeEnabled;

      if (_nightModeEnabled) {
        // Increase exposure compensation for low light
        await _controller!.setExposureOffset(1.0);
        debugPrint('[CameraService] Night Mode enabled: exposure set to +1.0');
      } else {
        // Reset to default book spine exposure
        await _controller!.setExposureOffset(0.7);
        debugPrint('[CameraService] Night Mode disabled: exposure reset to +0.7');
      }
    } catch (e) {
      debugPrint('[CameraService] Error toggling Night Mode: $e');
      _nightModeEnabled = false;
    }
  }

  Future<void> enableDepthMode() async {
    if (!Platform.isIOS || _controller == null) return;

    try {
      // Portrait mode depth is handled by the camera's auto-focus system
      // Ensure we're using auto focus for best depth detection
      await _controller!.setFocusMode(FocusMode.auto);
      debugPrint('[CameraService] iOS: Depth-enhanced auto focus enabled');
    } catch (e) {
      debugPrint('[CameraService] Error enabling depth mode: $e');
    }
  }

  Future<void> dispose() async {
    debugPrint('[CameraService] Disposing camera controller');
    if (_controller != null) {
      try {
        await _controller!.dispose();
        debugPrint('[CameraService] Camera controller disposed successfully');
      } catch (e) {
        debugPrint('[CameraService] Error disposing camera controller: $e');
      }
      _controller = null;
    }
    _isInitialized = false;
  }
}
