# Bookshelf Scanner Lessons - Wingtip Implementation Plan

**Created:** 2026-02-01
**Revised:** 2026-02-01 (v2 -- addresses Critic feedback)
**Source:** /Users/juju/dev_repos/BOOKSHELF_SCANNER_LESSONS.md
**Target:** Wingtip Flutter App (iOS-first)
**Estimated Total Effort:** 14-19 hours across 3 phases

---

## Context

### Original Request
Apply lessons learned from the bookshelf-scanner reference implementation to improve Wingtip's image processing, SSE handling, review queue UI, and progressive results UX.

### Interview Summary
Direct planning from lessons document analysis. Six key gaps identified for Wingtip from comparison with the bookshelf-scanner reference (YOLO11x + Moondream2 pipeline).

### Research Findings

**Current Wingtip State (verified from codebase):**
- **Existing ImageProcessor** at `lib/features/camera/image_processor.dart` -- already handles resize (1920px max) + JPEG compression (quality 85) via `compute()` isolate. Currently NOT used in the capture flow (`_onShutterTap()` passes raw `imagePath` directly to `uploadImage()`). This class is the correct place to add preprocessing.
- SSE client at `lib/core/sse_client.dart` -- functional, has retry logic, but no cleanup signaling on disconnect
- `TalariaClient` at `lib/core/talaria_client.dart` has `cleanupJob(jobId)` method (DELETE endpoint) -- called ONLY on successful completion via `_cleanupJob()`. The `_cleanupJob()` method also deletes the local temp file, which is wrong for cancellation scenarios.
- `talariaClientProvider` is a `FutureProvider<TalariaClient>` -- accessing it in `ref.onDispose()` requires handling async, making cleanup fire-and-forget.
- `LocalProcessorService._rectToMap()` returns **absolute pixel coordinates** from ML Kit (`Rect.left/top/width/height` in source image pixels), NOT normalized 0-1 coordinates. Bounding box scaling must map from source image pixel space to display canvas pixel space.
- Review queue exists (`lib/features/review/`) with database table (schema v7) but `BoundingBoxPainter.paint()` at `review_detail_screen.dart:192` is unimplemented (empty TODO)
- `ScanJob` model at `lib/features/talaria/job_state.dart` has `progressMessage` field -- can be extended
- `image` package version **4.7.2** confirmed in pubspec.lock. API verified:
  - `adjustColor(image, contrast: 1.5, brightness: 1.2)` -- correct, exists in 4.7.x
  - `gaussianBlur(image, radius: 1)` -- correct, `radius` is required named param
  - `copyRotate(image, angle: -90)` -- correct
  - `copyResize(image, width: N)` -- correct, already used in existing `ImageProcessor`

### Capture Flow Analysis (Critical for Integration Design)

Current flow in `camera_screen.dart:_onShutterTap()`:
```
1. HapticFeedback.lightImpact()
2. takePicture() -> raw XFile at imagePath
3. database.addToReviewQueue(imagePath: imagePath)    <-- review queue gets RAW image
4. localProcessorService.processImage(File(imagePath)) <-- ML detection on RAW image (background)
5. jobNotifier.uploadImage(imagePath, reviewQueueId)   <-- upload RAW image to Talaria
6. HapticFeedback.mediumImpact()
```

**Decision: Preprocessing happens INSIDE `uploadImage()` in `JobStateNotifier`**, not in `_onShutterTap()`. Rationale:
- Review queue should store the **raw** image (user sees original capture for review/editing)
- Local ML processing should use the **raw** image (ML Kit works on unmodified images)
- Only the Talaria upload benefits from preprocessing (server-side recognition accuracy)
- This isolates the preprocessing concern to a single location

---

## Work Objectives

### Core Objective
Improve scan recognition accuracy, reduce wasted backend resources, and complete the review queue feature by applying proven patterns from the bookshelf-scanner reference implementation.

### Deliverables
1. Image preprocessing pipeline (contrast, brightness, noise reduction, rotation detection) integrated into the existing `ImageProcessor` class, called inside `uploadImage()` before Talaria upload
2. SSE disconnection cleanup -- signal backend to stop processing when user navigates away or cancels (using `client.cleanupJob()` directly, NOT `_cleanupJob()` which also deletes files)
3. Complete review detail screen with working bounding box overlay (absolute pixel coordinate scaling) and Swiss Utility styling
4. Progressive results UI showing processing progress during multi-book scans
5. Tests for all new functionality

### Definition of Done
- All existing tests continue to pass (`flutter test`)
- New unit tests for image preprocessing pipeline
- SSE cleanup verified via debug logs (backend receives DELETE on cancel)
- Review detail screen renders bounding boxes correctly scaled to display
- No regressions in cold start time (< 1000ms target)
- `flutter analyze` clean

---

## Guardrails

### Must Have
- All image processing runs in isolate (never block UI thread)
- Preprocessing is optional/configurable (feature flag or setting)
- Backward compatibility with current Talaria API (no backend changes required for Phase 1)
- iOS-first quality (haptic feedback, smooth animations, ProMotion-compatible)
- Swiss Utility design language (OLED black, 1px borders, Inter/JetBrains Mono fonts)

### Must NOT Have
- Multi-provider architecture (explicitly deferred to future -- 8-12h effort, post-launch)
- Generic API result wrappers (low priority polish, not this sprint)
- Any changes to the Talaria backend or API contract
- On-device ML inference for book recognition (separate effort entirely)
- Changes to the database schema (all work uses existing schema v7)

---

## Task Flow and Dependencies

