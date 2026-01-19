import 'package:flutter/material.dart';

/// A widget that can restart the entire app by rebuilding its child tree.
///
/// Wrap your app's root widget with RestartWidget and call RestartWidget.restartApp(context)
/// to trigger a full app restart. This is useful for cases like regenerating device IDs
/// where you need to reinitialize the entire app state.
class RestartWidget extends StatefulWidget {
  const RestartWidget({super.key, required this.child});

  final Widget child;

  static void restartApp(BuildContext context) {
    context.findAncestorStateOfType<_RestartWidgetState>()?.restartApp();
  }

  @override
  State<RestartWidget> createState() => _RestartWidgetState();
}

class _RestartWidgetState extends State<RestartWidget> {
  Key _key = UniqueKey();

  void restartApp() {
    setState(() {
      _key = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: _key,
      child: widget.child,
    );
  }
}
