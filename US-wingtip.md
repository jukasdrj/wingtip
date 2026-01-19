### **Design Language: "Swiss Utility"**

* **Typography:** *JetBrains Mono* (headers/data) + *Inter* (body).
* **Palette:** `#000000` (Background), `#FFFFFF` (Text), `#FF3B30` (Accent - "International Orange" for status/action).
* **Borders:** 1px solid white borders on cards. No drop shadows.
* **Motion:** 0ms delay. Snap transitions.

---

# User Stories: Project Wingtip (MVP)

## Epic 1: Foundations & Architecture

*Building the "skeleton" of the app.*

**US-101: Initialize Flutter Project with Riverpod & Drift**
**As a** developer
**I want to** scaffold the app with the latest Flutter stack
**So that** I have a stable foundation for state and data.

* [ ] Project created with `com.ooheynerds.wingtip`.
* [ ] `flutter_riverpod` (v3) installed and `ProviderScope` configured.
* [ ] `drift` (v2) installed with `sqlite3_flutter_libs` for native performance.
* [ ] Folder structure set: `features/`, `core/`, `data/`.

**US-102: Implement "Swiss Utility" Theme System**
**As a** user
**I want to** experience a high-contrast, clean interface
**So that** the app feels precise and professional.

* [ ] Theme mode locked to **Dark** (OLED black).
* [ ] Font set to *JetBrains Mono* for all numbers/IDs and *Inter* for text.
* [ ] Components use 1px solid borders instead of shadows (flat design).
* [ ] Accent color defined as `#FF3B30` (International Orange).

**US-103: Generate & Store Persistent Device ID**
**As a** system
**I want to** generate a UUID v4 on first launch
**So that** I can authenticate with the Talaria backend.

* [ ] On first run, generate `uuid.v4()`.
* [ ] Store securely in `FlutterSecureStorage` key `device_id`.
* [ ] Inject `X-Device-ID` header into all Dio requests.
* [ ] Provide a "Regenerate ID" button in debug settings.

**US-104: Offline-First Network Client**
**As a** system
**I want to** queue requests when offline
**So that** I don't lose scans if the network drops.

* [ ] Configure `Dio` with a connection retry interceptor.
* [ ] Detect network status (Connectivity Plus).
* [ ] If offline, show a subtle "OFFLINE" tag in the top-right corner (Swiss style: small text, boxed border).

---

## Epic 2: The Viewfinder (Capture)

*The primary interface. Fast, dumb, and responsive.*

**US-105: Instant Camera Initialization**
**As a** user
**I want to** see the camera immediately upon opening the app
**So that** I can capture a book spine instantly.

* [ ] App launches directly to `CameraScreen`.
* [ ] Cold start to live feed < 1.0s.
* [ ] Hide system status bar for full immersion.

**US-106: Non-Blocking Shutter Action**
**As a** user
**I want to** tap the shutter button repeatedly without waiting
**So that** I can scan a whole shelf in seconds.

* [ ] Shutter button is a large, white ring at bottom center.
* [ ] On tap: Haptic "Tick" (Light impact).
* [ ] On tap: Screen flashes white (100ms opacity).
* [ ] UI does **not** show a loading spinner on the button itself (always clickable).

**US-107: Background Image Processing**
**As a** system
**I want to** compress and resize images in a background Isolate
**So that** the UI thread never janks.

* [ ] Spawn `compute` isolate for image manipulation.
* [ ] Resize to max 1920px (height or width) to save bandwidth.
* [ ] Compress to JPEG (quality 85).
* [ ] Save temporary file to `NSTemporaryDirectory`.

**US-108: The "Processing Stack" UI**
**As a** user
**I want to** see my active uploads as a queue
**So that** I know the system is working.

* [ ] Horizontal list above the shutter button.
* [ ] Each item is a 40x60px thumbnail of the photo.
* [ ] Status indicators: "Uploading" (Yellow border), "Analyzing" (Blue border), "Done" (Green border).
* [ ] Auto-remove card after 5 seconds of "Done" state.

