# User Stories: Project Wingtip (MVP)

## Design Language: "Swiss Utility"

* **Typography:** *JetBrains Mono* (headers/data) + *Inter* (body)
* **Palette:** `#000000` (Background), `#FFFFFF` (Text), `#FF3B30` (Accent - "International Orange" for status/action)
* **Borders:** 1px solid white borders on cards. No drop shadows
* **Motion:** 0ms delay. Snap transitions

---

## Epic 1: Foundations & Architecture

*Building the "skeleton" of the app.*

### US-101: Initialize Flutter Project with Riverpod & Drift

**As a** developer
**I want to** scaffold the app with the latest Flutter stack
**So that** I have a stable foundation for state and data

**Acceptance Criteria:**
- [ ] Project created with `com.ooheynerds.wingtip`
- [ ] `flutter_riverpod` (v3) installed and `ProviderScope` configured
- [ ] `drift` (v2) installed with `sqlite3_flutter_libs` for native performance
- [ ] Folder structure set: `features/`, `core/`, `data/`

**Priority:** P0 (Critical)
**Estimate:** 2 hours
**Dependencies:** None

---

### US-102: Implement "Swiss Utility" Theme System

**As a** user
**I want to** experience a high-contrast, clean interface
**So that** the app feels precise and professional

**Acceptance Criteria:**
- [ ] Theme mode locked to **Dark** (OLED black)
- [ ] Font set to *JetBrains Mono* for all numbers/IDs and *Inter* for text
- [ ] Components use 1px solid borders instead of shadows (flat design)
- [ ] Accent color defined as `#FF3B30` (International Orange)

**Priority:** P0 (Critical)
**Estimate:** 3 hours
**Dependencies:** US-101

---

### US-103: Generate & Store Persistent Device ID

**As a** system
**I want to** generate a UUID v4 on first launch
**So that** I can authenticate with the Talaria backend

**Acceptance Criteria:**
- [ ] On first run, generate `uuid.v4()`
- [ ] Store securely in `FlutterSecureStorage` key `device_id`
- [ ] Inject `X-Device-ID` header into all Dio requests
- [ ] Provide a "Regenerate ID" button in debug settings

**Priority:** P0 (Critical)
**Estimate:** 2 hours
**Dependencies:** US-101

---

### US-104: Offline-First Network Client

**As a** system
**I want to** queue requests when offline
**So that** I don't lose scans if the network drops

**Acceptance Criteria:**
- [ ] Configure `Dio` with a connection retry interceptor
- [ ] Detect network status (Connectivity Plus)
- [ ] If offline, show a subtle "OFFLINE" tag in the top-right corner (Swiss style: small text, boxed border)

**Priority:** P1 (High)
**Estimate:** 4 hours
**Dependencies:** US-103

---

## Epic 2: The Viewfinder (Capture)

*The primary interface. Fast, dumb, and responsive.*

### US-105: Instant Camera Initialization

**As a** user
**I want to** see the camera immediately upon opening the app
**So that** I can capture a book spine instantly

**Acceptance Criteria:**
- [ ] App launches directly to `CameraScreen`
- [ ] Cold start to live feed < 1.0s
- [ ] Hide system status bar for full immersion

**Priority:** P0 (Critical)
**Estimate:** 4 hours
**Dependencies:** US-101, US-102

---

### US-106: Non-Blocking Shutter Action

**As a** user
**I want to** tap the shutter button repeatedly without waiting
**So that** I can scan a whole shelf in seconds

**Acceptance Criteria:**
- [ ] Shutter button is a large, white ring at bottom center
- [ ] On tap: Haptic "Tick" (Light impact)
- [ ] On tap: Screen flashes white (100ms opacity)
- [ ] UI does **not** show a loading spinner on the button itself (always clickable)

**Priority:** P0 (Critical)
**Estimate:** 3 hours
**Dependencies:** US-105

---

### US-107: Background Image Processing

**As a** system
**I want to** compress and resize images in a background Isolate
**So that** the UI thread never janks

**Acceptance Criteria:**
- [ ] Spawn `compute` isolate for image manipulation
- [ ] Resize to max 1920px (height or width) to save bandwidth
- [ ] Compress to JPEG (quality 85)
- [ ] Save temporary file to `NSTemporaryDirectory`

