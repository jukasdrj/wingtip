# Product Requirements Document: Project Wingtip (Frontend)

**Version:** 1.0  
**Status:** Draft  
**Target Platform:** Flutter (iOS/Android)  
**Backend:** [Project Talaria]  
**Author:** Product Team  
**Last Updated:** 2026-01-18

---

## 1. Executive Summary

**Wingtip** is the "dumb" but beautiful lens for the Talaria brain. It is a local-first, offline-capable library manager that uses the camera solely as a data pipe.

### Core Philosophy

**"The Shutter That Remembers"** — While the backend (Talaria) forgets everything instantly, Wingtip remembers everything forever. It is the permanent residence for the data streaming back from the edge.

### Design Principles (The "Slim & Fast" Mandate)

1. **Zero-Blocking UI:** The shutter button must *always* be clickable. Uploads happen in background isolates.
2. **Haptic Fidelity:** Every stage of the SSE stream (Sent → Analyzed → Enriched) provides distinct haptic feedback.
3. **Optimistic fluidity:** The UI should predict success. Book covers animate into place before the full metadata arrives.
4. **Local Sovereignty:** All data lives in SQLite (Drift). The app works 100% offline for viewing/searching, only needing network to *scan*.

---

## 2. Success Metrics (Frontend)

| Metric | Target | Measurement |
| --- | --- | --- |
| **Cold Start Time** | < 1.0s | Time to interactive camera viewfinder |
| **Shutter Latency** | < 50ms | Tap to capture animation start |
| **Jank (Frame Drop)** | 0% | No dropped frames during SSE stream rendering |
| **Battery Impact** | Low | Camera session paused immediately on backgrounding |
| **Offline Reliability** | 100% | Library fully searchable in Airplane Mode |

---

## 3. Tech Stack & Architecture

### 3.1 Core Stack

* **Framework:** Flutter (Latest Stable)
* **Language:** Dart 3.0+
* **State Management:** `flutter_riverpod` (v2, Generator syntax) for reactive UI updates.
* **Local Database:** `drift` (SQLite abstraction) for high-performance structured storage.
* **Camera:** `camerawesome` (Better UI customization than standard `camera` package) or `camera` with custom texture implementation.
* **Networking:** `dio` (Multipart uploads) + `fetch_client` (for SSE streaming handling).

### 3.2 Data Flow (The "Capture Loop")

1. **Capture:** User taps shutter.
   * *UI:* Flash animation, haptic "click", thumbnail flies into a "processing queue" stack.
   * *Logic:* Image saved to temp cache. `ScanRepository` spawns an Isolate to compress/resize.

2. **Upload:**
   * *Logic:* `TalariaClient` uploads to `POST /v3/jobs/scans`.
   * *Header:* Injects `X-Device-ID` (UUID generated on first launch).

3. **Listen (The Stream):**
   * *Logic:* App connects to `GET /v3/jobs/scans/{jobId}/stream`.
   * *State:* Riverpod provider `scanStreamProvider(jobId)` listens to SSE events.

4. **Ingest:**
   * *Event `result`:* Data is upserted immediately into local SQLite `books` table (deduplication by ISBN).
   * *Event `complete`:* Temporary image cache is cleared.

5. **Display:**
   * The "Library" view listens to the SQLite stream, so books "pop" into the list automatically as they are saved.

---

## 4. Database Schema

### 4.1 Core Tables (Drift)

#### Books Table (Minimal Essential Fields)

```dart
class Books extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get isbn => text().unique()();
  TextColumn get title => text()();
  TextColumn get author => text()();
  TextColumn get coverUrl => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
```

#### Failed Scans Table (For Retry Queue)

```dart
class FailedScans extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get jobId => text().unique()();
  TextColumn get imagePath => text()(); // Local cached image
  TextColumn get errorMessage => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get expiresAt => dateTime()(); // Auto-delete after 7 days
}
```

### 4.2 Deduplication Strategy

* **Silent deduplication by ISBN:** When SSE `result` event arrives, perform `upsert` on ISBN.
* If book already exists, update `updatedAt` timestamp but preserve original `createdAt`.
* No user notification for duplicates (seamless experience).

---

## 5. Feature Specifications

### 5.1 The Viewfinder (Home Screen)

The app opens directly to the camera (Snapchat style) to reduce friction.

* **UI Elements:**
  * **Shutter Button:** Large, bottom center. Animated ring indicates "Processing" load.
  * **Library Peek:** Bottom right thumbnail showing the last scanned book cover. Tapping opens Library.
  * **Settings/Flash:** Minimal top bar.
  * **"Stream" Overlay:** A subtle, transparent log overlay (Matrix style but clean) that fades in/out showing real-time status: *"Analyzing... Found 12 spines... Enriched 'The Martian'..."*.

* **Gestures:**
  * **Swipe Up:** Open Library.
  * **Pinch:** Zoom (Essential for small spines).

### 5.2 The Processing Queue (The "Feed")

