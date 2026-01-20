import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:wingtip/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Wingtip App Integration Tests', () {
    testWidgets('Smoke test - app launches successfully', (WidgetTester tester) async {
      // Launch the app
      app.main();

      // Wait for the app to settle (splash screen, initialization, etc.)
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verify that the app launched by checking for MaterialApp
      expect(find.byType(MaterialApp), findsOneWidget);

      // The app should show one of three screens based on state:
      // 1. OnboardingScreen (if onboarding not completed)
      // 2. PermissionPrimerScreen (if onboarding completed but no camera permission)
      // 3. CameraScreen (if onboarding completed and permission granted)
      // We just verify the app is running by checking for a Scaffold or similar root widget
      expect(find.byType(Scaffold), findsAtLeastNWidgets(1));
    });
  });
}
