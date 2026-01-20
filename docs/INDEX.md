# Wingtip Documentation

## Quick Links

- **[User Stories](user-stories.md)** - Historical MVP feature requirements (Epic 3 complete)
- **[Verification](verification/)** - Feature verification documents and test results
- **[TODO](../TODO.md)** - Current status, Epic 3 completion summary, launch readiness

## Project Information

- **[README](../README.md)** - Project overview, features, setup instructions, and quick start guide
- **[CLAUDE.md](../CLAUDE.md)** - AI assistant context and comprehensive development guide
- **[PRD Epic 3 (JSON)](../tasks/prd-epic3.json)** - Complete product requirements (72 user stories, all complete)

## Epic 3 Features Documentation

### Production Readiness
- **[CRASH_REPORTING.md](../CRASH_REPORTING.md)** - Sentry integration for production error tracking
- **[TESTFLIGHT_SETUP.md](../TESTFLIGHT_SETUP.md)** - TestFlight beta testing configuration guide
- **[BETA_TESTER_EMAIL.md](../BETA_TESTER_EMAIL.md)** - Beta tester welcome email template
- **[PRIVACY.md](../PRIVACY.md)** - Privacy policy for App Store compliance
- **[SUPPORT.md](../SUPPORT.md)** - End-user support documentation

### iOS-Specific Features
- **[WIDGET_SETUP.md](../WIDGET_SETUP.md)** - iOS Home Screen widget Xcode configuration
- **[PROMOTION_120HZ.md](PROMOTION_120HZ.md)** - ProMotion 120Hz optimization guide and debugging

### App Store Materials
- **[App Store Assets](../assets/app-store/)** - Screenshots, video script, metadata, submission checklist
  - [README](../assets/app-store/README.md) - Overview of App Store materials
  - [SUBMISSION-CHECKLIST.md](../assets/app-store/SUBMISSION-CHECKLIST.md) - Pre-submission verification
  - [QUICK-REFERENCE.md](../assets/app-store/QUICK-REFERENCE.md) - Key app details for marketing

## Architecture

See [CLAUDE.md](../CLAUDE.md) for detailed architecture documentation:
- State Management (Riverpod 3.0)
- Database Layer (Drift ORM with SQLite)
- API Integration (HTTP + SSE streams)
- UI Layer (Swiss Utility design system)
- Data Flow (The Capture Loop)

## Development Guides

### Common Tasks
See [CLAUDE.md - Common Development Tasks](../CLAUDE.md#common-development-tasks) for:
- Adding new book fields to the database
- Adding new SSE event types
- Testing image processing pipeline
- Debugging SSE streams
- Performance monitoring

### Testing
- Unit tests: `test/data/` (database queries)
- Unit tests: `test/core/` (network clients, SSE parsing)
- Widget tests: `test/features/` (UI components)
- Run all tests: `flutter test`
- Coverage: `flutter test --coverage`

### Build & Release
- iOS (primary target): `flutter build ios --release`
- Android: `flutter build apk --release`

## API Reference

### Talaria Backend Integration

**Base URL:** Configured via `NetworkClient(baseUrl: ...)`

**Authentication:**
- `X-Device-ID` header (persistent UUID from secure storage)

**Endpoints:**
- `POST /v3/jobs/scans` - Upload image for analysis
  - Request: multipart/form-data with image
  - Response: `{jobId, streamUrl}`
  - Rate limit: 429 with `retryAfterMs`

- `GET /v3/jobs/scans/{jobId}/stream` - SSE stream for job updates
  - Events: `progress`, `result`, `complete`, `error`
  - Timeout: 5 minutes maximum

- `DELETE /v3/jobs/scans/{jobId}/cleanup` - Clean up server resources

**SSE Event Types:**
- `progress` - Analysis progress updates (0.0 - 1.0)
- `result` - Book metadata found (upsert to DB immediately)
- `complete` - Job finished successfully
- `error` - Job failed with error message

## Design System

### Swiss Utility Theme

**Color Palette:**
- OLED Black: `#000000` (background)
- International Orange: `#FF3B30` (accent)
- Border Gray: `#1C1C1E` (borders)
- Text Primary: `#FFFFFF`
- Text Secondary: `#8E8E93`

**Typography:**
- Body/UI: Inter (via Google Fonts)
- Code/ISBNs/JSON: JetBrains Mono (monospace)

**Design Principles:**
- Zero elevation on all components
- 1px solid borders instead of shadows
- Dark mode only (no light theme)
- Haptic feedback at every interaction stage (iOS-first)

## Archive

- **[Draft PRD](archive/PRD-wingtip-draft.md)** - Early planning documents and conversational artifacts

## Performance Targets

- Cold start: < 800ms to live camera ✅ (Epic 3 optimized)
- Shutter latency: < 30ms tap-to-haptic ✅ (Epic 3 optimized)
- Image processing: < 500ms per image (background isolate)
- ProMotion: 120fps on iPhone Pro devices ✅ (Epic 3 optimized)
- Memory footprint: < 200MB typical usage ✅ (Epic 3 optimized)
- SSE timeout: 5 minutes maximum job duration
- Image specs: Resized to max 1920px, compressed to JPEG quality 85

## Contributing

See [README - Contributing](../README.md#contributing) for:
- Commit conventions
- Testing requirements
- PR process
- iOS-first development mandate

---

**Platform Priority:** This project is developed **iOS-first**. All development decisions, performance targets, and UX patterns prioritize iOS. Android and web are secondary targets.
