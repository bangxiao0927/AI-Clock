import 'package:flutter/material.dart';

import '../core/services/feedback_context.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/ambient_background.dart';
import '../core/widgets/fade_indexed_stack.dart';
import '../core/widgets/glass_tab_bar.dart';
import '../features/home/home_screen.dart';
import '../features/settings/settings_screen.dart';
import '../tools/clock/clock_tool.dart';
import '../tools/tool_registry.dart';

/// The main screen: a floating glass tab bar with Home, one tab per tool, and
/// Options.
///
/// Tab 0 is Home, tabs 1..n are `appTools`, and the last tab is Options. Tabs
/// are built the first time they are opened and then kept alive.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _homeIndex = 0;
  static final _optionsIndex = appTools.length + 1;

  int _index = _homeIndex;

  void _select(int index) {
    if (index == _index) return;
    context.tapFeedback();
    setState(() => _index = index);
  }

  void _openClock() {
    final position = appTools.indexWhere((t) => t.info.id == clockInfo.id);
    if (position >= 0) _select(position + 1);
  }

  Widget _page(BuildContext context, int index) {
    if (index == _homeIndex) return HomeScreen(onOpenClock: _openClock);
    if (index == _optionsIndex) return const SettingsScreen();
    return appTools[index - 1].builder(context);
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      const GlassTabItem(
        icon: Icons.home_rounded,
        label: 'Home',
        color: AppColors.homeAccent,
      ),
      for (final tool in appTools)
        GlassTabItem(
          icon: tool.info.icon,
          label: tool.info.title,
          color: tool.info.color,
        ),
      GlassTabItem(
        icon: settingsInfo.icon,
        label: settingsInfo.title,
        color: settingsInfo.color,
      ),
    ];

    // Back goes to Home first, and only leaves the app from Home.
    return PopScope(
      canPop: _index == _homeIndex,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _index = _homeIndex);
      },
      child: Scaffold(
        extendBody: true,
        bottomNavigationBar: GlassTabBar(
          items: items,
          currentIndex: _index,
          onTap: _select,
        ),
        body: AmbientBackground(
          child: FadeIndexedStack(
            index: _index,
            itemCount: items.length,
            itemBuilder: _page,
          ),
        ),
      ),
    );
  }
}