Because the user can snap 5 photos in 3 seconds, the UI cannot block.

* **Implementation:** A horizontal "stories" style bar or a floating stack that shows active jobs.
* **States per Job:**
  1. **Uploading:** Indeterminate progress bar.
  2. **Analyzing (Gemini):** Pulsing "AI" icon.
  3. **Enriching:** Rapid cover art flickering as URLs resolve.
  4. **Done:** Disappears and increments the "New Books" badge on the Library icon.
  5. **Failed:** Red border, shows error toast, moves to "Failed" queue with retry option.

### 5.3 Failed Scan Queue

* **Storage:** When backend returns no books or errors occur, save to `FailedScans` table.
* **UI:** Show in "Failed" section of Library with error message and image preview.
* **Actions:**
  * **Retry:** Re-upload same image to backend.
  * **Delete:** Remove from queue.
* **Auto-cleanup:** Delete entries older than 7 days (configurable via settings).

### 5.4 The Library (Local SQLite)

* **View:** Infinite scroll grid of book covers.
* **Search:** Instant local full-text search (FTS5 via Drift) against Title, Author, ISBN.
* **Manual Override:** If Talaria returns `flag: review_needed`, the book card has a yellow "Review" border. Tapping allows manual metadata editing.
* **Export:** "Export CSV" button to dump the SQLite DB to the device file system (User data ownership).
* **Failed Section:** Separate tab/filter showing failed scans with retry options.

### 5.5 Settings & Privacy

* **Device ID:** Display the `X-Device-ID` UUID with a "Regenerate" button (Privacy nuking).
* **Cache Management:** Button to "Clear Cached Images" (covers downloaded from ISBNdb/Google).
* **Failed Scan Retention:** Configure auto-delete period (default: 7 days, options: 3/7/14/30 days, never).

---

## 6. UI/UX "Delighters"

* **The "Spine" Transition:** When a book is identified, if the user taps the notification, the cover art expands from the center, but the background is a blurred version of the *original photo* where the spine was found.
* **Haptic Syntax:**
  * *Light Tap:* Shutter press.
  * *Double Tick:* Scan complete (Server sent `status: complete`).
  * *Heavy Buzz:* Error/Retry needed.

* **Gamification:** A "Session Counter" in the corner during a scanning spree. "12 books... 24 books... 50 books!"

---

## 7. API Integration Contract

### 7.1 Authentication

* **UUID Generation:** On app install, generate `uuid.v4()`. Store in `FlutterSecureStorage`.
* **Headers:** Send `X-Device-ID: <uuid>` on *every* request.

### 7.2 SSE Handling (Talaria Loop)

The app must handle the specific SSE events defined in the Backend PRD:

| Event | Action |
| --- | --- |
| `progress` | Update progress bar percentage on the job card. |
| `result` | **CRITICAL:** Upsert book to Drift DB (dedupe by ISBN). Prefetch `cover_url` to disk cache. |
| `complete` | Trigger "Job Done" haptic. Send `DELETE /cleanup` request. |
| `error` | Save to `FailedScans` table. Show error toast. Keep image in "Failed" queue for retry. |

### 7.3 Error Handling (Resilience)

* **Talaria 400 (Bad Image):** Save to `FailedScans` with error message "Image quality too low". Show toast.
* **Talaria 404 (No Books Found):** Save to `FailedScans` with error message "No books detected". Keep image for retry.
* **Talaria 429 (Rate Limit):** If global/device limit hit, disable shutter button and show countdown.
* **Network Loss:** Queue uploads locally. Retry when connection restored (WorkManager).

---

## 8. Offline Queue Management

### 8.1 Upload Queue Strategy

* **Failed Scan Storage:** Unlimited storage in `FailedScans` table (disk space permitting).
* **Auto-cleanup:** Delete entries older than configured retention period (default: 7 days).
* **User Control:** Settings allow manual deletion of all failed scans or individual items.

### 8.2 Retry Logic

* **Manual Retry:** User taps "Retry" on failed scan card.
* **Batch Retry:** "Retry All Failed" button in Library failed section.
* **Network Resume:** When network connection restored, prompt user to retry failed scans.

---

## 9. Migration from Old App

* Since the backend "Purge" removes user accounts and recommendations, the new app is a fresh start.
* **Onboarding:** A simple 3-slide tutorial explaining: "1. Snap Shelf. 2. AI Analyzes. 3. Books Saved Locally."

---

## 10. Draft `pubspec.yaml` Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  # State
  flutter_riverpod: ^2.4.9
  riverpod_annotation: ^2.3.3
  # Data
  drift: ^2.14.0
  sqlite3_flutter_libs: ^0.5.18
  path_provider: ^2.1.2
  # Network
  dio: ^5.4.0
  fetch_client: ^1.0.0 # Essential for SSE on web/mobile
  # UI/Camera
  camerawesome: ^2.0.0 # Or mobile_scanner if we just want simple UI
  flutter_animate: ^4.5.0
  google_fonts: ^6.1.0
  cached_network_image: ^3.3.1
  # Utils
  uuid: ^4.3.3
  flutter_secure_storage: ^9.0.0
  share_plus: ^7.2.1 # For CSV export