**Priority:** P0 (Critical)
**Estimate:** 4 hours
**Dependencies:** US-106

---

### US-108: The "Processing Stack" UI

**As a** user
**I want to** see my active uploads as a queue
**So that** I know the system is working

**Acceptance Criteria:**
- [ ] Horizontal list above the shutter button
- [ ] Each item is a 40x60px thumbnail of the photo
- [ ] Status indicators: "Uploading" (Yellow border), "Analyzing" (Blue border), "Done" (Green border)
- [ ] Auto-remove card after 5 seconds of "Done" state

**Priority:** P1 (High)
**Estimate:** 5 hours
**Dependencies:** US-107

---

### US-109: Manual Focus & Zoom

**As a** user
**I want to** pinch to zoom and tap to focus
**So that** I can capture small text on spines

**Acceptance Criteria:**
- [ ] Pinch gesture controls camera zoom level (1x - 4x)
- [ ] Tap on preview sets focus point
- [ ] Show a square bracket cursor `[ ]` at focus point (Swiss style)

**Priority:** P1 (High)
**Estimate:** 3 hours
**Dependencies:** US-105

---

## Epic 3: The Talaria Link (Integration)

*Connecting to the backend brain.*

### US-110: Upload Image to Talaria

**As a** system
**I want to** POST the image to `/v3/jobs/scans`
**So that** I can start the analysis pipeline

**Acceptance Criteria:**
- [ ] Multipart upload of the processed JPEG
- [ ] Handle `202 Accepted` response
- [ ] Parse `jobId` and `streamUrl` from response
- [ ] Update UI state to "Listening"

**Priority:** P0 (Critical)
**Estimate:** 4 hours
**Dependencies:** US-107, US-103

---

### US-111: SSE Stream Listener

**As a** system
**I want to** listen to Server-Sent Events for a specific Job ID
**So that** I receive real-time updates

**Acceptance Criteria:**
- [ ] Open connection to `streamUrl` using `fetch_client`
- [ ] Maintain open connection until `complete` event or timeout (5m)
- [ ] Parse incoming JSON chunks (`progress`, `result`, `complete`)

**Priority:** P0 (Critical)
**Estimate:** 5 hours
**Dependencies:** US-110

---

### US-112: Visualize "Progress" Events

**As a** user
**I want to** see text updates as the AI thinks
**So that** I feel the speed of the system

**Acceptance Criteria:**
- [ ] Overlay transparent text on the specific job thumbnail
- [ ] Display `stage` messages: "Looking...", "Reading...", "Enriching..."
- [ ] Use Monospace font for these logs

**Priority:** P1 (High)
**Estimate:** 3 hours
**Dependencies:** US-111, US-108

---

### US-113: Handle "Result" Events (Data Upsert)

**As a** system
**I want to** save incoming book data immediately
**So that** the user sees results before the job finishes

**Acceptance Criteria:**
- [ ] Listen for `event: result`
- [ ] Map JSON to Drift `Book` entity
- [ ] `INSERT OR REPLACE` into local DB (deduplicate by ISBN)
- [ ] Trigger a specific haptic pattern (Double Click) on success

**Priority:** P0 (Critical)
**Estimate:** 4 hours
**Dependencies:** US-111, US-116

---

### US-114: Handle "Complete" & Cleanup

**As a** system
**I want to** clean up resources when a job finishes
**So that** I don't waste storage or battery

**Acceptance Criteria:**
- [ ] Listen for `event: complete`
- [ ] Send `DELETE /v3/jobs/scans/{jobId}/cleanup` request
- [ ] Delete local temporary JPEG file
- [ ] Close SSE connection

**Priority:** P0 (Critical)
**Estimate:** 3 hours
**Dependencies:** US-111

---

### US-115: Handle Global Rate Limits

**As a** user
**I want to** know if I've hit the daily limit
**So that** I don't waste time snapping photos

**Acceptance Criteria:**
- [ ] Intercept `429 Too Many Requests`
- [ ] Parse `retryAfterMs`
- [ ] Disable shutter button
- [ ] Show a countdown timer overlay: "LIMIT REACHED. RESETS IN HH:MM:SS"

