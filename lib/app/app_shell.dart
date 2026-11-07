import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_theme.dart';
import '../core/widgets/ambient_background.dart';
import '../core/widgets/fade_indexed_stack.dart';
import '../core/widgets/glass_tab_bar.dart';
import '../features/home/home_screen.dart';
import '../tools/app_tool.dart';
import '../tools/tool_registry.dart';

/// The main screen: a floating glass tab bar with Home plus one tab per tool.
///
/// Tab 0 is Home; tab `i + 1` is `appTools[i]`. Tabs are built the first time
/// they are opened and then kept alive.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _homeIndex = 0;

  int _index = _homeIndex;

  void _select(int index) {
    if (index == _index) return;
    HapticFeedback.selectionClick();
    setState(() => _index = index);
  }

  void _openTool(AppTool tool) => _select(appTools.indexOf(tool) + 1);

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
            itemBuilder: (context, index) => index == _homeIndex
                ? HomeScreen(onOpenTool: _openTool)
                : appTools[index - 1].builder(context),
          ),
        ),
      ),
    );
  }
}
