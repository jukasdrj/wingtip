import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wingtip/core/theme.dart';
import 'package:wingtip/features/camera/camera_provider.dart';
import 'package:wingtip/features/camera/image_processor.dart';
import 'package:wingtip/features/talaria/job_state.dart';
import 'package:wingtip/features/talaria/processing_stack_widget.dart';
import 'package:wingtip/features/talaria/job_state_provider.dart';
import 'package:wingtip/features/library/library_screen.dart';
import 'package:wingtip/widgets/error_snack_bar.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  bool _showFlash = false;
  double _currentZoom = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 4.0;
  double _baseScale = 1.0;
  Offset? _focusPoint;
  bool _showFocusIndicator = false;
  Timer? _countdownTimer;
  final Set<String> _shownErrorJobIds = {};

  @override
  void initState() {
    super.initState();
    _initializeZoomLevels();
    _startCountdownTimer();
    _setupJobErrorListener();
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

  @override
  void dispose() {
    _countdownTimer?.cancel();
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

  Future<void> _onShutterTap() async {
    // Trigger haptic feedback immediately
    HapticFeedback.lightImpact();

    // Show flash overlay
    setState(() {
      _showFlash = true;
    });

    // Hide flash after 100ms
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _showFlash = false;
        });
      }
    });

    // Capture and process image
    try {
      final cameraService = ref.read(cameraServiceProvider);
      if (cameraService.controller == null) {
        debugPrint('[CameraScreen] Cannot capture: camera not initialized');
        return;
      }

      // Capture image
      final XFile image = await cameraService.controller!.takePicture();
      debugPrint('[CameraScreen] Image captured: ${image.path}');

      // Process image in background isolate
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

  @override
  Widget build(BuildContext context) {
    final cameraService = ref.watch(cameraServiceProvider);

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
            if (_showFocusIndicator && _focusPoint != null)
              _buildFocusIndicator(),
          ],
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
          child: CameraPreview(cameraService.controller!),
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

  Widget _buildLibraryButton(BuildContext context) {
    return Positioned(
      top: 48,
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

  Widget _buildFocusIndicator() {
    return Positioned(
      left: _focusPoint!.dx - 30,
      top: _focusPoint!.dy - 30,
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: _showFocusIndicator ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
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