```
Phase 1: Critical (PARALLEL - no dependencies between tasks)
  |-- Task 1: Image Preprocessing Pipeline [3-4h]
  |-- Task 2: SSE Disconnect Cleanup [1-2h]
  |-- Task 3: Review Detail Screen Fix [2-3h]

Phase 2: High Value (depends on Phase 1 completion)
  |-- Task 4: Progressive Results UI [3-4h] (depends on Task 2 for SSE event model understanding)
  |-- Task 5: Rotation Detection UX [1-2h] (depends on Task 1 for preprocessing service)

Phase 3: Testing and Polish (depends on Phase 2)
  |-- Task 6: Integration Testing [2-3h]
```

---

## Phase 1: Critical Gaps (IMPLEMENT FIRST)

### Task 1: Image Preprocessing Pipeline
**Priority:** CRITICAL
**Estimated Effort:** 3-4 hours

**Files to Modify:**
- `lib/features/camera/image_processor.dart` (EXTEND existing class -- do NOT create a new service)
- `lib/features/talaria/job_state_notifier.dart` (call preprocessing inside `uploadImage()` before Talaria upload)

**Architectural Decision: Extend `ImageProcessor`, Do NOT Create New Class**

The existing `ImageProcessor` class at `lib/features/camera/image_processor.dart`:
- Already uses `compute()` for isolate-based processing
- Already uses the `image` package (`import 'package:image/image.dart' as img`)
- Already handles resize + JPEG encoding
- Already has `ImageProcessingParams` and `ImageProcessingResult` data classes
- Already has metrics recording via `imageProcessingMetricsNotifierProvider`
- Is currently NOT called in the capture flow (raw image goes directly to upload)

We will **extend** this class with a new method `processAndEnhanceImage()` that adds the preprocessing steps (contrast, brightness, noise, rotation) ON TOP of the existing resize + compress pipeline. The existing `processImage()` method remains unchanged for backward compatibility.

**Implementation Details:**

1. Add preprocessing to `ImageProcessor` (`lib/features/camera/image_processor.dart`):

   a. Add new `ImageEnhancementParams` class:
   ```dart
   class ImageEnhancementParams {
     final String sourcePath;
     final String outputDir;
     final int maxDimension;      // 2560 for enhanced (vs 1920 for basic)
     final int quality;           // 90 for enhanced (vs 85 for basic)
     final double contrastMultiplier;  // 1.5 default
     final int blurRadius;        // 1 for lightweight noise reduction
     final bool autoRotate;       // true to detect vertical bookshelves

     ImageEnhancementParams({...});
   }
   ```

   b. Add new `ImageEnhancementResult` extending `ImageProcessingResult`:
   ```dart
   class ImageEnhancementResult extends ImageProcessingResult {
     final bool wasRotated;
     final double brightnessAdjustment;

     ImageEnhancementResult({
       required super.outputPath,
       required super.processingTimeMs,
       required super.originalSize,
       required super.processedSize,
       required this.wasRotated,
       required this.brightnessAdjustment,
     });
   }
   ```

   c. Add static method `enhanceForUpload()`:
   ```dart
   static Future<ImageEnhancementResult> enhanceForUpload(
     String sourcePath, {
     WidgetRef? ref,
   }) async {
     final startTime = DateTime.now();
     final tempDir = await getTemporaryDirectory();
     final params = ImageEnhancementParams(
       sourcePath: sourcePath,
       outputDir: tempDir.path,
       maxDimension: 2560,
       quality: 90,
       contrastMultiplier: 1.5,
       blurRadius: 1,
       autoRotate: true,
     );

     final result = await compute(_enhanceImageInIsolate, params);
     // ... metrics and logging (same pattern as existing processImage())
   }
   ```

   d. Add isolate function `_enhanceImageInIsolate()`:
   ```dart
   static Future<Map<String, dynamic>> _enhanceImageInIsolate(
     ImageEnhancementParams params,
   ) async {
     final imageBytes = await File(params.sourcePath).readAsBytes();
     var image = img.decodeImage(imageBytes);
     if (image == null) throw Exception('Failed to decode image');

     bool wasRotated = false;
     double brightnessAdj = 1.0;

     // Step 1: Rotation detection (BEFORE resize for correct aspect ratio check)
     final aspectRatio = image.height / image.width;
     if (params.autoRotate && aspectRatio > 2.0) {
       image = img.copyRotate(image, angle: -90);
       wasRotated = true;
     }

     // Step 2: Resize to max dimension (same pattern as existing, larger target)
     final maxDim = image.width > image.height ? image.width : image.height;
     if (maxDim > params.maxDimension) {
       if (image.width > image.height) {
         image = img.copyResize(image, width: params.maxDimension,
           interpolation: img.Interpolation.linear);
       } else {
         image = img.copyResize(image, height: params.maxDimension,
           interpolation: img.Interpolation.linear);
       }
     }

     // Step 3: Contrast enhancement
     image = img.adjustColor(image, contrast: params.contrastMultiplier);

     // Step 4: Auto-brightness based on histogram
     brightnessAdj = _calculateBrightnessAdjustment(image);
     if (brightnessAdj != 1.0) {
       image = img.adjustColor(image, brightness: brightnessAdj);
     }

     // Step 5: Lightweight noise reduction
     if (params.blurRadius > 0) {
       image = img.gaussianBlur(image, radius: params.blurRadius);
     }

     // Step 6: Encode
     final encodedBytes = img.encodeJpg(image, quality: params.quality);
     image.clear(); // MEMORY: dispose

     // Save to temp
     final timestamp = DateTime.now().millisecondsSinceEpoch;
     final outputPath = p.join(params.outputDir, 'enhanced_$timestamp.jpg');
     await File(outputPath).writeAsBytes(encodedBytes);

     return {
       'outputPath': outputPath,
       'wasRotated': wasRotated,
       'brightnessAdjustment': brightnessAdj,
     };
   }
   ```

   e. Add brightness helper `_calculateBrightnessAdjustment()`:
   ```dart
   static double _calculateBrightnessAdjustment(img.Image image) {
     // Sample every 10th pixel for performance (full scan too slow in isolate)
     int totalLuminance = 0;
     int sampleCount = 0;

     for (int y = 0; y < image.height; y += 10) {
       for (int x = 0; x < image.width; x += 10) {
         final pixel = image.getPixel(x, y);
         final r = pixel.r.toInt();
         final g = pixel.g.toInt();
         final b = pixel.b.toInt();
         totalLuminance += (0.299 * r + 0.587 * g + 0.114 * b).round();
         sampleCount++;
       }
     }

     if (sampleCount == 0) return 1.0;
     final avgLuminance = totalLuminance / sampleCount;

     // Target mid-gray (128). Return multiplier.
     if (avgLuminance < 80) return 1.3;   // Very dark -> brighten significantly
     if (avgLuminance < 100) return 1.15;  // Dark -> brighten slightly
     if (avgLuminance > 200) return 0.8;   // Very bright -> darken
     if (avgLuminance > 160) return 0.9;   // Bright -> darken slightly
     return 1.0; // Normal range, no adjustment
   }
   ```

