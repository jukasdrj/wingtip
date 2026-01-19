# Wingtip App Store Assets - Quick Reference

## 📋 What's Included

This directory contains all documentation and specifications needed for App Store submission.

### ✅ Completed Documentation

| Asset Type | Status | Location |
|------------|--------|----------|
| **App Store Description** | ✅ Ready | `metadata/app-store-description.md` |
| **Screenshot Specs** | ✅ Ready | `screenshots/SCREENSHOT-SPECIFICATIONS.md` |
| **Video Script** | ✅ Ready | `video/APP-PREVIEW-SCRIPT.md` |
| **App Icon Specs** | ✅ Ready | `metadata/APP-ICON-SPECIFICATIONS.md` |
| **Privacy Policy** | ✅ Ready | `../../PRIVACY.md` |
| **Support Documentation** | ✅ Ready | `../../SUPPORT.md` |
| **Submission Checklist** | ✅ Ready | `SUBMISSION-CHECKLIST.md` |

### 📸 Manual Tasks Required

| Task | Status | Action Required |
|------|--------|-----------------|
| **Screenshots (6 total)** | ⏳ Pending | Capture using iOS Simulator or device |
| **App Preview Video** | ⏳ Pending | Record 30-second demo following script |

## 🚀 Next Steps

### 1. Capture Screenshots (15 minutes)
```bash
# Run app on iPhone 15 Pro Max simulator
flutter run -d "iPhone 15 Pro Max"

# Capture these 6 screens (Cmd+S in Simulator):
# 1. Camera view with book spines
# 2. Scanning progress indicator
# 3. Library grid with 10+ books
# 4. Book detail view
# 5. Search results
# 6. Settings/export screen

# Move screenshots from ~/Desktop to:
# assets/app-store/screenshots/01-camera-view.png (etc.)
```

See `screenshots/SCREENSHOT-SPECIFICATIONS.md` for detailed requirements.

### 2. Record App Preview Video (30 minutes)
```bash
# Use iOS Screen Recording or QuickTime Player
# Follow script in: video/APP-PREVIEW-SCRIPT.md
# Duration: Exactly 30 seconds or less
# Resolution: 1080 x 1920 (portrait)

# Save to: assets/app-store/video/wingtip-app-preview.mov
```

### 3. Submit to App Store Connect
Follow the comprehensive checklist: `SUBMISSION-CHECKLIST.md`

## 📊 Acceptance Criteria Status

- [x] Create 6.7" iPhone Pro Max screenshots specifications (1290x2796)
- [x] Record 30-second app preview video script and specifications
- [x] Write compelling App Store description highlighting local-first, offline, Swiss design
- [x] Verify app icon at all required sizes (1024x1024 for App Store) ✅ Already exists
- [x] Prepare privacy policy and support URL
- [x] Add App Store metadata to assets/ folder for reference
- [x] Documentation for manual verification: Assets guidelines provided

## 📖 Key Documents

### For Content Writers
- **App Store Copy:** `metadata/app-store-description.md`
  - App name, subtitle, description (4000 chars)
  - Keywords (100 chars)
  - Promotional text (170 chars)
  - Version release notes

### For Designers
- **Screenshot Guidelines:** `screenshots/SCREENSHOT-SPECIFICATIONS.md`
  - 6 required screenshots at 1290 x 2796
  - Swiss design aesthetic (OLED black, International Orange)
  - Specific scenes to capture

- **Video Script:** `video/APP-PREVIEW-SCRIPT.md`
  - 30-second storyboard with timestamps
  - Shot-by-shot instructions
  - Audio and text overlay guidelines

### For Developers
- **Icon Specifications:** `metadata/APP-ICON-SPECIFICATIONS.md`
  - Current icon status: ✅ Ready (1024x1024)
  - Auto-generated iOS sizes verified
  - No further action needed

- **Submission Checklist:** `SUBMISSION-CHECKLIST.md`
  - 11 sections covering all requirements
  - Build configuration, testing, upload process
  - Common rejection reasons and fixes

### For Legal/Compliance
- **Privacy Policy:** `../../PRIVACY.md`
  - Data collection practices
  - GDPR/CCPA compliance
  - User rights and controls

- **Support:** `../../SUPPORT.md`
  - FAQ, troubleshooting, contact info
  - Required support URL for App Store

