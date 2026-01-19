# Product Requirements Document: Project Wingtip (Frontend)

**Version:** 1.0
**Status:** Draft
**Target Platform:** Flutter (iOS/Android)
**Backend:** [Project Talaria]

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
* *Event `result`:* Data is upserted immediately into local SQLite `books` table.
* *Event `complete`:* Temporary image cache is cleared.


5. **Display:**
* The "Library" view listens to the SQLite stream, so books "pop" into the list automatically as they are saved.



---

## 4. Feature Specifications

### 4.1 The Viewfinder (Home Screen)

The app opens directly to the camera (Snapchat style) to reduce friction.

* **UI Elements:**
* **Shutter Button:** Large, bottom center. Animated ring indicates "Processing" load.
* **Library Peek:** Bottom right thumbnail showing the last scanned book cover. Tapping opens Library.
* **Settings/Flash:** Minimal top bar.
* **"Stream" Overlay:** A subtle, transparent log overlay (Matrix style but clean) that fades in/out showing real-time status: *"Analyzing... Found 12 spines... Enriched 'The Martian'..."*.


* **Gestures:**
* **Swipe Up:** Open Library.
* **Pinch:** Zoom (Essential for small spines).



### 4.2 The Processing Queue (The "Feed")

Because the user can snap 5 photos in 3 seconds, the UI cannot block.

* **Implementation:** A horizontal "stories" style bar or a floating stack that shows active jobs.
* **States per Job:**
1. **Uploading:** Indeterminate progress bar.
2. **Analyzing (Gemini):** Pulsing "AI" icon.
3. **Enriching:** Rapid cover art flickering as URLs resolve.
4. **Done:** Disappears and increments the "New Books" badge on the Library icon.



### 4.3 The Library (Local SQLite)

* **View:** Infinite scroll grid of book covers.
* **Search:** Instant local full-text search (FTS5 via Drift) against Title, Author, ISBN.
* **Manual Override:** If Talaria returns `flag: review_needed`, the book card has a yellow "Review" border. Tapping allows manual metadata editing.
* **Export:** "Export CSV" button to dump the SQLite DB to the device file system (User data ownership).

### 4.4 Settings & Privacy

* **Device ID:** Display the `X-Device-ID` UUID with a "Regenerate" button (Privacy nuking).
* **Cache Management:** Button to "Clear Cached Images" (covers downloaded from ISBNdb/Google).

---

## 5. UI/UX "Delighters"

* **The "Spine" Transition:** When a book is identified, if the user taps the notification, the cover art expands from the center, but the background is a blurred version of the *original photo* where the spine was found.
* **Haptic Syntax:**
* *Light Tap:* Shutter press.
* *Double Tick:* Scan complete (Server sent `status: complete`).
* *Heavy Buzz:* Error/Retry needed.


* **Gamification:** A "Session Counter" in the corner during a scanning spree. "12 books... 24 books... 50 books!"

---

## 6. API Integration Contract

### 6.1 Authentication

* **UUID Generation:** On app install, generate `uuid.v4()`. Store in `FlutterSecureStorage`.
* **Headers:** Send `X-Device-ID: <uuid>` on *every* request.

### 6.2 SSE Handling (Talaria Loop)

The app must handle the specific SSE events defined in the Backend PRD:

| Event | Action |
| --- | --- |
| `progress` | Update progress bar percentage on the job card. |
| `result` | **CRITICAL:** Upsert book to Drift DB. Prefetch `cover_url` to disk cache. |
| `complete` | Trigger "Job Done" haptic. Send `DELETE /cleanup` request. |
| `error` | Show toast notification. If `429`, show cool-down timer. |

### 6.3 Error Handling (Resilience)

* **Talaria 400 (Bad Image):** Show a "Too Blurry" overlay on the viewfinder immediately.
* **Talaria 429 (Rate Limit):** If global/device limit hit, disable shutter button and show countdown.
* **Network Loss:** Queue uploads locally. Retry when connection restored (WorkManager).

---

## 7. Migration from Old App

* Since the backend "Purge" removes user accounts and recommendations, the new app is a fresh start.
* **Onboarding:** A simple 3-slide tutorial explaining: "1. Snap Shelf. 2. AI Analyzes. 3. Books Saved Locally."

---

## 8. Draft `pubspec.yaml` Dependencies

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

### Next Steps for You

Would you like me to:

1. **Scaffold the Flutter Project:** Generate the directory structure and the core `ScanRepository` class that handles the Multipart Upload + SSE listening loop?
2. **Design the Local DB Schema:** Write the `Drift` table definition for `Books` to ensure it matches the JSON output from Talaria?
3. **Refine the API Client:** Create the Dio interceptor for the `X-Device-ID` injection?