2. Integrate into `job_state_notifier.dart` `uploadImage()` method:

   Insert preprocessing AFTER `ScanJob.uploading()` creation, BEFORE `client.uploadImage()`:
   ```dart
   // NEW: Preprocess image for better recognition accuracy
   String uploadPath = imagePath;  // Default: use raw image
   try {
     debugPrint('[JobStateNotifier] Starting image enhancement...');
     _updateJob(job.id, job.copyWith(
       progressMessage: 'Enhancing image...',
     ));

     final enhanceResult = await ImageProcessor.enhanceForUpload(imagePath);
     uploadPath = enhanceResult.outputPath;

     debugPrint('[JobStateNotifier] Enhancement completed in ${enhanceResult.processingTimeMs}ms');
     if (enhanceResult.wasRotated) {
       debugPrint('[JobStateNotifier] Image was auto-rotated (vertical bookshelf detected)');
     }
   } catch (e) {
     debugPrint('[JobStateNotifier] Enhancement failed, using raw image: $e');
     // Fallback: upload raw image (preprocessing is optional)
   }

   // Upload enhanced (or raw fallback) image
   final response = await client.uploadImage(uploadPath);
   ```

   **Key: `imagePath` (raw) is still used for review queue and failed scan storage. `uploadPath` (enhanced) is what goes to Talaria.**

**Why NOT a separate `ImagePreprocessor` class:**
- Would create confusion: two image processing services doing overlapping work
- `ImageProcessor` already has the isolate infrastructure, temp file management, metrics recording, and cleanup logic
- A single class is easier to maintain and test
- The `cleanupOldTempFiles()` method already handles temp files with `processed_` prefix; we add `enhanced_` prefix files to the same cleanup

**Acceptance Criteria:**
- [ ] `ImageProcessor.enhanceForUpload()` returns enhanced image at a temp path
- [ ] Processing runs in isolate (verified: UI remains responsive during preprocessing)
- [ ] Contrast (1.5x), brightness (auto), noise reduction (blur r=1) all applied
- [ ] Preprocessing completes in < 500ms for typical camera capture (2-4MP)
- [ ] Debug logs show preprocessing timing: `[ImageProcessor] Enhanced in Xms`
- [ ] Upload flow falls back to raw image if enhancement fails
- [ ] Review queue and failed scan storage always use the RAW image, never the enhanced one
- [ ] `cleanupOldTempFiles()` also cleans up `enhanced_*` temp files
- [ ] Unit test: enhancement produces output with different byte content than input
- [ ] Unit test: brightness calculation returns correct factors for dark/bright/normal images
- [ ] Unit test: existing `processImage()` method still works unchanged

**Test File:** `test/features/camera/image_processor_test.dart` (new -- tests both existing and new methods)

---

### Task 2: SSE Disconnect Cleanup
**Priority:** CRITICAL
**Estimated Effort:** 1-2 hours
**Files to Modify:**
- `lib/features/talaria/job_state_notifier.dart`
- `lib/features/camera/camera_screen.dart`

**Architectural Decision: Use `client.cleanupJob()` directly, NOT `_cleanupJob()`**

The existing `_cleanupJob(String jobId, String imagePath)` method does TWO things:
1. Sends DELETE to backend via `client.cleanupJob(jobId)` -- WANTED for cancellation
2. Deletes the local temp file at `imagePath` -- NOT wanted for cancellation (image should be preserved for failed scan queue / retry)

For disconnect/cancellation cleanup, we must call `client.cleanupJob(jobId)` directly on the `TalariaClient`, bypassing the private `_cleanupJob()` helper.

**Handling the async `talariaClientProvider` in `ref.onDispose()`:**

