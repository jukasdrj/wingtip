# Wingtip - App Preview Video Script

## Specifications

**Duration:** 30 seconds (max allowed by App Store)
**Resolution:** 1080 x 1920 pixels (portrait, 9:16 aspect ratio)
**Frame Rate:** 30 fps minimum, 60 fps recommended for ProMotion
**Format:** .mp4 or .mov (H.264/HEVC codec)
**File Size:** Max 500 MB
**Audio:** Optional but recommended - subtle UI sounds, no music

## 30-Second Script

### 0:00-0:03 - Cold Open (3 seconds)
**Visual:** App launches from cold start to live camera view
**On-Screen Text:** "Wingtip"
**Voiceover/Caption:** "Catalog your books in seconds."
**Action:** Show the app icon tap and immediate launch to camera

### 0:03-0:08 - Camera Scanning (5 seconds)
**Visual:** Point camera at bookshelf, tap International Orange shutter button
**On-Screen Text:** None (UI speaks for itself)
**Voiceover/Caption:** "Just point and scan."
**Action:**
- Camera focuses on book spines
- User taps orange shutter button
- Light haptic feedback (visual indicator)
- Image captures and compresses

### 0:08-0:13 - AI Processing (5 seconds)
**Visual:** Progress indicator, SSE events streaming
**On-Screen Text:** "AI identifies your books"
**Voiceover/Caption:** "AI recognizes every title."
**Action:**
- Show progress: 0% → 50% → 100%
- Display SSE events updating in real-time
- Book metadata appears: title, author, cover
- Medium haptic feedback when book saved

### 0:13-0:19 - Library View (6 seconds)
**Visual:** Navigate to library grid showing 20+ books
**On-Screen Text:** "100% Offline"
**Voiceover/Caption:** "Your library, always offline."
**Action:**
- Swipe to library tab
- Show grid of books with covers
- Scroll smoothly through collection
- Tap a book to open detail view

### 0:19-0:24 - Search (5 seconds)
**Visual:** Tap search, type query, instant results
**On-Screen Text:** "Lightning-fast search"
**Voiceover/Caption:** "Find anything instantly."
**Action:**
- Tap search icon
- Type "Hemingway" (example)
- Results filter in real-time (FTS5)
- Show 3-4 matching results

### 0:24-0:27 - Export/Privacy (3 seconds)
**Visual:** Settings screen showing CSV export and device ID
**On-Screen Text:** "Your data. Your device."
**Voiceover/Caption:** "Export anytime. No tracking."
**Action:**
- Navigate to settings
- Highlight "Export CSV" button
- Show "Device ID" in monospace font
- Flash "No analytics" messaging

### 0:27-0:30 - Closing (3 seconds)
**Visual:** Return to camera view, ready to scan again
**On-Screen Text:** "Wingtip - Swiss Design, Zero Tracking"
**Voiceover/Caption:** "Wingtip. Built for iOS."
**Action:**
- Fade to app icon
- Display App Store download badge (optional)
- End on OLED black background with logo

## Production Notes

### Camera Settings
- Record at 60fps for smooth motion on ProMotion displays
- Use iOS screen recording (Settings > Control Center > Screen Recording)
- Or use QuickTime Player screen recording on Mac with connected iPhone

### Recording Command (Mac + iPhone)
```bash
# Connect iPhone via USB
# Open QuickTime Player > File > New Movie Recording
# Select iPhone as camera source
# Record at maximum quality
```

### Editing Requirements
1. **Trim to exactly 30 seconds** - App Store rejects longer videos
2. **Add subtle transitions** - Fade between major sections (optional)
3. **Overlay text** - Use Inter Bold, white text, positioned safely
4. **Audio** - Include UI sounds (haptics, taps, whoosh transitions)
5. **No music** - Keep it professional and functional
6. **Compress** - Export as H.264, keep under 500 MB

### Text Overlay Guidelines
- Font: Inter Bold 36-48pt
- Color: White (#FFFFFF) with 50% black shadow
- Position: Top or bottom safe area (avoid notch)
- Duration: 2-3 seconds per caption
- Animation: Simple fade in/out

### Key Moments to Emphasize
1. **Speed** - Show cold start < 1 second
2. **Simplicity** - One tap to scan, no complex UI
3. **Offline** - Explicitly show "No connection required" during library browsing
4. **Privacy** - Highlight local storage, no cloud sync
5. **Design** - Showcase Swiss aesthetic, OLED black, borders

### Voiceover Script (Optional)
If adding voiceover, keep it minimal and confident:

> "Wingtip. Catalog your books in seconds. Just point and scan. AI recognizes every title. Your library, always offline. Find anything instantly. Export anytime. No tracking. Wingtip. Built for iOS."

**Tone:** Direct, factual, Swiss precision. No hype, no fluff.
**Duration:** 30 seconds exactly
**Voice:** Neutral, professional, medium pace

## Alternative: Silent Version
If no voiceover:
- Let UI and text overlays tell the story
- Use subtle UI sounds (taps, whoosh, success chimes)
- Focus on visual clarity and smooth interactions
- Ensure text overlays are concise and readable

## Technical Checklist

- [ ] Video is exactly 30 seconds or less
- [ ] Resolution is 1080 x 1920 (portrait)
- [ ] Frame rate is 30 fps minimum (60 fps preferred)
- [ ] Format is .mp4 or .mov (H.264/HEVC)
- [ ] File size is under 500 MB
- [ ] No personal data visible (sanitize ISBNs, device IDs)
- [ ] App version in video matches submitted build
- [ ] UI matches current screenshots
- [ ] All interactions are smooth (no lag or freezing)
- [ ] Text overlays are readable at small sizes
- [ ] Video demonstrates core value proposition
- [ ] Complies with App Store Review Guidelines

## Post-Production Tools

### Recommended Software
- **iMovie** (Mac/iOS) - Simple, free, good enough
- **Final Cut Pro** (Mac) - Professional, advanced features
- **Adobe Premiere** - Industry standard, overkill for this
- **DaVinci Resolve** - Free, powerful color grading

### Compression Settings
```
Codec: H.264
Resolution: 1080 x 1920
Frame Rate: 60 fps
Bitrate: 5-10 Mbps (variable)
Audio: AAC 128 kbps (if using audio)
```

## App Store Upload Notes

- Upload to App Store Connect > App Previews and Screenshots
- Select "iPhone 6.7 Display" device size
- Can upload up to 3 app preview videos per device size
- We're uploading 1 comprehensive 30-second preview
- Video autoplays on App Store (muted by default)
- First 3 seconds are critical for engagement

## Testing Before Upload

1. **Watch on iPhone** - AirDrop video to iPhone and view full-screen
2. **Mute test** - Watch without sound, ensure story is clear
3. **Small size test** - View thumbnail in grid, ensure it's compelling
4. **Timing check** - Verify exactly 30 seconds, not 30.5 or 29.5
5. **Quality check** - No pixelation, artifacts, or stuttering
6. **Accuracy check** - UI matches current build, no outdated features

## Version Control

Store the video source files and exported video:
```
assets/app-store/video/
├── APP-PREVIEW-SCRIPT.md (this file)
├── wingtip-app-preview.mov (final export)
└── source/ (optional - raw recordings, project files)
    ├── raw-recording.mov
    ├── wingtip-preview.fcpbundle (Final Cut project)
    └── overlay-assets/ (text overlays, logo, etc.)
```
