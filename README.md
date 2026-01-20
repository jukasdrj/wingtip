# Wingtip

A local-first, offline-capable library manager for Flutter that scans book spines using device cameras for seamless book identification and organization.

## Features

### 🎯 Core Capabilities
- **Camera-Based Scanning**: Instant camera initialization (<1s cold start) with AI-powered book spine recognition
- **Offline-First Design**: Fully functional library management without internet connectivity
- **Failed Scan Retry System**: Persistent queue with automatic and manual retry for network failures
- **SQLite Storage with Drift**: Robust local database with FTS5 full-text search across titles, authors, and ISBNs
- **SSE Job Processing**: Real-time integration with Talaria backend via Server-Sent Events for live scan updates
- **Swiss Utility Design**: OLED black backgrounds, 1px borders, zero elevation, high-contrast interfaces

### 📱 iOS-First Excellence
- **ProMotion 120Hz Support**: Butter-smooth animations optimized for iPhone Pro displays
- **Native iOS Gestures**: Swipe-back navigation, context menus, and iOS-native haptic feedback
- **Advanced Camera Controls**: Night Mode, depth sensing, focus/exposure lock for challenging lighting
- **iOS Home Screen Widget**: At-a-glance library stats and recent scans on your home screen
- **Haptic Feedback Strategy**: Light/medium/heavy haptics for shutter, success, and errors

### 📊 Advanced Features
- **Collections & Tags**: Organize books into custom collections (To Read, Favorites, etc.)
- **Multi-Sort & Filters**: Sort by date, title, author, confidence; filter by format, review status, date range
- **Statistics Dashboard**: Track total books, scan streaks, top authors, scanning sessions
- **Manual Metadata Editing**: Correct misidentified titles, authors, ISBNs with inline editing
- **Session Gamification**: Real-time scan counter with milestone celebrations

### 🛡️ Production Ready
- **Sentry Crash Reporting**: Production monitoring with privacy-respecting error tracking
- **Performance Monitoring**: Cold start, shutter latency, and processing time metrics
- **Memory Optimized**: Leak prevention, cache management, iOS memory pressure handling
- **TestFlight Ready**: Complete beta testing setup with tester onboarding materials

## Tech Stack

- **Flutter**: Cross-platform UI framework
- **Dart**: Programming language (SDK 3.10.7+)
- **Drift 2.0**: SQLite ORM for database operations
- **Riverpod 3.0**: State management
- **Camera Plugin**: For device camera access
- **HTTP/SSE**: Backend communication with Talaria via HTTP and Server-Sent Events
- **Google Fonts**: Inter for UI text, JetBrains Mono for code/ISBNs
- **Image Processing**: Background isolate compression and resizing

## Getting Started

### Prerequisites

- Flutter SDK (version 3.0 or later)
- Dart SDK 3.10.7+ (included with Flutter)
- For iOS: macOS with Xcode 14+ and an iOS device or simulator
- For Android: Android SDK and an emulator or device

### Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd wingtip
   ```

2. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```

3. Run Drift code generation:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. Verify your setup:
   ```bash
   flutter doctor
   ```

### Running the App

**iOS (Primary Target):**
```bash
flutter run -d iPhone
```

**Android:**
```bash
flutter run
```

**Development Mode:**
```bash
flutter run --verbose
```

## Project Structure

The project follows a modular structure under the `lib/` directory:

- **`core/`**: Core utilities, network clients, theme definitions, device ID management
- **`data/`**: Data layer including Drift database schemas, models, and DAOs
- **`features/`**: Feature-specific modules (camera, library, book management, search)
- **`services/`**: External services integration (Talaria backend, SSE streams, image processing)
- **`widgets/`**: Reusable UI components following Swiss Utility design principles

## Development

### Common Commands

**Run the app:**
```bash
flutter run
```

**Run tests:**
```bash
flutter test
```

**Run tests with coverage:**
```bash
flutter test --coverage
```

**Generate Drift database code:**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

**Watch for changes (auto-regenerate):**
```bash
flutter pub run build_runner watch
```

**Static analysis:**
```bash
flutter analyze
```

**Build for release:**
```bash
# iOS (primary target)
flutter build ios --release

# Android
flutter build apk --release
```

**Generate app icons:**
```bash
flutter pub run flutter_launcher_icons
```

**Generate splash screens:**
```bash
flutter pub run flutter_native_splash:create
```

### Code Style

Follow Dart's effective Dart guidelines. Use `dart format` for formatting and `flutter analyze` for linting.

## Architecture

Wingtip employs a layered architecture focused on local-first design:

### State Management
**Riverpod 3.0** for dependency injection and reactive state handling:
- UI components use `ConsumerWidget` or `Consumer` to access providers
- Business logic lives in Notifier classes (e.g., `JobStateNotifier`)
- Database streams are exposed via `StreamProvider`
- Manual provider definitions (generator packages not yet added)