`talariaClientProvider` is a `FutureProvider<TalariaClient>`. In `ref.onDispose()`, we cannot reliably await a Future. The cleanup must be fire-and-forget:
```dart
// In ref.onDispose() -- fire-and-forget cleanup
for (final job in state.activeJobs) {
  if (job.jobId != null) {
    // Fire-and-forget: don't await, don't block disposal
    ref.read(talariaClientProvider.future).then((client) {
      client.cleanupJob(job.jobId!).catchError((e) {
        debugPrint('[JobStateNotifier] Cleanup failed for ${job.jobId}: $e');
      });
    }).catchError((e) {
      debugPrint('[JobStateNotifier] Could not get client for cleanup: $e');
    });
  }
}
```

**Implementation Details:**

1. Add `cancelActiveJobs()` public method to `JobStateNotifier`:
   ```dart
   /// Cancel all active scan jobs and notify backend to stop processing.
   ///
   /// Unlike _cleanupJob(), this does NOT delete local image files
   /// (images are preserved for the failed scan retry queue).
   /// Backend cleanup is fire-and-forget (errors silently logged).
   Future<void> cancelActiveJobs() async {
     final activeJobs = state.activeJobs;
     if (activeJobs.isEmpty) return;

     debugPrint('[JobStateNotifier] Cancelling ${activeJobs.length} active jobs');

     // 1. Cancel all SSE subscriptions immediately (stops receiving events)
     for (final job in activeJobs) {
       await _sseSubscriptions[job.id]?.cancel();
       _sseSubscriptions.remove(job.id);
     }

     // 2. Update all active job states to cancelled
     for (final job in activeJobs) {
       _updateJob(job.id, job.copyWith(
         status: JobStatus.error,
         errorMessage: 'Scan cancelled',
       ));
     }

     // 3. Send backend cleanup (fire-and-forget, DO NOT delete local files)
     try {
       final client = await ref.read(talariaClientProvider.future);
       for (final job in activeJobs) {
         if (job.jobId != null) {
           client.cleanupJob(job.jobId!).then((_) {
             debugPrint('[JobStateNotifier] Backend cleanup sent for ${job.jobId}');
           }).catchError((e) {
             debugPrint('[JobStateNotifier] Backend cleanup failed for ${job.jobId}: $e');
           });
         }
       }
     } catch (e) {
       debugPrint('[JobStateNotifier] Could not get client for cleanup: $e');
     }
   }
   ```

2. Update `ref.onDispose()` callback (line 35-57):
   After existing subscription and timer cleanup, add fire-and-forget backend cleanup:
   ```dart
   ref.onDispose(() {
     // ... existing subscription/timer cleanup ...

     // NEW: Fire-and-forget backend cleanup for active jobs
     for (final job in state.activeJobs) {
       if (job.jobId != null) {
         ref.read(talariaClientProvider.future).then((client) {
           client.cleanupJob(job.jobId!).catchError((e) {
             debugPrint('[JobStateNotifier] Dispose cleanup failed for ${job.jobId}: $e');
           });
         }).catchError((e) {
           // Provider may already be disposed -- silently ignore
         });
       }
     }
   });
   ```

3. Call `cancelActiveJobs()` from `camera_screen.dart`:

   In `dispose()` (line 477-489):
   ```dart
   @override
   void dispose() {
     // ... existing stream stop and observer removal ...

     // NEW: Cancel active scan jobs and notify backend
     ref.read(jobStateProvider.notifier).cancelActiveJobs();

     super.dispose();
   }
   ```

   In `didChangeAppLifecycleState()` (line 74-81), on pause:
   ```dart
   if (state == AppLifecycleState.paused) {
     ref.read(sessionCounterProvider.notifier).reset();
     // NEW: Cancel active jobs when app goes to background
     // Only cancel jobs that have been processing > 30 seconds (grace period)
     final jobState = ref.read(jobStateProvider);
     final longRunningJobs = jobState.activeJobs.where((job) {
       if (job.sseListeningStartedAt == null) return false;
       return DateTime.now().difference(job.sseListeningStartedAt!).inSeconds > 30;
     }).toList();

     if (longRunningJobs.isNotEmpty) {
       ref.read(jobStateProvider.notifier).cancelActiveJobs();
     }
   }
   ```

**Acceptance Criteria:**
- [ ] `cancelActiveJobs()` sends `client.cleanupJob(jobId)` for each active job -- NOT `_cleanupJob()` (which deletes files)
- [ ] Local image files are PRESERVED after cancellation (available for failed scan retry)
- [ ] Backend cleanup is fire-and-forget (errors silently logged, never thrown)
- [ ] `ref.onDispose()` handles the async `talariaClientProvider.future` without blocking
- [ ] Navigating away from camera screen during active scan sends DELETE cleanup
- [ ] App backgrounding only cancels long-running jobs (> 30 second grace period)
- [ ] Existing successful completion cleanup (`_cleanupJob()` at line 888) still works unchanged
- [ ] Rate-limited jobs and jobs without server jobId are skipped (no cleanup sent)
- [ ] Unit test: `cancelActiveJobs()` updates all active job states to error with "Scan cancelled" message

**Test File:** Extend `test/features/camera/camera_screen_test.dart`

---

### Task 3: Review Detail Screen Completion
**Priority:** CRITICAL
**Estimated Effort:** 2-3 hours
**Files to Modify:**
- `lib/features/review/review_detail_screen.dart`
- `lib/features/review/review_queue_screen.dart`

**Architectural Decision: Bounding Boxes Use Absolute Pixel Coordinates**