**Priority:** P1 (High)
**Estimate:** 3 hours
**Dependencies:** US-110

---

## Epic 4: The Library (Drift DB)

*The permanent home for the data.*

### US-116: Drift Database Schema

**As a** developer
**I want to** define the `Books` table
**So that** I can store metadata efficiently

**Acceptance Criteria:**
- [ ] Columns: `isbn` (PK), `title`, `author`, `coverUrl`, `format`, `addedDate`, `spineConfidence`
- [ ] Index on `addedDate` (descending) for default sort

**Priority:** P0 (Critical)
**Estimate:** 2 hours
**Dependencies:** US-101

---

### US-117: Library Grid View

**As a** user
**I want to** see my books in a clean grid
**So that** I can browse my collection

**Acceptance Criteria:**
- [ ] 3-column grid of cover images
- [ ] Aspect ratio 1:1.5 (Standard book size)
- [ ] If no cover URL, show a solid grey card with Title/Author in monospace text
- [ ] Infinite scroll (lazy loading from Drift)

**Priority:** P0 (Critical)
**Estimate:** 5 hours
**Dependencies:** US-116, US-102

---

### US-118: Real-time List Updates

**As a** user
**I want to** see new books pop in automatically
**So that** I don't have to pull-to-refresh

**Acceptance Criteria:**
- [ ] Use Drift's `watch()` method to stream DB updates to the UI
- [ ] Animate new items: Fade in + Slide up (200ms)

**Priority:** P1 (High)
**Estimate:** 3 hours
**Dependencies:** US-117

---

### US-119: Full-Text Search (FTS5)

**As a** user
**I want to** search my library instantly
**So that** I can find a specific book

**Acceptance Criteria:**
- [ ] Enable FTS5 module in Drift
- [ ] Search bar at top of Library view
- [ ] Queries filter `title`, `author`, and `isbn`
- [ ] Results update as I type (< 100ms latency)

**Priority:** P1 (High)
**Estimate:** 4 hours
**Dependencies:** US-116, US-117

---

### US-120: "Review Needed" Indicator

**As a** user
**I want to** see which books had low confidence
**So that** I can manually check them

**Acceptance Criteria:**
- [ ] Check `flag: review_needed` from backend
- [ ] Overlay a small yellow triangle icon on the book cover
- [ ] Sort option: "Needs Review First"

**Priority:** P2 (Medium)
**Estimate:** 3 hours
**Dependencies:** US-117, US-113

---

### US-121: Export Data to CSV

**As a** user
**I want to** export my library
**So that** I own my data

**Acceptance Criteria:**
- [ ] "Export" button in settings
- [ ] Generates `wingtip_library_[date].csv`
- [ ] Opens system share sheet (Save to Files, AirDrop, etc.)

**Priority:** P2 (Medium)
**Estimate:** 3 hours
**Dependencies:** US-116

---

## Epic 5: Detail & Interaction

*The "Swiss Utility" feel comes from these interaction details.*

### US-122: Minimal Book Detail View

**As a** user
**I want to** tap a book to see its data
**So that** I can verify the scan

**Acceptance Criteria:**
- [ ] Modal bottom sheet (dragging up to full screen)
- [ ] Layout: Large Cover (Left) + Data Fields (Right) - "Passport style"
- [ ] Fields: ISBN (Monospace), Title (Bold), Author, Format
- [ ] Edit button to manually correct fields

**Priority:** P1 (High)
**Estimate:** 5 hours
**Dependencies:** US-117, US-102

---

### US-123: The "Raw Data" Toggle

**As a** user
**I want to** see the raw JSON for a book
**So that** I can geek out on the metadata

**Acceptance Criteria:**
- [ ] Toggle switch in Detail View: "Visual" vs "JSON"
- [ ] JSON view displays formatted code block in monospace green

**Priority:** P3 (Low)
**Estimate:** 2 hours
**Dependencies:** US-122

---

### US-124: Swipe to Delete

**As a** user
**I want to** remove bad scans easily
**So that** my library stays clean

