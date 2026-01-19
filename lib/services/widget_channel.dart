import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Platform channel for iOS widget data communication
class WidgetChannel {
  static const platform = MethodChannel('com.ooheynerds.wingtip/widget');

  /// Update widget data via platform channel
  static Future<void> updateWidgetData(Map<String, dynamic> data) async {
    try {
      await platform.invokeMethod('updateWidgetData', {
        'data': jsonEncode(data),
      });
    } on PlatformException catch (e) {
      debugPrint('[WidgetChannel] Error: ${e.message}');
    }
  }

  /// Reload all widgets
  static Future<void> reloadWidgets() async {
    try {
      await platform.invokeMethod('reloadWidgets');
    } on PlatformException catch (e) {
      debugPrint('[WidgetChannel] Error reloading widgets: ${e.message}');
    }
  }
}
