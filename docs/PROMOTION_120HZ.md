# ProMotion 120Hz Optimization Guide

This document describes the ProMotion 120Hz optimizations implemented in Wingtip and how to verify them.

## iOS Configuration

### Info.plist Settings
The app is configured to support 120Hz on ProMotion displays:

```xml
<key>CADisableMinimumFrameDurationOnPhone</key>
<true/>
```

This setting is located in `ios/Runner/Info.plist:44-45`.

## Optimizations Implemented

### 1. Camera Preview Rendering
**File:** `lib/features/camera/camera_service.dart:43-50`

- Camera controller configured with `fps: null` to use device maximum frame rate
- `RepaintBoundary` wraps camera preview to isolate rendering
- Prevents unnecessary repaints during UI updates

### 2. Grid Scroll Optimization
**File:** `lib/features/library/library_screen.dart:492-523`

- `BouncingScrollPhysics` with `AlwaysScrollableScrollPhysics` for iOS-native feel
- Each grid item wrapped in `RepaintBoundary` for 120fps scroll performance
- Prevents cascade repaints when scrolling through book covers

### 3. List Scroll Optimization
**File:** `lib/features/library/library_screen.dart:632-658`

- Failed scans list uses same physics optimization
- `RepaintBoundary` per list item for smooth 120Hz scrolling

### 4. Animation Curves
All animations updated to use `Curves.easeOutCubic` for iOS-native feel:

- **Library grid animations** (`library_screen.dart:708-722`)
  - New book fade-in and scale animations
  - Cover image loading animations (`library_screen.dart:775-789`)

- **Book detail animations** (`book_detail_screen.dart:37-43`)
  - Hero transition fade animations

- **Camera overlays** (`stream_overlay.dart:34-38`)
  - Matrix-style SSE message overlay with `easeInCubic` reverse curve

- **Focus indicator** (`camera_screen.dart:430-432`)
  - Tap-to-focus animation with cubic easing

### 5. Performance Profiling
**Files:**
- `lib/core/performance_overlay_provider.dart` - State management
- `lib/main.dart:125,134` - MaterialApp integration
- `lib/features/library/library_screen.dart:318-333` - Toggle gesture

**How to use:**
1. Navigate to Library screen
2. Long-press on "Library" title text
3. Performance overlay appears showing:
   - GPU raster thread timing (top)
   - UI thread timing (bottom)
   - Frame target: 8.33ms (120fps) on ProMotion devices

## Verification Checklist

### Prerequisites
- iPhone 13 Pro or newer (ProMotion display required)
- iOS 15.0+ (ProMotion support)
- Build app in Release mode for accurate profiling

### Build Commands
```bash
# Clean build
flutter clean
flutter pub get

# Build and run in Release mode on iOS
flutter run --release -d iPhone

# Or build iOS app bundle
flutter build ios --release
```

### Performance Testing

#### 1. Enable Performance Overlay
1. Launch app and scan at least 10 books
2. Open Library screen
3. Long-press on "Library" title
4. Verify overlay appears with green bars

#### 2. Test Grid Scrolling
1. With overlay enabled, scroll through book grid rapidly
2. **Target:** Green bars stay below 8.33ms line
3. **Success criteria:** 0 dropped frames (no red bars)
4. Verify smooth 120Hz scroll feel with bouncing physics

#### 3. Test List Scrolling
1. Navigate to "Failed" tab (create failed scans if needed)
2. Scroll through failed scans list
3. **Target:** Green bars stay below 8.33ms line
4. **Success criteria:** 0 dropped frames during scroll

#### 4. Test Camera Preview
1. Return to Camera screen
2. With overlay enabled, observe camera preview rendering
3. **Target:** Smooth 120fps preview (8.33ms frame time)
4. Test pinch-to-zoom gesture - should maintain 120fps
5. Test tap-to-focus - animation should be buttery smooth

#### 5. Test Transitions
1. From Library, tap any book cover
2. Observe Hero animation to detail screen
3. **Success criteria:**
   - Smooth 120Hz transition
   - No visible stuttering
   - Fade animation uses cubic easing
4. Tap close button and verify reverse animation

#### 6. Test Stream Overlay
1. From Camera, capture a book spine
2. Watch for green matrix-style SSE messages
3. **Success criteria:**
   - Fade-in/out animations at 120fps
   - No jank when overlay appears/disappears

### Xcode Instruments Profiling

For deeper analysis, use Xcode Instruments:

```bash
# Build for profiling
flutter build ios --release --profile

# Open in Xcode
open ios/Runner.xcworkspace
```

1. Product → Profile (⌘I)
2. Select "Time Profiler" instrument
3. Run typical scan workflow:
   - Launch app
   - Capture 5 book spines
   - Navigate to Library
   - Scroll through grid
   - Open book details
4. Analyze flame graph for:
   - Frame drops > 8.33ms
   - Excessive widget rebuilds
   - Rasterization bottlenecks

### Expected Results

**120Hz Performance Targets:**
- Camera preview: 120fps (8.33ms per frame)
- Grid scroll: 120fps with 0 dropped frames
- List scroll: 120fps with 0 dropped frames
- Animations: Smooth cubic easing at 120Hz
- Hero transitions: No visible stutter

**Common Bottlenecks to Watch:**
- Image decoding (mitigated by `CachedNetworkImage`)
- Widget rebuild cascades (mitigated by `RepaintBoundary`)
- Animation jank (mitigated by iOS-native curves)

## Troubleshooting

### Performance Overlay Shows Red Bars
- Red bars = dropped frames (> 8.33ms render time)
- Check Xcode console for performance warnings
- Use Instruments to identify specific bottleneck

### Animations Feel Sluggish
- Verify device is iPhone 13 Pro or newer
- Check Settings → Accessibility → Motion → Reduce Motion is OFF
- Ensure app is built in Release mode, not Debug

### Camera Preview Stutters
- Check ResolutionPreset (current: `high`)
- Verify `fps: null` is set in CameraController
- Test on actual device, not simulator

### Grid Scroll Drops Frames
- Check if images are very large (should be cached)
- Verify RepaintBoundary is wrapping grid items
- Profile with Instruments to find widget rebuild issues

## Technical Background

### Why 8.33ms?
- 120Hz = 120 frames per second
- 1000ms / 120 = 8.33ms per frame
- Flutter must render each frame in < 8.33ms to maintain 120Hz

### ProMotion Adaptive Refresh
iOS automatically adjusts refresh rate based on content:
- Static UI: 10-80Hz (power saving)
- Scrolling/Animation: 120Hz
- Video: Content-matched (24/30/60fps)

### Flutter 120Hz Support
Flutter supports high refresh rates when:
1. Device has high-refresh display (ProMotion, Android 90/120Hz)
2. `CADisableMinimumFrameDurationOnPhone` enabled on iOS
3. Rendering pipeline optimized (RepaintBoundary, const widgets)
4. No blocking operations on UI thread

## References

- [Flutter Performance Best Practices](https://docs.flutter.dev/perf/best-practices)
- [iOS ProMotion Technology](https://developer.apple.com/documentation/quartzcore/optimizing_promotion_refresh_rates_for_iphone_13_pro_and_ipad_pro)
- [Flutter RepaintBoundary](https://api.flutter.dev/flutter/widgets/RepaintBoundary-class.html)
- [Curves Documentation](https://api.flutter.dev/flutter/animation/Curves-class.html)
