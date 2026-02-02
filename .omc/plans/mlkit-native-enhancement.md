# ML Kit Native Enhancement Plan

## Revision History

| Rev | Date | Changes |
|-----|------|---------|
| v1 | 2026-02-01 | Initial plan |
| v2 | 2026-02-01 | Address Critic feedback: added Task 0.1 (InputImage converter extraction), Task 1.0 (getBookByIsbn), specified ISBN multipart transport, defined test fixture strategy, clarified overlay placement, fixed return type in Phase 2, assigned distinct barcode overlay color |

## Context

### Original Request
Integrate native ML Kit capabilities into the Wingtip Flutter app to replace manual image processing logic, add ISBN barcode scanning, upgrade object detection, and enable multi-script text recognition.

### Current State Analysis

**Dependencies (pubspec.yaml lines 104-105):**
- `google_mlkit_text_recognition: ^0.15.0` -- Used for Latin-only OCR
- `google_mlkit_object_detection: ^0.15.0` -- Used with default Coco model (generic)

**iOS Pods (Podfile.lock):**
- GoogleMLKit 7.0.0 with MLKitTextRecognition 5.0.0 and MLKitObjectDetection 6.0.0
- ObjectDetectionCustom already pulled in (unused)

**Missing ML Kit packages (not in pubspec.yaml):**
- `google_mlkit_barcode_scanning` -- ISBN barcode detection
- `google_mlkit_document_scanner` -- Perspective correction, shadow removal, auto-crop
- `google_mlkit_entity_extraction` or `google_mlkit_language_id` -- Language identification
- `google_mlkit_image_labeling` -- Alternative to object detection for book classification
- `google_mlkit_subject_segmentation` -- Foreground/background separation (requires iOS 15+)

### Key Files and Their Roles

| File | Path | Role | Lines |
|------|------|------|-------|
| ImageProcessor | `lib/features/camera/image_processor.dart` | Manual image processing (resize, contrast, brightness, blur, rotation) | 434 lines |
| LocalProcessorService | `lib/features/scancapture/local_processor_service.dart` | ML Kit integration point (text recognition + object detection) | 158 lines |
| LocalProcessorProvider | `lib/features/scancapture/local_processor_provider.dart` | Riverpod provider for LocalProcessorService | 8 lines |
| CameraScreen | `lib/features/camera/camera_screen.dart` | Camera UI with ML overlay, shutter capture, stream processing | 1113 lines |
| ObjectOverlayPainter | `lib/features/camera/object_overlay_painter.dart` | Renders bounding boxes on camera preview | 120 lines |
| JobStateNotifier | `lib/features/talaria/job_state_notifier.dart` | Upload pipeline, calls `ImageProcessor.enhanceForUpload()` at line 307 |
| TalariaClient | `lib/core/talaria_client.dart` | HTTP client, `uploadImage()` uses `FormData.fromMap` with multipart fields (line 37-43) | 73 lines |
| Database | `lib/data/database.dart` | Books table with ISBN primary key, ReviewQueue table. **No `getBookByIsbn()` method exists.** | 1085 lines |
| ImageProcessorTest | `test/features/camera/image_processor_test.dart` | 20 tests covering basic processing and enhancement | 393 lines |

### Gap Analysis Summary

1. **Barcode Scanning (Missing)** -- Books have ISBN barcodes on the back cover. ML Kit's barcode scanner natively detects EAN-13/ISBN barcodes with zero custom logic. This is the highest-ROI addition: instant ISBN lookup without OCR guesswork.

2. **Manual Image Processing Duplication** -- `ImageProcessor` (434 lines) manually implements contrast enhancement, brightness adjustment, Gaussian blur, auto-rotation, and resize using the `image` package in a compute isolate. ML Kit's Document Scanner API provides perspective correction, shadow removal, and auto-crop natively on-device with GPU acceleration. The manual approach is slower (CPU-bound Dart isolate) and less accurate.

3. **Generic Object Detection** -- `LocalProcessorService` uses `ObjectDetectorOptions` with the default Coco dataset model (line 14-19). This detects generic objects ("book", "potted plant", "laptop") but cannot distinguish book spines from other rectangular objects. The overlay painter hardcodes the label "Book" (line 46) regardless of what was detected.

4. **Latin-Only Text Recognition** -- `TextRecognizer` is hardcoded to `TextRecognitionScript.latin` (line 9). International libraries with Japanese, Chinese, Korean, Devanagari, or Arabic text on spines will produce garbage OCR results. ML Kit supports 7 script variants. Language ID API can auto-detect the script before routing to the correct recognizer.

5. **Duplicated InputImage Conversion** -- `_inputImageFromCameraImage` (line 115-152 of `local_processor_service.dart`) is a private method that will need to be duplicated for the new `BarcodeService`. This should be extracted to a shared utility first.

6. **Missing ISBN Lookup Query** -- The database has no `getBookByIsbn()` method despite `isbn` being the primary key on the `Books` table. This is needed for barcode-to-library deduplication.

---

## Work Objectives

### Core Objective
Upgrade Wingtip's on-device ML pipeline to leverage native ML Kit capabilities, eliminating manual image processing duplication and adding barcode scanning, improved object detection, and multi-script text recognition.

### Deliverables
1. Shared InputImage conversion utility extracted from LocalProcessorService
2. Database `getBookByIsbn()` query method
3. ISBN barcode scanner integrated into the camera stream and capture flow
4. Document Scanner API evaluation and selective integration for image preprocessing
5. Upgraded object detection (custom model or subject segmentation assessment)
6. Multi-script text recognition with language auto-detection
7. Updated tests for all new ML Kit integrations
8. Performance metrics comparison (before/after)

### Definition of Done
- All 4 phases (plus Phase 0 prerequisites) implemented and verified
- Existing test suite passes with no regressions
- New tests cover barcode scanning, document scanner, and multi-script OCR
- `flutter analyze` reports zero new warnings
- iOS build succeeds and runs on simulator
- Performance metrics: barcode scan < 100ms, document preprocessing < 300ms
- ImageProcessor manual pipeline either removed or relegated to fallback-only

---

## Guardrails

### Must Have
- Backward compatibility: existing scan flow must work if new ML features are unavailable
- Graceful degradation: if barcode scanning fails, fall back to existing OCR+backend pipeline
- iOS-first optimization: all ML Kit features must be tested on iOS first
- No new permissions required (camera permission already granted)
- All ML Kit resources properly disposed (close() called in dispose methods)
- Performance within targets (< 500ms total local processing)

