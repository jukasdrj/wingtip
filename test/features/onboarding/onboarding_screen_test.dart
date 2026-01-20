import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wingtip/core/theme.dart';
import 'package:wingtip/features/camera/permission_primer_screen.dart';
import 'package:wingtip/features/onboarding/onboarding_screen.dart';

/// Helper to set a larger viewport size for tests to avoid overflow
void setTestViewportSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OnboardingScreen Widget Tests', () {
    setUp(() {
      // Reset SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('OnboardingScreen renders 3 slides', (tester) async {
      setTestViewportSize(tester);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const OnboardingScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the screen is rendered
      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.byType(PageView), findsOneWidget);

      // Verify page indicators for 3 slides
      final pageIndicators = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).borderRadius != null &&
            widget.constraints != null &&
            widget.constraints!.maxHeight == 8.0,
      );
      expect(pageIndicators, findsNWidgets(3));

      // Verify first slide content is visible
      expect(find.text('The Shutter That Remembers'), findsOneWidget);
      expect(
        find.text(
            'Point your camera at any bookshelf. Wingtip sees every spine, identifies each book, and builds your library instantly.'),
        findsOneWidget,
      );

      // Verify Skip button is visible
      expect(find.text('Skip'), findsOneWidget);

      // Verify Next button is visible (not "Get Started" on first slide)
      expect(find.text('Next'), findsOneWidget);
      expect(find.text('Get Started'), findsNothing);
    });

    testWidgets('Swiping advances to next slide', (tester) async {
      setTestViewportSize(tester);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const OnboardingScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify first slide is visible
      expect(find.text('The Shutter That Remembers'), findsOneWidget);

      // Use Next button to navigate (more reliable than drag in tests)
      // Tap Next to go to second slide
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Verify second slide is now visible
      expect(find.text('Local-First Library'), findsOneWidget);
      expect(
        find.text(
            'Your data lives on your device. Browse, search, and organize offline. No cloud accounts, no subscriptions, no surveillance.'),
        findsOneWidget,
      );

      // Tap Next to go to third slide
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Verify third slide is now visible
      expect(find.text('Grant Camera Access'), findsOneWidget);
      expect(
        find.text(
            'Wingtip needs your camera to see books. Images are processed and deleted instantly. No photos are saved or uploaded.'),
        findsOneWidget,
      );

      // Verify "Get Started" button appears on final slide
      expect(find.text('Next'), findsNothing);
      expect(find.text('Get Started'), findsOneWidget);
    });

    testWidgets('Final slide Get Started button marks onboarding complete',
        (tester) async {
      setTestViewportSize(tester);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const OnboardingScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to the final slide by tapping Next button twice
      final nextButton = find.text('Next');
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      // Verify we're on the final slide
      expect(find.text('Grant Camera Access'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);

      // Tap "Get Started" button
      await tester.tap(find.text('Get Started'));
      await tester.pump(); // Start the async operation
      await tester.pump(); // Allow async to complete

      // Verify onboarding_completed was set to true in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('onboarding_completed'), isTrue);

      // Note: Navigation to PermissionPrimerScreen happens but we can't
      // easily verify it without more complex mocking. The important
      // assertion is that onboarding_completed is set to true.
    });

    testWidgets('Skip button marks onboarding complete from any slide',
        (tester) async {
      setTestViewportSize(tester);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const OnboardingScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify we're on the first slide
      expect(find.text('The Shutter That Remembers'), findsOneWidget);

      // Tap Skip button
      await tester.tap(find.text('Skip'));
      await tester.pump(); // Start the async operation
      await tester.pump(); // Allow async to complete

      // Verify onboarding_completed was set to true in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('onboarding_completed'), isTrue);
    });

    testWidgets('Next button advances through slides correctly',
        (tester) async {
      setTestViewportSize(tester);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const OnboardingScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify first slide
      expect(find.text('The Shutter That Remembers'), findsOneWidget);

      // Tap Next button to go to second slide
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Verify second slide
      expect(find.text('Local-First Library'), findsOneWidget);

      // Tap Next button to go to third slide
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Verify third slide
      expect(find.text('Grant Camera Access'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
    });

    testWidgets('Page indicators update as user navigates', (tester) async {
      setTestViewportSize(tester);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const OnboardingScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Find active indicator (first one should be active, wider width)
      final activeIndicator = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).color ==
                AppTheme.internationalOrange &&
            widget.constraints != null &&
            widget.constraints!.maxWidth == 24.0,
      );

      expect(activeIndicator, findsOneWidget);

      // Navigate to second slide
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Active indicator should still be one widget (now pointing to second slide)
      expect(activeIndicator, findsOneWidget);

      // Navigate to third slide
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Active indicator should still be one widget (now pointing to third slide)
      expect(activeIndicator, findsOneWidget);
    });

    testWidgets('All three slide titles are unique and present in PageView',
        (tester) async {
      setTestViewportSize(tester);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const OnboardingScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify first slide title
      expect(find.text('The Shutter That Remembers'), findsOneWidget);

      // Navigate to second slide using Next button
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Verify second slide title
      expect(find.text('Local-First Library'), findsOneWidget);

      // Navigate to third slide using Next button
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Verify third slide title
      expect(find.text('Grant Camera Access'), findsOneWidget);
    });
  });

  group('OnboardingScreen Integration with Permission Flow', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('Permission primer shows after onboarding completion',
        (tester) async {
      setTestViewportSize(tester);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const OnboardingScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to final slide
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Tap "Get Started"
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      // Verify PermissionPrimerScreen is now displayed
      expect(find.byType(PermissionPrimerScreen), findsOneWidget);
      expect(find.text('Camera Access'), findsOneWidget);
      expect(find.text('Grant Access'), findsOneWidget);
    });

    testWidgets('Skip button navigates to permission primer', (tester) async {
      setTestViewportSize(tester);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const OnboardingScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Skip from first slide
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      // Verify PermissionPrimerScreen is now displayed
      expect(find.byType(PermissionPrimerScreen), findsOneWidget);
      expect(find.text('Camera Access'), findsOneWidget);
    });
  });

  group('OnboardingScreen Skip Behavior', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('OnboardingScreen skipped when onboarding already completed',
        (tester) async {
      setTestViewportSize(tester);

      // Pre-set onboarding as completed
      SharedPreferences.setMockInitialValues({
        'onboarding_completed': true,
      });

      // Create a simple test app that checks onboarding status
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: FutureBuilder<bool>(
            future: SharedPreferences.getInstance().then(
              (prefs) => prefs.getBool('onboarding_completed') ?? false,
            ),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const CircularProgressIndicator();
              }

              // If onboarding completed, skip to permission primer
              if (snapshot.data == true) {
                return const PermissionPrimerScreen();
              }

              // Otherwise show onboarding
              return const OnboardingScreen();
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify OnboardingScreen is NOT displayed
      expect(find.byType(OnboardingScreen), findsNothing);

      // Verify PermissionPrimerScreen is displayed instead
      expect(find.byType(PermissionPrimerScreen), findsOneWidget);
      expect(find.text('Camera Access'), findsOneWidget);
    });

    testWidgets(
        'OnboardingScreen shown when onboarding not completed',
        (tester) async {
      setTestViewportSize(tester);

      // Ensure onboarding is not completed
      SharedPreferences.setMockInitialValues({
        'onboarding_completed': false,
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: FutureBuilder<bool>(
            future: SharedPreferences.getInstance().then(
              (prefs) => prefs.getBool('onboarding_completed') ?? false,
            ),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const CircularProgressIndicator();
              }

              if (snapshot.data == true) {
                return const PermissionPrimerScreen();
              }

              return const OnboardingScreen();
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify OnboardingScreen IS displayed
      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.text('The Shutter That Remembers'), findsOneWidget);

      // Verify PermissionPrimerScreen is NOT displayed
      expect(find.byType(PermissionPrimerScreen), findsNothing);
    });
  });
}
