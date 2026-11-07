import 'package:flutter/widgets.dart';

/// What the app needs to know about a tool to list it: the tab bar and the
/// Home screen are both built from this. Plain, const data, so a tool's
/// screen can import its own info without importing anything else.
@immutable
class ToolInfo {
  const ToolInfo({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  /// Stable identifier, unique across tools (also usable for route names).
  final String id;
  final String title;

  /// One line shown on the Home screen and under the screen title.
  final String description;
  final IconData icon;

  /// The tool's accent colour.
  final Color color;
}

/// A tool plugged into the app: its [info] plus the screen it opens.
@immutable
class AppTool {
  const AppTool({required this.info, required this.builder});

  final ToolInfo info;
  final WidgetBuilder builder;
}