### Must NOT Have
- No removal of the backend Talaria integration (barcode scanning supplements, not replaces)
- No breaking changes to the database schema (ISBN is already the primary key)
- No custom TensorFlow Lite models in Phase 1 (evaluate in Phase 3 only)
- No changes to the SSE streaming or job queue architecture
- No UI redesign of the camera screen (only add barcode overlay elements)
- No Android-specific optimizations (iOS-first per CLAUDE.md)

---

## Task Flow and Dependencies

```
Phase 0: Prerequisites (Foundation)
  |
  ├── Task 0.1: Extract InputImage conversion utility  [BLOCKS: 1.2, 4.3]
  └── Task 0.2: Add getBookByIsbn() database method    [BLOCKS: 1.5]
  |
Phase 1: Barcode Scanning (Highest ROI)
  |
  ├── Task 1.1: Add google_mlkit_barcode_scanning dependency
  ├── Task 1.2: Create BarcodeService with EAN-13/ISBN detection  [DEPENDS: 0.1, 1.1]
  ├── Task 1.3: Integrate barcode detection into camera stream    [DEPENDS: 1.2]
  ├── Task 1.4: Add barcode overlay painter                       [DEPENDS: 1.2]
  ├── Task 1.5: Auto-lookup ISBN on barcode detection              [DEPENDS: 0.2, 1.3]
  └── Task 1.6: Tests for barcode service                         [DEPENDS: 1.2]
  |
Phase 2: Document Scanner API (Replace ImageProcessor)
  |
  ├── Task 2.1: Evaluate google_mlkit_document_scanner availability
  ├── Task 2.2: Create DocumentPreprocessor service               [DEPENDS: 2.1]
  ├── Task 2.3: Integrate into upload pipeline (replace enhanceForUpload) [DEPENDS: 2.2]
  ├── Task 2.4: Retain ImageProcessor as fallback                 [DEPENDS: 2.3]
  └── Task 2.5: Performance comparison tests                      [DEPENDS: 2.2]
  |
Phase 3: Object Detection Upgrade (Assessment)
  |
  ├── Task 3.1: Evaluate Subject Segmentation API availability
  ├── Task 3.2: Assess custom object detection model feasibility
  ├── Task 3.3: Improve overlay painter with real labels
  └── Task 3.4: Document recommendation                           [DEPENDS: 3.1, 3.2, 3.3]
  |
Phase 4: Multi-Script OCR (International Support)
  |
  ├── Task 4.1: Add google_mlkit_language_id dependency (if available)
  ├── Task 4.2: Create LanguageAwareTextRecognizer                [DEPENDS: 4.1]
  ├── Task 4.3: Update LocalProcessorService to use language-aware recognizer [DEPENDS: 0.1, 4.2]
  ├── Task 4.4: Add script selection UI (optional)                [DEPENDS: 4.3]
  └── Task 4.5: Tests for multi-script recognition                [DEPENDS: 4.2]
```

---

## Detailed TODOs

### Phase 0: Prerequisites (Foundation)

**Rationale:** Two shared infrastructure pieces must exist before Phase 1 can begin cleanly. Extracting the InputImage converter avoids code duplication across services. Adding the ISBN lookup query is a trivial but critical database gap.

#### Task 0.1: Extract InputImage Conversion Utility

**Source File:** `/Users/juju/dev_repos/wingtip/lib/features/scancapture/local_processor_service.dart` (lines 115-152)
**New File:** `lib/core/ml_kit_image_converter.dart`

**Implementation Details:**
- Extract the private method `_inputImageFromCameraImage` from `LocalProcessorService` (lines 115-152)
- Create it as a **top-level function** (stateless, no class needed) named `inputImageFromCameraImage`
- Function signature:
  ```dart
  InputImage? inputImageFromCameraImage(
    CameraImage image,
    int sensorOrientation,
    DeviceOrientation deviceOrientation,
  )
  ```
- Keep all existing logic intact (rotation detection, format validation, platform checks, planes handling)
- Import dependencies: `dart:io`, `package:camera/camera.dart`, `package:flutter/services.dart`, `package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart` (for `InputImage`, `InputImageMetadata`, etc.)
  - Note: `InputImage` and related types are re-exported by all `google_mlkit_*` packages. Use the common import from `google_mlkit_commons` if available, otherwise import from `google_mlkit_text_recognition` since it's already a dependency.

**Update Source File:**
- In `local_processor_service.dart`: Replace the private `_inputImageFromCameraImage` method (lines 115-152) with an import of the new utility
- Update the call at line 80 from `_inputImageFromCameraImage(...)` to `inputImageFromCameraImage(...)`
- Remove the now-unused `import 'package:flutter/services.dart'` if no other usage remains (check: `DeviceOrientation` is used by the converter, not by the service itself)

**Acceptance Criteria:**
- `inputImageFromCameraImage` is a top-level function in `lib/core/ml_kit_image_converter.dart`
- `LocalProcessorService.processCameraImage()` uses the extracted function and behaves identically
- No regression: camera stream object detection overlay still works
- `flutter analyze` passes with zero new warnings
- The new file has no class wrapper (pure function)

#### Task 0.2: Add `getBookByIsbn()` Database Method

**File:** `/Users/juju/dev_repos/wingtip/lib/data/database.dart`

**Implementation Details:**
- Add new method to `AppDatabase` class (after the `deleteBooks` method at line 618):
  ```dart
  /// Get a single book by its ISBN, or null if not found.
  Future<Book?> getBookByIsbn(String isbn) {
    return (select(books)..where((t) => t.isbn.equals(isbn))).getSingleOrNull();
  }
  ```
- This follows the exact same Drift query pattern used by `getFailedScan()` at line 644:
  ```dart
  Future<FailedScan?> getFailedScan(String jobId) async {
    final query = select(failedScans)..where((t) => t.jobId.equals(jobId));
    return query.getSingleOrNull();
  }
  ```
- Uses the existing `isbn` primary key, so this query is O(1) via the index.

**Acceptance Criteria:**
- `getBookByIsbn('978-0-13-235088-4')` returns the Book if it exists, null otherwise
- Method follows existing Drift query patterns in the same file
- No schema changes required (isbn is already the primary key)
- `flutter analyze` passes

**Test Addition:**
- Add test to existing database test file (or create `test/data/database_isbn_lookup_test.dart`):
  - Test: returns null for non-existent ISBN
  - Test: returns Book for existing ISBN
  - Test: handles empty string ISBN gracefully

---

### Phase 1: Barcode Scanning Integration (Highest ROI)

**Rationale:** Books universally have EAN-13 barcodes containing the ISBN. ML Kit's barcode scanner can detect these in real-time from the camera stream. This provides instant, high-confidence book identification without waiting for backend OCR processing.

#### Task 1.1: Add Barcode Scanning Dependency

**File:** `/Users/juju/dev_repos/wingtip/pubspec.yaml`
**Change:** Add `google_mlkit_barcode_scanning: ^0.14.0` after line 105

