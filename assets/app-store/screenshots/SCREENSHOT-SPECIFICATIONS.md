# App Store Screenshot Specifications

## Device: 6.7" iPhone Pro Max (iPhone 15 Pro Max, 14 Pro Max)

**Resolution:** 1290 x 2796 pixels (3x scale)
**Aspect Ratio:** 19.5:9
**Format:** PNG or JPEG
**Color Space:** sRGB or Display P3
**File Size:** Max 500 KB per screenshot (PNG recommended)

## Required Screenshots (6 total)

Apple requires 1-10 screenshots. We're providing 6 to showcase core functionality:

### 1. Camera View (Home Screen)
**Filename:** `01-camera-view.png`
**Scene:** Active camera view with book spines visible in frame
**Overlay Text:** "Point and Scan" or "Catalog Your Books in Seconds"
**Purpose:** Show the primary interaction - camera scanning
**Key Elements:**
- Live camera viewfinder
- Shutter button (International Orange)
- Book spines visible in frame
- Clean OLED black UI borders

### 2. Scanning in Progress
**Filename:** `02-scanning-progress.png`
**Scene:** Progress indicator showing AI processing
**Overlay Text:** "AI-Powered Recognition" or "Identifying Your Books"
**Purpose:** Demonstrate the AI processing step
**Key Elements:**
- Progress bar or percentage indicator
- Book spine image captured
- SSE status updates visible
- Loading state UI

### 3. Library Grid View
**Filename:** `03-library-grid.png`
**Scene:** Grid of book covers in the library
**Overlay Text:** "Your Collection, Beautifully Organized"
**Purpose:** Show the main library interface
**Key Elements:**
- 2-3 columns of book covers
- At least 10-12 books visible
- Clean grid layout with borders
- Bottom navigation visible

### 4. Book Detail View
**Filename:** `04-book-detail.png`
**Scene:** Single book expanded with full metadata
**Overlay Text:** "Rich Metadata, Instant Access"
**Purpose:** Show detailed information for a single book
**Key Elements:**
- Large cover image
- Title, author, ISBN in JetBrains Mono
- Format, spine confidence score
- Edit/Delete actions
- Swiss design borders

### 5. Search Results
**Filename:** `05-search-results.png`
**Scene:** Search bar with filtered results
**Overlay Text:** "Lightning-Fast Full-Text Search"
**Purpose:** Demonstrate search functionality
**Key Elements:**
- Search bar with query visible
- Filtered results below
- FTS5 search in action
- Clear indication of matching terms

### 6. Settings/Export Screen
**Filename:** `06-settings-export.png`
**Scene:** Settings screen with export and privacy options
**Overlay Text:** "Your Data, Your Control"
**Purpose:** Highlight privacy, offline, export features
**Key Elements:**
- CSV Export button
- Offline mode indicator
- Device ID display (JetBrains Mono)
- Privacy-focused messaging

## Design Guidelines

### Swiss Utility Aesthetic
- OLED Black background: `#000000`
- International Orange accent: `#FF3B30`
- Border Gray: `#1C1C1E`
- Text Primary: `#FFFFFF`
- Text Secondary: `#8E8E93`

### Typography
- UI Text: Inter (Google Fonts)
- Numbers/ISBNs: JetBrains Mono

### Layout Principles
- Zero elevation on all components
- 1px solid borders instead of shadows
- High contrast for OLED displays
- Clean, functional, Swiss design

### Screenshot Overlay Text (Optional)
If adding marketing overlay text:
- Use Inter Bold 48-64pt
- White text with subtle shadow for readability
- Position at top or bottom, never over critical UI
- Keep text minimal and impactful

## How to Capture Screenshots

### Method 1: iOS Simulator (Recommended)
```bash
# Run app on iPhone 15 Pro Max simulator
flutter run -d "iPhone 15 Pro Max"

# Navigate to each screen and capture
# Simulator > Device > Screenshot (Cmd+S)
# Screenshots save to ~/Desktop
```

### Method 2: Physical Device
```bash
# Run on physical iPhone 15 Pro Max or 14 Pro Max
flutter run -d <device-id>

# Use device screenshot (Volume Up + Side Button)
# AirDrop to Mac for processing
```

### Method 3: Flutter Screenshot Tool
```bash
# Install screenshot testing package
flutter pub add integration_test

# Create integration test that navigates and captures
# Run: flutter drive --driver=test_driver/integration_test.dart
```

## Post-Processing

1. **Verify dimensions:** Must be exactly 1290 x 2796 pixels
2. **Optimize file size:** Compress to < 500 KB (use ImageOptim or similar)
3. **Check color space:** sRGB or Display P3
4. **Remove sensitive data:** No real personal ISBNs, sanitize device IDs
5. **Add overlay text (optional):** Use Figma or Sketch for professional results

## App Store Upload Order

Upload screenshots in this exact order:
1. Camera View
2. Scanning Progress
3. Library Grid
4. Book Detail
5. Search Results
6. Settings/Export

This order tells a story: Capture → Process → Organize → Explore → Search → Control

## Testing Checklist

- [ ] All screenshots are exactly 1290 x 2796 pixels
- [ ] File sizes are under 500 KB each
- [ ] Color space is sRGB or Display P3
- [ ] No personal or sensitive data visible
- [ ] UI matches current app build
- [ ] Swiss design aesthetic is consistent
- [ ] Text is readable at small sizes
- [ ] Screenshots tell a cohesive story
- [ ] All 6 screenshots are present
