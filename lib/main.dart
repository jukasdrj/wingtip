import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wingtip/core/theme.dart';
import 'package:wingtip/features/camera/camera_screen.dart';
import 'package:wingtip/features/camera/camera_service.dart';
import 'package:wingtip/features/camera/permission_primer_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Performance logging: App start time
  final appStartTime = DateTime.now();
  debugPrint('[Performance] App started at ${appStartTime.toIso8601String()}');

  // Hide system UI for full immersion
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

  // Check camera permission status
  final cameraPermissionStatus = await Permission.camera.status;

  // Only initialize camera if permission is already granted
  if (cameraPermissionStatus.isGranted) {
    // Initialize camera in background during startup
    final cameraService = CameraService();
    final cameraInitFuture = cameraService.initialize();

    // Performance logging: Camera initialization started
    debugPrint('[Performance] Camera initialization started');

    // Wait for camera to initialize
    await cameraInitFuture;

    // Performance logging: Cold start time
    final coldStartTime = DateTime.now().difference(appStartTime);
    debugPrint('[Performance] Cold start completed in ${coldStartTime.inMilliseconds}ms');

    if (cameraService.initializationDuration != null) {
      debugPrint('[Performance] Camera initialization took ${cameraService.initializationDuration!.inMilliseconds}ms');
    }
  } else {
    debugPrint('[Performance] Camera permission not granted, showing primer screen');
  }

  runApp(ProviderScope(child: MyApp(hasPermission: cameraPermissionStatus.isGranted)));
}

class MyApp extends StatelessWidget {
  final bool hasPermission;

  const MyApp({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wingtip',
      // Lock to dark theme with Swiss Utility styling
      theme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      // Show permission primer if not granted, otherwise camera screen
      home: hasPermission ? const CameraScreen() : const PermissionPrimerScreen(),
    );
  }
}
