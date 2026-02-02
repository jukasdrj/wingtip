import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wingtip/features/talaria/scan_progress_overlay.dart';

void main() {
  group('ScanProgressOverlay', () {
    testWidgets('renders with correct progress text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                ScanProgressOverlay(
                  currentBook: 3,
                  totalBooks: 12,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Processing book 3 of 12...'), findsOneWidget);
    });

    testWidgets('renders progress bar with correct value', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                ScanProgressOverlay(
                  currentBook: 6,
                  totalBooks: 12,
                ),
              ],
            ),
          ),
        ),
      );

      final progressBar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressBar.value, equals(0.5)); // 6/12 = 0.5
    });

    testWidgets('updates progress when currentBook changes', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                ScanProgressOverlay(
                  currentBook: 1,
                  totalBooks: 5,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Processing book 1 of 5...'), findsOneWidget);

      // Update to next book
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                ScanProgressOverlay(
                  currentBook: 2,
                  totalBooks: 5,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300)); // Animation duration

      expect(find.text('Processing book 2 of 5...'), findsOneWidget);
    });

    testWidgets('uses Swiss Utility design elements', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                ScanProgressOverlay(
                  currentBook: 1,
                  totalBooks: 10,
                ),
              ],
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(ScanProgressOverlay),
          matching: find.byType(Container),
        ).first,
      );

      final decoration = container.decoration as BoxDecoration;

      // Verify semi-transparent black background
      expect(decoration.color, equals(Colors.black.withValues(alpha: 0.8)));

      // Verify 1px border
      expect(decoration.border, isNotNull);
      final border = decoration.border as Border;
      expect(border.top.width, equals(1));
    });
  });
}
