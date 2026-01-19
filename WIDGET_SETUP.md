# iOS Widget Setup Instructions

This document explains how to complete the setup of the Wingtip iOS widget extension in Xcode.

## Overview

The widget files have been created in `ios/WingtipWidget/` but need to be added to the Xcode project manually.

## Setup Steps

### 1. Open the Xcode Project

```bash
open ios/Runner.xcworkspace
```

### 2. Add Widget Extension Target

1. In Xcode, click **File → New → Target**
2. Select **Widget Extension**
3. Configure the extension:
   - Product Name: `WingtipWidget`
   - Bundle Identifier: `com.ooheynerds.wingtip.WingtipWidget`
   - Language: Swift
   - **Important**: Uncheck "Include Configuration Intent"
4. Click **Finish**
5. When prompted about activating the scheme, click **Activate**

### 3. Remove Auto-Generated Files

Xcode will create some default files we don't need:

1. In the Project Navigator, find the `WingtipWidget` group
2. Delete these auto-generated files (Move to Trash):
   - `WingtipWidget.swift` (the default one)
   - `WingtipWidgetBundle.swift` (the default one)

### 4. Add Our Widget Files

1. In Finder, navigate to `ios/WingtipWidget/`
2. Drag these files into the `WingtipWidget` group in Xcode:
   - `WingtipWidget.swift`
   - `WingtipWidgetBundle.swift`
3. When prompted:
   - Check "Copy items if needed"
   - Select "Create groups"
   - Check the **WingtipWidget** target
   - Click **Add**

### 5. Update Info.plist

The widget's `Info.plist` should already exist at `ios/WingtipWidget/Info.plist`.

1. In Xcode, select the `WingtipWidget` target
2. Go to **Build Settings**
3. Search for "Info.plist"
4. Set **Info.plist File** to: `WingtipWidget/Info.plist`

### 6. Configure App Groups

App Groups allow data sharing between the main app and the widget.

#### For the Main App (Runner):

1. Select the **Runner** target
2. Go to **Signing & Capabilities**
3. Click **+ Capability**
4. Add **App Groups**
5. Click **+** and add: `group.com.ooheynerds.wingtip`
6. Check the box next to it

#### For the Widget Extension:

1. Select the **WingtipWidget** target
2. Go to **Signing & Capabilities**
3. Click **+ Capability**
4. Add **App Groups**
5. Click **+** and add: `group.com.ooheynerds.wingtip` (same as main app)
6. Check the box next to it

### 7. Configure Widget Target Settings

1. Select the **WingtipWidget** target
2. Go to **General**
3. Set:
   - **Deployment Target**: iOS 14.0 or higher
   - **Bundle Identifier**: `com.ooheynerds.wingtip.WingtipWidget`
4. Go to **Build Settings**
5. Search for "Swift Language Version"
6. Set to Swift 5 or later

### 8. Configure Signing

1. Select the **WingtipWidget** target
2. Go to **Signing & Capabilities**
3. Configure signing:
   - Team: Select your development team
   - Bundle Identifier: `com.ooheynerds.wingtip.WingtipWidget`
   - Signing Certificate: Select appropriate certificate

### 9. Build and Test

1. Select the **Runner** scheme (not WingtipWidget)
2. Build and run: `Cmd+R`
3. Once the app is running:
   - Long-press on the home screen
   - Tap the **+** button to add a widget
   - Find "Wingtip" in the widget gallery
   - Add either the small or medium widget
4. Scan a book in the app
5. Verify the widget updates with the new count

## Widget Features

### Small Widget
- Book icon (📚)
- Total count of scanned books
- "Books" label

### Medium Widget
- Total count on the left
- "Books Scanned" label
- Last scan date (relative time)
- Last scanned book cover (or placeholder) on the right

### Design
- OLED Black background (#000000)
- White text (#FFFFFF)
- Secondary text in gray (#8E8E93)
- 1px borders (#1C1C1E) - Swiss Utility design
- No shadows or elevation

### Deep Linking
- Tapping the widget opens the Wingtip app to the library view
- Uses the `wingtip://library` URL scheme

## Troubleshooting

### Widget Not Appearing
- Ensure App Groups are configured correctly on both targets
- Verify the bundle identifier is correct
- Check that the widget extension is embedded in the main app

### Widget Not Updating
- Check that the App Group ID matches in:
  - Runner target capabilities
  - WingtipWidget target capabilities
  - `AppDelegate.swift` (appGroupId constant)
  - `WingtipWidget.swift` (appGroupId constant)
- Verify all are: `group.com.ooheynerds.wingtip`

### Build Errors
- Clean build folder: `Cmd+Shift+K`
- Delete DerivedData: `~/Library/Developer/Xcode/DerivedData`
- Rebuild: `Cmd+B`

## Architecture

### Data Flow

1. **Book Saved** → `JobStateNotifier._saveBookResult()`
2. **Update Widget Data** → `WidgetDataService.updateWidgetData()`
3. **Platform Channel** → `WidgetChannel.updateWidgetData()`
4. **Native iOS** → `AppDelegate` writes to App Group UserDefaults
5. **Reload Widgets** → `WidgetCenter.shared.reloadAllTimelines()`
6. **Widget Reads** → `WingtipWidget` reads from App Group UserDefaults

### Files

#### Flutter/Dart:
- `lib/services/widget_data_service.dart` - Service to prepare widget data
- `lib/services/widget_channel.dart` - Platform channel communication
- `lib/features/talaria/job_state_notifier.dart` - Triggers widget updates after book saves

#### iOS/Swift:
- `ios/Runner/AppDelegate.swift` - Method channel handler, writes to App Group
- `ios/WingtipWidget/WingtipWidget.swift` - Widget UI and data loading
- `ios/WingtipWidget/WingtipWidgetBundle.swift` - Widget registration
- `ios/WingtipWidget/Info.plist` - Widget extension configuration
- `ios/Runner/Info.plist` - URL scheme configuration

## Testing Checklist

- [ ] Widget appears in iOS widget gallery
- [ ] Small widget displays correctly
- [ ] Medium widget displays correctly
- [ ] Widget shows "Open Wingtip to scan" when no books
- [ ] Widget updates immediately after scanning a book
- [ ] Book count is accurate
- [ ] Last scan date displays correctly
- [ ] Book cover loads (if available) or shows placeholder
- [ ] Tapping widget opens app to library view
- [ ] Widget respects Swiss Utility design (black background, 1px borders)
