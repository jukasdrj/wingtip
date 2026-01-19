import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wingtip/core/performance_metrics_provider.dart';
import 'package:wingtip/core/theme.dart';
import 'package:wingtip/features/camera/camera_provider.dart';
import 'package:wingtip/features/camera/image_processor.dart';
import 'package:wingtip/features/camera/session_counter_provider.dart';
import 'package:wingtip/features/camera/session_counter_widget.dart';
import 'package:wingtip/features/talaria/job_state.dart';
import 'package:wingtip/features/talaria/processing_stack_widget.dart';
import 'package:wingtip/features/talaria/job_state_provider.dart';
import 'package:wingtip/features/library/library_screen.dart';
import 'package:wingtip/features/camera/stream_overlay.dart';
import 'package:wingtip/widgets/error_snack_bar.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen>
    with WidgetsBindingObserver {
  bool _showFlash = false;
  double _currentZoom = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 4.0;
  double _baseScale = 1.0;
  Offset? _focusPoint;
  bool _showFocusIndicator = false;
  Timer? _countdownTimer;
  final Set<String> _shownErrorJobIds = {};
  final Set<String> _completedJobIds = {};

  // Focus and exposure lock state
  bool _focusLocked = false;
  Offset? _lockedFocusPoint;
  double _exposureCompensation = 0.0;
  double _baseExposureCompensation = 0.0;
  bool _isAdjustingExposure = false;
  double _swipeStartY = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeZoomLevels();
    _startCountdownTimer();
    _setupJobErrorListener();
    _setupJobCompletionListener();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // Reset session counter when app goes to background
      ref.read(sessionCounterProvider.notifier).reset();
    }
  }

  void _setupJobErrorListener() {
    // Listen for job state changes and show error notifications
    ref.listenManual(jobStateProvider, (previous, next) {
      if (!mounted) return;

      // Find jobs with errors that we haven't shown yet
      for (final job in next.jobs) {
        if (job.status == JobStatus.error &&
            job.errorMessage != null &&
            !_shownErrorJobIds.contains(job.id)) {
          // Mark as shown
          _shownErrorJobIds.add(job.id);

          // Show error notification with user-friendly message
          ErrorSnackBar.show(
            context,
            message: job.errorMessage!,
          );
        }
      }
    });
  }

  void _setupJobCompletionListener() {
    // Listen for job completions and increment session counter
    ref.listenManual(jobStateProvider, (previous, next) {
      if (!mounted) return;

      // Find jobs that just completed
      for (final job in next.jobs) {
        if (job.status == JobStatus.completed &&
            !_completedJobIds.contains(job.id)) {
          // Mark as counted
          _completedJobIds.add(job.id);

          // Increment session counter
          ref.read(sessionCounterProvider.notifier).increment();
        }
      }
    });
  }

  @override
  void dispose() {
    debugPrint('[CameraScreen] Disposing camera screen resources');
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    _countdownTimer = null;
    // Note: Camera controller disposal is handled by CameraService singleton
    // to allow reuse when navigating back to camera screen
    super.dispose();
  }

  void _startCountdownTimer() {
    // Update countdown every second
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          // Trigger rebuild to update countdown display
        });
      }
    });
  }

  Future<void> _initializeZoomLevels() async {
    final cameraService = ref.read(cameraServiceProvider);
    if (cameraService.controller != null) {
      final maxZoom = await cameraService.controller!.getMaxZoomLevel();
      final minZoom = await cameraService.controller!.getMinZoomLevel();
      setState(() {
        _maxZoom = maxZoom.clamp(1.0, 4.0);
        _minZoom = minZoom;
      });
    }
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _baseScale = _currentZoom;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    final cameraService = ref.read(cameraServiceProvider);
    if (cameraService.controller == null) return;

    final newZoom = (_baseScale * details.scale).clamp(_minZoom, _maxZoom);
    if (newZoom != _currentZoom) {
      setState(() {
        _currentZoom = newZoom;
      });
      cameraService.controller!.setZoomLevel(_currentZoom);
    }
  }

  void _handleTapUp(TapUpDetails details, BoxConstraints constraints) async {
    final cameraService = ref.read(cameraServiceProvider);
    if (cameraService.controller == null) return;

    // If focus is locked and user taps elsewhere, unlock
    if (_focusLocked) {
      setState(() {
        _focusLocked = false;
        _lockedFocusPoint = null;
        _exposureCompensation = 0.0;
        _baseExposureCompensation = 0.0;
      });

      // Reset to auto modes and default exposure
      try {
        await cameraService.controller!.setFocusMode(FocusMode.auto);
        await cameraService.controller!.setExposureMode(ExposureMode.auto);
        final nightModeOffset = cameraService.nightModeEnabled ? 1.0 : 0.7;
        await cameraService.controller!.setExposureOffset(nightModeOffset);
      } catch (e) {
        debugPrint('[CameraScreen] Error resetting camera modes: $e');
      }

      // Trigger haptic feedback for unlock
      HapticFeedback.lightImpact();
      return;
    }

    // Get tap position relative to the preview
    final offset = Offset(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );

    try {
      // Set focus point
      await cameraService.controller!.setFocusPoint(offset);
      await cameraService.controller!.setExposurePoint(offset);

      // Show focus indicator
      setState(() {
        _focusPoint = details.localPosition;
        _showFocusIndicator = true;
      });

      // Trigger haptic feedback
      HapticFeedback.selectionClick();

      // Hide focus indicator after 1 second
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _showFocusIndicator = false;
          });
        }
      });
    } catch (e) {
      debugPrint('[CameraScreen] Error setting focus: $e');
    }
  }

  void _handleLongPress(LongPressStartDetails details, BoxConstraints constraints) async {
    final cameraService = ref.read(cameraServiceProvider);
    if (cameraService.controller == null) return;

    // Get long-press position relative to the preview
    final offset = Offset(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );

    try {
      // Set and lock focus point
      await cameraService.controller!.setFocusPoint(offset);
      await cameraService.controller!.setExposurePoint(offset);
      await cameraService.controller!.setFocusMode(FocusMode.locked);
      await cameraService.controller!.setExposureMode(ExposureMode.locked);

      // Lock focus
      setState(() {
        _focusLocked = true;
        _lockedFocusPoint = details.localPosition;
        _showFocusIndicator = false; // Hide temporary indicator

        // Initialize exposure compensation based on current camera setting
        final nightModeOffset = cameraService.nightModeEnabled ? 1.0 : 0.7;
        _exposureCompensation = nightModeOffset;
        _baseExposureCompensation = nightModeOffset;
      });

      // Trigger medium haptic feedback for lock
      HapticFeedback.mediumImpact();

      debugPrint('[CameraScreen] Focus and exposure locked at ${details.localPosition}');
    } catch (e) {
      debugPrint('[CameraScreen] Error locking focus: $e');
    }
  }

  void _handleVerticalDragStart(DragStartDetails details) {
    if (!_focusLocked) return;

    setState(() {
      _isAdjustingExposure = true;
      _swipeStartY = details.globalPosition.dy;
      _baseExposureCompensation = _exposureCompensation;
    });
  }

  void _handleVerticalDragUpdate(DragUpdateDetails details) async {
    if (!_focusLocked || !_isAdjustingExposure) return;

    final cameraService = ref.read(cameraServiceProvider);
    if (cameraService.controller == null) return;

    // Calculate exposure change based on vertical swipe
    // Swipe up (negative delta) = increase exposure
    // Swipe down (positive delta) = decrease exposure
    final deltaY = details.globalPosition.dy - _swipeStartY;
    final exposureChange = -deltaY / 200.0; // Scale factor for sensitivity

    // Calculate new exposure compensation (-2.0 to +2.0)
    final newExposure = (_baseExposureCompensation + exposureChange).clamp(-2.0, 2.0);

    if ((newExposure - _exposureCompensation).abs() > 0.05) {
      setState(() {
        _exposureCompensation = newExposure;
      });

      try {
        await cameraService.controller!.setExposureOffset(_exposureCompensation);
        // Light haptic feedback during adjustment
        HapticFeedback.selectionClick();
      } catch (e) {
        debugPrint('[CameraScreen] Error adjusting exposure: $e');
      }
    }
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
    if (!_focusLocked) return;

    setState(() {
      _isAdjustingExposure = false;
    });
  }

  Future<void> _onShutterTap() async {
    // CRITICAL: Trigger haptic feedback IMMEDIATELY before any other work
    // Target: < 16ms (1 frame at 60fps)
    HapticFeedback.lightImpact();

    // Start performance timer for tap-to-capture latency
    final tapTime = DateTime.now();

    final cameraService = ref.read(cameraServiceProvider);

    // Show flash overlay immediately (optimized: no setState)
    // Use a flag check in build() instead of triggering rebuild
    _showFlash = true;

    // Schedule flash hide without blocking (fire-and-forget)
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _showFlash = false;
        // Trigger single rebuild for flash hide only
        if (mounted) setState(() {});
      }
    });

    // Unlock focus/exposure if locked (non-blocking - fire async)
    if (_focusLocked) {
      _focusLocked = false;
      _lockedFocusPoint = null;
      _exposureCompensation = 0.0;
      _baseExposureCompensation = 0.0;

      // Reset camera modes asynchronously (don't await - let it run in background)
      _resetCameraModesAsync(cameraService);
    }

    // Capture image immediately without waiting for focus reset
    try {
      if (cameraService.controller == null) {
        debugPrint('[CameraScreen] Cannot capture: camera not initialized');
        return;
      }

      // OPTIMIZED: takePicture() is the critical path - minimize work before this
      final XFile image = await cameraService.controller!.takePicture();

      // Calculate tap-to-capture latency
      final captureLatency = DateTime.now().difference(tapTime);

      debugPrint('[CameraScreen] Image captured in ${captureLatency.inMilliseconds}ms: ${image.path}');

      // Record shutter latency metric (non-blocking)
      _recordShutterLatencyAsync(captureLatency.inMilliseconds);

      // Process image in background isolate (this is already optimized)
      final result = await ImageProcessor.processImage(image.path, ref: ref);

      debugPrint('[CameraScreen] Image processed successfully:');
      debugPrint('  - Output: ${result.outputPath}');
      debugPrint('  - Processing time: ${result.processingTimeMs}ms');
      debugPrint('  - Size reduction: ${result.originalSize} -> ${result.processedSize} bytes');

      // Upload to Talaria for analysis
      final jobStateNotifier = ref.read(jobStateProvider.notifier);
      await jobStateNotifier.uploadImage(result.outputPath);
    } catch (e) {
      debugPrint('[CameraScreen] Error capturing/processing image: $e');
    }
  }

  /// Reset camera modes asynchronously without blocking capture
  void _resetCameraModesAsync(dynamic cameraService) {
    Future.microtask(() async {
      try {
        await cameraService.controller?.setFocusMode(FocusMode.auto);
        await cameraService.controller?.setExposureMode(ExposureMode.auto);
        final nightModeOffset = cameraService.nightModeEnabled ? 1.0 : 0.7;
        await cameraService.controller?.setExposureOffset(nightModeOffset);
      } catch (e) {
        debugPrint('[CameraScreen] Error resetting camera modes: $e');
      }
    });
  }

  /// Record shutter latency asynchronously without blocking
  void _recordShutterLatencyAsync(int latencyMs) {
    Future.microtask(() async {
      try {
        final metricsService = ref.read(performanceMetricsServiceProvider);
        await metricsService.recordShutterLatency(latencyMs);
      } catch (e) {
        debugPrint('[CameraScreen] Failed to record shutter latency: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cameraService = ref.watch(cameraServiceProvider);
    final jobState = ref.watch(jobStateProvider);

    // Get the active job's progress message
    final activeJob = jobState.activeJobs.isNotEmpty ? jobState.activeJobs.first : null;
    final streamMessage = activeJob?.progressMessage;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildBody(cameraService),
          if (_showFlash) _buildFlashOverlay(),
          if (cameraService.isInitialized && cameraService.controller != null) ...[
            const ProcessingStackWidget(),
            _buildShutterButton(),
            _buildZoomIndicator(),
            _buildNightModeButton(),
            if (_showFocusIndicator && _focusPoint != null)
              _buildFocusIndicator(),
            if (_focusLocked && _lockedFocusPoint != null)
              _buildLockedFocusIndicator(),
            if (_focusLocked && (_isAdjustingExposure || _exposureCompensation != 0.0))
              _buildExposureOverlay(),
          ],
          StreamOverlay(
            message: streamMessage,
            onDismiss: () {
              // Message dismissed by user - no action needed
              // Auto-dismissal is handled by the overlay itself
            },
          ),
          _buildSessionCounter(),
          _buildLibraryButton(context),
          _buildRateLimitOverlay(),
        ],
      ),
    );
  }

  Widget _buildBody(dynamic cameraService) {
    if (cameraService.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            cameraService.errorMessage!,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (!cameraService.isInitialized || cameraService.controller == null) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onScaleStart: _handleScaleStart,
          onScaleUpdate: _handleScaleUpdate,
          onTapUp: (details) => _handleTapUp(details, constraints),
          onLongPressStart: (details) => _handleLongPress(details, constraints),
          onVerticalDragStart: _handleVerticalDragStart,
          onVerticalDragUpdate: _handleVerticalDragUpdate,
          onVerticalDragEnd: _handleVerticalDragEnd,
          child: RepaintBoundary(
            // Isolate camera preview to avoid unnecessary repaints
            child: CameraPreview(cameraService.controller!),
          ),
        );
      },
    );
  }

  Widget _buildFlashOverlay() {
    return AnimatedOpacity(
      opacity: _showFlash ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 100),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
      ),
    );
  }

  Widget _buildShutterButton() {
    final jobState = ref.watch(jobStateProvider);
    final isRateLimited = jobState.rateLimit?.isActive ?? false;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 40,
      child: Center(
        child: GestureDetector(
          onTap: isRateLimited ? null : _onShutterTap,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isRateLimited ? Colors.white.withValues(alpha: 0.3) : Colors.white,
                width: 4,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSessionCounter() {
    return const Positioned(
      top: 48,
      right: 16,
      child: SessionCounterWidget(),
    );
  }

  Widget _buildLibraryButton(BuildContext context) {
    return Positioned(
      top: 108, // Position below session counter
      right: 16,
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const LibraryScreen(),
            ),
          );
        },
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.borderGray,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white,
              width: 1,
            ),
          ),
          child: const Icon(
            Icons.grid_view_rounded,
            color: AppTheme.textPrimary,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildZoomIndicator() {
    return Positioned(
      top: 48,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Text(
          '${_currentZoom.toStringAsFixed(1)}x',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildNightModeButton() {
    final cameraService = ref.watch(cameraServiceProvider);

    if (!cameraService.nightModeAvailable) {
      return const SizedBox.shrink();
    }

    final isEnabled = cameraService.nightModeEnabled;

    return Positioned(
      top: 108, // Position below zoom indicator
      left: 16,
      child: GestureDetector(
        onTap: () async {
          HapticFeedback.lightImpact();
          await cameraService.toggleNightMode();

          // Save Night Mode preference
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('camera_night_mode_enabled', cameraService.nightModeEnabled);
            debugPrint('[CameraScreen] Night Mode preference saved: ${cameraService.nightModeEnabled}');
          } catch (e) {
            debugPrint('[CameraScreen] Failed to save Night Mode preference: $e');
          }

          setState(() {}); // Trigger rebuild to update icon
        },
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isEnabled
                ? const Color(0xFFFFD700).withValues(alpha: 0.2) // Gold/yellow tint when enabled
                : Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isEnabled
                  ? const Color(0xFFFFD700) // Gold/yellow border
                  : Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Icon(
            Icons.nightlight_round,
            color: isEnabled
                ? const Color(0xFFFFD700) // Gold/yellow icon
                : Colors.white.withValues(alpha: 0.7),
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildFocusIndicator() {
    return Positioned(
      left: _focusPoint!.dx - 30,
      top: _focusPoint!.dy - 30,
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: _showFocusIndicator ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic, // iOS-native curve for 120Hz
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
            ),
            child: Stack(
              children: [
                // Top-left bracket
                Positioned(
                  left: 0,
                  top: 0,
                  child: CustomPaint(
                    size: const Size(12, 12),
                    painter: _BracketPainter(
                      color: Colors.white,
                      position: BracketPosition.topLeft,
                    ),
                  ),
                ),
                // Top-right bracket
                Positioned(
                  right: 0,
                  top: 0,
                  child: CustomPaint(
                    size: const Size(12, 12),
                    painter: _BracketPainter(
                      color: Colors.white,
                      position: BracketPosition.topRight,
                    ),
                  ),
                ),
                // Bottom-left bracket
                Positioned(
                  left: 0,
                  bottom: 0,
                  child: CustomPaint(
                    size: const Size(12, 12),
                    painter: _BracketPainter(
                      color: Colors.white,
                      position: BracketPosition.bottomLeft,
                    ),
                  ),
                ),
                // Bottom-right bracket
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: CustomPaint(
                    size: const Size(12, 12),
                    painter: _BracketPainter(
                      color: Colors.white,
                      position: BracketPosition.bottomRight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLockedFocusIndicator() {
    const yellowColor = Color(0xFFFFD700); // iOS focus lock yellow

    return Positioned(
      left: _lockedFocusPoint!.dx - 30,
      top: _lockedFocusPoint!.dy - 30,
      child: IgnorePointer(
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            border: Border.all(
              color: yellowColor,
              width: 2,
            ),
          ),
          child: Stack(
            children: [
              // Top-left bracket
              Positioned(
                left: 0,
                top: 0,
                child: CustomPaint(
                  size: const Size(12, 12),
                  painter: _BracketPainter(
                    color: yellowColor,
                    position: BracketPosition.topLeft,
                  ),
                ),
              ),
              // Top-right bracket
              Positioned(
                right: 0,
                top: 0,
                child: CustomPaint(
                  size: const Size(12, 12),
                  painter: _BracketPainter(
                    color: yellowColor,
                    position: BracketPosition.topRight,
                  ),
                ),
              ),
              // Bottom-left bracket
              Positioned(
                left: 0,
                bottom: 0,
                child: CustomPaint(
                  size: const Size(12, 12),
                  painter: _BracketPainter(
                    color: yellowColor,
                    position: BracketPosition.bottomLeft,
                  ),
                ),
              ),
              // Bottom-right bracket
              Positioned(
                right: 0,
                bottom: 0,
                child: CustomPaint(
                  size: const Size(12, 12),
                  painter: _BracketPainter(
                    color: yellowColor,
                    position: BracketPosition.bottomRight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExposureOverlay() {
    // Calculate exposure compensation relative to base (Night Mode or default)
    final cameraService = ref.watch(cameraServiceProvider);
    final baseOffset = cameraService.nightModeEnabled ? 1.0 : 0.7;
    final evChange = _exposureCompensation - baseOffset;

    final evString = evChange >= 0
        ? '+${evChange.toStringAsFixed(1)}'
        : evChange.toStringAsFixed(1);

    return Positioned(
      left: _lockedFocusPoint!.dx - 50,
      top: _lockedFocusPoint!.dy + 40, // Below the focus box
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: const Color(0xFFFFD700).withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Text(
            '$evString EV',
            style: const TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRateLimitOverlay() {
    final jobState = ref.watch(jobStateProvider);
    final rateLimit = jobState.rateLimit;

    if (rateLimit == null || !rateLimit.isActive) {
      return const SizedBox.shrink();
    }

    final remainingMs = rateLimit.remainingMs;
    final hours = remainingMs ~/ (1000 * 60 * 60);
    final minutes = (remainingMs % (1000 * 60 * 60)) ~/ (1000 * 60);
    final seconds = (remainingMs % (1000 * 60)) ~/ 1000;

    final timeString = '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.7),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'LIMIT REACHED',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'RESETS IN',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  timeString,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum BracketPosition {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

class _BracketPainter extends CustomPainter {
  final Color color;
  final BracketPosition position;

  _BracketPainter({
    required this.color,
    required this.position,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();

    switch (position) {
      case BracketPosition.topLeft:
        path.moveTo(size.width, 0);
        path.lineTo(0, 0);
        path.lineTo(0, size.height);
        break;
      case BracketPosition.topRight:
        path.moveTo(0, 0);
        path.lineTo(size.width, 0);
        path.lineTo(size.width, size.height);
        break;
      case BracketPosition.bottomLeft:
        path.moveTo(0, 0);
        path.lineTo(0, size.height);
        path.lineTo(size.width, size.height);
        break;
      case BracketPosition.bottomRight:
        path.moveTo(size.width, 0);
        path.lineTo(size.width, size.height);
        path.lineTo(0, size.height);
        break;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
