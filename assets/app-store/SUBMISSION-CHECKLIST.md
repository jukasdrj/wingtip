# App Store Submission Checklist for Wingtip

Use this checklist to ensure all requirements are met before submitting to the App Store.

## Pre-Submission Requirements

### 1. Development & Testing

#### Code Quality
- [ ] All features are implemented and working
- [ ] No debug code or console logs in production build
- [ ] No hardcoded test data or mock services
- [ ] All TODOs and FIXMEs are resolved or documented
- [ ] Code passes `flutter analyze` with no errors
- [ ] All tests pass: `flutter test`

#### Performance
- [ ] Cold start time < 1 second (measured)
- [ ] Camera initializes within 500ms
- [ ] Search is instant (< 100ms)
- [ ] No memory leaks detected
- [ ] App runs smoothly on target devices (iPhone 12+)
- [ ] Battery usage is acceptable

#### Error Handling
- [ ] Camera permission denial handled gracefully
- [ ] Network errors display user-friendly messages
- [ ] Rate limiting shows countdown timer
- [ ] Database errors are caught and logged
- [ ] App doesn't crash on bad input

#### Offline Functionality
- [ ] Library browsing works offline
- [ ] Search works offline
- [ ] CSV export works offline
- [ ] Only scanning requires network (clearly indicated)

### 2. Build Configuration

#### Version Information
- [ ] Version number updated in `pubspec.yaml` (currently 1.0.0+1)
- [ ] Build number incremented (1 for first submission)
- [ ] Version string matches marketing version

#### iOS Configuration
- [ ] Bundle identifier is correct: `com.yourcompany.wingtip`
- [ ] Display name is "Wingtip"
- [ ] Minimum iOS version is set (e.g., iOS 14.0)
- [ ] Supported devices: iPhone (portrait only)
- [ ] Capabilities configured in Xcode:
  - [ ] Camera usage
  - [ ] Network access
- [ ] Signing configured (App Store distribution certificate)

#### Permissions & Entitlements
- [ ] Camera permission description in Info.plist:
  ```xml
  <key>NSCameraUsageDescription</key>
  <string>Wingtip needs camera access to scan book spines and identify titles.</string>
  ```
- [ ] Network usage description (if required)
- [ ] Keychain sharing enabled for device UUID storage

### 3. App Store Assets

#### Screenshots (1290 x 2796 pixels)
- [ ] 01-camera-view.png - Camera with book spines visible
- [ ] 02-scanning-progress.png - AI processing with progress indicator
- [ ] 03-library-grid.png - Grid of books in library
- [ ] 04-book-detail.png - Single book detail view
- [ ] 05-search-results.png - Search with filtered results
- [ ] 06-settings-export.png - Settings with export/privacy features

**Verification:**
- [ ] All screenshots are exactly 1290 x 2796 pixels
- [ ] File sizes are under 500 KB each
- [ ] No personal or sensitive data visible
- [ ] UI matches current build (no outdated screenshots)
- [ ] Images are high-quality (no compression artifacts)

#### App Preview Video (Optional but Recommended)
- [ ] Video is recorded (1080 x 1920 pixels, portrait)
- [ ] Duration is exactly 30 seconds or less
- [ ] Format is .mov or .mp4 (H.264/HEVC codec)
- [ ] File size is under 500 MB
- [ ] No personal data visible
- [ ] Demonstrates core workflow: Scan → Process → Library → Search

#### App Icon
- [ ] Icon exists at `assets/icon/icon.png` (1024 x 1024)
- [ ] All iOS sizes generated via `flutter_launcher_icons`
- [ ] Icon appears correctly in Xcode Assets.xcassets
- [ ] Icon follows Apple guidelines (no transparency, no rounded corners)
- [ ] Icon is recognizable at small sizes

### 4. Metadata & Copy

#### App Information
- [ ] App name: "Wingtip" (under 30 characters)
- [ ] Subtitle: "Local-first library manager" (under 30 characters)
- [ ] Primary category: Productivity
- [ ] Secondary category: Reference (optional)
- [ ] Age rating: 4+ (no objectionable content)

#### Description
- [ ] Full description written (from `metadata/app-store-description.md`)
- [ ] Under 4000 characters
- [ ] Highlights key features: camera scanning, offline-first, privacy, Swiss design
- [ ] No typos or grammatical errors
- [ ] Includes clear value proposition in first 170 characters

#### Keywords
- [ ] Keywords optimized (max 100 characters, comma-separated)
- [ ] Suggested: `library,books,catalog,scanner,camera,isbn,local,offline,privacy,collection,organizer,bookshelf`
- [ ] No repeated keywords
- [ ] No competitor app names
- [ ] No category names (Apple adds these automatically)

#### Promotional Text (Optional)
- [ ] Written (max 170 characters)
- [ ] Suggested: "Scan your bookshelf with AI. Manage your library offline. Export anytime. No cloud required. Swiss design, zero tracking."

#### What's New (Version 1.0.0)
- [ ] Release notes written
- [ ] Suggested: "Initial release with camera-based book scanning, offline library management, full-text search, CSV export, and Swiss utility design."