### Database Layer
**Drift ORM** interacts with SQLite for local storage:
- Full-text search with FTS5 virtual tables
- Watch streams for reactive UI updates
- Schema migrations for version management
- Books table with ISBN as primary key

### Backend Integration
**HTTP and SSE** streams connect to the Talaria backend:
- Multipart image upload to `/v3/jobs/scans`
- SSE stream for real-time job updates (progress, result, complete, error)
- Device-ID based authentication via `X-Device-ID` header
- Exponential backoff retry logic for connection failures

### UI Layer
**Swiss Utility design principles:**
- OLED black backgrounds (#000000)
- International Orange accent (#FF3B30)
- 1px solid borders instead of shadows
- Zero elevation on all components
- Haptic feedback at every interaction stage (iOS-focused)

### Data Flow: The Capture Loop

1. **Capture** - User taps shutter → Image saved to temp cache → Background isolate compresses/resizes
2. **Upload** - Multipart POST to `/v3/jobs/scans` with `X-Device-ID` header
3. **Listen** - Connect to SSE stream at returned `streamUrl`
4. **Ingest** - SSE events (`progress`, `result`, `complete`, `error`) trigger UI updates and database upserts
5. **Display** - Library auto-refreshes via Drift's `.watch()` streams

### Offline Behavior

- Library is 100% functional offline (viewing, searching, deleting, editing)
- Only camera scanning requires network connection
- Network status shown in top-right corner when offline
- **Failed Scan Queue**: Failed uploads are automatically saved with persistent retry queue
  - Manual retry for individual scans
  - Batch retry for all failed scans
  - Automatic retry prompt when network reconnects
  - Configurable retention period (3/7/14/30 days or never)
  - Failed scans preserved with original images for later retry
  - Detailed analytics showing failure reasons (network, quality, no books found, etc.)

## Testing

Run unit and widget tests using Flutter's built-in test framework:

```bash
flutter test
```

For specific test files:
```bash
flutter test test/path/to/test_file.dart
```

With coverage report:
```bash
flutter test --coverage
```

Tests should cover:
- Database queries and FTS5 search (`test/data/`)
- Network clients and SSE parsing (`test/core/`)
- UI components (`test/features/`)
- Mock providers using Riverpod's testing utilities

## Performance Targets

- **Cold start**: < 800ms to live camera (target met in Epic 3)
- **Shutter latency**: < 30ms tap-to-haptic feedback (target met in Epic 3)
- **Image processing**: < 500ms per image (background isolate)
- **ProMotion**: 120fps on iPhone Pro devices with zero dropped frames
- **Memory footprint**: < 200MB for typical usage (100+ books, active scanning)
- **SSE timeout**: 5 minutes maximum job duration
- **Image specs**: Resized to max 1920px, compressed to JPEG quality 85

## Documentation

### Core Documentation
- **[CLAUDE.md](CLAUDE.md)**: Comprehensive development guide for AI assistants and developers
- **[TODO.md](TODO.md)**: Current status, Epic 3 completion summary, launch readiness checklist
- **[docs/INDEX.md](docs/INDEX.md)**: Documentation index and quick links
- **[tasks/prd-epic3.json](tasks/prd-epic3.json)**: Complete product requirements (72 user stories)

### Production Guides
- **[CRASH_REPORTING.md](CRASH_REPORTING.md)**: Sentry integration and crash monitoring setup
- **[TESTFLIGHT_SETUP.md](TESTFLIGHT_SETUP.md)**: Beta testing configuration guide
- **[BETA_TESTER_EMAIL.md](BETA_TESTER_EMAIL.md)**: Welcome email template for beta testers
- **[PRIVACY.md](PRIVACY.md)**: Privacy policy for App Store submission
- **[SUPPORT.md](SUPPORT.md)**: User support documentation

### iOS-Specific Guides
- **[WIDGET_SETUP.md](WIDGET_SETUP.md)**: iOS Home Screen widget setup and Xcode configuration
- **[docs/PROMOTION_120HZ.md](docs/PROMOTION_120HZ.md)**: ProMotion 120Hz optimization guide and debugging

### App Store Materials
- **[assets/app-store/](assets/app-store/)**: Screenshots, app preview video script, metadata, submission checklist

## Contributing

1. Fork the repository and create a feature branch
2. Write tests for new features
3. Ensure code passes `flutter analyze` and `flutter test`
4. Follow commit conventions (e.g., "feat: add camera scanning")
5. Submit a pull request with a detailed description

**Priorities:**
- iOS compatibility is mandatory
- Maintain Swiss Utility design principles
- All features must work offline-first

## License

See [LICENSE](LICENSE) file for details.

---

**Platform Priority**: This app is developed **iOS-first**. All development decisions, performance targets, and UX patterns prioritize iOS. Android and web are secondary targets.
