# Wingtip - App Store Assets

This directory contains all assets and documentation required for App Store submission.

## Directory Structure

```
assets/app-store/
├── README.md (this file)
├── SUBMISSION-CHECKLIST.md
├── screenshots/
│   ├── SCREENSHOT-SPECIFICATIONS.md
│   ├── 01-camera-view.png (1290 x 2796) - TO BE CAPTURED
│   ├── 02-scanning-progress.png (1290 x 2796) - TO BE CAPTURED
│   ├── 03-library-grid.png (1290 x 2796) - TO BE CAPTURED
│   ├── 04-book-detail.png (1290 x 2796) - TO BE CAPTURED
│   ├── 05-search-results.png (1290 x 2796) - TO BE CAPTURED
│   └── 06-settings-export.png (1290 x 2796) - TO BE CAPTURED
├── video/
│   ├── APP-PREVIEW-SCRIPT.md
│   ├── wingtip-app-preview.mov (1080 x 1920, 30s) - TO BE RECORDED
│   └── source/ (optional - raw recordings)
└── metadata/
    ├── app-store-description.md
    ├── APP-ICON-SPECIFICATIONS.md
    └── keywords-analysis.md (optional)
```

## Quick Start

### 1. Capture Screenshots
```bash
# Run app on iPhone 15 Pro Max simulator
flutter run -d "iPhone 15 Pro Max"

# Navigate to each screen and capture (Cmd+S in Simulator)
# Screenshots save to ~/Desktop
# Move them to assets/app-store/screenshots/
```

See `screenshots/SCREENSHOT-SPECIFICATIONS.md` for detailed requirements.

### 2. Record App Preview Video
```bash
# Use iOS Screen Recording or QuickTime Player
# Record 30-second demo following APP-PREVIEW-SCRIPT.md
# Edit to exactly 30 seconds
# Export as .mov or .mp4 (H.264)
# Save to assets/app-store/video/
```

See `video/APP-PREVIEW-SCRIPT.md` for detailed script.

### 3. Verify App Icon
```bash
# Check existing icon
ls -lh ../icon/icon.png

# Should be 1024 x 1024 pixels
# Already generated and ready for submission ✅
```

See `metadata/APP-ICON-SPECIFICATIONS.md` for details.

### 4. Review Metadata
- App Store description: `metadata/app-store-description.md`
- Privacy policy: `../../PRIVACY.md`
- Support documentation: `../../SUPPORT.md`

### 5. Submit to App Store Connect
Follow `SUBMISSION-CHECKLIST.md` for step-by-step submission process.

## Asset Requirements Summary

