import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wingtip/core/crash_reporting_service.dart';
import 'package:wingtip/core/crash_context_provider.dart';
import 'package:wingtip/core/memory_pressure_handler.dart';
import 'package:wingtip/core/theme.dart';
import 'package:wingtip/core/app_lifecycle_observer.dart';
import 'package:wingtip/core/performance_metrics_service.dart';
import 'package:wingtip/core/performance_overlay_provider.dart';
import 'package:wingtip/core/restart_widget.dart';
import 'package:wingtip/features/camera/camera_screen.dart';
import 'package:wingtip/features/camera/camera_service.dart';
import 'package:wingtip/features/camera/permission_primer_screen.dart';
import 'package:wingtip/features/onboarding/onboarding_screen.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:wingtip/services/failed_scans_cleanup_service_provider.dart';
import 'package:wingtip/widgets/network_reconnect_listener.dart';
import 'package:wingtip/widgets/shake_to_feedback_wrapper.dart';

void main() async {
  // Initialize Sentry for crash reporting and analytics
  // Configure via: flutter run --dart-define=SENTRY_DSN="your-dsn-here"
  // Get DSN from: https://sentry.io/settings/projects/<your-project>/keys/
  // See CRASH_REPORTING.md for detailed setup instructions
  await CrashReportingService.initialize(
    dsn: const String.fromEnvironment(
      'SENTRY_DSN',
      defaultValue: '', // Empty DSN disables Sentry in development
    ),
    environment: const String.fromEnvironment(
      'SENTRY_ENVIRONMENT',
      defaultValue: 'development',
    ),
    appRunner: _runApp,
  );
}

Future<void> _runApp() async {
  // Preserve the splash screen
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Performance logging: App start time
  final appStartTime = DateTime.now();
  debugPrint('[Performance] App started at ${appStartTime.toIso8601String()}');

  // Hide system UI for full immersion (lightweight operation)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

  // Create provider container (deferred provider initialization)
  final container = ProviderContainer();

  // Check onboarding completion and camera permission status
  final prefs = await SharedPreferences.getInstance();
  final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
  final cameraPermissionStatus = await Permission.camera.status;

  // Optimization: Start all async operations in parallel
  final futures = <Future<void>>[];

  // 1. Minimum splash time (reduced from 500ms to 300ms for faster perceived startup)
  final splashTimer = Future.delayed(const Duration(milliseconds: 300));
  futures.add(splashTimer);

  // 2. Initialize camera if permission granted (heavyweight, but necessary for camera screen)
  Future<void>? cameraInitFuture;
  if (cameraPermissionStatus.isGranted) {
    debugPrint('[Performance] Camera initialization started');

    cameraInitFuture = Future(() async {
      final cameraService = CameraService();

      // Load SharedPreferences once for camera settings
      final prefs = await SharedPreferences.getInstance();
      final nightModeEnabled = prefs.getBool('camera_night_mode_enabled') ?? false;

      await cameraService.initialize(restoreNightMode: nightModeEnabled);

      if (cameraService.initializationDuration != null) {
        debugPrint('[Performance] Camera initialization took ${cameraService.initializationDuration!.inMilliseconds}ms');
      }
    });
    futures.add(cameraInitFuture);
  }

  // Wait for critical startup tasks
  await Future.wait(futures);

  // Performance logging: Cold start time
  final coldStartTime = DateTime.now().difference(appStartTime);
  debugPrint('[Performance] Cold start completed in ${coldStartTime.inMilliseconds}ms');

  // Deferred: Record metrics asynchronously after app is interactive
  if (cameraPermissionStatus.isGranted) {
    _recordColdStartMetrics(coldStartTime.inMilliseconds).catchError((e) {
      debugPrint('[Performance] Failed to record cold start metric: $e');
    });
  }

  // Deferred: Run cleanup in background after app launch (non-blocking)
  _deferredCleanup(container);

  // MEMORY OPTIMIZATION: Start listening for memory pressure warnings (iOS)
  MemoryPressureHandler.startListening();

  runApp(
    // Wrap the app in RestartWidget to enable full app restarts
    RestartWidget(
      child: UncontrolledProviderScope(
        container: container,
        child: MyApp(
          onboardingCompleted: onboardingCompleted,
          hasPermission: cameraPermissionStatus.isGranted,
        ),
      ),
    ),
  );
}

/// Deferred: Record cold start metrics after app is interactive
Future<void> _recordColdStartMetrics(int coldStartMs) async {
  final prefs = await SharedPreferences.getInstance();
  final metricsService = PerformanceMetricsService(prefs);
  await metricsService.recordColdStart(coldStartMs);
}

/// Deferred: Run cleanup service in background after app launch
void _deferredCleanup(ProviderContainer container) {
  // Defer cleanup by 2 seconds to avoid competing with initial UI render
  Future.delayed(const Duration(seconds: 2), () {
    try {
      final cleanupService = container.read(failedScansCleanupServiceProvider);
      cleanupService.runFullCleanup().catchError((error) {
        debugPrint('[Startup] Deferred cleanup failed: $error');
        return 0;
      });
      debugPrint('[Startup] Deferred cleanup initiated');
    } catch (e) {
      debugPrint('[Startup] Failed to initiate cleanup: $e');
    }
  });
}

class MyApp extends StatefulWidget {
  final bool onboardingCompleted;
  final bool hasPermission;

  const MyApp({
    super.key,
    required this.onboardingCompleted,
    required this.hasPermission,
  });

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

        // Watch performance overlay state
        final showPerformanceOverlay = ref.watch(performanceOverlayProvider);

        // Initialize crash context monitoring
        ref.watch(crashContextProvider);

        return NetworkReconnectListener(
          child: MaterialApp(
            title: 'Wingtip',
            // Lock to dark theme with Swiss Utility styling
            theme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            // Enable performance overlay for ProMotion profiling
            showPerformanceOverlay: showPerformanceOverlay,
            // Route logic: Onboarding → Permission → Camera
            home: ShakeToFeedbackWrapper(
              child: _determineHomeScreen(),
            ),
          ),
        );
      },
    );
  }

  Widget _determineHomeScreen() {
    // If onboarding not completed, show onboarding first
    if (!widget.onboardingCompleted) {
      return const OnboardingScreen();
    }

    // If onboarding completed but no camera permission, show permission primer
    if (!widget.hasPermission) {
      return const PermissionPrimerScreen();
    }

    // If onboarding completed and permission granted, show camera screen
    return const CameraScreen();
  }

  @override
  void dispose() {
    _lifecycleObserver?.dispose();
    super.dispose();
  }
}
