import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wingtip/core/performance_metrics.dart';
import 'package:wingtip/core/performance_metrics_service.dart';
import 'package:wingtip/core/theme.dart';
import 'package:wingtip/features/camera/camera_provider.dart';
import 'package:wingtip/features/camera/camera_screen.dart';
import 'package:wingtip/features/camera/camera_service.dart';
import 'package:wingtip/features/camera/permission_primer_screen.dart';
import 'package:wingtip/features/camera/session_counter_provider.dart';
import 'package:wingtip/features/talaria/job_state.dart';
import 'package:wingtip/features/talaria/job_state_notifier.dart';
import 'package:wingtip/features/talaria/job_state_provider.dart';
import 'package:wingtip/core/performance_metrics_provider.dart';

/// Mock CameraService that simulates an initialized camera
class MockCameraService implements CameraService {
  final bool _mockIsInitialized;
  final CameraController? _mockController;
  final String? _mockErrorMessage;
  final bool _mockNightModeAvailable;
  final bool _mockNightModeEnabled;

  MockCameraService({
    bool isInitialized = true,
    CameraController? controller,
    String? errorMessage,
    bool nightModeAvailable = false,
    bool nightModeEnabled = false,
  })  : _mockIsInitialized = isInitialized,
        _mockController = controller,
        _mockErrorMessage = errorMessage,
        _mockNightModeAvailable = nightModeAvailable,
        _mockNightModeEnabled = nightModeEnabled;

  @override
  bool get isInitialized => _mockIsInitialized;

  @override
  CameraController? get controller => _mockController;

  @override
  String? get errorMessage => _mockErrorMessage;

  @override
  bool get nightModeAvailable => _mockNightModeAvailable;

  @override
  bool get nightModeEnabled => _mockNightModeEnabled;

  @override
  Duration? get initializationDuration => null;

  @override
  Future<void> dispose() async {}

  @override
  Future<void> enableDepthMode() async {}

  @override
  Future<void> initialize({bool? restoreNightMode}) async {}

  @override
  Future<void> toggleNightMode() async {}
}

/// Mock CameraController for testing
class MockCameraController extends CameraController {
  MockCameraController()
      : super(
          const CameraDescription(
            name: 'mock_camera',
            lensDirection: CameraLensDirection.back,
            sensorOrientation: 0,
          ),
          ResolutionPreset.high,
        );

  @override
  CameraValue get value => CameraValue(
        isInitialized: true,
        previewSize: const Size(1920, 1080),
        isRecordingVideo: false,
        isTakingPicture: false,
        isStreamingImages: false,
        isRecordingPaused: false,
        flashMode: FlashMode.off,
        exposureMode: ExposureMode.auto,
        focusMode: FocusMode.auto,
        exposurePointSupported: true,
        focusPointSupported: true,
        deviceOrientation: DeviceOrientation.portraitUp,
        description: const CameraDescription(
          name: 'mock_camera',
          lensDirection: CameraLensDirection.back,
          sensorOrientation: 0,
        ),
      );

  @override
  Future<void> setZoomLevel(double zoom) async {}

  @override
  Future<double> getMaxZoomLevel() async => 4.0;

  @override
  Future<double> getMinZoomLevel() async => 1.0;

  @override
  Future<void> setFocusPoint(Offset? point) async {}

  @override
  Future<void> setExposurePoint(Offset? point) async {}

  @override
  Future<void> setFocusMode(FocusMode mode) async {}

  @override
  Future<void> setExposureMode(ExposureMode mode) async {}

  @override
  Future<double> setExposureOffset(double offset) async => offset;

  @override
  Future<void> dispose() async {
    await super.dispose();
  }
}

/// Mock JobStateNotifier for testing
class MockJobStateNotifier extends JobStateNotifier {
  final JobState initialState;

  MockJobStateNotifier({this.initialState = const JobState()});

  @override
  JobState build() => initialState;
}

/// Mock PerformanceMetricsService for testing
class MockPerformanceMetricsService implements PerformanceMetricsService {
  @override
  Future<void> recordColdStart(int durationMs) async {}

  @override
  Future<void> recordShutterLatency(int latencyMs) async {}

