import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wingtip/core/theme.dart';
import 'package:wingtip/core/app_lifecycle_observer.dart';
import 'package:wingtip/core/performance_metrics_service.dart';
import 'package:wingtip/core/restart_widget.dart';
import 'package:wingtip/features/camera/camera_screen.dart';
import 'package:wingtip/features/camera/camera_service.dart';
import 'package:wingtip/features/camera/permission_primer_screen.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:wingtip/services/failed_scans_cleanup_service_provider.dart';
import 'package:wingtip/widgets/network_reconnect_listener.dart';

void main() async {
  // Preserve the splash screen
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Performance logging: App start time
  final appStartTime = DateTime.now();
  debugPrint('[Performance] App started at ${appStartTime.toIso8601String()}');

  // Hide system UI for full immersion
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

  // Create provider container for startup initialization
  final container = ProviderContainer();

  // Run cleanup on startup (non-blocking)
  final cleanupService = container.read(failedScansCleanupServiceProvider);
  cleanupService.runFullCleanup().catchError((error) {
    debugPrint('[Startup] Cleanup failed: $error');
    return 0;
  });

  // Minimum splash display time (500ms)
  final splashTimer = Future.delayed(const Duration(milliseconds: 500));

  // Check camera permission status
  final cameraPermissionStatus = await Permission.camera.status;

  // Only initialize camera if permission is already granted
  if (cameraPermissionStatus.isGranted) {
    // Initialize camera in background during startup
    final cameraService = CameraService();
    final cameraInitFuture = cameraService.initialize();

    // Performance logging: Camera initialization started
    debugPrint('[Performance] Camera initialization started');

    // Wait for both camera initialization and minimum splash time
    await Future.wait([cameraInitFuture, splashTimer]);

    // Performance logging: Cold start time
    final coldStartTime = DateTime.now().difference(appStartTime);
    debugPrint('[Performance] Cold start completed in ${coldStartTime.inMilliseconds}ms');

    // Record cold start time to metrics
    try {
      final prefs = await SharedPreferences.getInstance();
      final metricsService = PerformanceMetricsService(prefs);
      await metricsService.recordColdStart(coldStartTime.inMilliseconds);
    } catch (e) {
      debugPrint('[Performance] Failed to record cold start metric: $e');
    }

    if (cameraService.initializationDuration != null) {
      debugPrint('[Performance] Camera initialization took ${cameraService.initializationDuration!.inMilliseconds}ms');
    }
  } else {
    // Wait for minimum splash time even without camera initialization
    await splashTimer;
    debugPrint('[Performance] Camera permission not granted, showing primer screen');
  }

  runApp(
    // Wrap the app in RestartWidget to enable full app restarts
    RestartWidget(
      child: UncontrolledProviderScope(
        container: container,
        child: MyApp(hasPermission: cameraPermissionStatus.isGranted),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  final bool hasPermission;

  const MyApp({super.key, required this.hasPermission});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  AppLifecycleObserver? _lifecycleObserver;

  @override
  void initState() {
    super.initState();

    // Remove splash screen after first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        // Initialize lifecycle observer once we have access to the container
        if (_lifecycleObserver == null) {
          final cleanupService = ref.read(failedScansCleanupServiceProvider);
          _lifecycleObserver = AppLifecycleObserver(cleanupService);
          WidgetsBinding.instance.addObserver(_lifecycleObserver!);
        }

        return NetworkReconnectListener(
          child: MaterialApp(
            title: 'Wingtip',
            // Lock to dark theme with Swiss Utility styling
            theme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            // Show permission primer if not granted, otherwise camera screen
            home: widget.hasPermission ? const CameraScreen() : const PermissionPrimerScreen(),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _lifecycleObserver?.dispose();
    super.dispose();
  }
}
