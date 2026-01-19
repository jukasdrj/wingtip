# Wingtip - App Icon Specifications

## Current Status

✅ **App icon already exists at required size:**
- Location: `assets/icon/icon.png`
- Resolution: 1024 x 1024 pixels
- Format: PNG (8-bit RGB)

## App Store Requirements

### Primary App Icon (App Store)
- **Resolution:** 1024 x 1024 pixels
- **Format:** PNG (no alpha channel for iOS)
- **Color Space:** sRGB or Display P3
- **File Size:** Max 1 MB
- **Purpose:** Displayed in App Store listings
- **Current File:** `assets/icon/icon.png` ✅

### iOS App Bundle Icons (Auto-Generated)
The following sizes are automatically generated from the 1024x1024 source using `flutter_launcher_icons`:

| Size (points) | Scale | Pixels       | Usage                          |
|---------------|-------|--------------|--------------------------------|
| 20x20         | @2x   | 40 x 40      | iPhone Notification            |
| 20x20         | @3x   | 60 x 60      | iPhone Notification            |
| 29x29         | @2x   | 58 x 58      | iPhone Settings                |
| 29x29         | @3x   | 87 x 87      | iPhone Settings                |
| 40x40         | @2x   | 80 x 80      | iPhone Spotlight               |
| 40x40         | @3x   | 120 x 120    | iPhone Spotlight               |
| 60x60         | @2x   | 120 x 120    | iPhone App                     |
| 60x60         | @3x   | 180 x 180    | iPhone App (Home Screen)       |
| 76x76         | @2x   | 152 x 152    | iPad App                       |
| 83.5x83.5     | @2x   | 167 x 167    | iPad Pro                       |
| 1024x1024     | @1x   | 1024 x 1024  | App Store                      |

All of these are already generated and stored in:
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/` ✅

## Design Guidelines

### Swiss Utility Icon Design
The Wingtip icon should embody Swiss design principles:

**Visual Elements:**
- Clean, geometric shapes
- High contrast (black background, white/orange foreground)
- Minimal detail (recognizable at small sizes)
- No gradients, no shadows (flat design)
- Functional, not decorative

**Color Palette:**
- Background: OLED Black `#000000`
- Primary: International Orange `#FF3B30`
- Accent: White `#FFFFFF` or Border Gray `#1C1C1E`

**Concept Ideas:**
1. **Book Spine Icon** - Stylized book spine with title lines
2. **Camera Crosshair** - Viewfinder focusing on book outline
3. **Wing Symbol** - Abstract wing shape (Wingtip = wing of plane/bird)
4. **Scan Lines** - Horizontal scan lines over book shape
5. **Swiss Cross + Book** - Swiss cross integrated with book form

**Recommended Approach:**
- Simple geometric book shape (white outline on black)
- International Orange accent (camera dot or scan line)
- Instantly recognizable as book-related
- Distinct from other library/reading apps

## Regenerating Icons

If the icon needs to be updated:

```bash
# 1. Replace the source icon
cp new-icon.png assets/icon/icon.png

# 2. Verify it's 1024x1024
sips -g pixelWidth -g pixelHeight assets/icon/icon.png

# 3. Generate all iOS/Android sizes
flutter pub run flutter_launcher_icons

# 4. Clean and rebuild
flutter clean
flutter pub get
flutter build ios --release
```

## Configuration

Icon generation is configured in `pubspec.yaml`:

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon/icon.png"
  adaptive_icon_background: "#000000"
  adaptive_icon_foreground: "assets/icon/icon.png"
  remove_alpha_ios: true