#### URLs
- [ ] Support URL: `https://github.com/yourusername/wingtip/blob/main/SUPPORT.md`
- [ ] Privacy Policy URL: `https://github.com/yourusername/wingtip/blob/main/PRIVACY.md`
- [ ] Marketing URL (optional): GitHub repository
- [ ] All URLs are live and accessible (test in browser)

#### Copyright
- [ ] Copyright text: "2026 Wingtip Contributors" (or your company name)

### 5. Privacy & Legal

#### Privacy Policy
- [ ] Privacy policy created: `PRIVACY.md`
- [ ] Policy is accessible via public URL
- [ ] Policy accurately describes data collection:
  - [ ] Device UUID (rate limiting only)
  - [ ] Book spine images (temporary, deleted after 5 minutes)
  - [ ] No user accounts, no tracking, no analytics
- [ ] Policy includes contact information
- [ ] Policy complies with GDPR, CCPA (if applicable)

#### App Privacy Labels (App Store Connect)
- [ ] "Data Used to Track You": **None**
- [ ] "Data Linked to You": **None**
- [ ] "Data Not Linked to You":
  - [ ] User Content (book spine images, temporary during scanning)
  - [ ] Identifiers (device UUID, for rate limiting only)

#### Terms of Service (Optional)
- [ ] Not required for Wingtip (simple utility app)
- [ ] If added, include URL in App Store Connect

#### Export Compliance
- [ ] App uses HTTPS (encryption)
- [ ] Select "No" for "Does your app use encryption?" (standard HTTPS is exempt)
- [ ] Or select "Yes" and choose "App uses standard encryption"

### 6. Backend & Infrastructure

#### Talaria Backend
- [ ] Backend is deployed and accessible
- [ ] API endpoints are working:
  - [ ] `POST /v3/jobs/scans` - Upload and create job
  - [ ] `GET /v3/jobs/scans/{jobId}/stream` - SSE stream
  - [ ] `DELETE /v3/jobs/scans/{jobId}/cleanup` - Cleanup
- [ ] Rate limiting is configured and tested
- [ ] Server has sufficient capacity for launch traffic
- [ ] Monitoring and logging are in place

#### Third-Party Services
- [ ] Google Fonts API is accessible (Inter, JetBrains Mono)
- [ ] Book cover image CDNs are working
- [ ] No third-party analytics or tracking SDKs (intentionally none)

### 7. Build & Archive

#### Build Process
- [ ] Dependencies installed: `flutter pub get`
- [ ] Code generation run: `flutter pub run build_runner build --delete-conflicting-outputs`
- [ ] Release build succeeds: `flutter build ios --release`
- [ ] No build warnings or errors

#### Xcode Archive
- [ ] Open `ios/Runner.xcworkspace` in Xcode
- [ ] Select "Any iOS Device" or connected device
- [ ] Product > Archive
- [ ] Archive succeeds with no errors
- [ ] Organizer shows archive with correct version and build number

#### Binary Validation
- [ ] Click "Validate App" in Xcode Organizer
- [ ] Validation succeeds (no errors)
- [ ] No missing entitlements or capabilities
- [ ] Signing is correct (App Store distribution)

#### Upload to App Store Connect
- [ ] Click "Distribute App" in Xcode Organizer
- [ ] Select "App Store Connect"
- [ ] Upload succeeds
- [ ] Processing completes in App Store Connect (wait 5-15 minutes)
- [ ] Build appears under "Activity" tab

### 8. App Store Connect Configuration

#### General Information
- [ ] App name: "Wingtip"
- [ ] Subtitle: "Local-first library manager"
- [ ] Primary language: English (U.S.)
- [ ] Bundle ID matches Xcode configuration

#### Version Information (1.0.0)
- [ ] Version number: 1.0.0
- [ ] Build number: 1 (or latest uploaded build)
- [ ] Copyright: "2026 Wingtip Contributors"

#### App Information
- [ ] Categories: Productivity (primary), Reference (secondary)
- [ ] Age rating questionnaire completed
  - [ ] No violence, profanity, adult content, etc.
  - [ ] Result: 4+

#### Pricing and Availability
- [ ] Price: Free
- [ ] Available in: All territories (or select specific countries)
- [ ] Pre-orders: No (for first release)

#### App Privacy
- [ ] Privacy policy URL added
- [ ] Privacy questions answered:
  - [ ] "Does your app collect data?" → Yes (device UUID, book images temporarily)
  - [ ] "Is data used to track users?" → No
  - [ ] "Is data linked to user identity?" → No
- [ ] Privacy labels generated and reviewed

#### App Review Information
- [ ] Contact information (email, phone)
- [ ] Demo account (if applicable): **Not needed** (no login system)
- [ ] Notes for reviewer (optional):
  ```
  Wingtip is a local-first library manager that uses AI to scan and identify book spines.

  To test:
  1. Grant camera permission when prompted
  2. Point camera at book spines (real books or images)
  3. Tap orange shutter button to scan
  4. View library by switching to "Library" tab
  5. Search by typing in search bar
  6. Export library via Settings > Export CSV

  Note: Scanning requires network access (AI identification), but all other features work offline.
  ```

