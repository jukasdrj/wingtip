import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:wingtip/data/database.dart';
import 'package:wingtip/services/widget_channel.dart';

/// Service to export widget data for iOS WidgetKit extension
class WidgetDataService {
  /// Update widget data after book changes
  static Future<void> updateWidgetData(AppDatabase database) async {
    try {
      // Get total book count
      final books = await database.getAllBooks();
      final totalCount = books.length;

      // Get last scanned book (most recent by addedDate)
      Book? lastBook;
      if (books.isNotEmpty) {
        lastBook = books.first; // Already sorted by addedDate DESC
      }

      // Prepare widget data
      final widgetData = {
        'totalCount': totalCount,
        'lastScanDate': lastBook?.addedDate ?? 0,
        'lastBookTitle': lastBook?.title ?? '',
        'lastBookAuthor': lastBook?.author ?? '',
        'lastBookCoverUrl': lastBook?.coverUrl ?? '',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      // Write to shared UserDefaults (App Group) via platform channel
      if (Platform.isIOS) {
        await WidgetChannel.updateWidgetData(widgetData);
        await WidgetChannel.reloadWidgets();
      }
    } catch (e) {
      // Silent fail - widget updates are not critical
      debugPrint('[WidgetDataService] Error updating widget data: $e');
    }
  }
}