```

**Key Settings:**
- `remove_alpha_ios: true` - Removes alpha channel for iOS compliance
- `adaptive_icon_background: "#000000"` - Black background for Android adaptive icons
- Source file must be 1024x1024 minimum

## Quality Checklist

### Visual Quality
- [ ] Icon is recognizable at 40x40 pixels (smallest size)
- [ ] High contrast for OLED black backgrounds
- [ ] No fine details that blur at small sizes
- [ ] No text or wordmarks (icons should be symbolic)
- [ ] Consistent with app's Swiss design aesthetic

### Technical Quality
- [ ] 1024 x 1024 pixels (exact dimensions)
- [ ] PNG format with no alpha channel (iOS requirement)
- [ ] sRGB color space
- [ ] File size under 1 MB
- [ ] No compression artifacts
- [ ] Crisp edges, no anti-aliasing issues

### App Store Compliance
- [ ] No Apple hardware depicted (no iPhone/iPad shapes)
- [ ] No Apple design elements (no SF Symbols)
- [ ] No trademark violations (no copyrighted logos)
- [ ] No misleading imagery (icon matches app functionality)
- [ ] Follows Human Interface Guidelines

## Testing Icon Appearance

### Test on Device
```bash
# Build and install on test device
flutter build ios --release
flutter install

# Check icon on:
# - Home screen (60x60@3x = 180x180)
# - Settings (29x29@3x = 87x87)
# - Spotlight search (40x40@3x = 120x120)
# - Notifications (20x20@3x = 60x60)
```

### Test in App Store Connect
1. Upload build to TestFlight
2. View icon in TestFlight app list
3. Verify icon in App Store Connect > App Information
4. Check appearance on both light and dark mode (device settings)

### Visual Tests
- **Small size:** Does it read clearly at 40x40?
- **Dark backgrounds:** Does it stand out on black?
- **Light backgrounds:** Does it work on white (Settings app)?
- **Notification badges:** Does the red badge obscure important details?
- **Quick glance:** Is it instantly recognizable in a grid of apps?

## Alternative Icon Ideas

If the current icon needs refinement, consider these concepts:

### Option 1: Minimalist Book Spine
```
╔═══════════╗
║           ║  <- White outline
║    ―――    ║  <- Orange title lines
║    ―――    ║
║           ║
╚═══════════╝
Black background
```

### Option 2: Camera Viewfinder
```
┌─┐     ┌─┐  <- White corners
│ │ 📖  │ │  <- Orange book icon in center
└─┘     └─┘
Black background
```

### Option 3: Wingtip Literal (Bird Wing)
```
     ╱╲     <- White wing shape
    ╱  ╲
   ╱ ● ╲   <- Orange dot (camera/eye)
  ╱      ╲
Black background
```

### Option 4: Scan Lines
```
━━━━━━━━━━
    📖       <- White book
━━━━━━━━━━  <- Orange scan lines
Black background
```

**Recommended:** Option 1 or 2 - most clearly communicates "book scanning"

## File Locations

### Source Icon
- `assets/icon/icon.png` - 1024x1024 master file

### Generated iOS Icons
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png` - All iOS sizes

### Generated Android Icons
- `android/app/src/main/res/mipmap-*dpi/ic_launcher.png` - Android sizes

### App Store Upload
- Upload `assets/icon/icon.png` directly to App Store Connect
- Or let Xcode handle it automatically from Assets.xcassets

## Version Control

Current icon is committed at:
```
assets/icon/icon.png (1024 x 1024)
```

If updating icon:
1. Commit new source file
2. Run `flutter_launcher_icons`
3. Commit all generated files
4. Update changelog with "Updated app icon"

## Resources

- [Apple Human Interface Guidelines - App Icons](https://developer.apple.com/design/human-interface-guidelines/app-icons)
- [flutter_launcher_icons package](https://pub.dev/packages/flutter_launcher_icons)
- [iOS App Icon Generator](https://www.appicon.co/)
- [Icon design tools: Figma, Sketch, Affinity Designer]

## Notes

The current icon at `assets/icon/icon.png` meets all App Store requirements:
- ✅ Correct dimensions (1024x1024)
- ✅ Correct format (PNG)
- ✅ Ready for upload
- ✅ All iOS sizes auto-generated

**No further action required for icon creation.** The existing icon is ready for App Store submission.
