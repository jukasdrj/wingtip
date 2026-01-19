# Crash Reporting & Analytics Setup

This document describes how to configure and test crash reporting and analytics in Wingtip using Sentry.

## Overview

Wingtip uses **Sentry** for crash reporting and analytics. The implementation is privacy-first:
- No PII (personally identifiable information)
- IP addresses anonymized
- Device IDs are hashed before sending
- Only essential context is captured

## Setup Instructions

### 1. Create a Sentry Account

1. Go to [sentry.io](https://sentry.io)
2. Sign up for a free account
3. Create a new project for "Flutter"
4. Copy the DSN (Data Source Name) - you'll need this for configuration

### 2. Configure Sentry DSN

The Sentry DSN should be provided via environment variables to avoid committing secrets to git.

#### Development (Optional)

For development builds, Sentry is disabled by default (empty DSN). To enable it in development:

```bash
flutter run --dart-define=SENTRY_DSN="your-dsn-here" --dart-define=SENTRY_ENVIRONMENT="development"
```

#### Production

For release builds, always provide the DSN:

```bash
flutter build ios --release \
  --dart-define=SENTRY_DSN="your-production-dsn-here" \
  --dart-define=SENTRY_ENVIRONMENT="production"
```

### 3. Environment Variables

The app uses these environment variables:

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `SENTRY_DSN` | No | `""` (disabled) | Sentry project DSN from sentry.io |
| `SENTRY_ENVIRONMENT` | No | `"development"` | Environment name (development, staging, production) |

## Custom Context

The app automatically attaches custom context to all crash reports:

- **device_id** - Hashed UUID (privacy-safe)
- **books_count** - Total books in library
- **active_jobs_count** - Active scanning jobs

This context is updated automatically as the app state changes via `CrashContextProvider`.

## Analytics Events

The following events are tracked:

### scan_started
Logged when user taps shutter to start a scan.
- Parameters: `job_id`

### scan_completed
Logged when a scan completes successfully with books found.
- Parameters: `job_id`, `books_found`

### book_saved
Logged when a book is saved to the database.
- Parameters: `isbn`, `has_cover`, `spine_confidence`

## Testing Crash Reporting

### Test in Debug Mode

1. Install and run the app with Sentry DSN configured:
   ```bash
   flutter run --dart-define=SENTRY_DSN="your-dsn-here"
   ```

2. Manually trigger a test crash (for testing only):
   ```dart
   import 'package:wingtip/core/crash_reporting_service.dart';

   // Only works in debug mode
   CrashReportingService.testCrash();
   ```

3. Check Sentry dashboard - you should see the crash within a few seconds

### Test in Release Mode

1. Build a release version:
   ```bash
   flutter build ios --release --dart-define=SENTRY_DSN="your-dsn-here" --dart-define=SENTRY_ENVIRONMENT="production"
   ```

2. Install and run the release build on a device

3. Force a crash by triggering an error condition

4. Restart the app - Sentry will upload the crash report

5. Check Sentry dashboard

### Verify Context Data

After triggering a crash, verify in Sentry dashboard that:
- Device ID is present (as a hashed value, not the raw UUID)
- Books count is accurate
- Active jobs count is accurate

## Manual Error Logging

You can log non-fatal errors manually:

```dart
import 'package:wingtip/core/crash_reporting_service.dart';

try {
  // Risky operation
} catch (error, stackTrace) {
  CrashReportingService.logError(
    error,
    stackTrace,
    hint: 'Failed to process image',
    extra: {
      'image_path': imagePath,
      'file_size': fileSize,
    },
  );
}
```

## Privacy Considerations

### What is NOT sent to Sentry:

- Raw device IDs (only hashed versions)
- User-identifiable information
- IP addresses (anonymized by Sentry)
- Screenshots of the app
- View hierarchy
- Specific book titles, authors, or ISBNs (only counts)

### What IS sent to Sentry:

- Stack traces
- Error messages
- Custom context (device_id hash, counts)
- Event breadcrumbs (analytics events)
- Device model and OS version
- App version

## Performance Monitoring

Sentry is configured with 10% sampling for performance monitoring:
- Transaction traces capture performance data
- Profile samples help identify slow operations
- All sampling is done server-side to minimize overhead

## Troubleshooting

### Crashes not appearing in Sentry

1. Verify DSN is correct:
   ```bash
   flutter run --dart-define=SENTRY_DSN="your-dsn-here" --verbose
   ```
   Check logs for `[Sentry]` messages

2. Check internet connectivity

3. Verify Sentry project is active and DSN is valid

4. In release builds, crashes are uploaded on next app start (not immediately)

### Analytics events not visible

Analytics events appear as "Breadcrumbs" in Sentry:
1. Open a crash report
2. Look for the "Breadcrumbs" tab
3. Filter by category: "analytics"

## Cost Considerations

Sentry free tier includes:
- 5,000 errors/month
- 10,000 transactions/month
- 30-day retention

With 10% sampling and privacy filters, this should be sufficient for most development and small production deployments.

## Additional Resources

- [Sentry Flutter SDK Documentation](https://docs.sentry.io/platforms/flutter/)
- [Sentry Privacy & Security](https://sentry.io/security/)
- [Flutter Performance Monitoring](https://docs.sentry.io/platforms/flutter/performance/)
