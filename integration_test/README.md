# Integration Tests

This directory contains integration tests for the Wingtip app. Integration tests validate end-to-end user flows by running the app on a real device or simulator.

## Prerequisites

- Flutter SDK installed and configured
- iOS Simulator (for iOS testing) or Android Emulator (for Android testing)
- Xcode (for iOS) or Android Studio (for Android)
- **CocoaPods** (required for iOS): Install with `sudo gem install cocoapods`
  - After installing CocoaPods, run `cd ios && pod install` before running tests

## Running Integration Tests

### Quick Start

Run all integration tests on the default connected device:

```bash
flutter test integration_test/
```

### iOS Simulator (Recommended for Development)

1. **Start an iOS Simulator:**
   ```bash
   open -a Simulator
   ```

2. **List available devices:**
   ```bash
   flutter devices
   ```

3. **Run tests on a specific iOS simulator:**
   ```bash
   flutter test integration_test/ -d "iPhone 15 Pro"
   ```

4. **Run tests on any available iOS simulator:**
   ```bash
   flutter test integration_test/ -d iPhone
   ```

### Android Emulator

1. **Start an Android emulator from Android Studio or:**
   ```bash
   emulator -avd <emulator_name>
   ```

2. **Run tests on Android:**
   ```bash
   flutter test integration_test/ -d <device_id>
   ```

### Physical Device

Connect a physical device via USB and run:

```bash
flutter test integration_test/ -d <device_id>
```

Use `flutter devices` to find the device ID.

## Test Structure

Integration tests use the `integration_test` package (Flutter's official integration testing solution). Tests are structured similarly to widget tests but run the full app.

### Current Tests

- **`app_test.dart`** - Smoke test that verifies the app launches successfully and displays the appropriate initial screen (onboarding, permission primer, or camera screen).
- **`critical_flows_test.dart`** - Integration tests for critical user flows:
  - **Failed scan → retry → success flow** - Tests the complete lifecycle of a failed scan: network failure during upload, saving to FailedScans table with image preservation, successful retry, and cleanup.
  - **Multiple failed scans with different error types** - Verifies multiple failed scans can coexist with different failure reasons (network error, quality too low, no books found).
  - **Failed scan cleanup when image missing** - Ensures cleanup handles missing image files gracefully.
  - **Expired failed scans identification** - Tests that expired scans can be identified by expiresAt timestamp.

## Writing New Integration Tests

1. Create a new test file in `integration_test/`:
   ```dart
   import 'package:flutter_test/flutter_test.dart';
   import 'package:integration_test/integration_test.dart';
   import 'package:wingtip/main.dart' as app;

   void main() {
     IntegrationTestWidgetsFlutterBinding.ensureInitialized();

     testWidgets('Your test description', (WidgetTester tester) async {
       app.main();
       await tester.pumpAndSettle();

       // Your test logic here
       expect(find.text('Expected Text'), findsOneWidget);
     });
   }
   ```

2. Run your new test:
   ```bash
   flutter test integration_test/your_test.dart
   ```

## Common Patterns

### Waiting for Async Operations

```dart
// Wait for animations and async operations to complete
await tester.pumpAndSettle();

// Wait for a specific duration
await tester.pumpAndSettle(const Duration(seconds: 3));

// Wait for a specific widget to appear
await tester.pumpAndSettle();
expect(find.text('Success'), findsOneWidget);
```

### Interacting with Widgets

```dart
// Tap a button
await tester.tap(find.byIcon(Icons.camera));
await tester.pumpAndSettle();

// Enter text
await tester.enterText(find.byType(TextField), 'Test input');
await tester.pumpAndSettle();

// Scroll
await tester.drag(find.byType(ListView), const Offset(0, -300));
await tester.pumpAndSettle();
```

### Finding Widgets

```dart
// By text
find.text('Camera')

// By type
find.byType(CameraScreen)

// By icon
find.byIcon(Icons.add)

// By key
find.byKey(const Key('submit_button'))
```

## Debugging Integration Tests

### Enable Verbose Logging

```bash
flutter test integration_test/ --verbose
```

### Run with Observatory (Flutter DevTools)

```bash
flutter test integration_test/ --start-paused
```

Then connect Flutter DevTools to inspect the running test.

### Take Screenshots During Tests

```dart
await binding.takeScreenshot('screenshot_name');
```

## Troubleshooting

### Test Times Out

- Increase the timeout in your test:
  ```dart
  testWidgets('Test', (WidgetTester tester) async {
    // ...
  }, timeout: const Timeout(Duration(minutes: 5)));
  ```

### Simulator Not Found

- Ensure the iOS Simulator is running before executing tests
- Check available devices with `flutter devices`

### Permission Dialogs Block Tests

- Grant permissions manually in the simulator before running tests
- Or handle permission dialogs in your test code

### App State Persists Between Tests

- Integration tests run the full app, including persistent storage
- Consider clearing app data between test runs if needed:
  ```bash
  xcrun simctl uninstall booted com.example.wingtip
  ```

## CI/CD Integration

Integration tests can be run in CI pipelines:

```yaml
# Example GitHub Actions workflow
- name: Run Integration Tests
  run: |
    flutter emulators --launch apple_ios_simulator
    flutter test integration_test/ -d iPhone
```

## Performance Considerations

- Integration tests are slower than unit/widget tests (they run the full app)
- Use integration tests for critical user flows only
- Keep unit and widget tests for detailed component testing
- Consider running integration tests only on CI or before releases

## Related Documentation

- [Flutter Integration Testing Guide](https://docs.flutter.dev/testing/integration-tests)
- [flutter_test package](https://api.flutter.dev/flutter/flutter_test/flutter_test-library.html)
- [integration_test package](https://github.com/flutter/flutter/tree/main/packages/integration_test)
