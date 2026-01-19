# TestFlight Beta Testing Setup Guide

This guide walks through the steps to distribute Wingtip via TestFlight for beta testing.

## Prerequisites

- Apple Developer account ($99/year)
- Xcode installed on macOS
- App Store Connect access
- Signing certificates and provisioning profiles configured

## Step 1: Configure iOS Bundle ID and Signing

The app is already configured with:
- **Bundle ID**: `com.ooheynerds.wingtip`
- **Display Name**: libScan
- **Team ID**: 8Z67H8Y8DW

### Verify Signing Configuration

1. Open the project in Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. Select the **Runner** target in the project navigator

3. Go to **Signing & Capabilities** tab

4. Ensure:
   - "Automatically manage signing" is checked
   - Your development team is selected
   - Provisioning profile shows "Xcode Managed Profile"

### Update for Distribution

For TestFlight distribution, you may need to create an App Store distribution certificate:

1. In Xcode, go to **Preferences > Accounts**
2. Select your Apple ID
3. Click **Manage Certificates**
4. Click **+** and select **Apple Distribution**

## Step 2: Create App in App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com/)

2. Click **My Apps** → **+ icon** → **New App**

3. Fill in app information:
   - **Platform**: iOS
   - **Name**: Wingtip (or your preferred name)
   - **Primary Language**: English
   - **Bundle ID**: Select `com.ooheynerds.wingtip`
   - **SKU**: `wingtip-ios` (or your preferred SKU)
   - **User Access**: Full Access

4. Click **Create**

## Step 3: Configure TestFlight

1. In App Store Connect, select your app

2. Go to **TestFlight** tab

3. Configure **Test Information**:
   - **Beta App Description**: Brief description of what testers should focus on
   - **Feedback Email**: Where testers can send feedback
   - **Marketing URL**: (optional) Link to your website
   - **Privacy Policy URL**: (optional) Link to privacy policy

4. Create a **Test Group**:
   - Click **+** next to Internal Testing or External Testing
   - Name it "Beta Testers"
   - Add the build (after upload in Step 4)

### Internal vs External Testing

- **Internal Testing**: Up to 100 testers from your App Store Connect team. No Apple review required. Builds available immediately.
- **External Testing**: Up to 10,000 external testers. Requires Apple review (usually 24-48 hours). Recommended for wider beta.

## Step 4: Build and Upload to TestFlight

### Using Flutter CLI + Xcode

1. Increment version/build number in `pubspec.yaml`:
   ```yaml
   version: 1.0.0+2  # Format: version+buildNumber
   ```

2. Build the iOS release:
   ```bash
   flutter build ios --release
   ```

3. Open the project in Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```

4. Select **Product > Archive** from the menu

5. Once archiving completes, the Organizer window opens automatically

6. Select your archive and click **Distribute App**

7. Choose **App Store Connect** → **Upload**

8. Follow the wizard:
   - Include bitcode: NO (Flutter doesn't use bitcode)
   - Upload symbols: YES (helps with crash reporting)
   - Automatically manage signing: YES

9. Click **Upload**

### Wait for Processing

- Upload typically takes 5-15 minutes
- Build processing in App Store Connect takes 15-30 minutes
- You'll receive email confirmation when the build is ready

## Step 5: Invite Beta Testers

### For Internal Testing:

1. Go to **Users and Access** in App Store Connect
2. Add testers with their Apple ID email addresses
3. Assign them to your team with "App Manager" or "Developer" role
4. Go back to TestFlight → Internal Testing → Add users to your test group

### For External Testing:

1. Go to TestFlight → External Testing
2. Click **+** to create a new group
3. Add testers by email (they don't need App Store Connect access)
4. Select the build to test
5. Submit for Beta App Review
6. Wait for Apple approval (usually 24-48 hours)

### Public Link (Optional):

You can generate a public TestFlight link that anyone can use to join:
1. Go to TestFlight → External Testing → Your Group
2. Enable "Public Link"
3. Share the generated link

## Step 6: Beta Tester Instructions

Send the following to your testers:

---

**Subject: Wingtip Beta Testing Invitation**

Hi,

You've been invited to beta test Wingtip, a local-first library manager that scans book spines using your camera.

### Getting Started:

1. Install **TestFlight** from the App Store (if you don't have it)
2. Open the TestFlight invitation link sent to your email
3. Tap **Accept** and then **Install**
4. Launch Wingtip from your home screen

### What to Test:

- **Book Scanning**: Use the camera to scan book spines
- **Library Management**: Browse, search, and organize your books
- **Offline Mode**: Test the app without internet connection
- **Performance**: Note any lag, crashes, or UI issues

### Providing Feedback:

**In-App Feedback (Recommended)**:
- Shake your device anywhere in the app
- This will open a feedback form with automatic log attachment
- Describe what happened and submit

**Via TestFlight**:
- Open TestFlight app
- Select Wingtip
- Tap "Send Beta Feedback"
- Include screenshots if relevant

### Known Issues:

- First camera load may take 1-2 seconds
- Large book collections (>500 books) may cause slight search delays
- Rate limiting may occur after ~20 rapid scans

### Privacy Note:

All your book data is stored locally on your device. Images are temporarily uploaded to our server for AI identification, then immediately deleted after processing.

Thank you for helping make Wingtip better!

---

## Step 7: Monitor and Iterate

### Check TestFlight Metrics:

- Go to TestFlight → Your Build → Metrics
- View installs, sessions, crashes

### Review Crash Reports:

- TestFlight provides automatic crash reporting
- View crashes in Xcode → Window → Organizer → Crashes
- Also check Sentry dashboard for detailed reports

### Update and Redeploy:

1. Fix bugs based on feedback
2. Increment build number in `pubspec.yaml`
3. Repeat Step 4 to upload a new build
4. TestFlight automatically notifies testers of updates

## Troubleshooting

### Build Upload Fails

- Check that signing certificate is valid and not expired
- Ensure bundle ID matches App Store Connect
- Try uploading from Xcode Organizer instead of CLI

### Processing Stuck

- Wait at least 30 minutes before worrying
- Check App Store Connect status page for outages
- Contact Apple Developer Support if stuck >2 hours

### Testers Can't Install

- Verify tester's email matches their Apple ID
- Check that build has finished processing
- Ensure tester has accepted the invite in TestFlight app

### Crashes in TestFlight but Not Locally

- Check device compatibility (iOS 13+ required)
- Review crash logs in Xcode Organizer
- Test on physical devices, not just simulator

## App Store Submission (After Beta)

Once beta testing is complete and you're ready for public release:

1. Go to App Store Connect → Your App → App Store tab
2. Fill in all required metadata:
   - Screenshots (iPhone 6.7", 6.5", 5.5")
   - App description
   - Keywords
   - Support URL
   - Privacy policy
3. Select the TestFlight build for release
4. Submit for App Store Review
5. Review typically takes 1-3 days

## Additional Resources

- [Apple TestFlight Documentation](https://developer.apple.com/testflight/)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [Flutter iOS Deployment Guide](https://docs.flutter.dev/deployment/ios)