`LocalProcessorService._rectToMap()` returns absolute pixel coordinates from ML Kit:
```dart
{'left': 120.0, 'top': 45.0, 'width': 300.0, 'height': 80.0}
```
These are in **source image pixel space** (e.g., a 4032x3024 camera image). The `BoundingBoxPainter` must scale these to the display canvas size while preserving aspect ratio. The image is displayed with `BoxFit.contain`, so there may be letterboxing.

**Implementation Details:**

1. Fix `BoundingBoxPainter.paint()` at line 192:

   The painter needs the source image dimensions to calculate the scale factor. Add `imageSize` parameter:
   ```dart
   class BoundingBoxPainter extends CustomPainter {
     final Map<String, dynamic> mlData;
     final Size imageSize; // Source image pixel dimensions

     BoundingBoxPainter({required this.mlData, required this.imageSize});

     @override
     void paint(Canvas canvas, Size size) {
       // Calculate scale factor for BoxFit.contain
       final scaleX = size.width / imageSize.width;
       final scaleY = size.height / imageSize.height;
       final scale = scaleX < scaleY ? scaleX : scaleY; // min = contain

       // Calculate offset for centering (letterbox)
       final scaledWidth = imageSize.width * scale;
       final scaledHeight = imageSize.height * scale;
       final offsetX = (size.width - scaledWidth) / 2;
       final offsetY = (size.height - scaledHeight) / 2;

       final paint = Paint()
         ..color = const Color(0xFF00FF00) // Matrix green
         ..style = PaintingStyle.stroke
         ..strokeWidth = 2.0;

       final textStyle = TextStyle(
         color: const Color(0xFF00FF00),
         fontSize: 10,
         fontFamily: 'JetBrainsMono', // Swiss Utility monospace
         backgroundColor: Colors.black.withOpacity(0.7),
       );

       // Draw bounding boxes for detected objects
       final objects = mlData['objects'] as List<dynamic>? ?? [];
       for (final obj in objects) {
         final bbox = obj['boundingBox'] as Map<String, dynamic>?;
         if (bbox == null) continue;

         // Scale absolute pixel coordinates to display coordinates
         final left = (bbox['left'] as num).toDouble() * scale + offsetX;
         final top = (bbox['top'] as num).toDouble() * scale + offsetY;
         final width = (bbox['width'] as num).toDouble() * scale;
         final height = (bbox['height'] as num).toDouble() * scale;

         canvas.drawRect(Rect.fromLTWH(left, top, width, height), paint);

         // Draw label with confidence
         final labels = obj['labels'] as List<dynamic>? ?? [];
         if (labels.isNotEmpty) {
           final label = labels.first;
           final text = label['text'] as String? ?? '';
           final confidence = (label['confidence'] as num?)?.toDouble() ?? 0;
           final labelText = '$text ${(confidence * 100).toInt()}%';

           final textSpan = TextSpan(text: labelText, style: textStyle);
           final textPainter = TextPainter(
             text: textSpan,
             textDirection: TextDirection.ltr,
           )..layout();

           textPainter.paint(canvas, Offset(left, top - textPainter.height - 2));
         }
       }

       // Draw bounding boxes for text blocks
       final textBlocks = mlData['textBlocks'] as List<dynamic>? ?? [];
       final textPaint = Paint()
         ..color = const Color(0xFF00FF00).withOpacity(0.5)
         ..style = PaintingStyle.stroke
         ..strokeWidth = 1.0;

       for (final block in textBlocks) {
         final bbox = block['boundingBox'] as Map<String, dynamic>?;
         if (bbox == null) continue;

         final left = (bbox['left'] as num).toDouble() * scale + offsetX;
         final top = (bbox['top'] as num).toDouble() * scale + offsetY;
         final width = (bbox['width'] as num).toDouble() * scale;
         final height = (bbox['height'] as num).toDouble() * scale;

         canvas.drawRect(Rect.fromLTWH(left, top, width, height), textPaint);
       }
     }

     @override
     bool shouldRepaint(covariant BoundingBoxPainter oldDelegate) {
       return oldDelegate.mlData != mlData || oldDelegate.imageSize != imageSize;
     }
   }
   ```

2. Update `ReviewDetailScreen` to pass image dimensions:

   In the `build()` method, get the source image dimensions:
   ```dart
   // Get source image size for bounding box scaling
   final imageFile = File(widget.item.imagePath);
   // Use a FutureBuilder or pre-calculate in initState
   ```

   In `initState()`:
   ```dart
   late Size _imageSize;

   @override
   void initState() {
     super.initState();
     // ... existing init ...

     // Get source image dimensions for bounding box scaling
     _loadImageSize();
   }

   Future<void> _loadImageSize() async {
     try {
       final file = File(widget.item.imagePath);
       final bytes = await file.readAsBytes();
       final decoded = await decodeImageFromList(bytes);
       if (mounted) {
         setState(() {
           _imageSize = Size(decoded.width.toDouble(), decoded.height.toDouble());
         });
       }
     } catch (e) {
       debugPrint('Error loading image size: $e');
       _imageSize = const Size(1920, 1080); // Fallback
     }
   }
   ```

   Then pass to painter:
   ```dart
   CustomPaint(
     painter: BoundingBoxPainter(
       mlData: _mlData!,
       imageSize: _imageSize,
     ),
   ),
   ```

