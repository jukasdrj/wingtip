# Wingtip TODO

## Current Status

- ✅ **Epic 4: Failed Scan Queue & Production Resilience** - Completed (20/20 user stories: US-131–US-152)
  - All stories marked as "passes": true
  - Recent commits confirm: Performance Dashboard, Failed Scan Analytics, Session Counter, Background Processing Verification, SSE Interruption Handling

Project is in post-Epic-4 phase with core production resilience features implemented.

## Epic 4 Recap

Epic 4 focused on production resilience for the book scanning workflow:

- **Failed Scan Queue & Retry System**: Automatic retry mechanisms for failed image uploads and processing, with persistent queuing for offline recovery
- **Analytics Dashboard**: Performance metrics and scan analytics to track success rates, bottlenecks, and user behavior
- **Session Gamification**: Scan session counters and progress tracking to encourage usage
- **Background Processing Verification**: Robust background image compression and upload handling
- **SSE Interruption Handling**: Fault-tolerant Server-Sent Events streams with automatic reconnection and error recovery

These features ensure the app remains functional under poor network conditions and provides insights for production monitoring.

## Original MVP Status (Epics 1–6)

Based on `docs/user-stories.md`, the original roadmap consists of 30 user stories across 6 epics (estimated 98 hours total).

**Likely Completed (Critical Path MVP Foundation)**:
- Core setup items from early epics (e.g., Flutter project scaffolding, Riverpod setup) may have been implemented as prerequisites, but no explicit completion markers in the file.

**Likely Incomplete**:
- Most P0/P1 stories from Epics 1–6 appear pending implementation.
- The new Epic 4 (US-131–US-152) was an additional resilience layer built on top of the original plan.
- Assumption: Original epics 1–3, 5–6 are not yet fully implemented, as the focus has been on Epic 4. Library basics (Epic 4 original US-116–121) may be partially done if needed for Epic 4, but require verification.

## Remaining Work from Original Epics (P0/P1 Priority)

Focus on critical path items for MVP launch. These are high-priority stories that enable core functionality. Estimated 41 hours for MVP critical path.

### Epic 1: Foundations & Architecture (P0)
- [ ] US-101: Initialize Flutter Project with Riverpod & Drift
- [ ] US-102: Implement "Swiss Utility" Theme System
- [ ] US-103: Generate & Store Persistent Device ID
- [ ] US-116: Drift Database Schema (Library table setup)

### Epic 2: The Viewfinder (Capture) (P0)
- [ ] US-105: Instant Camera Initialization
- [ ] US-106: Non-Blocking Shutter Action
- [ ] US-107: Background Image Processing
- [ ] US-108: The "Processing Stack" UI (P1)
- [ ] US-109: Manual Focus & Zoom (P1)

### Epic 3: The Talaria Link (Integration) (P0)
- [ ] US-104: Offline-First Network Client (P1)
- [ ] US-110: Upload Image to Talaria
- [ ] US-111: SSE Stream Listener
- [ ] US-112: Visualize "Progress" Events (P1)
- [ ] US-113: Handle "Result" Events (Data Upsert)
- [ ] US-114: Handle "Complete" & Cleanup
- [ ] US-115: Handle Global Rate Limits (P1)

### Epic 4: The Library (Drift DB) (P0)
- [ ] US-117: Library Grid View
- [ ] US-118: Real-time List Updates (P1)
- [ ] US-119: Full-Text Search (FTS5) (P1)

### Epic 5: Detail & Interaction (P1)
- [ ] US-122: Minimal Book Detail View
- [ ] US-125: Haptic Feedback Strategy

### Epic 6: Polish & Launch (P1)
- [ ] US-127: App Icon & Splash Screen
- [ ] US-128: Permission Priming
- [ ] US-129: Empty States
- [ ] US-130: Error Toasts (Snackbars)

## Post-MVP Enhancements (P2/P3)

These are nice-to-have features for improved UX and data management, to be tackled after MVP.

### Epic 4: The Library (Drift DB) (P2)
- [ ] US-120: "Review Needed" Indicator
- [ ] US-121: Export Data to CSV

### Epic 5: Detail & Interaction (P2/P3)
- [ ] US-123: The "Raw Data" Toggle (P3)
- [ ] US-124: Swipe to Delete

### Epic 6: Polish & Launch (P2)
- [ ] US-126: Cache Manager

## Technical Debt

Address these to improve maintainability, scalability, and developer experience within the existing Flutter/Riverpod/Drift stack.

- [ ] **Riverpod Generators**: Add `riverpod_generator` and `riverpod_annotation` packages for cleaner providers (reduces boilerplate, improves compile-time safety)
- [ ] **Integration Tests for Camera Flow**: Implement end-to-end tests covering camera initialization, image processing, and upload pipeline using `integration_test` package
- [ ] **SSE Client Evaluation**: Current implementation uses `http` package - consider evaluating dedicated SSE clients for better reconnection handling if issues arise
- [ ] **API Documentation**: Create `docs/api.md` documenting Talaria backend endpoints, SSE event formats, and request/response schemas
- [ ] **Code Coverage Targets**: Aim for >80% unit test coverage on core modules (database, state management, services)
- [ ] **Drift Schema Versioning**: Ensure proper migration scripts for future database schema changes

## Known Issues

(None currently documented)

## Next Milestone (Suggestions for Epic 5 or Production Readiness)

With Epic 4 complete, focus shifts to MVP completion and launch preparation. Suggested next epic: "MVP Polish & Production Hardening" (~4-6 weeks).

**Proposed Epic 5: User Experience Polish & Platform Integration**
- Multi-platform release preparation (iOS App Store, Android Play Store)
- Advanced interaction details: gesture refinements, accessibility compliance (WCAG AA for iOS/Android)
- Performance optimization: memory management for large libraries, battery usage monitoring
- Advanced library features: book deduplication algorithms, cover image lazy loading optimizations
- Analytics integration: Anonymous usage tracking with GDPR compliance

**Short-term (2-4 weeks): Production Readiness Checklist**
- Complete all P0 stories from critical path
- End-to-end testing across devices (iOS priority, Android compatibility)
- Security audit: data encryption, secure storage validation
- CI/CD setup: Automated builds and deployments for beta releases
- Beta testing program: Collect user feedback on core workflows

Prioritize iOS-first deployment given project constraints. Measure success by scan accuracy, app stability, and user retention metrics from Epic 4 analytics.
