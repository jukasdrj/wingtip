# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Wingtip is a local-first, offline-capable library manager Flutter app that uses the camera to scan book spines. It connects to the Talaria backend for AI-powered book identification and enrichment, but stores all data locally in SQLite. The app follows a "Swiss Utility" design philosophy: high-contrast, clean, zero-elevation interfaces with OLED black backgrounds and 1px borders instead of shadows.

## Core Commands

### Build & Development
```bash
# Install dependencies
flutter pub get

# Run code generation for Drift database
flutter pub run build_runner build --delete-conflicting-outputs

# Run the app
flutter run

# Run on specific device
flutter run -d <device-id>

# Build for iOS
flutter build ios

# Build for Android
flutter build apk
```

### Testing & Analysis
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/path/to/test_file.dart

# Run tests with coverage
flutter test --coverage

# Static analysis
flutter analyze
```

### Asset & Icon Generation
```bash
# Generate app icons
flutter pub run flutter_launcher_icons

# Generate splash screens
flutter pub run flutter_native_splash:create
```

## Architecture & Code Structure

### Directory Layout
- `lib/core/` - Cross-cutting concerns (network, theme, device ID)
- `lib/data/` - Database layer (Drift schema, providers)
- `lib/features/` - Feature modules (camera, library, talaria integration)
- `lib/services/` - Background services
- `lib/widgets/` - Reusable UI components
- `test/` - Unit and widget tests mirroring lib/ structure

### State Management Pattern
This app uses **Riverpod 3.x** for all state management:

- Providers are defined using the generator syntax with annotations
- UI components use `ConsumerWidget` or `Consumer` to access providers
- Business logic lives in Notifier classes (e.g., `JobStateNotifier`)
- Database streams are exposed via `StreamProvider`

**Key Providers:**
- `deviceIdProvider` - Persistent UUID from secure storage
- `databaseProvider` - Drift database instance
- `talariaClientProvider` - HTTP client for Talaria API
- `networkStatusProvider` - Connectivity monitoring
- `jobStateNotifierProvider` - Active scan job queue
- `booksProvider` - Stream of books from database
- `searchQueryProvider` - Current search query state

### Data Flow: The Capture Loop

1. **Capture** - User taps shutter → Image saved to temp cache → Background isolate compresses/resizes
2. **Upload** - Multipart POST to `/v3/jobs/scans` with `X-Device-ID` header
3. **Listen** - Connect to SSE stream at returned `streamUrl`
4. **Ingest** - SSE events (`progress`, `result`, `complete`, `error`) trigger UI updates and database upserts
5. **Display** - Library auto-refreshes via Drift's `.watch()` streams

### Database Schema (Drift)

**Books Table:**
- `isbn` (TEXT, PRIMARY KEY)
- `title` (TEXT)
- `author` (TEXT)
- `coverUrl` (TEXT, nullable)
- `format` (TEXT, nullable)
- `addedDate` (INTEGER, timestamp)
- `spineConfidence` (REAL, nullable)
- `reviewNeeded` (BOOL, default false)

**Full-Text Search:**
- Uses SQLite FTS5 virtual table `books_fts`
- Automatically synced via triggers on insert/update/delete
- Search via `database.searchBooks(query)`

**Failed Scans Table:**
- Tracks jobs that errored for debugging

### API Integration

**Base URL:** Not hardcoded - configured via `NetworkClient(baseUrl: ...)`

**Headers:**
- `X-Device-ID: <uuid>` on all requests

**Endpoints:**
- `POST /v3/jobs/scans` - Upload image, returns `{jobId, streamUrl}`
- `GET /v3/jobs/scans/{jobId}/stream` - SSE stream of job events
- `DELETE /v3/jobs/scans/{jobId}/cleanup` - Clean up server resources

**SSE Event Types:**
- `progress` - Analysis progress updates (0.0 - 1.0)
- `result` - Book metadata found (upsert to DB immediately)
- `complete` - Job finished successfully
- `error` - Job failed with error message

**Error Handling:**
- 429 Rate Limit → Parse `retryAfterMs`, disable shutter, show countdown
- Connection errors → Retry with exponential backoff (max 3 retries)
- 400 Bad Image → Show "Too Blurry" UI feedback

### Theme System

**Swiss Utility Design Tokens:**
- OLED Black: `#000000`
- International Orange: `#FF3B30` (accent)
- Border Gray: `#1C1C1E`
- Text Primary: `#FFFFFF`
- Text Secondary: `#8E8E93`

**Typography:**
- Body/UI text: Inter (via Google Fonts)
- Numbers/ISBNs/JSON: JetBrains Mono (via `AppTheme.monoStyle()`)

**Key Principles:**
- Zero elevation on all components
- 1px solid borders instead of shadows
- Dark mode only (no light theme)
- Haptic feedback at every interaction stage

### Haptic Feedback Strategy

- **Light Impact** - Shutter tap
- **Medium Impact** - Book saved to database
- **Heavy Impact** - Error or rate limit hit

Trigger via `HapticFeedback.lightImpact()` etc.

## Common Development Tasks

### Adding a New Book Field

1. Update `Books` table in `lib/data/database.dart`:
   ```dart
   TextColumn get newField => text().nullable()();
   ```

2. Increment `schemaVersion` in `AppDatabase`

3. Add migration in `onUpgrade`:
   ```dart
   if (from < 4) {
     await m.addColumn(books, books.newField);
   }
   ```

4. Run code generation:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

5. Update `_saveBookResult()` in `job_state_notifier.dart` to map the new field

### Adding a New SSE Event Type

1. Add enum value to `SseEventType` in `lib/core/sse_client.dart`

2. Update switch statement in `SseEvent.fromJson()`

3. Handle the event in `JobStateNotifier._handleSseEvent()`

### Testing Image Processing Pipeline

Use fixture images in `test/fixtures/`:

```dart
final testImage = File('test/fixtures/test_book_spine.jpg');
final processor = ImageProcessor();
final result = await processor.processImage(testImage.path);
```

### Debugging SSE Streams

Enable verbose logging in `lib/core/sse_client.dart` - all events are already logged with `debugPrint()`. Run with:

```bash
flutter run --verbose
```

Look for `[SseClient]` and `[JobStateNotifier]` prefixed logs.

### Performance Monitoring

Cold start metrics are logged automatically in `main.dart`:
- `[Performance] App started at ...`
- `[Performance] Camera initialization started`
- `[Performance] Cold start completed in Xms`

Target: < 1000ms cold start to live camera.

## Background Processing

Image compression runs in an isolate via `compute()` to avoid blocking the UI thread:

```dart
final result = await compute(_processImageInIsolate, imagePath);
```

Target: < 500ms processing time per image.

## Offline Behavior

- Library is 100% functional offline (viewing, searching, deleting)
- Only camera scanning requires network connection
- Network status shown in top-right corner when offline
- Failed uploads are NOT queued - user must manually retry

## Testing Strategy

- Unit tests for database queries (`test/data/`)
- Unit tests for network clients and SSE parsing (`test/core/`)
- Widget tests for UI components (`test/features/`)
- Mock providers using Riverpod's testing utilities

Example:
```dart
final container = ProviderContainer(
  overrides: [
    databaseProvider.overrideWithValue(mockDatabase),
  ],
);
```

## Known Constraints

- Camera permission is required before showing camera screen
- SQLite FTS5 module must be available on the platform
- SSE timeout is 5 minutes - longer jobs will fail
- Rate limits are enforced by backend - no client-side bypass
- Images are resized to max 1920px and compressed to JPEG quality 85
