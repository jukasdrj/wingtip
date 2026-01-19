# Wingtip

A local-first, offline-capable library manager for Flutter that scans book spines using device cameras for seamless book identification and organization.

## Features

- **Camera-Based Scanning**: Capture and process book spines with the device camera for quick identification
- **Offline-First Design**: Full functionality without internet access, with local data storage and background syncing
- **SQLite Storage with Drift**: Robust local database using Drift ORM for efficient data management
- **SSE Job Processing**: Real-time integration with the Talaria backend via Server-Sent Events (SSE) for AI-powered book identification
- **Full-Text Search**: Powered by SQLite's FTS5 for fast, advanced search across titles, authors, and metadata
- **Haptic Feedback**: Interactive user experience with haptic feedback on every user interaction
- **iOS-First Development**: Prioritized for iOS with Swiss Utility design (OLED black, 1px borders, zero elevation)

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

- Library is 100% functional offline (viewing, searching, deleting)
- Only camera scanning requires network connection
- Network status shown in top-right corner when offline
- Failed uploads are NOT queued - user must manually retry

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

- **Cold start**: < 1000ms to live camera
- **Image processing**: < 500ms per image (background isolate)
- **SSE timeout**: 5 minutes maximum job duration
- **Image specs**: Resized to max 1920px, compressed to JPEG quality 85

## Documentation

- **[CLAUDE.md](CLAUDE.md)**: Comprehensive development guide for AI assistants and developers
- **[docs/user-stories.md](docs/user-stories.md)**: MVP feature requirements and user stories
- **[tasks/prd.json](tasks/prd.json)**: Machine-readable product requirements

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