**US-109: Manual Focus & Zoom**
**As a** user
**I want to** pinch to zoom and tap to focus
**So that** I can capture small text on spines.

* [ ] Pinch gesture controls camera zoom level (1x - 4x).
* [ ] Tap on preview sets focus point.
* [ ] Show a square bracket cursor `[ ]` at focus point (Swiss style).

---

## Epic 3: The Talaria Link (Integration)

*Connecting to the backend brain.*

**US-110: Upload Image to Talaria**
**As a** system
**I want to** POST the image to `/v3/jobs/scans`
**So that** I can start the analysis pipeline.

* [ ] Multipart upload of the processed JPEG.
* [ ] Handle `202 Accepted` response.
* [ ] Parse `jobId` and `streamUrl` from response.
* [ ] Update UI state to "Listening".

**US-111: SSE Stream Listener**
**As a** system
**I want to** listen to Server-Sent Events for a specific Job ID
**So that** I receive real-time updates.

* [ ] Open connection to `streamUrl` using `fetch_client`.
* [ ] Maintain open connection until `complete` event or timeout (5m).
* [ ] Parse incoming JSON chunks (`progress`, `result`, `complete`).

**US-112: Visualize "Progress" Events**
**As a** user
**I want to** see text updates as the AI thinks
**So that** I feel the speed of the system.

* [ ] Overlay transparent text on the specific job thumbnail.
* [ ] Display `stage` messages: "Looking...", "Reading...", "Enriching...".
* [ ] Use Monospace font for these logs.

**US-113: Handle "Result" Events (Data Upsert)**
**As a** system
**I want to** save incoming book data immediately
**So that** the user sees results before the job finishes.

* [ ] Listen for `event: result`.
* [ ] Map JSON to Drift `Book` entity.
* [ ] `INSERT OR REPLACE` into local DB (deduplicate by ISBN).
* [ ] Trigger a specific haptic pattern (Double Click) on success.

**US-114: Handle "Complete" & Cleanup**
**As a** system
**I want to** clean up resources when a job finishes
**So that** I don't waste storage or battery.

* [ ] Listen for `event: complete`.
* [ ] Send `DELETE /v3/jobs/scans/{jobId}/cleanup` request.
* [ ] Delete local temporary JPEG file.
* [ ] Close SSE connection.

**US-115: Handle Global Rate Limits**
**As a** user
**I want to** know if I've hit the daily limit
**So that** I don't waste time snapping photos.

* [ ] Intercept `429 Too Many Requests`.
* [ ] Parse `retryAfterMs`.
* [ ] Disable shutter button.
* [ ] Show a countdown timer overlay: "LIMIT REACHED. RESETS IN HH:MM:SS".

---

## Epic 4: The Library (Drift DB)

*The permanent home for the data.*

**US-116: Drift Database Schema**
**As a** developer
**I want to** define the `Books` table
**So that** I can store metadata efficiently.

* [ ] Columns: `isbn` (PK), `title`, `author`, `coverUrl`, `format`, `addedDate`, `spineConfidence`.
* [ ] Index on `addedDate` (descending) for default sort.

**US-117: Library Grid View**
**As a** user
**I want to** see my books in a clean grid
**So that** I can browse my collection.

* [ ] 3-column grid of cover images.
* [ ] Aspect ratio 1:1.5 (Standard book size).
* [ ] If no cover URL, show a solid grey card with Title/Author in monospace text.
* [ ] Infinite scroll (lazy loading from Drift).

**US-118: Real-time List Updates**
**As a** user
**I want to** see new books pop in automatically
**So that** I don't have to pull-to-refresh.

* [ ] Use Drift's `watch()` method to stream DB updates to the UI.
* [ ] Animate new items: Fade in + Slide up (200ms).

