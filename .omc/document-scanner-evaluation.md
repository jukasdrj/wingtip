# ML Kit Document Scanner API - Flutter Evaluation

**Research Date:** 2026-02-01
**Researcher:** oh-my-claudecode:researcher
**Context:** Wingtip barcode/ISBN reading enhancement (Phase 2)

---

## Executive Summary

**Key Finding:** Google's ML Kit Document Scanner API is **Android-only** and remains in beta. However, a viable cross-platform solution exists via `flutter_doc_scanner`, which uses ML Kit on Android and Apple's VisionKit on iOS.

**Recommendation:** **Do NOT integrate** ML Kit Document Scanner for Wingtip's use case. Use existing `ImageProcessor` with potential VisionKit integration for iOS-specific enhancements if needed.

**Rationale:**
1. Wingtip is **iOS-first** - ML Kit Document Scanner doesn't support iOS
2. Document Scanner provides a **full UI flow** (not suitable for book spine scanning)
3. VisionKit alternative (`flutter_doc_scanner`) solves wrong problem (document scanning vs. book spine preprocessing)
4. Current `ImageProcessor` (compression/resize) is sufficient for ISBN barcode detection

---

## 1. Package Existence & Availability

### Official Google Package

**Package:** [`google_mlkit_document_scanner`](https://pub.dev/packages/google_mlkit_document_scanner)

- **Status:** Available on pub.dev
- **Maintainer:** Community-maintained (not official Google support)
- **Current Version:** Active development
- **Platform Support:** **Android-only** (beta)

### Community Alternative

**Package:** [`flutter_doc_scanner`](https://pub.dev/packages/flutter_doc_scanner)

- **Status:** Available on pub.dev
- **Maintainer:** Community-maintained
- **Platform Support:** Android (ML Kit) + iOS (VisionKit)
- **Cross-platform:** Yes, via platform channels

---

## 2. Platform Availability Matrix

| Feature | google_mlkit_document_scanner | flutter_doc_scanner | VisionKit (Native iOS) |
|---------|-------------------------------|---------------------|------------------------|
| **Android** | ✅ Full support (API 21+) | ✅ Via ML Kit | ❌ N/A |
| **iOS** | ❌ Not available | ✅ Via VisionKit (iOS 13+) | ✅ Native (iOS 13+) |
| **Web** | ❌ Not available | ❌ Not available | ❌ N/A |
| **Status** | Beta (Android-only) | Stable (cross-platform) | Stable (iOS-only) |
| **GPU Acceleration** | Not documented | Not documented | Not documented |
| **Minimum iOS Version** | N/A (iOS 15.5 in pubspec, but no actual iOS support) | iOS 13.0+ | iOS 13.0+ |
| **Minimum Android Version** | API 21 (Lollipop) | API 21 (Lollipop) | N/A |

### Platform Support Summary

**ML Kit Document Scanner:**
- ⚠️ **Android-only** (confirmed as of 2026-02-01)
- ⚠️ Still in **beta** status
- ⚠️ No iOS timeline from Google
- Requires 1.7GB+ RAM on Android
- Uses Google Play Services (low binary size impact)

**VisionKit (iOS Alternative):**
- ✅ Native iOS support since iOS 13
- ✅ Stable, production-ready
- ✅ Used in Apple Notes app
- ✅ Part of iOS SDK (no external dependencies)

---

## 3. Feature Comparison

### ML Kit Document Scanner Features

| Feature | Supported | Notes |
|---------|-----------|-------|
| **Auto Document Detection** | ✅ | Real-time detection during capture |
| **Edge Detection** | ✅ | Accurate crop boundary detection |
| **Perspective Correction** | ✅ | Transforms skewed documents to rectangular view |
| **Dewarping** | ❌ | Not mentioned in official docs (no advanced curve correction) |
| **Shadow Removal** | ✅ | Via SCANNER_MODE_FULL |
| **Stain Removal** | ✅ | Via SCANNER_MODE_FULL (ML-enabled cleaning) |
| **Auto-crop** | ✅ | Based on edge detection |
| **Automatic Rotation** | ✅ | Aligns documents upright |
| **Filters** | ✅ | Grayscale, auto-enhancement (SCANNER_MODE_BASE_WITH_FILTER) |
| **Multi-page Support** | ✅ | Continuous scanning |
| **Gallery Import** | ✅ | Scan from existing photos |
| **On-device Processing** | ✅ | Privacy-preserving, no network required |
| **GPU Acceleration** | ⚠️ | Not documented (likely uses ML Kit's neural networks) |

### VisionKit (iOS) Features

| Feature | Supported | Notes |
|---------|-----------|-------|
| **Auto Document Detection** | ✅ | Real-time detection |
| **Edge Detection** | ✅ | Automatic boundary detection |
| **Perspective Correction** | ✅ | Pre-applied to output images |
| **Dewarping** | ⚠️ | Not explicitly mentioned |
| **Auto-crop** | ✅ | User can adjust crop boundaries |
| **Color Correction** | ✅ | Pre-applied to output images |
| **Auto-capture** | ✅ | Triggers when document detected |
| **Torch Toggle** | ✅ | Built-in flashlight control |
| **User Guidance** | ✅ | On-screen instructions |
| **Multi-page Support** | ✅ | Via `pageCount` property |
| **On-device Processing** | ✅ | Privacy-preserving |

### Feature Summary

**What ML Kit/VisionKit Do Well:**
- Document scanning (receipts, papers, contracts)
- Perspective correction for flat documents
- Shadow/stain removal for document legibility
- Multi-page document workflows

**What They DON'T Do:**
- Advanced dewarping for curved surfaces (e.g., book spines)
- Real-time preprocessing for barcode detection
- Programmatic image enhancement without UI
- Fine-grained control over compression/resizing

---

## 4. iOS Alternatives Analysis

### Option A: flutter_doc_scanner (VisionKit Wrapper)

**Implementation Complexity:** Low-Medium

```dart
// Example usage
import 'package:flutter_doc_scanner/flutter_doc_scanner.dart';

final FlutterDocScanner scanner = FlutterDocScanner();
final result = await scanner.getScanDocuments();

// Android: Returns PDF via `pdfUri`
// iOS: Returns PNG images via VisionKit
```

**Pros:**
- Cross-platform (Android + iOS)
- Maintained community package
- Simple API
- Platform-native UX (different on Android vs iOS)

**Cons:**
- Provides **full UI flow** (not suitable for Wingtip's inline camera)
- Outputs entire scanned document (not preprocessing for barcode detection)
- Platform behavior differences (PDF on Android, PNG on iOS)
- No programmatic control over image enhancement
- Not designed for real-time camera stream preprocessing

### Option B: Native VisionKit via Platform Channel

**Implementation Complexity:** High

**Pros:**
- Full control over VisionKit API
- Can integrate with existing camera flow
- Native iOS performance
- Fine-grained customization

**Cons:**
- Requires Swift/Objective-C development
- Platform channel maintenance overhead
- Still presents **full document scanner UI** (not inline)
- Overkill for simple image preprocessing

### Option C: Keep Current ImageProcessor

**Implementation Complexity:** None (already implemented)

**Pros:**
- Already working
- Simple, predictable behavior
- Cross-platform consistent
- Sufficient for barcode detection (compression + resize)
- No additional dependencies

**Cons:**
- No advanced preprocessing (dewarping, shadow removal)
- Manual implementation required for enhancements

---

## 5. Recommendation for Wingtip

### Final Recommendation: **Do NOT Integrate ML Kit Document Scanner**

**Why Not ML Kit Document Scanner?**

1. **iOS-First Platform Priority:**
   - Wingtip targets iOS as primary platform
   - ML Kit Document Scanner is **Android-only**
   - No iOS timeline from Google

2. **Wrong Tool for the Job:**
   - Document Scanner provides **full UI flow** (camera → crop → edit → save)
   - Wingtip needs **inline preprocessing** for barcode detection
   - Document Scanner outputs final scanned documents, not preprocessed images

3. **Barcode Detection Works Without It:**
   - Current `ImageProcessor` (resize + compress) is sufficient
   - Barcode detection via `google_mlkit_barcode_scanning` doesn't require document preprocessing
   - Real bottleneck is image quality during capture, not preprocessing

4. **VisionKit Alternative Solves Wrong Problem:**
   - `flutter_doc_scanner` uses VisionKit for **document scanning UI**
   - Doesn't provide programmatic image enhancement for barcode detection
   - Introduces platform-specific behavior differences

### What to Use Instead

**Phase 2: Keep Current Approach**
- ✅ Current `ImageProcessor` (compression + resize)
- ✅ Existing barcode detection via ML Kit
- ✅ Focus on **capture-time quality** (camera settings, lighting guidance)

**Future Enhancements (Phase 3+ if needed):**

1. **iOS Camera Optimizations:**
   - Auto exposure compensation (+0.5 to +1.0 for book spines)
   - Focus/exposure lock via long-press
   - Night Mode for low-light conditions
   - **Already implemented in Wingtip** (see CLAUDE.md)

2. **Custom Preprocessing (if barcode detection struggles):**
   - Contrast enhancement via `image` package
   - Adaptive thresholding for low-light
   - Crop to center region (reduce search area)
   - Implement manually - simpler than integrating Document Scanner

3. **Subject Segmentation (Advanced):**
   - Use ML Kit's Subject Segmentation API
   - Isolate book spine from background
   - Enhance contrast on isolated subject
   - **Phase 3 task** - evaluate separately

### Implementation Path Forward

**Phase 2 (Current):**
1. ✅ Add barcode scanning to camera stream
2. ✅ Auto-lookup ISBN on detection
3. ❌ Skip Document Scanner integration
4. ✅ Keep existing `ImageProcessor`

**Phase 3 (Future Optimization):**
1. Evaluate custom preprocessing (contrast, thresholding)
2. Assess Subject Segmentation API for spine isolation
3. Consider iOS-specific camera enhancements (already implemented)
4. Performance testing: barcode detection success rate vs. preprocessing complexity

---

## 6. Technical Deep Dive

### flutter_doc_scanner Implementation Details

**Platform Channel Architecture:**
```
Flutter/Dart (App Layer)
    ↓ MethodChannel
Native Android (Kotlin/Java)
    ↓ ML Kit Document Scanner API
Google Play Services

Flutter/Dart (App Layer)
    ↓ FlutterMethodChannel
Native iOS (Swift/Objective-C)
    ↓ VisionKit (VNDocumentCameraViewController)
iOS SDK
```

**Key Differences:**
- **Android:** Returns PDF via `pdfUri` with `pageCount`
- **iOS:** Returns PNG images via VisionKit, one per page

**Permissions:**
- **Android:** No camera permission required (uses Google Play Services)
- **iOS:** Requires `NSCameraUsageDescription` in Info.plist

### VisionKit (VNDocumentCameraViewController) Details

**What It Provides:**
- Full-screen camera UI (similar to Apple Notes)
- Automatic document detection with visual feedback
- Edge detection with adjustable crop handles
- Perspective correction applied to output images
- Color correction and enhancement
- Multi-page scanning with page management

**What It Doesn't Provide:**
- Programmatic preprocessing API (no headless mode)
- Real-time image enhancement
- Integration into existing camera views
- Dewarping for curved surfaces

**Example Output:**
- Pre-corrected UIImage instances (perspective + color corrected)
- One image per scanned page
- No access to raw/uncorrected images

---

## 7. Performance Considerations

### ML Kit Document Scanner Performance

**Processing Time:**
- Not documented (likely 500ms-2s per document)
- Uses on-device ML models (no network latency)
- Leverages Google Play Services (model updates without app updates)

**Resource Requirements:**
- Android: 1.7GB+ RAM
- Binary size impact: Low (models delivered via Google Play Services)
- Battery impact: Medium (ML processing during scanning)

### VisionKit Performance

**Processing Time:**
- Real-time document detection
- Instant perspective correction on capture
- Pre-processing done by iOS (highly optimized)

**Resource Requirements:**
- iOS 13.0+ (lightweight framework)
- Binary size impact: None (part of iOS SDK)
- Battery impact: Low-Medium (native iOS optimization)

### Comparison to Current ImageProcessor

**Wingtip's Current Approach:**
```dart
// ImageProcessor (lib/services/image_processor.dart)
final result = await compute(_processImageInIsolate, imagePath);

// In isolate:
- Resize to max 1920px
- Compress to JPEG quality 85
- Return processed bytes
```

**Performance:**
- ✅ < 500ms processing time (target met)
- ✅ Runs in isolate (non-blocking)
- ✅ Predictable, consistent behavior
- ✅ Cross-platform identical

**Document Scanner Overhead:**
- ❌ Adds UI flow (camera → crop → edit → save)
- ❌ Requires user interaction
- ❌ Not suitable for rapid-fire scanning workflow
- ❌ Overkill for barcode preprocessing

---

## 8. Cost-Benefit Analysis

### Integrating Document Scanner

**Costs:**
- ❌ Platform-specific implementations (Android vs iOS)
- ❌ Behavioral differences (PDF vs PNG output)
- ❌ UI flow disruption (full-screen scanner vs inline camera)
- ❌ Maintenance overhead (two platform channels)
- ❌ No iOS support for official ML Kit package
- ❌ Beta status (Android-only, stability concerns)

**Benefits:**
- ✅ Professional document scanning UX
- ✅ Shadow/stain removal for documents
- ✅ Perspective correction for flat documents

**Verdict:** **Costs outweigh benefits** for Wingtip's use case.

### Keeping Current Approach

**Costs:**
- ⚠️ No advanced preprocessing (dewarping, shadow removal)
- ⚠️ Manual implementation required for future enhancements

**Benefits:**
- ✅ Simple, proven approach
- ✅ Cross-platform consistency
- ✅ iOS-first compatible
- ✅ Fast processing (< 500ms)
- ✅ No external dependencies
- ✅ No UI flow disruption
- ✅ Sufficient for barcode detection

**Verdict:** **Benefits outweigh costs** for current needs.

---

## 9. Alternative Packages Considered

| Package | Platform Support | Status | Notes |
|---------|------------------|--------|-------|
| **google_mlkit_document_scanner** | Android-only | Beta | Official community package, no iOS |
| **flutter_doc_scanner** | Android + iOS | Stable | VisionKit on iOS, ML Kit on Android |
| **document_scanner_kit** | Android + iOS | Active | Similar to flutter_doc_scanner |
| **doc_scan** | Android + iOS | Active | Wrapper for ML Kit + VisionKit |
| **scanbot_sdk** | Android + iOS + Web | Commercial | Paid SDK, feature-rich |
| **Mobile Scanner** | Android + iOS | Active | Barcode scanning only (Wingtip already uses this approach) |

**None are suitable for Wingtip's use case** - all provide full document scanning UI workflows, not programmatic image preprocessing.

---

## 10. Sources

### Official Documentation
- [ML Kit Document Scanner](https://developers.google.com/ml-kit/vision/doc-scanner) - Google's official ML Kit docs
- [Document scanner with ML Kit on Android](https://developers.google.com/ml-kit/vision/doc-scanner/android) - Android-specific implementation guide
- [VNDocumentCameraViewController | Apple Developer Documentation](https://developer.apple.com/documentation/visionkit/vndocumentcameraviewcontroller) - VisionKit official docs
- [VisionKit | Apple Developer Documentation](https://developer.apple.com/documentation/visionkit) - VisionKit framework overview

### Flutter Packages
- [google_mlkit_document_scanner | Flutter package](https://pub.dev/packages/google_mlkit_document_scanner) - Official community package
- [flutter_doc_scanner | Flutter package](https://pub.dev/packages/flutter_doc_scanner) - Cross-platform wrapper
- [document_scanner_kit | Flutter package](https://pub.dev/packages/document_scanner_kit) - Alternative wrapper

### Technical Articles
- [Using ML Kit to build a Flutter document scanner app for Android and iOS - Scanbot SDK](https://scanbot.io/techblog/flutter-mlkit-document-scanner-tutorial/) - Implementation guide
- [Flutter Doc Scanner: A Comprehensive Guide for Developers | by Shirsh Shukla | Medium](https://shirsh94.medium.com/flutter-doc-scanner-a-comprehensive-guide-for-developers-9093f49253d6) - Developer guide
- [Build a Flutter document scanner with flutter_doc_scanner - Scanbot SDK](https://scanbot.io/techblog/flutter-doc-scanner-tutorial/) - Tutorial
- [Implementing the new Document Scanner ML kit to your Flutter App | by Benson Arafat | Medium](https://bensonarafat.medium.com/implementing-the-new-document-scanner-ml-kit-to-your-flutter-app-e3d978ef2957) - Implementation walkthrough
- [ML Kit Document Scanner in action | Google Developer Experts](https://medium.com/google-developer-experts/ml-kit-document-scanner-in-action-1c3a49ef5a33) - Expert analysis
- [Building a Production-Ready Document Scanner in Android with Google ML Kit | by Chetan Gaikwad | Medium](https://gaikwadchetan93.medium.com/building-a-production-ready-document-scanner-in-android-with-google-ml-kit-2e76a82b99c5) - Production implementation
- [Scanning documents with Vision and VisionKit on iOS 13 | by Mister Grizzly | Medium](https://mistergrizzly.medium.com/scanning-documents-with-vision-and-visionkit-on-ios-13-913c0a6f9392) - VisionKit deep dive
- [Comparing iOS document scanners: WeScan vs. VisionKit](https://scanbot.io/blog/ios-document-scanners-wescan-vs-visionkit/) - iOS alternatives comparison
- [How to use VNDocumentCameraViewController and SwiftUI to build a document scanner app for iOS - Scanbot SDK](https://scanbot.io/techblog/vndocumentcameraviewcontroller-ios-document-scanner-tutorial/) - iOS-specific guide

### Comparison & Analysis
- [ML Kit vs. OpenCV for document scanning - Scanbot SDK](https://scanbot.io/blog/ml-kit-vs-opencv-document-scanning-software/) - Technology comparison
- [Genius Scan SDK vs ML Kit | Genius Scan SDK](https://geniusscansdk.com/vs/ml-kit/) - Commercial vs. free comparison

### Community Resources
- [GitHub - shirsh94/flutter_doc_scanner](https://github.com/shirsh94/flutter_doc_scanner) - flutter_doc_scanner source code
- [GitHub - AhmetSBulbul/document_scanner_kit](https://github.com/AhmetSBulbul/document_scanner_kit) - document_scanner_kit source code
- [GitHub - Ideeri/doc_scan](https://github.com/Ideeri/doc_scan) - doc_scan source code

---

## Appendix A: Decision Matrix

| Criterion | Weight | google_mlkit_document_scanner | flutter_doc_scanner | Keep ImageProcessor |
|-----------|--------|-------------------------------|---------------------|---------------------|
| **iOS Support** | 🔴 Critical | ❌ 0/10 (Android-only) | ✅ 8/10 (Via VisionKit) | ✅ 10/10 (Works on iOS) |
| **Inline Integration** | 🔴 Critical | ❌ 2/10 (Full UI flow) | ❌ 2/10 (Full UI flow) | ✅ 10/10 (Programmatic) |
| **Barcode Preprocessing** | 🟡 High | ⚠️ 3/10 (Wrong tool) | ⚠️ 3/10 (Wrong tool) | ✅ 7/10 (Sufficient) |
| **Simplicity** | 🟡 High | ⚠️ 4/10 (Platform channels) | ⚠️ 4/10 (Platform channels) | ✅ 10/10 (Existing code) |
| **Performance** | 🟢 Medium | ⚠️ 6/10 (ML overhead) | ⚠️ 6/10 (ML overhead) | ✅ 9/10 (< 500ms) |
| **Maintenance** | 🟢 Medium | ⚠️ 5/10 (Community pkg) | ⚠️ 5/10 (Community pkg) | ✅ 10/10 (No dependencies) |
| **Cross-platform** | 🟢 Medium | ❌ 0/10 (Android-only) | ✅ 8/10 (Both platforms) | ✅ 10/10 (Identical behavior) |

**Weighted Score:**
- **google_mlkit_document_scanner:** ❌ 2.8/10 (Fails iOS requirement)
- **flutter_doc_scanner:** ⚠️ 4.5/10 (Wrong use case)
- **Keep ImageProcessor:** ✅ 9.4/10 (Best fit)

**Recommendation:** Keep existing `ImageProcessor` approach.

---

## Appendix B: Implementation Effort Estimate

### If Integrating flutter_doc_scanner

**Effort:** 3-5 days (Medium complexity)

1. **Day 1: Setup & Configuration**
   - Add `flutter_doc_scanner` dependency
   - Configure iOS Info.plist (`NSCameraUsageDescription`)
   - Configure Android minSdkVersion (already 21+)
   - Platform-specific initialization

2. **Day 2: Camera Integration**
   - Replace inline camera with Document Scanner UI flow
   - Handle Android (PDF) vs iOS (PNG) output differences
   - Update upload pipeline to accept both formats
   - Test full workflow on both platforms

3. **Day 3: Backend Integration**
   - Update Talaria API to accept PDF files
   - Handle multi-page documents (if needed)
   - Test SSE streaming with new file formats
   - Performance testing

4. **Day 4: UX Refinement**
   - Handle edge cases (cancel, errors, rate limits)
   - Update haptic feedback for new flow
   - Test offline behavior
   - Update analytics tracking

5. **Day 5: Testing & Documentation**
   - Widget tests for new flow
   - Integration tests (Android + iOS)
   - Update CLAUDE.md documentation
   - Code review

**Risks:**
- ⚠️ Platform behavior differences (PDF vs PNG)
- ⚠️ UX disruption (full-screen scanner vs inline camera)
- ⚠️ Community package maintenance concerns
- ⚠️ No clear benefit over current approach

### Keeping Current ImageProcessor

**Effort:** 0 days (Already implemented)

**Future Enhancements (if needed):**
- **Contrast Enhancement:** 1-2 days (use `image` package)
- **Adaptive Thresholding:** 1-2 days (manual implementation)
- **Subject Segmentation:** 3-5 days (ML Kit integration)

---

## Appendix C: Phase 2 Task Status Update

**Task #9: [in_progress] Phase 2: Evaluate Document Scanner API**

**Status:** ✅ **COMPLETED** (Recommendation: Do NOT integrate)

**Next Steps:**
1. Mark task #9 as completed
2. Update task #11 to skip Document Scanner integration
3. Proceed with barcode detection using existing `ImageProcessor`
4. Consider Phase 3 enhancements (custom preprocessing) if barcode success rate is low

**Updated Phase 2 Plan:**
- ✅ Task #6: Add barcode overlay painter (DONE)
- ✅ Task #7: Auto-lookup ISBN on detection (DONE)
- ✅ Task #9: Evaluate Document Scanner API (DONE - Recommendation: Skip)
- ⏭️ Task #11: Skip Document Scanner integration, keep ImageProcessor
- ⏭️ Task #12: Performance comparison tests (barcode detection success rate)

---

**End of Evaluation Report**