**Acceptance Criteria:**
- `flutter pub get` succeeds
- `pod install` succeeds (iOS)
- No version conflicts with existing ML Kit packages

**Notes:**
- Version must be compatible with existing `google_mlkit_text_recognition: ^0.15.0` and `google_mlkit_object_detection: ^0.15.0`
- All google_mlkit packages share the same GoogleMLKit iOS pod, so versions should align
- Check pub.dev for latest compatible version

#### Task 1.2: Create BarcodeService

**Depends on:** Task 0.1 (InputImage converter), Task 1.1 (dependency added)

**New File:** `lib/features/scancapture/barcode_service.dart`

**Implementation Details:**
- Create `BarcodeService` class wrapping `BarcodeScanner` from ML Kit
- Configure for EAN-13 format only (ISBN barcodes): `BarcodeFormat.ean13`
- Also support EAN-8 as fallback: `BarcodeFormat.ean8`
- Expose methods:
  - `Future<List<IsbnResult>> scanFromFile(File imageFile)` -- for captured images, creates `InputImage.fromFile(imageFile)`
  - `Future<List<IsbnResult>> scanFromCameraImage(CameraImage image, int sensorOrientation, DeviceOrientation deviceOrientation)` -- for live stream, uses the shared `inputImageFromCameraImage()` from `lib/core/ml_kit_image_converter.dart` (Task 0.1)
- Create `IsbnResult` data class with fields: `isbn` (String), `boundingBox` (Rect), `rawValue` (String), `format` (BarcodeFormat)
  - Note: ML Kit's BarcodeScanner does not return a numeric confidence score. Detection is binary (found or not found). The EAN-13 checksum provides built-in validation. Remove `confidence` from the data class.
- Validate ISBN-13 checksum before returning results:
  ```dart
  static bool isValidIsbn13(String isbn) {
    if (isbn.length != 13) return false;
    int sum = 0;
    for (int i = 0; i < 12; i++) {
      final digit = int.tryParse(isbn[i]);
      if (digit == null) return false;
      sum += (i.isEven) ? digit : digit * 3;
    }
    final checkDigit = (10 - (sum % 10)) % 10;
    return checkDigit == int.tryParse(isbn[12]);
  }
  ```
- Proper `dispose()` method calling `_barcodeScanner.close()`

**Acceptance Criteria:**
- BarcodeService correctly detects EAN-13 barcodes from file images
- BarcodeService correctly detects EAN-13 barcodes from camera stream using shared converter
- ISBN checksum validation rejects invalid barcodes
- Scanner configured for only book-relevant barcode formats (not QR, etc.)
- Proper resource cleanup on dispose
- No code duplication of InputImage conversion logic

**Create Provider File:** `lib/features/scancapture/barcode_provider.dart`
- Riverpod provider following same pattern as `local_processor_provider.dart` (lines 1-8):
  ```dart
  final barcodeServiceProvider = Provider<BarcodeService>((ref) {
    final service = BarcodeService();
    ref.onDispose(() => service.dispose());
    return service;
  });
  ```

#### Task 1.3: Integrate Barcode Detection into Camera Stream

**Depends on:** Task 1.2 (BarcodeService exists)

**File:** `/Users/juju/dev_repos/wingtip/lib/features/camera/camera_screen.dart`

**Changes:**
- Import barcode provider (after line 14):
  ```dart
  import 'package:wingtip/features/scancapture/barcode_provider.dart';
  import 'package:wingtip/features/scancapture/barcode_service.dart';
  ```
- Add state variables (after line 58, `_detectedObjects`):
  ```dart
  List<IsbnResult> _detectedBarcodes = [];
  final Set<String> _recentlyLookedUpIsbns = {};  // For debounce
  ```
- In `_processStreamFrame()` (line 456-491): Run barcode detection IN PARALLEL with object detection
  - Use `Future.wait()` to run both `localProcessorService.processCameraImage()` and `barcodeService.scanFromCameraImage()` concurrently:
    ```dart
    final results = await Future.wait([
      ref.read(localProcessorServiceProvider).processCameraImage(image, sensorOrientation, deviceOrientation),
      ref.read(barcodeServiceProvider).scanFromCameraImage(image, sensorOrientation, deviceOrientation),
    ]);
    final objectResults = results[0] as Map<String, dynamic>;
    final barcodeResults = results[1] as List<IsbnResult>;
    ```
  - Update `_detectedObjects` from objectResults (existing logic, line 479-484)
  - Update `_detectedBarcodes` from barcodeResults
- Add barcode overlay rendering in the **inner Stack** inside `_buildBody()` (line 626-647), after the object detection overlay (line 630-644):
  ```dart
  // Barcode Detection Overlay (after Object Detection Overlay)
  if (_detectedBarcodes.isNotEmpty)
    Positioned.fill(
      child: CustomPaint(
        painter: BarcodeOverlayPainter(
          barcodes: _detectedBarcodes,
          absoluteImageSize: Size(
            cameraService.controller!.value.previewSize!.height,
            cameraService.controller!.value.previewSize!.width,
          ),
          rotation: InputImageRotation.rotation90deg,
        ),
      ),
    ),
  ```
  - Rationale for `_buildBody()` inner Stack: The barcode overlay must be co-located with the camera preview and scaled to its coordinate system, just like the existing object detection overlay. Placing it in the outer `build()` Stack would require different coordinate math.
- On barcode detection: trigger haptic feedback (`HapticFeedback.selectionClick()`) and show ISBN in overlay

**Performance Constraint:**
- Barcode scanning must not increase frame processing time beyond 150ms total (currently ~100ms for object detection alone)
- If both detectors together exceed budget, implement frame alternation:
  ```dart
  bool _useBarcodeScannerThisFrame = true;  // Toggle each frame
  ```
  - Even frames: run object detection + barcode scanning
  - Odd frames: run object detection only
  - This ensures object detection always runs (required for overlay UX) while barcode scanning runs at 5 FPS (still adequate for barcode detection)

**Acceptance Criteria:**
- Camera stream processes barcodes in real-time alongside object detection
- Detected barcodes render as overlay on camera preview in `_buildBody()` inner Stack
- Frame rate stays at or above 10 FPS for ML processing
- No UI jank during barcode detection
- Frame alternation fallback implemented if performance budget exceeded

#### Task 1.4: Create Barcode Overlay Painter

**Depends on:** Task 1.2 (IsbnResult data class exists)

**New File:** `lib/features/camera/barcode_overlay_painter.dart`

