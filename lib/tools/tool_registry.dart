import 'app_tool.dart';
import 'clock/clock_screen.dart';
import 'clock/clock_tool.dart';
import 'day/day_screen.dart';
import 'day/day_tool.dart';
import 'notes/notes_screen.dart';
import 'notes/notes_tool.dart';

/// Every tool in the app, in tab-bar order.
///
/// To add a tool:
///  1. Create `lib/tools/<name>/` with `<name>_tool.dart` (a const `ToolInfo`)
///     and `<name>_screen.dart` (the screen; use `ToolScaffold`).
///  2. Add one `AppTool(...)` line below.
///
/// The tab bar and the Home screen pick it up automatically. The tab bar is
/// meant for roughly 3 to 4 tools; past that, keep extra tools on Home only.
final List<AppTool> appTools = List.unmodifiable([
  AppTool(info: clockInfo, builder: (_) => const ClockScreen()),
  AppTool(info: dayInfo, builder: (_) => const DayScreen()),
  AppTool(info: notesInfo, builder: (_) => const NotesScreen()),
]);
