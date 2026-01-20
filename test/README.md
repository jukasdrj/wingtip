# Wingtip Test Suite

This directory contains comprehensive tests for the Wingtip app following Flutter's testing best practices. Tests are organized by type and mirror the `lib/` structure for easy navigation.

## Test Structure

```
test/
├── integration/           # Critical flow tests (~30 seconds)
│   └── critical_flows_test.dart
├── features/              # Widget tests (~1-2 minutes)
│   ├── camera/            # Camera UI tests
│   ├── library/           # Library screen tests
│   ├── talaria/           # Job state tests
│   └── onboarding/        # Onboarding tests
├── core/                  # Network and SSE tests (~10 seconds)
│   ├── talaria_client_test.dart
│   ├── sse_client_test.dart
│   ├── device_id_service_test.dart
│   └── network_client_test.dart
├── data/                  # Database tests (~10 seconds)
│   ├── database_test.dart
│   └── failed_scans_repository_test.dart
├── services/              # Background service tests (~10 seconds)
│   └── failed_scans_cleanup_service_test.dart
└── README.md              # This file
```

## Quick Start

Use the test runner script for fast validation:

```bash
# Quick smoke test - Integration tests only (~30 seconds)
./scripts/test.sh quick

# Full safety net - Integration + widget tests (~2-3 minutes) [DEFAULT]
./scripts/test.sh

# Everything - Analyze + all tests (~3-5 minutes)
./scripts/test.sh all
```

## Test Categories

### Integration Tests (`test/integration/`)

**Purpose**: Validate critical end-to-end flows that must never break.

**What they test**:
- Complete scan workflow: Capture → Upload → SSE → Database → UI
- Failed scan persistence and retry logic
- Network reconnection handling
- Database operations with real Drift schema

**Example: Critical Flow Test**
```dart
testWidgets('critical flow: scan → save → display in library', (tester) async {
  // Setup: Create in-memory database and mock SSE client
  final database = AppDatabase(NativeDatabase.memory());
  final mockSseClient = MockSseClient(shouldSimulateSuccess: true);

  // Inject providers
  final container = ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(database),
      sseClientProvider.overrideWithValue(mockSseClient),
    ],
  );

  // Execute: Submit a scan job
  final notifier = container.read(jobStateNotifierProvider.notifier);
  await notifier.submitScan(File('test/fixtures/book_spine.jpg'));

  // Verify: Book saved to database
  final books = await database.getAllBooks();
  expect(books.length, 1);
  expect(books.first.title, 'The Martian');
});
```

**Run time**: ~30 seconds for all integration tests

### Widget Tests (`test/features/`)

**Purpose**: Test UI components and user interactions in isolation.

**What they test**:
- Widget rendering and layout
- User interactions (taps, swipes, form input)
- State changes and UI updates
- Navigation flows
- Error states and loading indicators

**Example: Camera Screen Test**
```dart
testWidgets('camera screen shows shutter button when initialized', (tester) async {
  // Setup: Mock camera service
  final mockCameraService = MockCameraService(isInitialized: true);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        cameraServiceProvider.overrideWithValue(mockCameraService),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme(),
        home: const CameraScreen(),
      ),
    ),
  );

  // Verify: Shutter button visible
  expect(find.byType(ShutterButton), findsOneWidget);
});
```

**Run time**: ~1-2 minutes for all widget tests

### Unit Tests (`test/core/`, `test/data/`, `test/services/`)

**Purpose**: Test business logic, services, and utilities in isolation.

**What they test**:
- Network client request/response handling
- SSE event parsing
- Database queries and FTS5 search
- Failed scan cleanup logic
- Device ID generation and persistence

**Example: SSE Client Test**
```dart
test('SSE client parses progress events', () async {
  final client = SseClient();
  final mockStream = Stream.value('data: {"type":"progress","progress":0.5}\n\n');

  final event = await client.parseEvent(mockStream).first;

  expect(event.type, SseEventType.progress);
  expect(event.data['progress'], 0.5);
});
```

**Run time**: ~10 seconds per category

## Mocking Patterns

### Riverpod Provider Overrides