**Implementation Details:**
- Similar structure to `ObjectOverlayPainter` (`lib/features/camera/object_overlay_painter.dart`)
- Use **Cyan (#00BCD4)** for barcode overlays to visually distinguish from object detection boxes (which use International Orange #FF4500):
  - Rationale: Cyan provides high contrast against both dark backgrounds and the orange object boxes. It's also associated with "information" in the Swiss Utility design language.
  - The original plan specified International Orange (#FF4500) with dashed borders, but using the same color as object detection creates visual confusion even with different line styles.
- Draw bounding box around detected barcode with **dashed border** in Cyan (#00BCD4)
- Display ISBN number below bounding box in JetBrains Mono font (per `AppTheme.monoStyle()`)
- Show green checkmark (Unicode or icon) next to ISBN when checksum is valid
- Reuse the `_scaleRect` approach from `ObjectOverlayPainter` (lines 82-111) for coordinate transformation

**Coordinate Scaling:**
- Accept same parameters as `ObjectOverlayPainter`: `absoluteImageSize`, `rotation`
- Use identical `_scaleRect` logic for consistency

**Acceptance Criteria:**
- Barcode bounding box renders correctly scaled on camera preview
- ISBN text displayed in JetBrains Mono (monospace) font
- Visual distinction from object detection boxes: Cyan dashed vs Orange solid borders
- Follows Swiss Utility design language (1px borders, high contrast, OLED black compatible)
- Green checkmark shown for valid ISBN-13 checksums

#### Task 1.5: Auto-Lookup ISBN on Barcode Detection

**Depends on:** Task 0.2 (getBookByIsbn exists), Task 1.3 (barcode detection in stream)

**File:** `/Users/juju/dev_repos/wingtip/lib/features/camera/camera_screen.dart`

**Changes:**
- When a valid ISBN barcode is detected in the stream:
  1. Check debounce: skip if ISBN was looked up within last 500ms (use `_recentlyLookedUpIsbns` set + timestamp map)
  2. Check local database: `database.getBookByIsbn(isbn)` (Task 0.2)
  3. If book exists locally: show "Already in library" toast with book title via existing `ErrorSnackBar.show()` pattern but with a success-style variant
  4. If book NOT in library: auto-trigger upload to Talaria backend with ISBN hint
- Debounce implementation:
  ```dart
  final Map<String, DateTime> _isbnLookupTimes = {};

  bool _shouldLookupIsbn(String isbn) {
    final lastLookup = _isbnLookupTimes[isbn];
    if (lastLookup != null && DateTime.now().difference(lastLookup).inMilliseconds < 500) {
      return false;
    }
    _isbnLookupTimes[isbn] = DateTime.now();
    return true;
  }
  ```

**File:** `/Users/juju/dev_repos/wingtip/lib/core/talaria_client.dart`

**Changes to `uploadImage()` method (lines 36-57):**
- Add optional `isbnHint` parameter:
  ```dart
  Future<ScanJobResponse> uploadImage(String imagePath, {String? isbnHint}) async {
    final formFields = <String, dynamic>{
      'image': await MultipartFile.fromFile(
        imagePath,
        filename: imagePath.split('/').last,
      ),
      'device_id': _deviceId,
    };

    // Add ISBN hint as multipart form field if available
    if (isbnHint != null) {
      formFields['isbn_hint'] = isbnHint;
    }

    final formData = FormData.fromMap(formFields);
    // ... rest unchanged
  }
  ```
- **Transport mechanism:** ISBN is passed as an additional **multipart form field** named `isbn_hint` in the existing `FormData.fromMap` payload. This is the least-invasive change since the upload already uses multipart form encoding (line 37-43).
- **Backend dependency:** The Talaria backend must recognize the `isbn_hint` field. If the backend does not support this field, it will simply ignore it (multipart forms allow extra fields). This is a **soft dependency** -- the feature degrades gracefully if the backend doesn't use the hint.

**File:** `/Users/juju/dev_repos/wingtip/lib/features/talaria/job_state_notifier.dart`

**Changes:**
- Update `uploadImage()` method signature (around line 280) to accept optional `isbn`:
  ```dart
  Future<void> uploadImage(String imagePath, {int? reviewQueueId, String? isbnHint}) async {
  ```
- Pass `isbnHint` through to `client.uploadImage(uploadPath, isbnHint: isbnHint)` at line 327
- Log barcode-sourced uploads distinctly for analytics:
  ```dart
  if (isbnHint != null) {
    debugPrint('[JobStateNotifier] Upload includes ISBN hint: $isbnHint');
    CrashReportingService.logEvent('scan_started_with_isbn', parameters: {'isbn': isbnHint});
  }
  ```

**File:** `/Users/juju/dev_repos/wingtip/lib/features/camera/camera_screen.dart`

**Changes to `_onShutterTap()` method (line 338-436):**
- Update the `jobNotifier.uploadImage()` call at line 421 to pass ISBN if a barcode was detected:
  ```dart
  final detectedIsbn = _detectedBarcodes.isNotEmpty ? _detectedBarcodes.first.isbn : null;
  jobNotifier.uploadImage(imagePath, reviewQueueId: reviewQueueId, isbnHint: detectedIsbn);
  ```

**Acceptance Criteria:**
- Detected ISBNs are checked against local database via `getBookByIsbn()` before upload
- Duplicate ISBN detection shows user-friendly "Already in library" message
- New ISBNs trigger upload with `isbn_hint` multipart form field for faster backend processing
- 500ms debounce prevents rapid-fire lookups for the same barcode
- ISBN hint is a soft dependency: upload works with or without backend support for the field

#### Task 1.6: Tests for Barcode Service

**Depends on:** Task 1.2 (BarcodeService exists)

**New File:** `test/features/scancapture/barcode_service_test.dart`

**Test Fixture Strategy:**

ML Kit's `BarcodeScanner` requires native platform code and cannot be tested directly in Flutter unit tests (which run on the host machine, not a device). The testing strategy has three layers:

1. **ISBN Checksum Validation (Pure Dart -- Unit Tests):**
   - The static `BarcodeService.isValidIsbn13()` method is pure Dart math and can be tested directly without mocking:
     ```dart
     test('validates correct ISBN-13', () {
       expect(BarcodeService.isValidIsbn13('9780132350884'), isTrue);  // Clean Code
       expect(BarcodeService.isValidIsbn13('9780201633610'), isTrue);  // Design Patterns
       expect(BarcodeService.isValidIsbn13('9780596007126'), isTrue);  // Head First
     });

     test('rejects invalid ISBN-13 checksum', () {
       expect(BarcodeService.isValidIsbn13('9780132350885'), isFalse);  // Wrong check digit
       expect(BarcodeService.isValidIsbn13('978013235088'), isFalse);   // Too short
       expect(BarcodeService.isValidIsbn13('97801323508841'), isFalse); // Too long
       expect(BarcodeService.isValidIsbn13('abcdefghijklm'), isFalse); // Non-numeric
     });
     ```

2. **BarcodeService Logic (Mocked Scanner -- Unit Tests):**
   - Create a `MockBarcodeScanner` that implements the same interface or use constructor injection:
     ```dart
     // In barcode_service.dart, accept scanner via constructor for testability:
     class BarcodeService {
       final BarcodeScanner _scanner;

       BarcodeService({BarcodeScanner? scanner})
         : _scanner = scanner ?? BarcodeScanner(formats: [BarcodeFormat.ean13, BarcodeFormat.ean8]);
     ```
   - In tests, create a mock that returns predefined `Barcode` results
   - Test cases:
     - Returns empty list when scanner finds no barcodes
     - Filters out non-EAN barcodes (if scanner hypothetically returns QR codes)
     - Returns `IsbnResult` with correct fields from scanner output
     - Calls `close()` on dispose

3. **End-to-End Barcode Detection (Integration Tests):**
   - Place test barcode images in `test/fixtures/barcodes/`:
     - `isbn_clean_code.png` -- Generated programmatically using the `barcode_image` Dart package or manually photographed
     - `no_barcode.png` -- Plain image without any barcode
   - **Generation approach:** Use the `barcode_widget` package in a test setup script to generate EAN-13 barcode images from known ISBNs, save to `test/fixtures/barcodes/`
   - These integration tests would run on-device only (tagged with `@Tags(['integration'])`)

**Test Cases (All Layers):**

| Layer | Test | Type |
|-------|------|------|
| Unit | Validates correct ISBN-13 checksums (5 known ISBNs) | Pure Dart |
| Unit | Rejects invalid ISBN-13 checksums (5 invalid cases) | Pure Dart |
| Unit | Rejects ISBN-10 format (not EAN-13) | Pure Dart |
| Unit | Handles empty string ISBN | Pure Dart |
| Unit | BarcodeService returns empty list when scanner finds nothing | Mocked |
| Unit | BarcodeService filters results to only EAN-13/EAN-8 | Mocked |
| Unit | BarcodeService.dispose() calls scanner.close() | Mocked |
| Integration | Detects EAN-13 from test fixture image | On-device |
| Integration | Returns empty for image without barcode | On-device |

**Acceptance Criteria:**
- All unit tests pass in `flutter test` (no device needed)
- ISBN-13 checksum validation covers at least 5 valid and 5 invalid cases
- BarcodeService is testable via constructor-injected mock scanner
- Integration test fixtures documented with generation instructions
- Tests structured for CI (unit tests run always, integration tests tagged separately)

---

### Phase 2: Document Scanner API (Replace ImageProcessor)

**Rationale:** The current `ImageProcessor` class (434 lines) manually implements contrast enhancement, brightness histogram analysis, Gaussian blur, auto-rotation, and resize. ML Kit's Document Scanner API does perspective correction, shadow removal, and auto-crop on-device with GPU acceleration, which should be faster and more accurate.

**IMPORTANT NOTE:** `google_mlkit_document_scanner` may only be available on Android (as of the latest pub.dev info). If not available on iOS, this phase becomes an **evaluation-only** task with a recommendation document. The manual ImageProcessor would be retained.

#### Task 2.1: Evaluate Document Scanner API Availability

**Research Task -- No Code Changes**

**Investigation:**
- Check `google_mlkit_document_scanner` package on pub.dev for iOS support
- Check Google ML Kit documentation for iOS Document Scanner API availability
- If NOT available on iOS: Document findings, skip Tasks 2.2-2.3, retain ImageProcessor
- If available: Proceed with integration

**Alternative Approaches (if Document Scanner unavailable on iOS):**
- Use Apple's VisionKit `VNDocumentCameraViewController` via platform channel
- Use Apple's Vision framework `VNDetectDocumentSegmentationRequest` for perspective correction
- Retain manual ImageProcessor with targeted improvements only

**Acceptance Criteria:**
- Clear determination of Document Scanner availability on iOS
- If unavailable: documented alternative recommendation
- If available: green light for Tasks 2.2-2.5

#### Task 2.2: Create DocumentPreprocessor Service (Conditional)

**Depends on:** Task 2.1 (availability confirmed)

**New File:** `lib/features/scancapture/document_preprocessor.dart`

**Implementation Details:**
- Wrap ML Kit Document Scanner or alternative (per Task 2.1 findings)
- Return type must be `ImageEnhancementResult` (not `ImageProcessingResult`) to match the existing `enhanceForUpload()` return type used in `job_state_notifier.dart` at line 307:
  ```dart
  static Future<ImageEnhancementResult> preprocess(String sourcePath) async {
    // ... ML Kit Document Scanner processing ...
    return ImageEnhancementResult(
      outputPath: outputPath,
      processingTimeMs: processingTimeMs,
      originalSize: originalSize,
      processedSize: processedSize,
      wasRotated: wasRotated,        // Detect if document was de-skewed
      brightnessAdjustment: 1.0,     // Not applicable for ML Kit, use neutral value
    );
  }
  ```
- Focus on: perspective correction, shadow removal, auto-crop
- Still use isolate-based resize/compress for final output (keep from ImageProcessor)
- Measure and log processing time for comparison

**Acceptance Criteria:**
- Preprocessor returns `ImageEnhancementResult` compatible with existing upload pipeline
- Preprocessor produces visually improved images compared to ImageProcessor
- Processing time <= 300ms (ML Kit target) vs current ~200-400ms
- Output compatible with existing upload pipeline at `job_state_notifier.dart` line 307

#### Task 2.3: Integrate into Upload Pipeline (Conditional)

**Depends on:** Task 2.2 (DocumentPreprocessor exists)

**File:** `/Users/juju/dev_repos/wingtip/lib/features/talaria/job_state_notifier.dart`

**Changes at line 307:**
- Replace `ImageProcessor.enhanceForUpload(imagePath)` with `DocumentPreprocessor.preprocess(imagePath)`
- Keep ImageProcessor as fallback if DocumentPreprocessor fails:
  ```dart
  ImageEnhancementResult enhanceResult;
  try {
    enhanceResult = await DocumentPreprocessor.preprocess(imagePath);
    debugPrint('[JobStateNotifier] ML Kit preprocessing completed in ${enhanceResult.processingTimeMs}ms');
  } catch (e) {
    debugPrint('[JobStateNotifier] ML Kit preprocessing failed, falling back to manual: $e');
    enhanceResult = await ImageProcessor.enhanceForUpload(imagePath);
  }
  uploadPath = enhanceResult.outputPath;
  ```

**Acceptance Criteria:**
- Upload pipeline uses Document Scanner API when available
- Falls back to ImageProcessor on failure
- No regression in upload success rate
- Performance metrics logged for comparison

#### Task 2.4: Retain ImageProcessor as Fallback

**File:** `/Users/juju/dev_repos/wingtip/lib/features/camera/image_processor.dart`

**Changes:**
- Add `@Deprecated('Use DocumentPreprocessor instead. Retained as fallback.')` annotation on `enhanceForUpload` if Document Scanner is available
- Keep `processImage()` for basic resize/compress (still needed regardless)
- Keep `cleanupOldTempFiles()` (used by memory pressure handler at `lib/core/memory_pressure_handler.dart` line 72)

**Acceptance Criteria:**
- ImageProcessor still functional as fallback
- No breaking changes to existing callers
- Deprecation annotation guides future developers

#### Task 2.5: Performance Comparison Tests

**New File:** `test/features/scancapture/document_preprocessor_test.dart` (if applicable)

**Test Cases:**
- Document preprocessor produces valid output
- Processing time comparison with ImageProcessor
- Output image quality comparison (visual inspection checklist)
- Fallback behavior when Document Scanner unavailable

**Acceptance Criteria:**
- Performance data captured and documented
- Clear winner identified between manual and ML Kit approaches

---

### Phase 3: Object Detection Upgrade (Assessment Phase)

**Rationale:** The current object detection uses ML Kit's default Coco model, which classifies objects into generic categories. For a book scanning app, we need either a book-specific detection model or a better approach to isolating book spines from the background.

#### Task 3.1: Evaluate Subject Segmentation API

**Research Task -- No Code Changes**

**Investigation:**
- Check `google_mlkit_subject_segmentation` availability on iOS
- Subject Segmentation separates foreground subjects from background
- Could be useful for isolating bookshelves from room background
- Requires iOS 15+ (Wingtip targets iOS 26 per Podfile line 2, so compatible)

**Acceptance Criteria:**
- Clear determination of Subject Segmentation availability on iOS
- Assessment of whether it adds value for book spine detection specifically

#### Task 3.2: Assess Custom Model Feasibility

**Research Task -- No Code Changes**

**Investigation:**
- ML Kit supports custom TFLite models via `google_mlkit_object_detection` with `ObjectDetectorOptions.custom()`
- Evaluate: Is a custom book spine detection model worth training?
- Consider: AutoML Vision Edge for training book-specific detector
- Alternative: Use existing Coco model but filter for "book" label only
- Cost/benefit: Custom model training time vs. marginal accuracy improvement

**Acceptance Criteria:**
- Documented recommendation on custom model approach
- If recommended: training data requirements and timeline estimate
- If not recommended: rationale for staying with Coco model

#### Task 3.3: Improve Overlay Painter with Real Labels

**File:** `/Users/juju/dev_repos/wingtip/lib/features/camera/object_overlay_painter.dart`

**Changes at line 46:**
- Replace hardcoded `"Book"` label with actual ML Kit labels from detection results:
  ```dart
  // Before:
  final labelText = "Book";

  // After:
  final labels = object['labels'] as List<dynamic>;
  final labelText = labels.isNotEmpty
    ? '${(labels.first as Map)['text']} (${((labels.first as Map)['confidence'] as double * 100).toStringAsFixed(0)}%)'
    : 'Unknown';
  ```
- Filter overlay to only show objects with "Book" label or confidence > 0.5
- Add color coding: green (#4CAF50) for high confidence (>0.7), orange (#FF9800) for medium (0.5-0.7), red (#F44336) for low (<0.5)

**File:** `/Users/juju/dev_repos/wingtip/lib/features/scancapture/local_processor_service.dart`

**Changes:**
- Fix pre-existing bug: Change `DetectionMode.single` (line 15) to `DetectionMode.stream` for `processCameraImage()` usage. `DetectionMode.single` is for static images; `DetectionMode.stream` enables tracking across frames.
  - Note: This requires creating two `ObjectDetector` instances or switching mode. Recommended: Create separate detectors for `processImage()` (single mode) and `processCameraImage()` (stream mode).
- Filter detected objects to only return those with "Book" label (line 43-57)
- Log detection statistics for analytics

**Acceptance Criteria:**
- Overlay displays actual ML Kit labels instead of hardcoded "Book"
- Confidence scores visible in overlay
- Only book-relevant objects highlighted
- Filtering reduces false positive overlay boxes
- DetectionMode.stream used for camera stream processing

#### Task 3.4: Document Recommendation

**Depends on:** Tasks 3.1, 3.2, 3.3

**Output File:** `.omc/plans/mlkit-object-detection-recommendation.md`

**Content:**
- Summary of Phase 3 findings
- Recommendation for next steps (custom model, subject segmentation, or status quo)
- Effort estimate for each option
- Impact assessment on user experience

**Acceptance Criteria:**
- Clear, actionable recommendation document
- Decision captured for future reference

---

### Phase 4: Multi-Script OCR (International Support)

**Rationale:** The current `TextRecognizer` is hardcoded to `TextRecognitionScript.latin` (line 9 of `local_processor_service.dart`). International users with books in Japanese, Chinese, Korean, Devanagari, or Arabic text on spines will produce garbage OCR results. ML Kit supports 7 script variants. Language ID API can auto-detect the script before routing to the correct recognizer.

#### Task 4.1: Add Language Identification (if Available)

**Research + Dependency:**
- Check if `google_mlkit_language_id` or equivalent is available
- Alternative: Use ML Kit's `TextRecognitionScript` enum to try multiple scripts
- Note: Language ID may not be a separate ML Kit Flutter package; it may be embedded in text recognition

**If language ID package exists:**
- Add to `pubspec.yaml`
- Run `flutter pub get` and `pod install`

**If not available as separate package:**
- Implement multi-script detection by running multiple recognizers and scoring results

**Acceptance Criteria:**
- Clear determination of language ID availability
- Dependency added if available
- Alternative approach documented if not

#### Task 4.2: Create LanguageAwareTextRecognizer

**Depends on:** Task 4.1 (language ID assessment)

**New File:** `lib/features/scancapture/language_aware_text_recognizer.dart`

**Implementation Details:**
- Manages multiple `TextRecognizer` instances for different scripts:
  - `TextRecognitionScript.latin` (default, always loaded)
  - `TextRecognitionScript.chinese` (lazy-loaded)
  - `TextRecognitionScript.japanese` (lazy-loaded)
  - `TextRecognitionScript.korean` (lazy-loaded)
  - `TextRecognitionScript.devanagari` (lazy-loaded)
- **Strategy A (if Language ID available):** Detect language first, then use appropriate recognizer
- **Strategy B (if no Language ID):** Run Latin recognizer first; if confidence is low or text looks like non-Latin characters, try additional recognizers
- Expose method: `Future<RecognizedText> recognizeText(InputImage image, {TextRecognitionScript? preferredScript})`
- Lazy initialization: only create recognizers for scripts that are actually needed
- Memory management: close unused recognizers after 5 minutes of inactivity
- Proper `dispose()` method closing all active recognizers

**Acceptance Criteria:**
- Latin script recognition works identically to current behavior (no regression)
- At least one additional script (Chinese, Japanese, or Korean) correctly recognized
- Lazy loading prevents unnecessary memory usage
- Memory cleanup for idle recognizers

#### Task 4.3: Update LocalProcessorService

**Depends on:** Task 0.1 (InputImage converter extracted), Task 4.2 (LanguageAwareTextRecognizer exists)

**File:** `/Users/juju/dev_repos/wingtip/lib/features/scancapture/local_processor_service.dart`

**Changes:**
- Replace `_textRecognizer` (line 8-10) with `LanguageAwareTextRecognizer`
- Update `processImage()` (line 22-64) to use new recognizer
- Update `processCameraImage()` (line 75-113) to use new recognizer
  - This method already uses `inputImageFromCameraImage()` (extracted in Task 0.1)
- Update `dispose()` (line 154-157) to close new recognizer
- For camera stream: default to Latin (fastest) with optional multi-script mode
- For captured images: use full multi-script detection

**Acceptance Criteria:**
- LocalProcessorService uses LanguageAwareTextRecognizer
- Camera stream performance not degraded (Latin-only by default for stream)
- Captured image processing uses multi-script detection
- Dispose properly closes all recognizers

#### Task 4.4: Add Script Selection UI (Optional/Low Priority)

**File:** `/Users/juju/dev_repos/wingtip/lib/features/camera/camera_screen.dart`

**Changes:**
- Add small language/script indicator icon in camera UI (near night mode button area)
- Options: "Auto" (default), "Latin", "CJK", "Devanagari", "Arabic"
- Persist preference via SharedPreferences
- Connects to LanguageAwareTextRecognizer's `preferredScript` parameter

**Acceptance Criteria:**
- Script selector visible in camera UI
- Selection persisted across app restarts
- "Auto" mode uses language detection/multi-script approach
- Manual selection constrains to single script for performance

#### Task 4.5: Tests for Multi-Script Recognition

**New File:** `test/features/scancapture/language_aware_text_recognizer_test.dart`

**Test Cases:**
- Latin text recognition (regression test)
- Lazy loading: only requested recognizers are created
- Memory cleanup: idle recognizers are closed
- Preferred script parameter respected
- Dispose closes all active recognizers
- Graceful handling when non-Latin models not available

**Acceptance Criteria:**
- All test cases pass
- No regression in Latin text recognition
- Memory management verified

---

## Commit Strategy

### Phase 0 Commits (Prerequisites)
0. `refactor: extract InputImage conversion utility to lib/core/ml_kit_image_converter.dart` (new file + update local_processor_service)
1. `feat: add getBookByIsbn() database method with tests` (database.dart + test)

### Phase 1 Commits (Barcode Scanning)
2. `feat: add google_mlkit_barcode_scanning dependency` (pubspec.yaml only)
3. `feat: implement BarcodeService with EAN-13/ISBN detection and checksum validation` (service + provider + tests)
4. `feat: integrate barcode scanning into camera stream with cyan overlay` (camera_screen + barcode_overlay_painter)
5. `feat: add ISBN auto-lookup with multipart isbn_hint transport` (camera_screen + talaria_client + job_state_notifier)

### Phase 2 Commits (Document Scanner)
6. `docs: Document Scanner API availability assessment` (evaluation results)
7. `feat: implement DocumentPreprocessor returning ImageEnhancementResult` (conditional)
8. `refactor: replace ImageProcessor.enhanceForUpload with DocumentPreprocessor` (conditional)

### Phase 3 Commits (Object Detection)
9. `fix: use DetectionMode.stream for camera and display real ML Kit labels` (local_processor_service + overlay_painter)
10. `docs: object detection upgrade recommendation` (assessment document)

### Phase 4 Commits (Multi-Script OCR)
11. `feat: implement LanguageAwareTextRecognizer with multi-script support` (new service + tests)
12. `refactor: update LocalProcessorService to use LanguageAwareTextRecognizer` (integration)
13. `feat: add script selection UI in camera screen` (optional UI)

---

## Risk Identification and Mitigations

### Risk 1: ML Kit Package Version Conflicts
**Probability:** Medium
**Impact:** High (blocks all phases)
**Mitigation:** All `google_mlkit_*` packages share the same underlying GoogleMLKit iOS pod. Pin versions to the same major release (0.14.x or 0.15.x). Run `flutter pub get` and `pod install` after adding each new dependency to catch conflicts early.

### Risk 2: Document Scanner API Not Available on iOS
**Probability:** High (Google's Document Scanner is Android-only as of late 2024)
**Impact:** Medium (Phase 2 becomes evaluation-only)
**Mitigation:** Phase 2 is designed as conditional. If unavailable, retain ImageProcessor and document alternative approaches (Apple VisionKit, Vision framework). The manual ImageProcessor is functional -- this is an optimization, not a blocker.

### Risk 3: Camera Stream Performance Degradation
**Probability:** Medium (adding barcode scanning alongside object detection)
**Impact:** High (UI jank unacceptable for iOS-first app)
**Mitigation:**
- Run barcode and object detection in parallel via `Future.wait()`
- If total frame time exceeds 150ms, alternate detectors on successive frames (Task 1.3 specifies frame alternation fallback)
- Barcode scanner with `BarcodeFormat.ean13` only (not all formats) is highly optimized
- Monitor with existing `_minFrameInterval` throttling (100ms, line 61 of camera_screen.dart)

### Risk 4: Memory Pressure from Multiple ML Kit Models
**Probability:** Medium (especially with multi-script recognizers)
**Impact:** Medium (crashes on older devices)
**Mitigation:**
- Lazy-load recognizers (only create when needed)
- Auto-close idle recognizers after 5 minutes
- Hook into existing memory pressure handler (`lib/core/memory_pressure_handler.dart`)
- Monitor memory via existing performance metrics system
- On memory warning: close all non-Latin recognizers first

### Risk 5: Barcode Detection False Positives
**Probability:** Low (EAN-13 has built-in checksum)
**Impact:** Low (wrong ISBN lookup is harmless -- book won't match)
**Mitigation:**
- Validate ISBN-13 checksum before acting on detection (Task 1.2 includes checksum validation)
- Debounce at 500ms to require sustained detection (not single frame)
- No confidence threshold needed (ML Kit barcode detection is binary: found or not)

### Risk 6: iOS Build Size Increase
**Probability:** High (each ML Kit model adds ~5-15MB)
**Impact:** Low-Medium (App Store has 200MB OTA limit)
**Mitigation:**
- Only add barcode scanning model in Phase 1 (~5MB)
- Document Scanner may not apply (iOS unavailable)
- Multi-script OCR models are downloaded on-demand by ML Kit (not bundled)
- Monitor IPA size after each phase

### Risk 7: BarcodeScanner Untestable in Unit Tests
**Probability:** Certain (ML Kit requires native platform)
**Impact:** Medium (reduces test coverage confidence)
**Mitigation:**
- Constructor injection in BarcodeService for mock scanner (Task 1.6)
- Pure Dart ISBN checksum validation tested directly (no mock needed)
- Integration tests tagged separately for on-device execution
- Three-layer test strategy ensures maximum coverage per environment

---

## Verification Steps

### Per-Phase Verification

**Phase 0 Verification:**
1. `flutter analyze` reports zero new warnings
2. `flutter test` passes -- camera stream overlay still works with extracted converter
3. `getBookByIsbn()` returns null for non-existent ISBN
4. `getBookByIsbn()` returns Book for existing ISBN
5. `inputImageFromCameraImage()` is importable from `lib/core/ml_kit_image_converter.dart`

**Phase 1 Verification:**
1. `flutter pub get` succeeds with new barcode dependency
2. `flutter analyze` reports zero new warnings
3. `flutter test` passes all existing + new barcode tests
4. iOS build succeeds: `flutter build ios --debug`
5. Manual test: point camera at book barcode, verify ISBN detected and displayed in Cyan overlay
6. Manual test: verify detected ISBN checks local database via `getBookByIsbn()`
7. Performance: barcode scan completes in < 100ms per frame
8. Manual test: upload request includes `isbn_hint` multipart field (verify in debug logs)

**Phase 2 Verification:**
1. Document Scanner API availability confirmed/denied
2. If available: `flutter pub get` + `pod install` succeed
3. If available: `DocumentPreprocessor.preprocess()` returns `ImageEnhancementResult`
4. If available: processing time comparison logged (target < 300ms)
5. If available: visual quality comparison (perspective correction visible)
6. Fallback path tested: disable Document Scanner, verify ImageProcessor used

**Phase 3 Verification:**
1. Object overlay shows real ML Kit labels (not hardcoded "Book")
2. Confidence scores displayed correctly
3. `DetectionMode.stream` used for camera stream (verify in debugPrint logs)
4. Filtering reduces false positive overlay boxes
5. Recommendation document saved and reviewed

**Phase 4 Verification:**
1. Latin text recognition has zero regression (compare outputs)
2. At least one CJK script correctly recognized from test image
3. Memory: idle recognizers cleaned up (verify via debugPrint logs)
4. Camera stream performance not degraded with Latin-only default
5. `flutter test` passes all new multi-script tests

### Final Integration Verification
1. Full scan workflow: barcode scan -> ISBN lookup -> backend upload -> book saved
2. Full scan workflow: spine photo -> ML processing -> backend upload -> book saved
3. Memory usage under 200MB target during active scanning
4. No UI jank on camera screen (target: 60fps minimum, 120fps on ProMotion)
5. `flutter analyze` clean
6. All tests pass: `flutter test`

---

## Success Criteria

| Metric | Current | Target | Measurement |
|--------|---------|--------|-------------|
| Barcode detection | N/A | < 100ms per frame | Performance metrics |
| Image preprocessing | ~200-400ms (manual) | < 300ms (ML Kit) | Processing time logs |
| OCR script support | 1 (Latin) | 5+ scripts | Feature checklist |
| Object detection labels | Hardcoded "Book" | Real ML Kit labels | Visual verification |
| Camera stream FPS | ~10 FPS | >= 10 FPS (no regression) | Frame timing logs |
| iOS build success | Yes | Yes (no regression) | CI build |
| Test coverage | 20 tests | 40+ tests | `flutter test` count |
| App binary size | Baseline | < +20MB increase | IPA size comparison |
| Code duplication | InputImage converter duplicated | Single shared utility | File count |

---

## Metis Review Notes

**Architectural Gaps Identified:**
1. The `image` package dependency (`pubspec.yaml` line 74) can likely be removed if Document Scanner replaces ImageProcessor. However, it may still be needed for test fixtures. Mark as "evaluate for removal" after Phase 2.
2. The `ReviewQueue` table stores `mlResult` as JSON text. Barcode results should be stored in the same field to maintain consistency.
3. Camera stream processing (`_processStreamFrame`) runs on the main isolate for ML Kit calls. Adding barcode scanning means two ML Kit calls per frame. Task 1.3 addresses this with `Future.wait()` parallelism and frame alternation fallback.
4. The `ObjectDetectorOptions` at line 14-19 of `local_processor_service.dart` uses `DetectionMode.single` -- this should be `DetectionMode.stream` for camera stream processing (line 88-112). This is a pre-existing bug addressed in Task 3.3.

**iOS-First Optimization Opportunities:**
1. ML Kit on iOS uses Core ML backend for hardware acceleration -- no special configuration needed
2. Barcode scanning on iOS uses AVFoundation under the hood -- very fast on Apple Neural Engine
3. Consider using `camera` package's built-in barcode mode if available (reduces ML Kit overhead)
4. The iOS deployment target is 26.0 (Podfile line 2) -- all ML Kit features are available

**Integration Risk:**
- Adding `google_mlkit_barcode_scanning` may trigger a Podfile.lock update that changes ML Kit pod versions. Run `pod install` immediately after adding the dependency and verify no breaking changes.

**Critic Feedback Addressed (v2):**
1. **getBookByIsbn** -- Added as Task 0.2 with exact Drift query pattern matching existing `getFailedScan()` at line 644
2. **ISBN transport mechanism** -- Specified as multipart form field `isbn_hint` in `FormData.fromMap` at `talaria_client.dart` line 37. Soft backend dependency: field is ignored if backend doesn't support it.
3. **Test fixture strategy** -- Three-layer approach: pure Dart checksum tests, mocked scanner tests via constructor injection, and tagged integration tests with generated barcode fixture images.
4. **InputImage converter extraction** -- Added as Task 0.1 per Architect recommendation. Top-level function in `lib/core/ml_kit_image_converter.dart`.
5. **Overlay placement** -- Specified as `_buildBody()` inner Stack (after line 630) with rationale: co-located with camera preview for correct coordinate scaling.
6. **Return type mismatch** -- Task 2.2 now returns `ImageEnhancementResult` instead of `ImageProcessingResult`.
7. **Overlay color** -- Barcode overlay uses Cyan (#00BCD4) to distinguish from object detection orange (#FF4500).
