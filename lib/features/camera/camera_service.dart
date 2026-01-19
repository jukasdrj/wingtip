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

  bool get isInitialized => _isInitialized;
  CameraController? get controller => _controller;
  String? get errorMessage => _errorMessage;

  Duration? get initializationDuration {
    if (_initStartTime != null && _initEndTime != null) {
      return _initEndTime!.difference(_initStartTime!);
    }
    return null;
  }

  Future<void> initialize() async {
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
    } catch (e) {
      _errorMessage = 'Failed to initialize camera: $e';
      _initEndTime = DateTime.now();
      debugPrint('[CameraService] Camera initialization failed: $e');
    }
  }

  void dispose() {
    _controller?.dispose();
    _controller = null;
    _isInitialized = false;
  }
}