  @override
  Future<void> recordUploadTime(int durationMs) async {}

  @override
  Future<void> recordSseFirstResultTime(int durationMs) async {}

  @override
  Future<void> recordFrameDrop() async {}

  @override
  PerformanceMetrics getMetrics() {
    return PerformanceMetrics.empty();
  }

  @override
  Future<void> resetMetrics() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CameraScreen Widget Tests', () {
    late MockCameraController mockController;
    late MockCameraService mockCameraService;
    late MockPerformanceMetricsService mockPerformanceService;

    setUp(() {
      mockController = MockCameraController();
      mockCameraService = MockCameraService(
        isInitialized: true,
        controller: mockController,
      );
      mockPerformanceService = MockPerformanceMetricsService();
    });

    testWidgets('CameraScreen renders without crashing with mocked camera controller',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cameraServiceProvider.overrideWithValue(mockCameraService),
            jobStateProvider.overrideWith(() => MockJobStateNotifier()),
            performanceMetricsServiceProvider.overrideWithValue(mockPerformanceService),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const CameraScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the camera screen is rendered
      expect(find.byType(CameraScreen), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('Shutter button is visible and tappable', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cameraServiceProvider.overrideWithValue(mockCameraService),
            jobStateProvider.overrideWith(() => MockJobStateNotifier()),
            performanceMetricsServiceProvider.overrideWithValue(mockPerformanceService),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const CameraScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find shutter button by its circular container with 80x80 size
      final shutterButton = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).shape == BoxShape.circle &&
            widget.constraints?.maxWidth == 80,
      );

      expect(shutterButton, findsOneWidget);

      // Tap the shutter button
      await tester.tap(shutterButton);
      await tester.pump();
      // Pump a few more times to allow async operations to complete
      await tester.pump(const Duration(milliseconds: 200));

      // No error should be thrown
    });

    testWidgets('Shows loading indicator when camera is not initialized',
        (tester) async {
      final uninitializedService = MockCameraService(
        isInitialized: false,
        controller: null,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cameraServiceProvider.overrideWithValue(uninitializedService),
            jobStateProvider.overrideWith(() => MockJobStateNotifier()),
            performanceMetricsServiceProvider.overrideWithValue(mockPerformanceService),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const CameraScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify loading indicator is shown
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Shows error message when camera initialization fails',
        (tester) async {
      const errorMessage = 'Failed to initialize camera';
      final errorService = MockCameraService(
        isInitialized: false,
        controller: null,
        errorMessage: errorMessage,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cameraServiceProvider.overrideWithValue(errorService),
            jobStateProvider.overrideWith(() => MockJobStateNotifier()),
            performanceMetricsServiceProvider.overrideWithValue(mockPerformanceService),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const CameraScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify error message is displayed
      expect(find.text(errorMessage), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('Stream overlay appears when progressMessage is set in job state',
        (tester) async {
      // Create a notifier with an active job that has a progress message
      final jobStateWithMessage = JobState(
        jobs: [
          ScanJob(
            id: '1',
            jobId: 'job-123',
            imagePath: '/tmp/test.jpg',
            status: JobStatus.processing,
            progressMessage: 'Analyzing book spines...',
            createdAt: DateTime.now(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cameraServiceProvider.overrideWithValue(mockCameraService),
            jobStateProvider.overrideWith(() => MockJobStateNotifier(initialState: jobStateWithMessage)),
            performanceMetricsServiceProvider.overrideWithValue(mockPerformanceService),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const CameraScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify stream overlay with message is displayed
      expect(find.text('Analyzing book spines...'), findsOneWidget);
    });

    testWidgets('Session counter displays correctly and shows count',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cameraServiceProvider.overrideWithValue(mockCameraService),
            jobStateProvider.overrideWith(() => MockJobStateNotifier()),
            performanceMetricsServiceProvider.overrideWithValue(mockPerformanceService),
            // Override session counter to show a count
            sessionCounterProvider.overrideWith(() {
              return TestSessionCounterNotifier(initialCount: 5);
            }),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const CameraScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify session counter displays the count
      expect(find.text('5 books scanned...'), findsOneWidget);
    });

    testWidgets('Session counter is hidden when count is zero', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cameraServiceProvider.overrideWithValue(mockCameraService),
            jobStateProvider.overrideWith(() => MockJobStateNotifier()),
            performanceMetricsServiceProvider.overrideWithValue(mockPerformanceService),
            // Default session counter starts at 0
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const CameraScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify session counter text is not displayed
      expect(find.textContaining('books scanned'), findsNothing);
    });

    testWidgets('Library button is visible and tappable', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cameraServiceProvider.overrideWithValue(mockCameraService),
            jobStateProvider.overrideWith(() => MockJobStateNotifier()),
            performanceMetricsServiceProvider.overrideWithValue(mockPerformanceService),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const CameraScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find library button by icon
      final libraryButton = find.byIcon(Icons.grid_view_rounded);
      expect(libraryButton, findsOneWidget);

      // Tap library button (just verify it's tappable, don't wait for navigation)
      await tester.tap(libraryButton);
      await tester.pump();

      // Note: We don't verify navigation completion as it requires complex mocking
      // but tapping without error confirms the button is tappable
    });

    testWidgets('Rate limit overlay appears when rate limit is active',
        (tester) async {
      final rateLimitedState = JobState(
        rateLimit: RateLimitInfo(
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
          retryAfterMs: 3600000,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cameraServiceProvider.overrideWithValue(mockCameraService),
            jobStateProvider.overrideWith(() => MockJobStateNotifier(initialState: rateLimitedState)),
            performanceMetricsServiceProvider.overrideWithValue(mockPerformanceService),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const CameraScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify rate limit overlay is displayed
      expect(find.text('LIMIT REACHED'), findsOneWidget);
      expect(find.text('RESETS IN'), findsOneWidget);
    });

    testWidgets('Shutter button is disabled when rate limited', (tester) async {
      final rateLimitedState = JobState(
        rateLimit: RateLimitInfo(
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
          retryAfterMs: 3600000,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cameraServiceProvider.overrideWithValue(mockCameraService),
            jobStateProvider.overrideWith(() => MockJobStateNotifier(initialState: rateLimitedState)),
            performanceMetricsServiceProvider.overrideWithValue(mockPerformanceService),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const CameraScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find shutter button
      final shutterButton = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).shape == BoxShape.circle &&
            widget.constraints?.maxWidth == 80,
      );

      expect(shutterButton, findsOneWidget);

      // Verify button appears disabled (has reduced opacity border)
      final container = tester.widget<Container>(shutterButton);
      final decoration = container.decoration as BoxDecoration;
      final borderColor = decoration.border as Border;

      // Border should have reduced opacity when rate limited
      expect((borderColor.top.color.a * 255.0).round() < 255, isTrue);
    });
  });

  group('PermissionPrimerScreen Widget Tests', () {
    testWidgets('Permission primer screen renders correctly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const PermissionPrimerScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify key elements are displayed
      expect(find.text('Camera Access'), findsOneWidget);
      expect(find.text('Grant Access'), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt_outlined), findsOneWidget);
      expect(
        find.text(
            'Wingtip needs your camera to see books. Images are processed and deleted instantly.'),
        findsOneWidget,
      );
    });

    testWidgets('Grant Access button is visible and tappable', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const PermissionPrimerScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find Grant Access button
      final grantButton = find.text('Grant Access');
      expect(grantButton, findsOneWidget);

      // Verify button is tappable (wrapped in ElevatedButton)
      final elevatedButton = find.ancestor(
        of: grantButton,
        matching: find.byType(ElevatedButton),
      );
      expect(elevatedButton, findsOneWidget);

      // Note: We can't easily test the permission request flow without mocking
      // the permission_handler package, but we can verify the button exists and is tappable
    });
  });
}

/// Test notifier for session counter with initial count
class TestSessionCounterNotifier extends SessionCounterNotifier {
  final int initialCount;

  TestSessionCounterNotifier({this.initialCount = 0});

  @override
  SessionCounterState build() {
    return SessionCounterState(
      count: initialCount,
      lastScanAt: DateTime.now(),
    );
  }
}
