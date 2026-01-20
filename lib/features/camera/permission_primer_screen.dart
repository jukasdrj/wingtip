import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wingtip/core/theme.dart';
import 'package:wingtip/features/camera/camera_screen.dart';

class PermissionPrimerScreen extends StatefulWidget {
  const PermissionPrimerScreen({super.key});

  @override
  State<PermissionPrimerScreen> createState() => _PermissionPrimerScreenState();
}

class _PermissionPrimerScreenState extends State<PermissionPrimerScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Check permission status on first load
    _checkPermissionStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When app returns to foreground (e.g., from Settings), check permission
    if (state == AppLifecycleState.resumed) {
      _checkPermissionStatus();
    }
  }

  Future<void> _checkPermissionStatus() async {
    final status = await Permission.camera.status;

    if (!mounted) return;

    if (status.isGranted) {
      // Permission granted, navigate to camera screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const CameraScreen(),
        ),
      );
    }
  }

  Future<void> _handleGrantAccess() async {
    // Check current status first
    final currentStatus = await Permission.camera.status;
    debugPrint('[PermissionPrimer] Current camera status: $currentStatus');
    debugPrint('[PermissionPrimer] isGranted: ${currentStatus.isGranted}');
    debugPrint('[PermissionPrimer] isDenied: ${currentStatus.isDenied}');
    debugPrint('[PermissionPrimer] isPermanentlyDenied: ${currentStatus.isPermanentlyDenied}');
    debugPrint('[PermissionPrimer] isRestricted: ${currentStatus.isRestricted}');
    debugPrint('[PermissionPrimer] isLimited: ${currentStatus.isLimited}');

    // If already granted, navigate immediately
    if (currentStatus.isGranted) {
      debugPrint('[PermissionPrimer] Permission already granted, navigating to camera');
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const CameraScreen(),
        ),
      );
      return;
    }

    // Request permission (shows iOS system dialog)
    debugPrint('[PermissionPrimer] Requesting camera permission...');
    final status = await Permission.camera.request();
    debugPrint('[PermissionPrimer] Permission request result: $status');

    if (!mounted) return;

    if (status.isGranted) {
      debugPrint('[PermissionPrimer] Permission granted, navigating to camera');
      // Permission granted, navigate to camera screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const CameraScreen(),
        ),
      );
    } else if (status.isDenied) {
      debugPrint('[PermissionPrimer] Permission denied');
      // Permission denied once, allow retry
      _showPermissionDeniedDialog(isDenied: true);
    } else if (status.isPermanentlyDenied) {
      debugPrint('[PermissionPrimer] Permission permanently denied');
      // Permission permanently denied, show settings dialog
      _showPermissionDeniedDialog(isPermanentlyDenied: true);
    } else {
      debugPrint('[PermissionPrimer] Unexpected permission status: $status');
    }
  }

  void _showPermissionDeniedDialog({
    bool isDenied = false,
    bool isPermanentlyDenied = false,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Camera Access Required'),
          content: Text(
            isPermanentlyDenied
                ? 'Camera access has been permanently denied. Please enable it in your device settings to use Wingtip.'
                : 'Wingtip needs camera access to scan book spines. Without it, you won\'t be able to add books to your library.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            if (isPermanentlyDenied)
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await openAppSettings();
                },
                child: const Text('Open Settings'),
              )
            else
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _handleGrantAccess();
                },
                child: const Text('Try Again'),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.oledBlack,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // Camera icon
              Icon(
                Icons.camera_alt_outlined,
                size: 120,
                color: AppTheme.internationalOrange,
              ),

              const SizedBox(height: 48),

              // Title
              Text(
                'Camera Access',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Explanation text
              Text(
                'Wingtip needs your camera to see books. Images are processed and deleted instantly.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              // Grant Access button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _handleGrantAccess,
                  child: const Text('Grant Access'),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
