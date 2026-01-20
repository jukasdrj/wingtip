# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Wingtip is a local-first, offline-capable library manager Flutter app that uses the camera to scan book spines. It connects to the Talaria backend for AI-powered book identification and enrichment, but stores all data locally in SQLite. The app follows a "Swiss Utility" design philosophy: high-contrast, clean, zero-elevation interfaces with OLED black backgrounds and 1px borders instead of shadows.

**Platform Priority: iOS-first.** All development decisions, performance targets, and UX patterns should prioritize iOS. Android and web are secondary targets.

## Core Commands

### Build & Development
```bash
# Install dependencies
flutter pub get

# Run code generation for Drift database
flutter pub run build_runner build --delete-conflicting-outputs

# Run the app (defaults to connected device)
flutter run

# Run on iOS simulator
flutter run -d iPhone

# Run on specific device
flutter run -d <device-id>

# Build for iOS (primary target)
flutter build ios --release

# Build for Android (secondary)
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

- Providers are defined manually (note: generator packages `riverpod_annotation`/`riverpod_generator` not yet added)
- UI components use `ConsumerWidget` or `Consumer` to access providers
- Business logic lives in Notifier classes (e.g., `JobStateNotifier`)
- Database streams are exposed via `StreamProvider`

**Key Providers:**
- `deviceIdProvider` - Persistent UUID from secure storage
- `databaseProvider` - Drift database instance
- `talariaClientProvider` - HTTP client for Talaria API
- `networkStatusProvider` - Connectivity monitoring
- `jobStateNotifierProvider` - Active scan job queue with SSE streaming
- `booksProvider` - Stream of books from database with sort/filter/collection support
- `searchQueryProvider` - Current search query state
- `failedScansRepositoryProvider` - Failed scan persistence and retry logic
- `watchFailedScansProvider` - Stream of failed scans for UI
- `collectionsNotifierProvider` - Collections management (create, delete, add/remove books)
- `selectedCollectionProvider` - Currently active collection filter
- `sortOrderProvider` - Current sort option (date, title, author, confidence)
- `filterStateProvider` - Active filters (format, review status, date range)
- `performanceMetricsProvider` - Cold start, shutter latency, processing time tracking
- `sessionCounterProvider` - Scan session gamification counter
- `cameraSettingsProvider` - iOS camera preferences (Night Mode, etc.)
- `performanceOverlayProvider` - 120Hz ProMotion debugging overlay toggle

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

**FailedScans Table:**
- `id` (INTEGER, PRIMARY KEY AUTOINCREMENT)
- `jobId` (TEXT)
- `imagePath` (TEXT) - Path to preserved image in app_documents/failed_scans/
- `errorMessage` (TEXT) - User-friendly error description
- `createdAt` (INTEGER, timestamp)
- `expiresAt` (INTEGER, timestamp) - Based on retention policy (default 7 days)
- Supports persistent retry queue with configurable retention
- Images preserved for manual/batch retry operations

**Collections Table:**
- `id` (INTEGER, PRIMARY KEY AUTOINCREMENT)
- `name` (TEXT) - Collection name (e.g., "To Read", "Favorites")
- `createdAt` (INTEGER, timestamp)

**BookCollections Table (Many-to-Many):**
- `bookIsbn` (TEXT, foreign key to Books)
- `collectionId` (INTEGER, foreign key to Collections)
- Composite primary key on (bookIsbn, collectionId)
- Enables books to belong to multiple collections

### API Integration

**Base URL:** Not hardcoded - configured via `NetworkClient(baseUrl: ...)`

**Network Stack:** Uses standard `http` package for HTTP requests and SSE event streaming (not `fetch_client`)

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

**iOS-focused haptic design** - haptics are critical to the Wingtip UX:

- **Light Impact** - Shutter tap
- **Medium Impact** - Book saved to database
- **Heavy Impact** - Error or rate limit hit

Trigger via `HapticFeedback.lightImpact()` etc.

On iOS, these map to UIImpactFeedbackGenerator with different intensities. Android haptics are best-effort.

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

- Library is 100% functional offline (viewing, searching, deleting, editing, collections management)
- Only camera scanning requires network connection
- Network status shown in top-right corner when offline
- **Failed Scan Queue System:**
  - Failed uploads automatically saved to FailedScans table with preserved images
  - Manual retry: Tap retry button on individual failed scan cards
  - Batch retry: "Retry All" button processes all failed scans sequentially (throttled to 1/second)
  - Auto-retry prompt: When network reconnects, user prompted to retry all failed scans
  - Configurable retention: 3/7/14/30 days or never (default 7 days)
  - Auto-cleanup: Expired scans deleted on app startup and daily checks
  - Detailed analytics: Failure breakdown by type (network, quality, no books, server error, rate limit)

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

## Epic 3 Production Features

### iOS-First Optimizations

**ProMotion 120Hz Support:**
- Enabled via `CADisableMinimumFrameDurationOnPhone` in Info.plist
- All animations optimized for 120fps (grid scroll, transitions, overlays)
- Performance overlay toggle: Long-press "Library" title to enable/disable
- Target: Zero dropped frames during typical scan workflow
- See [docs/PROMOTION_120HZ.md](docs/PROMOTION_120HZ.md) for optimization guide

**Native iOS Gestures:**
- Swipe-back gesture via `CupertinoPageRoute` for all navigation
- Long-press context menus via `CupertinoActionSheet` (View Details, Edit, Delete, Share)
- iOS-native haptic patterns using `UIImpactFeedbackGenerator`
- Pull-to-refresh in library with iOS-style spinner

**iOS Camera Enhancements:**
- Night Mode: Auto-enabled in low light conditions (yellow moon indicator)
- Depth sensing: Uses portrait mode depth for improved spine focus
- Auto exposure compensation: +0.5 to +1.0 for book spines
- Focus/Exposure lock: Long-press to lock, swipe up/down to adjust exposure
- Settings persistence via `CameraSettingsService`

**iOS Home Screen Widget:**
- Small widget: Total books count with Wingtip icon
- Medium widget: Count + last scanned book cover + date
- WidgetKit extension in `ios/WingtipWidget/`
- Widget uses Swiss Utility design (black background, white text, 1px borders)
- Tapping widget opens app to library view
- See [WIDGET_SETUP.md](WIDGET_SETUP.md) for Xcode configuration

### Advanced Library Features

**Collections & Tags:**
- Create custom collections (e.g., "To Read", "Favorites", "Sci-Fi")
- Long-press book → "Add to Collection" in context menu
- Collections tab shows list with book count badges
- Many-to-many relationship: Books can belong to multiple collections
- Managed via `CollectionsNotifier` with Riverpod

**Multi-Sort & Advanced Filters:**
- Sort options: Date Added (newest/oldest), Title (A-Z/Z-A), Author (A-Z/Z-A), Spine Confidence (high/low)
- Filters: Format (All/Hardcover/Paperback/eBook), Review Status (All/Needs Review/Verified), Date Range (All Time/Last Week/Last Month/Custom)
- Active filter count badge on filter icon
- Sort preference persisted via SharedPreferences
- Filter state is session-only (cleared on app restart)

**Statistics Dashboard:**
- Total Books, Books This Week/Month, Scan Streak (consecutive days)
- Top authors and formats as simple bar charts
- Average books per scanning session
- Accessed via Settings → Stats section
- Efficient Drift aggregation queries

**Manual Metadata Editing:**
- Book Detail View shows "Edit" button for review_needed books
- Editable fields: Title, Author, ISBN, Format
- Swiss Utility form styling (1px borders, monospace for ISBN)
- Clears review_needed flag after successful edit
- Updates via Drift with optimistic UI

### Production Readiness

**Crash Reporting (Sentry):**
- Sentry integration for production error tracking
- Custom crash keys: device_id, books_count, active_jobs_count
- Global error handler for uncaught exceptions
- Privacy-respecting: No PII in logs
- Analytics events: scan_started, scan_completed, book_saved
- See [CRASH_REPORTING.md](CRASH_REPORTING.md) for setup

**Performance Monitoring:**
- Cold start time tracking (target < 800ms)
- Shutter latency metrics (target < 30ms)
- Image processing time (target < 500ms)
- Memory footprint monitoring
- Performance dashboard in Debug Settings
- Metrics color-coded: Green (meeting target), Red (missing target)
- Rolling averages over last 20 operations

**Memory Optimization:**
- Image cache limited to 50MB with LRU eviction
- Proper disposal of camera controllers and streams
- Memory warning handler: Clears caches on `didReceiveMemoryWarning`
- Target: < 200MB for typical usage (100+ books, active scanning)

**Session Gamification:**
- Session counter in top-right corner of camera screen
- Format: "5 books scanned...", "10 books scanned...", "25 books scanned!"
- Celebratory pulse animation at milestones: 10, 25, 50, 100 books
- Resets when app backgrounds or after 5 minutes idle
- Encourages batch scanning sessions

### Delighter Features

**Spine Transition Animation:**
- Hero animation: Book cover expands from library thumbnail to detail view
- Blurred spine background fades in (uses original captured photo)
- Smooth 300-400ms ease-out curve
- Connects physical book to digital result visually

**Matrix-Style Stream Overlay:**
- Transparent overlay at top of camera during active scans
- Displays real-time SSE messages in green (#00FF00) JetBrains Mono
- Messages: "Analyzing...", "Found 12 spines...", "Enriching The Martian..."
- Auto-dismisses 3 seconds after last message
- Tappable to manually dismiss
- Semi-transparent black background

**Optimistic Cover Loading:**
- Cover images prefetched immediately on SSE result event
- Fade-in + scale animation (300ms) when cache completes
- Hero animation between grid and detail view
- Maintains 60fps (120fps on ProMotion) during animation

## Known Constraints

- Camera permission is required before showing camera screen
- SQLite FTS5 module must be available on the platform
- SSE timeout is 5 minutes - longer jobs will fail
- Rate limits are enforced by backend - no client-side bypass
- Images are resized to max 1920px and compressed to JPEG quality 85
- iOS widget requires Xcode configuration (see WIDGET_SETUP.md)
- Sentry DSN must be configured for crash reporting (see CRASH_REPORTING.md)
- CocoaPods required for iOS builds (Firebase dependencies)