### Screenshots (Required)
- **Device:** iPhone 6.7" Display (15 Pro Max, 14 Pro Max)
- **Resolution:** 1290 x 2796 pixels
- **Format:** PNG or JPEG
- **Quantity:** 1-10 (we're providing 6)
- **File size:** < 500 KB each

### App Preview Video (Optional but Recommended)
- **Resolution:** 1080 x 1920 pixels (portrait)
- **Duration:** Up to 30 seconds
- **Format:** .mp4 or .mov (H.264/HEVC)
- **File size:** < 500 MB
- **Frame rate:** 30 fps minimum, 60 fps recommended

### App Icon (Required)
- **Resolution:** 1024 x 1024 pixels
- **Format:** PNG (no alpha channel)
- **Location:** `../icon/icon.png` ✅
- **Status:** Already generated and ready

### Metadata (Required)
- App name, subtitle, description
- Keywords (100 characters max)
- Privacy policy URL
- Support URL
- Category, age rating
- Version information

## Status Tracking

### ✅ Completed
- [x] App icon (1024x1024) - `../icon/icon.png`
- [x] App Store description written
- [x] Privacy policy created
- [x] Support documentation created
- [x] Screenshot specifications documented
- [x] App preview video script written
- [x] App icon specifications documented

### 📸 To Be Captured (Manual)
- [ ] Screenshot 1: Camera View
- [ ] Screenshot 2: Scanning Progress
- [ ] Screenshot 3: Library Grid
- [ ] Screenshot 4: Book Detail
- [ ] Screenshot 5: Search Results
- [ ] Screenshot 6: Settings/Export

### 🎥 To Be Recorded (Manual)
- [ ] 30-second app preview video

### 🔍 To Be Verified (Before Submission)
- [ ] All screenshots are 1290 x 2796
- [ ] Video is exactly 30 seconds or less
- [ ] No personal data in screenshots/video
- [ ] App icon meets all requirements
- [ ] Privacy policy URL is live and accessible
- [ ] Support URL is live and accessible
- [ ] Metadata copy is proofread
- [ ] Keywords are optimized

## Tools and Resources

### Capturing Screenshots
- **iOS Simulator:** `flutter run -d "iPhone 15 Pro Max"`
- **Keyboard shortcut:** Cmd+S (saves to ~/Desktop)
- **Alternative:** Physical device Volume Up + Side Button

### Recording Video
- **iOS Screen Recording:** Settings > Control Center > Screen Recording
- **QuickTime Player:** File > New Movie Recording (Mac + connected iPhone)
- **Editing:** iMovie, Final Cut Pro, DaVinci Resolve

### Image Optimization
- **ImageOptim:** https://imageoptim.com/ (Mac)
- **TinyPNG:** https://tinypng.com/ (web-based)
- **sips (CLI):** `sips -Z 500 image.png` (resize/compress)

### Design Tools
- **Figma:** For creating marketing overlays (optional)
- **Sketch:** Alternative design tool
- **Affinity Designer:** Budget-friendly option

## Best Practices

### Screenshot Guidelines
1. Show the app in actual use (not empty states)
2. Use real book data (but sanitize ISBNs if sensitive)
3. Ensure UI is pixel-perfect (no bugs or glitches)
4. Maintain Swiss design aesthetic (OLED black, high contrast)
5. Tell a story: Scan → Process → Organize → Explore

### Video Guidelines
1. Keep it under 30 seconds (App Store hard limit)
2. Show most important features first (first 3 seconds critical)
3. Smooth transitions, no lag or stuttering
4. Include subtle UI sounds (taps, haptics)
5. No background music (keep it professional)

### Metadata Guidelines
1. Front-load keywords in description (first 170 characters)
2. Use bullet points for readability
3. Emphasize unique value props: local-first, privacy, Swiss design
4. Include call-to-action: "Download now" or "Get started"
5. Optimize keywords for search (use App Store analytics)

## App Store Connect Upload Steps

### 1. Prepare Binary
```bash
# Archive for release
flutter build ios --release

# Open in Xcode
open ios/Runner.xcworkspace

# Product > Archive
# Validate and upload to App Store Connect
```

### 2. Upload Assets
1. Log in to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to your app
3. Click on version (e.g., 1.0.0)
4. Upload screenshots to "iPhone 6.7 Display" section
5. Upload app preview video (optional)
6. Verify app icon appears correctly

### 3. Enter Metadata
1. App name: "Wingtip"
2. Subtitle: "Local-first library manager"
3. Description: Copy from `metadata/app-store-description.md`
4. Keywords: Copy from metadata file
5. Support URL: `https://github.com/yourusername/wingtip/blob/main/SUPPORT.md`
6. Privacy URL: `https://github.com/yourusername/wingtip/blob/main/PRIVACY.md`

### 4. Configure Privacy Labels
- Data Used to Track You: **None**
- Data Linked to You: **None**
- Data Not Linked to You:
  - ✅ User Content (book spine images, temporary)
  - ✅ Identifiers (device UUID, rate limiting only)

### 5. Submit for Review
1. Answer App Review questions
2. Add notes for reviewer (if needed)
3. Submit

## Testing Before Submission

### Internal Testing
- [ ] Install release build on test device
- [ ] Verify all features work
- [ ] Test camera scanning
- [ ] Test offline library browsing
- [ ] Test search functionality
- [ ] Test CSV export
- [ ] Check performance (cold start < 1s)

### Screenshot Verification
- [ ] All screenshots show current UI
- [ ] No debug overlays or developer tools visible
- [ ] Text is readable at thumbnail size
- [ ] Images are high-quality (no pixelation)
- [ ] Correct dimensions (1290 x 2796)

### Video Verification
- [ ] Plays smoothly on iPhone
- [ ] Audio is clear (if included)
- [ ] Exactly 30 seconds or less
- [ ] Shows key features in logical order
- [ ] No personal data visible

### Metadata Verification
- [ ] No typos or grammatical errors
- [ ] Keywords are relevant and optimized
- [ ] URLs are live and accessible
- [ ] Privacy policy is accurate
- [ ] Support contact information is correct

## Post-Submission

### Expected Timeline
- **Submission:** Day 0
- **In Review:** 24-48 hours
- **Review Duration:** 1-3 days (average)
- **Approval/Rejection:** Day 2-5

### If Approved
1. App goes live on App Store
2. Monitor reviews and ratings
3. Respond to user feedback
4. Plan future updates

### If Rejected
1. Read rejection reason carefully
2. Fix issues identified by App Review
3. Resubmit with changes
4. Common rejection reasons:
   - Inaccurate screenshots
   - Missing privacy policy
   - Broken functionality
   - Guideline violations

## Version Control

All assets in this directory should be committed to git:
```bash
git add assets/app-store/
git commit -m "feat: Add App Store assets for v1.0.0"
```

For binary assets (screenshots, video):
- Consider using Git LFS for large files
- Or store links to external hosting (Dropbox, Google Drive)
- Include checksums for verification

## Contact

Questions about App Store submission?
- **Email:** [your-email@example.com]
- **GitHub Issues:** [https://github.com/yourusername/wingtip/issues](https://github.com/yourusername/wingtip/issues)

## Resources

### Apple Documentation
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [App Store Product Page](https://developer.apple.com/app-store/product-page/)
- [App Preview Specifications](https://developer.apple.com/help/app-store-connect/reference/app-preview-specifications)
- [Screenshot Specifications](https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications)

### Flutter Resources
- [Flutter iOS Deployment](https://docs.flutter.dev/deployment/ios)
- [Flutter Build Modes](https://docs.flutter.dev/testing/build-modes)

### Design Resources
- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [SF Symbols](https://developer.apple.com/sf-symbols/) (for icons)

---

**Wingtip** - Swiss design, zero tracking.