dev_dependencies:
  build_runner: ^2.4.8
  riverpod_generator: ^2.3.9
  drift_dev: ^2.14.0
```

---

## 11. User Stories

### Epic 1: Camera & Capture
- **US-1.1:** As a user, I want to open the app directly to the camera viewfinder so I can start scanning immediately.
- **US-1.2:** As a user, I want the shutter button to always be clickable so I can capture multiple books rapidly.
- **US-1.3:** As a user, I want haptic feedback when I capture a photo so I know the action registered.
- **US-1.4:** As a user, I want to pinch-zoom the camera so I can capture small book spines clearly.

### Epic 2: Upload & Processing
- **US-2.1:** As a user, I want to see my scans processing in a queue so I know what's happening.
- **US-2.2:** As a user, I want uploads to happen in the background so I can continue scanning.
- **US-2.3:** As a user, I want distinct haptic feedback for different processing stages so I understand progress without looking.
- **US-2.4:** As a user, I want to see real-time AI analysis status so I can track what the backend is doing.

### Epic 3: Library Management
- **US-3.1:** As a user, I want to see all my scanned books in a grid view so I can browse my library.
- **US-3.2:** As a user, I want to search my library instantly so I can find books quickly.
- **US-3.3:** As a user, I want my library to work offline so I can access it without internet.
- **US-3.4:** As a user, I want to export my library as CSV so I own my data.

### Epic 4: Error Handling & Retry
- **US-4.1:** As a user, I want failed scans to be saved with the original image so I can retry later.
- **US-4.2:** As a user, I want to see why a scan failed so I can understand what went wrong.
- **US-4.3:** As a user, I want to manually retry failed scans so I can recover from temporary errors.
- **US-4.4:** As a user, I want old failed scans to auto-delete after 7 days so my storage doesn't fill up.

### Epic 5: Settings & Privacy
- **US-5.1:** As a user, I want to see my device ID so I understand how I'm identified.
- **US-5.2:** As a user, I want to regenerate my device ID so I can reset my privacy.
- **US-5.3:** As a user, I want to clear cached images so I can reclaim storage space.
- **US-5.4:** As a user, I want to configure failed scan retention so I control cleanup behavior.

### Epic 6: Gamification & Delight
- **US-6.1:** As a user, I want to see a session counter during scanning sprees so I feel accomplishment.
- **US-6.2:** As a user, I want smooth cover art animations so the app feels polished.
- **US-6.3:** As a user, I want to see the original shelf photo behind book details so I remember context.

---

## 12. Acceptance Criteria

### MVP Release Criteria
- [ ] Camera opens in < 1.0s on cold start
- [ ] Shutter latency < 50ms from tap to animation
- [ ] Background upload isolates don't block UI
- [ ] SSE events properly update UI in real-time
- [ ] Books deduplicate silently by ISBN
- [ ] Failed scans saved to retry queue with image
- [ ] Library search works offline with FTS5
- [ ] CSV export generates valid file
- [ ] Auto-cleanup deletes failed scans after 7 days
- [ ] All haptic feedback implemented per spec

### Performance Criteria
- [ ] Zero dropped frames during SSE rendering
- [ ] Library scrolling at 60fps with 1000+ books
- [ ] Image compression in isolate completes in < 500ms
- [ ] SQLite queries return in < 100ms

### Quality Criteria
- [ ] No memory leaks during scanning sessions
- [ ] Camera session properly releases on background
- [ ] Network failures handled gracefully
- [ ] Rate limiting shows countdown timer

---

## 13. Out of Scope (Future Considerations)

- Reading status tracking (To Read, Reading, Finished)
- Personal ratings and reviews
- Social features / sharing
- Barcode scanning mode
- Multi-language support (MVP is English-only)
- Cloud backup of library data
- Advanced search filters (genre, year, publisher)

---

## 14. Dependencies & Risks

### Dependencies
- Talaria backend API must be stable and available
- ISBNdb/Google Books APIs must be accessible for cover images
- Camera permissions must be granted by user

### Technical Risks
- **SSE Reliability:** Network interruptions during streaming could lose data.
  - *Mitigation:* Implement reconnection logic with exponential backoff.
- **Storage Growth:** Unlimited failed scans could consume device storage.
  - *Mitigation:* Default 7-day auto-cleanup with user override.
- **Camera Performance:** Older devices may struggle with high-res capture.
  - *Mitigation:* Adaptive image quality based on device capabilities.

### UX Risks
- **Over-scanning:** Users might capture blurry/duplicate images rapidly.
  - *Mitigation:* Visual feedback during processing queue buildup.
- **Failed Scan Confusion:** Users may not understand why scans fail.
  - *Mitigation:* Clear error messages with actionable suggestions.