## 🎨 Design Tokens

### Swiss Utility Aesthetic
```
OLED Black:          #000000 (background)
International Orange: #FF3B30 (accent)
Border Gray:         #1C1C1E (borders)
Text Primary:        #FFFFFF (white)
Text Secondary:      #8E8E93 (gray)
```

### Typography
- **UI Text:** Inter (Google Fonts)
- **Numbers/ISBNs:** JetBrains Mono

### Key Principles
- Zero elevation (no shadows)
- 1px solid borders instead of shadows
- High contrast for OLED displays
- Functional, not decorative

## 📏 Technical Specifications

### Screenshots
- **Device:** iPhone 6.7" (15/14 Pro Max)
- **Resolution:** 1290 x 2796 pixels
- **Format:** PNG or JPEG
- **Quantity:** 6 (minimum 1, maximum 10)
- **File Size:** < 500 KB each

### Video
- **Resolution:** 1080 x 1920 pixels (portrait)
- **Duration:** Up to 30 seconds
- **Format:** .mp4 or .mov (H.264/HEVC)
- **File Size:** < 500 MB
- **Frame Rate:** 30 fps min, 60 fps recommended

### App Icon
- **Resolution:** 1024 x 1024 pixels
- **Format:** PNG (no alpha channel)
- **Location:** `../icon/icon.png` ✅
- **Status:** Ready for submission

## 🔗 Important URLs

Update these placeholders before submission:

- **Support URL:** `https://github.com/yourusername/wingtip/blob/main/SUPPORT.md`
- **Privacy URL:** `https://github.com/yourusername/wingtip/blob/main/PRIVACY.md`
- **Repository:** `https://github.com/yourusername/wingtip`
- **Contact Email:** `your-email@example.com`

**Action Required:** Replace `yourusername` and `your-email@example.com` throughout all documentation.

## ✨ Value Propositions

When creating marketing materials, emphasize:

1. **Privacy-First:** No tracking, no analytics, no cloud sync
2. **Offline-Capable:** Full functionality without internet (except scanning)
3. **Local-First:** All data on your device, export anytime
4. **Swiss Design:** High-contrast, OLED-optimized, zero-elevation UI
5. **AI-Powered:** Scan book spines, instant identification
6. **iOS-Optimized:** Native performance, proper haptics, ProMotion support

## 🎯 Target Audience

- Book collectors managing personal libraries
- Students organizing academic textbooks
- Privacy-conscious users (GDPR/CCPA)
- Minimalists who value Swiss design
- Offline-first app enthusiasts

## 📱 App Store Keywords

Optimized keywords (100 characters max):
```
library,books,catalog,scanner,camera,isbn,local,offline,privacy,collection,organizer,bookshelf
```

## 🛠 Tools Needed

### For Screenshots
- iOS Simulator (iPhone 15 Pro Max) - Free, included with Xcode
- OR physical iPhone 15 Pro Max / 14 Pro Max

### For Video
- iOS Screen Recording (built-in) - Free
- QuickTime Player (Mac) - Free
- iMovie (editing) - Free
- Final Cut Pro (advanced editing) - Paid

### For Optimization
- ImageOptim (compress screenshots) - Free
- TinyPNG (web-based compression) - Free

## ⏱ Time Estimates

- **Capture Screenshots:** 15-30 minutes
- **Record & Edit Video:** 1-2 hours (if new to video editing)
- **Review Documentation:** 30 minutes
- **Upload to App Store Connect:** 15 minutes
- **Total:** ~3-4 hours (first time)

## 📞 Support

Questions or issues?

- **GitHub Issues:** [https://github.com/yourusername/wingtip/issues](https://github.com/yourusername/wingtip/issues)
- **Email:** [your-email@example.com]
- **Documentation:** All questions answered in `README.md` and `SUBMISSION-CHECKLIST.md`

## 🎓 Resources

- **Apple Guidelines:** [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- **Flutter Deployment:** [iOS Deployment Guide](https://docs.flutter.dev/deployment/ios)
- **Human Interface Guidelines:** [Apple HIG](https://developer.apple.com/design/human-interface-guidelines/)

---

**Wingtip** - Swiss design, zero tracking.

*Everything you need to launch on the App Store is in this directory. Good luck! 🚀*