The most common pattern for testing with Riverpod:

```dart
final container = ProviderContainer(
  overrides: [
    // Override with mock implementation
    talariaClientProvider.overrideWithValue(mockTalariaClient),

    // Override with in-memory database
    databaseProvider.overrideWithValue(AppDatabase(NativeDatabase.memory())),

    // Override with test value
    deviceIdProvider.overrideWithValue('test-device-id'),
  ],
);

// Access provider in test
final notifier = container.read(jobStateNotifierProvider.notifier);
```

### Mock SSE Client

Used in integration tests to simulate backend responses:

```dart
class MockSseClient extends SseClient {
  final bool shouldSimulateSuccess;
  final Map<String, dynamic>? mockBookData;

  @override
  Stream<SseEvent> listen(String streamUrl) async* {
    // Emit progress
    yield SseEvent(
      type: SseEventType.progress,
      data: {'progress': 0.5, 'message': 'Analyzing spine...'},
    );

    // Emit result
    yield SseEvent(
      type: SseEventType.result,
      data: mockBookData ?? {
        'isbn': '9780553418026',
        'title': 'The Martian',
        'author': 'Andy Weir',
        'coverUrl': 'https://example.com/cover.jpg',
      },
    );

    // Emit complete
    yield SseEvent(type: SseEventType.complete, data: {});
  }
}
```

### Mock Camera Service

Used in widget tests to avoid real camera initialization:

```dart
class MockCameraService implements CameraService {
  final bool _mockIsInitialized;
  final CameraController? _mockController;

  @override
  bool get isInitialized => _mockIsInitialized;

  @override
  CameraController? get controller => _mockController;

  @override
  Future<void> initialize({bool? restoreNightMode}) async {
    // No-op in tests
  }
}
```

### In-Memory Database

Drift supports in-memory SQLite for fast, isolated database tests:

```dart
test('database saves and retrieves books', () async {
  // Create in-memory database
  final database = AppDatabase(NativeDatabase.memory());

  // Insert test book
  await database.insertBook(BooksCompanion.insert(
    isbn: '9780553418026',
    title: 'The Martian',
    author: 'Andy Weir',
    addedDate: DateTime.now().millisecondsSinceEpoch,
  ));

  // Query and verify
  final books = await database.getAllBooks();
  expect(books.length, 1);
  expect(books.first.title, 'The Martian');

  // Clean up
  await database.close();
});
```

### Fake Path Provider

Used in tests that require file system access:

```dart
class FakePathProviderPlatform extends PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    final dir = await Directory.systemTemp.createTemp('app_documents_');
    return dir.path;
  }

  @override
  Future<String?> getTemporaryPath() async {
    return Directory.systemTemp.path;
  }
}

void main() {
  setUpAll(() {
    PathProviderPlatform.instance = FakePathProviderPlatform();
  });
}
```

## Testing Best Practices

### 1. Test Naming Convention

Use descriptive names that explain what is being tested:

```dart
// Good
test('SSE client parses progress events correctly')
testWidgets('camera screen shows error message when initialization fails')

// Bad
test('test 1')
testWidgets('camera test')
```

### 2. Arrange-Act-Assert Pattern

Structure tests with clear sections:

```dart
test('failed scan cleanup deletes expired scans', () async {
  // Arrange: Setup test data
  final database = AppDatabase(NativeDatabase.memory());
  final service = FailedScansCleanupService(database);
  await database.insertFailedScan(/* ... */);

  // Act: Execute the operation
  await service.cleanupExpiredScans();

  // Assert: Verify the result
  final scans = await database.getFailedScans();
  expect(scans.length, 0);
});
```

### 3. Isolate Tests

Each test should be independent and not rely on state from other tests:

```dart
setUp(() {
  // Reset state before each test
  database = AppDatabase(NativeDatabase.memory());
});

tearDown(() async {
  // Clean up after each test
  await database.close();
});
```

### 4. Use Test Fixtures

Store test images and data in `test/fixtures/` for reuse:

```dart
final testImage = File('test/fixtures/test_book_spine.jpg');
final testJson = File('test/fixtures/mock_sse_response.json').readAsStringSync();
```

