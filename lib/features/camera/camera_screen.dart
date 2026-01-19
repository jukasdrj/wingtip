import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wingtip/core/theme.dart';
import 'package:wingtip/features/camera/camera_provider.dart';
import 'package:wingtip/features/camera/image_processor.dart';
import 'package:wingtip/features/talaria/job_state_provider.dart';
import 'package:wingtip/features/library/library_screen.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  bool _showFlash = false;

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
      final result = await ImageProcessor.processImage(image.path);

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
          if (cameraService.isInitialized && cameraService.controller != null)
            _buildShutterButton(),
          _buildLibraryButton(context),
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

    return CameraPreview(cameraService.controller!);
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
    return Positioned(
      left: 0,
      right: 0,
      bottom: 40,
      child: Center(
        child: GestureDetector(
          onTap: _onShutterTap,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
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
}