#### Attachments (Optional)
- [ ] Additional notes or documentation for reviewer
- [ ] Test images of book spines (if helpful)

### 9. Pre-Submission Testing

#### Device Testing
- [ ] Installed release build on physical iPhone
- [ ] Tested on iPhone 12 or newer
- [ ] Tested on iOS 14.0 (minimum supported version)
- [ ] Tested on latest iOS version (currently 17.x)

#### Feature Testing
- [ ] Camera permission prompt appears
- [ ] Camera initializes and displays live preview
- [ ] Shutter button captures book spine image
- [ ] Image uploads to Talaria backend
- [ ] SSE stream receives events (progress, result, complete)
- [ ] Book appears in library with metadata
- [ ] Library displays books in grid layout
- [ ] Search filters books by title/author/ISBN
- [ ] Book detail view shows all metadata
- [ ] CSV export generates valid file
- [ ] App works offline (library browsing, search)
- [ ] Rate limiting displays countdown when triggered
- [ ] Error states display user-friendly messages

#### Performance Testing
- [ ] Cold start < 1 second
- [ ] Camera initialization < 500ms
- [ ] Search < 100ms
- [ ] No crashes or freezes
- [ ] Memory usage is acceptable
- [ ] Battery drain is reasonable

#### Edge Case Testing
- [ ] Deny camera permission → Shows explanation and settings link
- [ ] No network connection → Shows offline indicator, library still works
- [ ] Rate limit reached → Shows countdown timer, scanning disabled
- [ ] Blurry image → Shows "Too Blurry" message (if implemented)
- [ ] Unknown book → Shows "Not Found" or fallback (if implemented)
- [ ] Empty library → Shows empty state illustration

### 10. Final Checks

#### Documentation
- [ ] README.md is up-to-date
- [ ] PRIVACY.md is complete and accurate
- [ ] SUPPORT.md provides helpful troubleshooting
- [ ] CLAUDE.md has correct project information
- [ ] All documentation links are working

#### Repository
- [ ] All code is committed to git
- [ ] No uncommitted changes
- [ ] Git tags version (e.g., `git tag v1.0.0`)
- [ ] Repository is clean (no sensitive data)

#### Communication
- [ ] Team/stakeholders notified of submission
- [ ] Support email is monitored
- [ ] GitHub issues are enabled
- [ ] Social media accounts ready (if applicable)

#### Post-Launch Preparation
- [ ] Monitoring dashboard configured
- [ ] Error tracking in place (if any)
- [ ] User feedback collection method ready
- [ ] Update plan for v1.1.0 drafted

### 11. Submission

#### App Store Connect
- [ ] Log in to [App Store Connect](https://appstoreconnect.apple.com)
- [ ] Navigate to "My Apps" > "Wingtip" > version 1.0.0
- [ ] Upload screenshots to "iPhone 6.7 Display"
- [ ] Upload app preview video (optional)
- [ ] Enter all metadata (description, keywords, URLs, etc.)
- [ ] Configure privacy labels
- [ ] Select build from uploaded binaries
- [ ] Answer export compliance questions
- [ ] Click "Add for Review"
- [ ] Click "Submit for Review"

#### Confirmation
- [ ] Submission confirmation received (email)
- [ ] App status changes to "Waiting for Review"
- [ ] Check status in App Store Connect

## Post-Submission

### Expected Timeline
- **Waiting for Review:** 0-48 hours
- **In Review:** 1-3 days (average)
- **Processing for App Store:** 1-24 hours (if approved)

### If Approved
- [ ] App status changes to "Ready for Sale"
- [ ] App appears on App Store (search for "Wingtip")
- [ ] Download and verify live app
- [ ] Monitor reviews and ratings
- [ ] Respond to user feedback
- [ ] Announce launch (social media, GitHub, etc.)

### If Rejected
- [ ] Read rejection reason carefully
- [ ] Identify and fix issues
- [ ] Update binary if needed (increment build number)
- [ ] Update metadata if needed
- [ ] Respond to App Review in Resolution Center
- [ ] Resubmit for review

### Common Rejection Reasons
- Inaccurate screenshots (doesn't match app)
- Missing or inaccessible privacy policy
- Broken functionality (crashes, errors)
- Misleading description or metadata
- Guideline violations (2.1, 2.3, 4.0, 5.1)

## Support & Resources

### Apple Resources
- [App Store Connect](https://appstoreconnect.apple.com)
- [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)

### Flutter Resources
- [iOS Deployment Guide](https://docs.flutter.dev/deployment/ios)
- [Flutter Build Modes](https://docs.flutter.dev/testing/build-modes)

### Wingtip Resources
- [GitHub Repository](https://github.com/yourusername/wingtip)
- [Privacy Policy](../../PRIVACY.md)
- [Support Documentation](../../SUPPORT.md)

### Contact
- **Email:** [your-email@example.com]
- **GitHub Issues:** [https://github.com/yourusername/wingtip/issues](https://github.com/yourusername/wingtip/issues)

---

**Wingtip** - Swiss design, zero tracking.

*Good luck with your submission! 🚀*
