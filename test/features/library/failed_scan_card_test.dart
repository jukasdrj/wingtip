import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wingtip/core/theme.dart';
import 'package:wingtip/data/database.dart';
import 'package:wingtip/data/database_provider.dart';
import 'package:wingtip/features/library/library_provider.dart';
import 'package:wingtip/features/library/widgets/failed_scan_card.dart';
import 'package:wingtip/features/library/failed_scan_detail_screen.dart';

void main() {
  late AppDatabase database;
  late FailedScan testFailedScan;

  setUp(() {
    database = AppDatabase.test(NativeDatabase.memory());

    // Create a test failed scan
    testFailedScan = FailedScan(
      id: 1,
      jobId: 'test-job-123',
      imagePath: '/path/to/test/image.jpg',
      errorMessage: 'Network connection failed',
      failureReason: FailureReason.networkError,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      expiresAt: DateTime.now().add(const Duration(days: 7)).millisecondsSinceEpoch,
    );
  });

  tearDown(() async {
    await database.close();
  });

  group('FailedScanCard', () {
    testWidgets('should render with error message and timestamp', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(database),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: FailedScanCard(
                failedScan: testFailedScan,
                onRetry: () {},
                onDelete: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify error message is displayed
      expect(find.text('Network connection failed'), findsOneWidget);

      // Verify timestamp is displayed (should be "Just now" since we just created it)
      expect(find.text('Just now'), findsOneWidget);

      // Verify action buttons are displayed
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('should trigger retry callback when retry button is tapped', (tester) async {
      bool retryCalled = false;
      bool deleteCalled = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(database),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: FailedScanCard(
                failedScan: testFailedScan,
                onRetry: () => retryCalled = true,
                onDelete: () => deleteCalled = true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the retry button
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      // Verify callback was triggered
      expect(retryCalled, true);
      expect(deleteCalled, false);
    });

    testWidgets('should trigger delete callback when delete button is tapped', (tester) async {
      bool retryCalled = false;
      bool deleteCalled = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(database),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: FailedScanCard(
                failedScan: testFailedScan,
                onRetry: () => retryCalled = true,
                onDelete: () => deleteCalled = true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the delete button
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Verify callback was triggered
      expect(deleteCalled, true);
      expect(retryCalled, false);
    });

    testWidgets('should navigate to detail screen when card is tapped', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(database),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: FailedScanCard(
                failedScan: testFailedScan,
                onRetry: () {},
                onDelete: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the card (but not on buttons)
      await tester.tap(find.byType(FailedScanCard));
      await tester.pumpAndSettle();

      // Verify detail screen is shown
      expect(find.byType(FailedScanDetailScreen), findsOneWidget);
      expect(find.text('Failed Scan Details'), findsOneWidget);
    });

    testWidgets('should show broken image icon when image file does not exist', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(database),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: FailedScanCard(
                failedScan: testFailedScan,
                onRetry: () {},
                onDelete: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify broken image icon is displayed (since test path doesn't exist)
      expect(find.byIcon(Icons.broken_image), findsOneWidget);
    });

    testWidgets('should format relative timestamps correctly', (tester) async {
      // Test various time differences
      final testCases = [
        {
          'time': DateTime.now().subtract(const Duration(seconds: 30)).millisecondsSinceEpoch,
          'expected': 'Just now',
        },
        {
          'time': DateTime.now().subtract(const Duration(minutes: 5)).millisecondsSinceEpoch,
          'expected': '5 minutes ago',
        },
        {
          'time': DateTime.now().subtract(const Duration(hours: 2)).millisecondsSinceEpoch,
          'expected': '2 hours ago',
        },
        {
          'time': DateTime.now().subtract(const Duration(days: 3)).millisecondsSinceEpoch,
          'expected': '3 days ago',
        },
      ];

      for (final testCase in testCases) {
        final failedScan = FailedScan(
          id: 1,
          jobId: 'test-job',
          imagePath: '/test.jpg',
          errorMessage: 'Test error',
          failureReason: FailureReason.networkError,
          createdAt: testCase['time'] as int,
          expiresAt: DateTime.now().add(const Duration(days: 7)).millisecondsSinceEpoch,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(database),
            ],
            child: MaterialApp(
              theme: AppTheme.darkTheme,
              home: Scaffold(
                body: FailedScanCard(
                  failedScan: failedScan,
                  onRetry: () {},
                  onDelete: () {},
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text(testCase['expected'] as String), findsOneWidget);

        // Clean up for next iteration
        await tester.pumpWidget(Container());
      }
    });

    testWidgets('should show checkbox in select mode', (tester) async {
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(database),
          failedScanSelectModeProvider.overrideWith(() => FailedScanSelectModeNotifier()),
          selectedFailedScansProvider.overrideWith(() => SelectedFailedScansNotifier()),
        ],
      );

      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: FailedScanCard(
                failedScan: testFailedScan,
                onRetry: () {},
                onDelete: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially no checkbox should be visible
      expect(find.byIcon(Icons.check), findsNothing);

      // Enable select mode
      container.read(failedScanSelectModeProvider.notifier).enable();
      await tester.pumpAndSettle();

      // Checkbox should now be visible (but not checked)
      final checkboxContainer = find.byWidgetPredicate(
        (widget) => widget is Container && widget.decoration is BoxDecoration,
      );
      expect(checkboxContainer, findsWidgets);
    });

    testWidgets('should toggle selection when tapped in select mode', (tester) async {
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(database),
          failedScanSelectModeProvider.overrideWith(() => FailedScanSelectModeNotifier()),
          selectedFailedScansProvider.overrideWith(() => SelectedFailedScansNotifier()),
        ],
      );

      addTearDown(container.dispose);

      // Enable select mode
      container.read(failedScanSelectModeProvider.notifier).enable();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: FailedScanCard(
                failedScan: testFailedScan,
                onRetry: () {},
                onDelete: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially not selected
      expect(container.read(selectedFailedScansProvider).contains(testFailedScan.jobId), false);

      // Tap the card to select it
      await tester.tap(find.byType(FailedScanCard));
      await tester.pumpAndSettle();

      // Should now be selected
      expect(container.read(selectedFailedScansProvider).contains(testFailedScan.jobId), true);

      // Tap again to deselect
      await tester.tap(find.byType(FailedScanCard));
      await tester.pumpAndSettle();

      // Should be deselected
      expect(container.read(selectedFailedScansProvider).contains(testFailedScan.jobId), false);
    });

    testWidgets('should hide action buttons in select mode', (tester) async {
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(database),
          failedScanSelectModeProvider.overrideWith(() => FailedScanSelectModeNotifier()),
          selectedFailedScansProvider.overrideWith(() => SelectedFailedScansNotifier()),
        ],
      );

      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: FailedScanCard(
                failedScan: testFailedScan,
                onRetry: () {},
                onDelete: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Buttons should be visible initially
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      // Enable select mode
      container.read(failedScanSelectModeProvider.notifier).enable();
      await tester.pumpAndSettle();

      // Buttons should be hidden in select mode
      expect(find.text('Retry'), findsNothing);
      expect(find.text('Delete'), findsNothing);
    });

    testWidgets('should enable select mode on long press', (tester) async {
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(database),
          failedScanSelectModeProvider.overrideWith(() => FailedScanSelectModeNotifier()),
          selectedFailedScansProvider.overrideWith(() => SelectedFailedScansNotifier()),
        ],
      );

      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: FailedScanCard(
                failedScan: testFailedScan,
                onRetry: () {},
                onDelete: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially not in select mode
      expect(container.read(failedScanSelectModeProvider), false);

      // Long press the card
      await tester.longPress(find.byType(FailedScanCard));
      await tester.pumpAndSettle();

      // Should now be in select mode with this item selected
      expect(container.read(failedScanSelectModeProvider), true);
      expect(container.read(selectedFailedScansProvider).contains(testFailedScan.jobId), true);
    });
  });

  group('FailedScanDetailScreen', () {
    testWidgets('should render with full error message and image', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(database),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: FailedScanDetailScreen(
              failedScan: testFailedScan,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify app bar title
      expect(find.text('Failed Scan Details'), findsOneWidget);

      // Verify error message label and text
      expect(find.text('Error Message'), findsOneWidget);
      expect(find.text('Network connection failed'), findsOneWidget);

      // Verify action buttons
      expect(find.text('Retry Scan'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      // Verify close button
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('should show broken image icon when image file does not exist', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(database),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: FailedScanDetailScreen(
              failedScan: testFailedScan,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify broken image icon is displayed
      expect(find.byIcon(Icons.broken_image), findsOneWidget);
    });

    testWidgets('should show confirmation dialog when delete button is tapped', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(database),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: FailedScanDetailScreen(
              failedScan: testFailedScan,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the delete button
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();

      // Verify confirmation dialog is shown
      expect(find.text('Delete failed scan?'), findsOneWidget);
      expect(find.text('This action cannot be undone.'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Find delete button in dialog (should be different from the one in the bottom bar)
      final deleteButtonsInDialog = find.ancestor(
        of: find.text('Delete'),
        matching: find.byType(TextButton),
      );
      expect(deleteButtonsInDialog, findsOneWidget);
    });

    testWidgets('should cancel delete when Cancel is tapped in dialog', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(database),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: FailedScanDetailScreen(
              failedScan: testFailedScan,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the delete button
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();

      // Tap cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog should be dismissed, detail screen should still be visible
      expect(find.text('Delete failed scan?'), findsNothing);
      expect(find.text('Failed Scan Details'), findsOneWidget);
    });

    testWidgets('should show expandable help section', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(database),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: FailedScanDetailScreen(
              failedScan: testFailedScan,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify help section header
      expect(find.text('Why did this fail?'), findsOneWidget);
      expect(find.byIcon(Icons.help_outline), findsOneWidget);

      // Help content should not be visible initially
      expect(find.textContaining('Network Connection Error'), findsNothing);

      // Tap to expand help section
      await tester.tap(find.text('Why did this fail?'));
      await tester.pumpAndSettle();

      // Help content should now be visible
      expect(find.textContaining('Network Connection Error'), findsOneWidget);
      expect(find.textContaining('Check your internet connection'), findsOneWidget);

      // Expand icon should change
      expect(find.byIcon(Icons.expand_less), findsOneWidget);
    });

    testWidgets('should provide contextual help for different error types', (tester) async {
      final errorTypes = {
        'Rate limit exceeded': 'Rate Limit Error',
        'Image too blurry': 'Image Quality Issue',
        'No books detected': 'No Books Detected',
        'Server error 500': 'Server Error',
      };

      for (final entry in errorTypes.entries) {
        final failedScan = FailedScan(
          id: 1,
          jobId: 'test-job',
          imagePath: '/test.jpg',
          errorMessage: entry.key,
          failureReason: FailureReason.unknown,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          expiresAt: DateTime.now().add(const Duration(days: 7)).millisecondsSinceEpoch,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(database),
            ],
            child: MaterialApp(
              theme: AppTheme.darkTheme,
              home: FailedScanDetailScreen(
                failedScan: failedScan,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Expand help section
        await tester.tap(find.text('Why did this fail?'));
        await tester.pumpAndSettle();

        // Verify correct contextual help is shown
        expect(find.textContaining(entry.value), findsOneWidget);

        // Clean up for next iteration
        await tester.pumpWidget(Container());
        await tester.pumpAndSettle();
      }
    });

    testWidgets('should close screen when close button is tapped', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(database),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => FailedScanDetailScreen(
                          failedScan: testFailedScan,
                        ),
                      ),
                    );
                  },
                  child: const Text('Open Detail'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open detail screen
      await tester.tap(find.text('Open Detail'));
      await tester.pumpAndSettle();

      // Verify we're on detail screen
      expect(find.byType(FailedScanDetailScreen), findsOneWidget);

      // Tap close button
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Verify we're back to the original screen
      expect(find.text('Open Detail'), findsOneWidget);
      expect(find.byType(FailedScanDetailScreen), findsNothing);
    });

    testWidgets('should format full timestamp correctly', (tester) async {
      final testTime = DateTime(2026, 1, 15, 14, 30);
      final failedScan = FailedScan(
        id: 1,
        jobId: 'test-job',
        imagePath: '/test.jpg',
        errorMessage: 'Test error',
        failureReason: FailureReason.networkError,
        createdAt: testTime.millisecondsSinceEpoch,
        expiresAt: DateTime.now().add(const Duration(days: 7)).millisecondsSinceEpoch,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(database),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: FailedScanDetailScreen(
              failedScan: failedScan,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify formatted timestamp is displayed
      expect(find.textContaining('Failed on'), findsOneWidget);
      expect(find.textContaining('Jan 15, 2026'), findsOneWidget);
    });
  });

  group('Batch Retry Functionality', () {
    testWidgets('should show batch retry UI elements when multiple scans are selected', (tester) async {
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(database),
          failedScanSelectModeProvider.overrideWith(() => FailedScanSelectModeNotifier()),
          selectedFailedScansProvider.overrideWith(() => SelectedFailedScansNotifier()),
        ],
      );

      addTearDown(container.dispose);

      // Enable select mode and select items
      container.read(failedScanSelectModeProvider.notifier).enable();
      container.read(selectedFailedScansProvider.notifier).selectAll(['job1', 'job2', 'job3']);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  final selectedCount = ref.watch(selectedFailedScansProvider).length;
                  final selectMode = ref.watch(failedScanSelectModeProvider);

                  return Column(
                    children: [
                      if (selectMode && selectedCount > 0)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Text(
                                '$selectedCount selected',
                                style: const TextStyle(color: AppTheme.textPrimary),
                              ),
                              const Spacer(),
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.internationalOrange,
                                ),
                                child: const Text('Retry All'),
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify batch retry button appears
      expect(find.text('3 selected'), findsOneWidget);
      expect(find.text('Retry All'), findsOneWidget);
    });

    testWidgets('should update selection count when items are selected/deselected', (tester) async {
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(database),
          failedScanSelectModeProvider.overrideWith(() => FailedScanSelectModeNotifier()),
          selectedFailedScansProvider.overrideWith(() => SelectedFailedScansNotifier()),
        ],
      );

      addTearDown(container.dispose);

      // Enable select mode
      container.read(failedScanSelectModeProvider.notifier).enable();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  final selectedCount = ref.watch(selectedFailedScansProvider).length;
                  final selectMode = ref.watch(failedScanSelectModeProvider);

                  return Column(
                    children: [
                      if (selectMode && selectedCount > 0)
                        Text(
                          '$selectedCount selected',
                          style: const TextStyle(color: AppTheme.textPrimary),
                        ),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(selectedFailedScansProvider.notifier).toggle('job1');
                        },
                        child: const Text('Toggle Job 1'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(selectedFailedScansProvider.notifier).toggle('job2');
                        },
                        child: const Text('Toggle Job 2'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially no selection
      expect(find.text('1 selected'), findsNothing);

      // Select one item
      await tester.tap(find.text('Toggle Job 1'));
      await tester.pumpAndSettle();

      expect(find.text('1 selected'), findsOneWidget);

      // Select another item
      await tester.tap(find.text('Toggle Job 2'));
      await tester.pumpAndSettle();

      expect(find.text('2 selected'), findsOneWidget);

      // Deselect one item
      await tester.tap(find.text('Toggle Job 1'));
      await tester.pumpAndSettle();

      expect(find.text('1 selected'), findsOneWidget);
    });

    testWidgets('should clear selection when exiting select mode', (tester) async {
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(database),
          failedScanSelectModeProvider.overrideWith(() => FailedScanSelectModeNotifier()),
          selectedFailedScansProvider.overrideWith(() => SelectedFailedScansNotifier()),
        ],
      );

      addTearDown(container.dispose);

      // Enable select mode and select items
      container.read(failedScanSelectModeProvider.notifier).enable();
      container.read(selectedFailedScansProvider.notifier).selectAll(['job1', 'job2']);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  final selectedCount = ref.watch(selectedFailedScansProvider).length;
                  final selectMode = ref.watch(failedScanSelectModeProvider);

                  return Column(
                    children: [
                      Text('Selected: $selectedCount'),
                      Text('Select mode: $selectMode'),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(failedScanSelectModeProvider.notifier).disable();
                        },
                        child: const Text('Exit Select Mode'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify items are selected
      expect(find.text('Selected: 2'), findsOneWidget);
      expect(find.text('Select mode: true'), findsOneWidget);

      // Exit select mode
      await tester.tap(find.text('Exit Select Mode'));
      await tester.pumpAndSettle();

      // Verify selection is cleared
      expect(find.text('Selected: 0'), findsOneWidget);
      expect(find.text('Select mode: false'), findsOneWidget);
    });
  });
}