### 5. Mock External Dependencies

Never hit real APIs or file systems in tests:

```dart
// Good: Mock the HTTP client
final mockClient = MockTalariaClient();
when(mockClient.uploadImage(any)).thenReturn(/* ... */);

// Bad: Hit real API
final client = TalariaClient(baseUrl: 'https://api.example.com');
```

### 6. Test Edge Cases

Don't just test happy paths:

```dart
test('handles empty search query gracefully', () async {
  final results = await database.searchBooks('');
  expect(results.isEmpty, true);
});

test('retries failed upload with exponential backoff', () async {
  // Simulate network failure, then success
  mockClient.failNextRequest();
  await notifier.submitScan(testImage);

  // Verify retry happened
  expect(mockClient.requestCount, 2);
});
```

### 7. Widget Testing with Pumps

Use proper pump methods for async UI updates:

```dart
testWidgets('shows loading indicator during scan', (tester) async {
  await tester.pumpWidget(/* ... */);

  // Trigger scan
  await tester.tap(find.byType(ShutterButton));
  await tester.pump(); // Start async operation

  // Verify loading indicator appears
  expect(find.byType(CircularProgressIndicator), findsOneWidget);

  // Wait for operation to complete
  await tester.pumpAndSettle();

  // Verify loading indicator disappears
  expect(find.byType(CircularProgressIndicator), findsNothing);
});
```

## Running Tests

### Via Test Runner Script (Recommended)

```bash
# Quick pre-commit check (~30 sec)
./scripts/test.sh quick

# Full safety net (~2-3 min) [DEFAULT]
./scripts/test.sh

# Complete validation (~3-5 min)
./scripts/test.sh all

# Specific test types
./scripts/test.sh unit     # Unit tests only
./scripts/test.sh widget   # Widget tests only
```

### Via Flutter CLI

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/integration/critical_flows_test.dart

# Run tests in a directory
flutter test test/features/

# Run with coverage
flutter test --coverage

# Run with verbose output
flutter test --verbose
```

## Coverage

Generate coverage reports to identify untested code:

```bash
# Generate coverage
flutter test --coverage

# View coverage report (requires lcov)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

**Coverage targets**:
- Critical paths (integration tests): 100%
- Widget tests: 80%+
- Unit tests: 90%+

## Common Issues

### Issue: Camera tests fail on CI

**Solution**: Mock the camera service to avoid platform channel issues:

```dart
await tester.pumpWidget(
  ProviderScope(
    overrides: [
      cameraServiceProvider.overrideWithValue(MockCameraService()),
    ],
    child: /* ... */,
  ),
);
```

### Issue: Database tests interfere with each other

**Solution**: Use in-memory databases and proper teardown:

```dart
setUp(() {
  database = AppDatabase(NativeDatabase.memory());
});

tearDown(() async {
  await database.close();
});
```

### Issue: Async tests timeout

**Solution**: Increase timeout or ensure futures complete:

```dart
test('long operation', () async {
  await operation();
}, timeout: const Timeout(Duration(seconds: 30)));
```

### Issue: Widget tests can't find widgets

**Solution**: Use `pumpAndSettle()` to wait for animations:

```dart
await tester.pumpWidget(/* ... */);
await tester.pumpAndSettle(); // Wait for all animations
expect(find.byType(MyWidget), findsOneWidget);
```

## Contributing

When adding new features:

1. Write tests first (TDD approach)
2. Ensure integration tests cover critical flows
3. Add widget tests for new UI components
4. Mock all external dependencies
5. Run `./scripts/test.sh all` before committing

## Resources

- [Flutter Testing Documentation](https://docs.flutter.dev/testing)
- [Riverpod Testing Guide](https://riverpod.dev/docs/cookbooks/testing)
- [Drift Testing Guide](https://drift.simonbinder.eu/docs/advanced-features/testing/)
- [Widget Testing Guide](https://docs.flutter.dev/cookbook/testing/widget)

---

**Last Updated**: Epic 3 (US-213)
**Test Coverage**: Integration (100%), Widget (85%), Unit (90%)