3. Auto-populate fields from ML text blocks:

   In `initState()`, after parsing `_mlData`:
   ```dart
   if (_mlData != null && widget.item.backendResult == null) {
     // Backend hasn't responded yet -- heuristic populate from ML text blocks
     final textBlocks = _mlData!['textBlocks'] as List<dynamic>? ?? [];
     if (textBlocks.isNotEmpty) {
       // Sort by text length descending
       final sortedBlocks = List<Map<String, dynamic>>.from(textBlocks)
         ..sort((a, b) => (b['text'] as String).length.compareTo((a['text'] as String).length));

       // Longest text = likely title, second longest = likely author
       if (sortedBlocks.isNotEmpty) {
         _titleController.text = sortedBlocks[0]['text'] as String? ?? '';
       }
       if (sortedBlocks.length > 1) {
         _authorController.text = sortedBlocks[1]['text'] as String? ?? '';
       }
     }
   }
   ```

4. Apply Swiss Utility styling to form and queue:
   - OLED black background on Scaffold
   - 1px border InputDecoration on TextFields
   - Inter font for labels, JetBrains Mono for ISBN field
   - Status overlays on review queue tiles (green check for ready, red X for error)

**Acceptance Criteria:**
- [ ] `BoundingBoxPainter` receives source image `Size` and scales from absolute pixel coords to display coords
- [ ] Letterboxing offset calculated correctly for `BoxFit.contain` display
- [ ] Green (#00FF00) boxes with 2px stroke for objects, 1px stroke for text blocks
- [ ] Labels show object type + confidence in JetBrains Mono
- [ ] Auto-population uses text block length heuristic (longest = title, second = author)
- [ ] "Add to Library" saves to Books and removes from ReviewQueue
- [ ] "Delete" removes from ReviewQueue and deletes image file
- [ ] `shouldRepaint()` correctly detects data changes (not always repainting)
- [ ] Widget test: BoundingBoxPainter renders boxes when given valid mlData with absolute coords

**Test File:** `test/features/review/review_detail_screen_test.dart` (new)

---

## Phase 2: High Value Features (LAUNCH POLISH)

### Task 4: Progressive Results UI
**Priority:** HIGH
**Estimated Effort:** 3-4 hours
**Depends On:** Task 2 (SSE event model understanding)
**Files to Modify:**
- `lib/core/sse_client.dart` (extend event parsing for metadata)
- `lib/features/talaria/job_state.dart` (add progress fields to ScanJob)
- `lib/features/talaria/job_state_notifier.dart` (handle new progress data)
- `lib/features/camera/camera_screen.dart` or new widget (progress overlay)

**Files to Create:**
- `lib/features/talaria/scan_progress_overlay.dart` (new widget)

**Description:**
Add richer progress feedback during scan processing. When the backend sends progress events with metadata (book count, current processing index), display a progress bar and "Processing book N of M" text. This works with the existing SSE event model but extracts more data from `progress` events.

**Implementation Details:**

1. Extend `SseEvent` to extract metadata:
   - The existing `data` map on `SseEvent` already contains whatever the backend sends
   - Add helper getters: `int? get totalBooks => data['totalBooks'] as int?;`
   - Add helper: `int? get currentBook => data['current'] as int?;`
   - No breaking changes -- just convenience accessors

2. Extend `ScanJob` model:
   - Add `int? totalBooks` field -- total detected books in this scan
   - Add `int? currentBook` field -- which book is currently being processed
   - Update `copyWith` to include these fields

3. Update `_handleSseEvent()` in `JobStateNotifier`:
   - On `SseEventType.progress` events, extract `totalBooks` and `currentBook` from event data
   - Update `ScanJob` with these values alongside existing `progress` and `progressMessage`

4. Create processing progress overlay widget:
   - New widget: `lib/features/talaria/scan_progress_overlay.dart`
   - Shows when a job has `totalBooks > 0`:
     a. Linear progress bar (current/total)
     b. Text: "Processing book 3 of 12..."
     c. Semi-transparent black background (#000000 at 80% opacity)
     d. Positioned at bottom of camera screen, above shutter button
   - Swiss Utility design: 1px border, Inter font, white text on OLED black
   - Smooth animation (300ms ease-out) when progress updates
   - Auto-dismisses when job completes

5. Integrate into `CameraScreen.build()`:
   - Add the progress overlay to the Stack, conditionally shown when active job has totalBooks data
   - Sits above the StreamOverlay but below the shutter button

**Note on Backend Dependency:**
The current Talaria backend may not send `totalBooks`/`currentBook` in progress events. This implementation is forward-compatible: if the fields are missing, the overlay simply does not show. When Talaria is updated to send these fields, the UI automatically activates.

**Acceptance Criteria:**
- [ ] Progress overlay appears when backend sends totalBooks metadata in progress events
- [ ] Progress bar accurately reflects current/total
- [ ] Text shows "Processing book N of M..." in Swiss Utility style
- [ ] Overlay auto-dismisses on job completion
- [ ] Graceful degradation: no overlay if metadata fields are absent (backward compatible)
- [ ] Smooth animation on progress updates (no jank)
- [ ] Widget test: progress overlay renders with mock progress data

**Test File:** `test/features/talaria/scan_progress_overlay_test.dart` (new)

---

### Task 5: Rotation Detection UX Feedback
**Priority:** HIGH
**Estimated Effort:** 1-2 hours
**Depends On:** Task 1 (`ImageProcessor.enhanceForUpload()` returns `ImageEnhancementResult` with `wasRotated`)
**Files to Modify:**
- `lib/features/talaria/job_state_notifier.dart` (surface rotation info to UI)
- `lib/features/camera/camera_screen.dart` (brief rotation feedback toast)

**Description:**
When the image preprocessor detects a vertical bookshelf photo (aspect ratio > 2.0) and auto-rotates it, show a brief toast notification to the user. This builds user trust and explains what the app is doing.

**Implementation Details:**

1. In `JobStateNotifier.uploadImage()` (already modified in Task 1):
   - After `ImageProcessor.enhanceForUpload()` returns, check `result.wasRotated`
   - If true, update the `ScanJob.progressMessage` to "Rotated vertical bookshelf image"
   - This message appears in the existing `StreamOverlay`

2. Optionally add a dedicated info snackbar:
   - Create `InfoSnackBar.show()` following the same pattern as existing `ErrorSnackBar.show()`
   - Use green tint instead of red, with rotation icon
   - Brief display (2 seconds), non-blocking
   - Only show once per capture (not on every SSE event)

**Acceptance Criteria:**
- [ ] Vertical images (h/w > 2.0) are auto-rotated before upload (handled by Task 1)
- [ ] User sees brief feedback when rotation occurs via StreamOverlay or snackbar
- [ ] No feedback shown when image is already in normal orientation
- [ ] Rotation + full preprocessing combined still < 500ms
- [ ] Unit test: vertical image produces rotated output (covered by Task 1 tests)

**Test File:** Extend `test/features/camera/image_processor_test.dart`

---

## Phase 3: Testing and Polish

### Task 6: Integration Testing and A/B Validation
**Priority:** HIGH
**Estimated Effort:** 2-3 hours
**Depends On:** Tasks 1-5
**Files to Create:**
- `test/features/camera/image_processor_test.dart` (if not created in Task 1)
- `test/features/review/review_detail_screen_test.dart` (if not created in Task 3)
- `test/features/talaria/scan_progress_overlay_test.dart` (if not created in Task 4)

**Files to Modify:**
- `test/features/camera/camera_screen_test.dart` (add disconnect cleanup tests)

**Description:**
Write comprehensive tests for all new functionality and validate that preprocessing improves outcomes.

**Implementation Details:**

1. Image Processor Enhancement Tests (`test/features/camera/image_processor_test.dart`):
   - Test `enhanceForUpload()` returns result with valid output path
   - Test existing `processImage()` still works unchanged (no regression)
   - Test contrast enhancement produces different output than input
   - Test brightness calculation:
     - avgLuminance < 80 returns 1.3
     - avgLuminance 80-100 returns 1.15
     - avgLuminance 100-160 returns 1.0
     - avgLuminance 160-200 returns 0.9
     - avgLuminance > 200 returns 0.8
   - Test rotation detection: image with h/w > 2.0 produces `wasRotated: true`
   - Test no rotation: image with normal aspect ratio produces `wasRotated: false`
   - Test resize respects 2560px max dimension for enhancement
   - Test graceful failure on corrupted input
   - Test `cleanupOldTempFiles()` removes `enhanced_*` files older than 1 hour

2. SSE Cleanup Tests (extend `test/features/camera/camera_screen_test.dart`):
   - Test `cancelActiveJobs()` updates active job states to `JobStatus.error` with "Scan cancelled"
   - Test `cancelActiveJobs()` skips jobs without server jobId
   - Test `cancelActiveJobs()` skips completed/error jobs
   - Test cleanup is fire-and-forget (no exception propagation)

3. Review Detail Tests (`test/features/review/review_detail_screen_test.dart`):
   - Test `BoundingBoxPainter` with absolute pixel coords scales correctly to a known canvas size
   - Test letterboxing offset for non-matching aspect ratios
   - Test auto-population of title/author from text blocks
   - Test "Add to Library" flow (mock database)
   - Test "Delete" flow (mock database + file check)
   - Test `shouldRepaint()` returns true when data changes, false when same

4. Progressive Results Tests (`test/features/talaria/scan_progress_overlay_test.dart`):
   - Test overlay shows when job has totalBooks > 0
   - Test overlay hidden when totalBooks is null
   - Test progress bar renders correct value
   - Test auto-dismiss on job completion

5. Run full test suite:
   ```bash
   flutter test
   flutter analyze
   ```

**Acceptance Criteria:**
- [ ] All new tests pass
- [ ] All existing tests continue to pass (zero regressions)
- [ ] `flutter analyze` clean (no warnings or errors)
- [ ] Code coverage for new functionality > 80%
- [ ] No performance regression (cold start still < 1000ms)

---

## Commit Strategy

### Commit 1: Image Enhancement in Existing ImageProcessor
```
feat: add image enhancement pipeline to ImageProcessor for upload preprocessing

- Extend existing ImageProcessor with enhanceForUpload() method
- Add contrast (1.5x), auto-brightness, noise reduction, rotation detection
- Integrate into uploadImage() flow (review queue keeps raw image)
- Target < 500ms processing per image in isolate
```
**Files:** `lib/features/camera/image_processor.dart`, `lib/features/talaria/job_state_notifier.dart`

### Commit 2: SSE Disconnect Cleanup (Backend-Only, No File Deletion)
```
fix: send backend cleanup signal on SSE disconnect without deleting local files

- Add cancelActiveJobs() calling client.cleanupJob() directly (not _cleanupJob)
- Fire-and-forget async cleanup in ref.onDispose() for talariaClientProvider Future
- Preserve local images for failed scan retry queue
- 30-second grace period before cancelling on app background
```
**Files:** `lib/features/talaria/job_state_notifier.dart`, `lib/features/camera/camera_screen.dart`

### Commit 3: Review Detail Screen with Absolute Pixel Coordinate Scaling
```
feat: complete review detail screen with bounding box overlay and Swiss Utility styling

- Implement BoundingBoxPainter scaling from absolute pixel coords to display canvas
- Calculate BoxFit.contain letterbox offset for correct positioning
- Auto-populate fields from ML text blocks (longest = title heuristic)
- Add status indicators to review queue grid
```
**Files:** `lib/features/review/review_detail_screen.dart`, `lib/features/review/review_queue_screen.dart`

### Commit 4: Progressive Results UI
```
feat: add progressive results overlay showing per-book processing progress

- Extend ScanJob model with totalBooks/currentBook fields
- Create ScanProgressOverlay widget with progress bar
- Forward-compatible with future Talaria metadata events
```
**Files:** `lib/features/talaria/job_state.dart`, `lib/features/talaria/scan_progress_overlay.dart`, `lib/features/camera/camera_screen.dart`

### Commit 5: Rotation Detection UX
```
feat: add user feedback for vertical bookshelf auto-rotation

- Surface wasRotated flag from ImageEnhancementResult
- Show brief toast/overlay when rotation occurs
- No feedback for normal orientation images
```
**Files:** `lib/features/talaria/job_state_notifier.dart`, `lib/features/camera/camera_screen.dart`

### Commit 6: Tests
```
test: add comprehensive tests for enhancement, SSE cleanup, review UI, and progress overlay

- Image processor enhancement tests (brightness, contrast, rotation, existing method regression)
- SSE disconnect cleanup tests (fire-and-forget, no file deletion)
- Review detail screen tests (absolute pixel coord scaling, letterbox offset)
- Progressive results overlay widget tests
```
**Files:** `test/features/camera/image_processor_test.dart`, `test/features/review/review_detail_screen_test.dart`, `test/features/talaria/scan_progress_overlay_test.dart`, `test/features/camera/camera_screen_test.dart`

---

## Success Criteria

| Metric | Target | How to Measure |
|--------|--------|----------------|
| Enhancement time | < 500ms per image | Debug logs in `[ImageProcessor] Enhanced in Xms` |
| Cold start time | < 1000ms (no regression) | Existing `[Performance]` logs |
| Failed scan rate | Reduced (A/B comparison) | Compare 25 enhanced vs 25 raw scans |
| Orphaned backend jobs | Zero new orphans | Monitor backend logs for cleanup calls |
| Review queue usability | Bounding boxes render correctly at absolute pixel coords | Visual verification on device |
| Test suite | All pass, 0 regressions | `flutter test` exit code 0 |
| Static analysis | Clean | `flutter analyze` exit code 0 |

---

## Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Enhancement too slow (> 500ms) | Medium | Performance regression | Reduce: skip gaussianBlur first, reduce contrast to 1.3, sample fewer pixels for brightness |
| Backend doesn't send totalBooks metadata | High | Progressive UI won't show | Forward-compatible design: graceful degradation, no UI if fields absent |
| BoundingBoxPainter letterbox offset wrong | Medium | Visual misalignment | Test with multiple aspect ratios, compare to ObjectOverlayPainter in camera_screen.dart |
| Enhancement over-processes, reduces accuracy | Low | Worse scan results | Add toggle in settings, A/B test before shipping, fallback to raw on failure |
| Cleanup DELETE fails (network error) | Medium | Orphaned job not cleaned | Fire-and-forget with silent logging, backend should have its own TTL cleanup |
| `ref.onDispose()` async cleanup races | Medium | Cleanup never sent | Use `.then()` chain (fire-and-forget), not `await`. Accept some cleanup may not send if app kills fast. |
| `enhanceForUpload()` and `processImage()` both called | Low | Double processing waste | Document clearly: `enhanceForUpload()` replaces `processImage()` in the upload path. They should NEVER both be called on the same image. |

---

## Excluded from This Plan (Future Work)

These items from the lessons document are intentionally deferred:

| Item | Reason | Estimated Effort |
|------|--------|-----------------|
| Multi-provider architecture | Post-launch architecture concern, requires major refactoring | 8-12h |
| Generic API result wrappers | Polish, not blocking any feature | 2-3h |
| On-device ML inference | Entirely separate effort, requires Core ML integration | 20-30h |
| CUDA/GPU dependency management | Backend concern, not relevant to Flutter client | N/A |

---

## Critic Feedback Addressed (v2 Changes)

| Critic Issue | Resolution |
|-------------|------------|
| 1. Existing `ImageProcessor` class overlooked | Plan now EXTENDS `ImageProcessor` with `enhanceForUpload()` instead of creating a separate class. Avoids confusion and double-processing. |
| 2. `_cleanupJob()` deletes local files | Plan now calls `client.cleanupJob(jobId)` DIRECTLY for cancellation, preserving local files. `_cleanupJob()` only used for successful completion. Async `talariaClientProvider.future` handled with `.then()` fire-and-forget chain. |
| 3. Bounding box coordinates are absolute, not normalized | Plan now correctly specifies absolute pixel coordinate scaling with `BoxFit.contain` letterbox offset calculation. Painter receives source `imageSize`. |
| 4. `image` package v4.x API unverified | API confirmed against version 4.7.2 in pubspec.lock: `adjustColor(contrast:, brightness:)`, `gaussianBlur(radius:)`, `copyRotate(angle:)` all exist with correct signatures. |
| 5. Preprocessing flow integration unclear | Decision documented: preprocessing happens INSIDE `uploadImage()` in `JobStateNotifier`. Review queue gets raw image. ML detection uses raw image. Only Talaria upload uses enhanced image. |

---

**Generated by:** Prometheus (Planner Agent)
**Plan Version:** 2.0
**Total Tasks:** 6
**Total Estimated Effort:** 14-19 hours