**Acceptance Criteria:**
- [ ] In Library view, long-press to enter "Select Mode"
- [ ] Select multiple items -> Tap Trash icon
- [ ] Confirm dialog: "Delete X books?"

**Priority:** P2 (Medium)
**Estimate:** 4 hours
**Dependencies:** US-117

---

### US-125: Haptic Feedback Strategy

**As a** user
**I want to** feel the app working
**So that** I don't have to look at the screen constantly

**Acceptance Criteria:**
- [ ] Shutter: `HapticFeedback.lightImpact()`
- [ ] Scan Success: `HapticFeedback.mediumImpact()`
- [ ] Error: `HapticFeedback.heavyImpact()`

**Priority:** P1 (High)
**Estimate:** 2 hours
**Dependencies:** US-106, US-113

---

### US-126: Cache Manager

**As a** user
**I want to** clear cached cover images
**So that** the app doesn't eat up my storage

**Acceptance Criteria:**
- [ ] Settings option: "Clear Image Cache"
- [ ] Uses `DefaultCacheManager.emptyCache()`
- [ ] Shows current cache size (e.g., "Cache: 124 MB")

**Priority:** P2 (Medium)
**Estimate:** 3 hours
**Dependencies:** US-117

---

## Epic 6: Polish & Launch

*Getting ready for the store.*

### US-127: App Icon & Splash Screen

**As a** user
**I want to** recognize the app on my home screen
**So that** I can launch it quickly

**Acceptance Criteria:**
- [ ] Icon: Abstract white "Wing" glyph on Black background
- [ ] Splash: Black screen, white "Wingtip" text (Monospace), fades out

**Priority:** P2 (Medium)
**Estimate:** 3 hours
**Dependencies:** US-102

---

### US-128: Permission Priming

**As a** user
**I want to** understand why you need camera access
**So that** I trust the app

**Acceptance Criteria:**
- [ ] Before requesting permission, show a full-screen "Primer" slide
- [ ] Text: "Wingtip needs your camera to see books. Images are processed and deleted instantly."
- [ ] "Grant Access" button triggers OS prompt

**Priority:** P1 (High)
**Estimate:** 3 hours
**Dependencies:** US-105

---

### US-129: Empty States

**As a** user
**I want to** see helpful text when my library is empty
**So that** I know what to do

**Acceptance Criteria:**
- [ ] Library View empty state: "0 Books. Tap [O] to scan."
- [ ] Use ASCII art or a simple vector outline of a bookshelf

**Priority:** P2 (Medium)
**Estimate:** 2 hours
**Dependencies:** US-117

---

### US-130: Error Toasts (Snackbars)

**As a** user
**I want to** see errors without them blocking me
**So that** I can keep scanning

**Acceptance Criteria:**
- [ ] Custom Snackbar design
- [ ] Black background, white text, red left border
- [ ] Floating at bottom of screen
- [ ] Dismiss on tap

**Priority:** P1 (High)
**Estimate:** 2 hours
**Dependencies:** US-102

---

## Summary Statistics

**Total User Stories:** 30
**Total Estimated Hours:** 98 hours (~12-13 days)

### Priority Breakdown
- **P0 (Critical):** 13 stories
- **P1 (High):** 11 stories
- **P2 (Medium):** 5 stories
- **P3 (Low):** 1 story

### Epic Breakdown
- **Epic 1 (Foundations):** 4 stories, 11 hours
- **Epic 2 (Viewfinder):** 5 stories, 19 hours
- **Epic 3 (Talaria Link):** 6 stories, 22 hours
- **Epic 4 (Library):** 6 stories, 20 hours
- **Epic 5 (Detail & Interaction):** 5 stories, 16 hours
- **Epic 6 (Polish & Launch):** 4 stories, 10 hours

### Critical Path (MVP)
For a minimal viable product, focus on P0 stories first:
1. US-101 → US-102 → US-103 → US-116 (Foundation: 9 hours)
2. US-105 → US-106 → US-107 (Camera: 11 hours)
3. US-110 → US-111 → US-113 → US-114 (Integration: 16 hours)
4. US-117 (Library: 5 hours)

**MVP Total: ~41 hours (5-6 days)**