**US-119: Full-Text Search (FTS5)**
**As a** user
**I want to** search my library instantly
**So that** I can find a specific book.

* [ ] Enable FTS5 module in Drift.
* [ ] Search bar at top of Library view.
* [ ] Queries filter `title`, `author`, and `isbn`.
* [ ] Results update as I type (< 100ms latency).

**US-120: "Review Needed" Indicator**
**As a** user
**I want to** see which books had low confidence
**So that** I can manually check them.

* [ ] Check `flag: review_needed` from backend.
* [ ] Overlay a small yellow triangle icon on the book cover.
* [ ] Sort option: "Needs Review First".

**US-121: Export Data to CSV**
**As a** user
**I want to** export my library
**So that** I own my data.

* [ ] "Export" button in settings.
* [ ] Generates `wingtip_library_[date].csv`.
* [ ] Opens system share sheet (Save to Files, AirDrop, etc.).

---

## Epic 5: Detail & Interaction

*The "Swiss Utility" feel comes from these interaction details.*

**US-122: Minimal Book Detail View**
**As a** user
**I want to** tap a book to see its data
**So that** I can verify the scan.

* [ ] Modal bottom sheet (dragging up to full screen).
* [ ] Layout: Large Cover (Left) + Data Fields (Right) - "Passport style".
* [ ] Fields: ISBN (Monospace), Title (Bold), Author, Format.
* [ ] Edit button to manually correct fields.

**US-123: The "Raw Data" Toggle**
**As a** user
**I want to** see the raw JSON for a book
**So that** I can geek out on the metadata.

* [ ] Toggle switch in Detail View: "Visual" vs "JSON".
* [ ] JSON view displays formatted code block in monospace green.

**US-124: Swipe to Delete**
**As a** user
**I want to** remove bad scans easily
**So that** my library stays clean.

* [ ] In Library view, long-press to enter "Select Mode".
* [ ] Select multiple items -> Tap Trash icon.
* [ ] Confirm dialog: "Delete X books?".

**US-125: Haptic Feedback Strategy**
**As a** user
**I want to** feel the app working
**So that** I don't have to look at the screen constantly.

* [ ] Shutter: `HapticFeedback.lightImpact()`.
* [ ] Scan Success: `HapticFeedback.mediumImpact()`.
* [ ] Error: `HapticFeedback.heavyImpact()`.

**US-126: Cache Manager**
**As a** user
**I want to** clear cached cover images
**So that** the app doesn't eat up my storage.

* [ ] Settings option: "Clear Image Cache".
* [ ] Uses `DefaultCacheManager.emptyCache()`.
* [ ] Shows current cache size (e.g., "Cache: 124 MB").

---

## Epic 6: Polish & Launch

*Getting ready for the store.*

**US-127: App Icon & Splash Screen**
**As a** user
**I want to** recognize the app on my home screen
**So that** I can launch it quickly.

* [ ] Icon: Abstract white "Wing" glyph on Black background.
* [ ] Splash: Black screen, white "Wingtip" text (Monospace), fades out.

**US-128: Permission Priming**
**As a** user
**I want to** understand why you need camera access
**So that** I trust the app.

* [ ] Before requesting permission, show a full-screen "Primer" slide.
* [ ] Text: "Wingtip needs your camera to see books. Images are processed and deleted instantly."
* [ ] "Grant Access" button triggers OS prompt.

**US-129: Empty States**
**As a** user
**I want to** see helpful text when my library is empty
**So that** I know what to do.

* [ ] Library View empty state: "0 Books. Tap [O] to scan."
* [ ] Use ASCII art or a simple vector outline of a bookshelf.

**US-130: Error Toasts (Snackbars)**
**As a** user
**I want to** see errors without them blocking me
**So that** I can keep scanning.

* [ ] Custom Snackbar design.
* [ ] Black background, white text, red left border.
* [ ] Floating at bottom of screen.
* [ ] Dismiss on tap.