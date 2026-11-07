import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_time_format.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/ticking_builder.dart';
import '../../core/widgets/tool_icon.dart';
import '../../tools/app_tool.dart';
import '../../tools/tool_registry.dart';

/// Home tab: the app name, a greeting, and a card for every tool.
/// Tapping a card calls [onOpenTool] (the shell switches to that tool's tab).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onOpenTool});

  final ValueChanged<AppTool> onOpenTool;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodyMedium?.copyWith(color: AppColors.textMuted);
    // Includes the height of the tab bar, because the shell extends the body
    // behind it.
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: EdgeInsets.fromLTRB(24, 24, 24, bottomInset + 24),
              children: [
                Row(
                  children: [
                    SizedBox.square(
                      dimension: 56,
                      child: Hero(tag: AppLogo.heroTag, child: const AppLogo()),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FadeSlideIn(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Semantics(
                              header: true,
                              child: Text(
                                AppInfo.name,
                                style: textTheme.headlineMedium,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(AppInfo.tagline, style: muted),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 36),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 100),
                  child: TickingBuilder(
                    interval: const Duration(minutes: 1),
                    builder: (context, now) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(greeting(now), style: textTheme.headlineLarge),
                        const SizedBox(height: 4),
                        Text(formatFullDate(now), style: muted),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 160),
                  child: Text(
                    'TOOLS',
                    style: textTheme.labelMedium?.copyWith(
                      color: AppColors.textMuted,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                for (final (index, tool) in appTools.indexed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: FadeSlideIn(
                      delay: Duration(milliseconds: 220 + 90 * index),
                      child: _ToolCard(
                        tool: tool,
                        onTap: () => onOpenTool(tool),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({required this.tool, required this.onTap});

  final AppTool tool;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final info = tool.info;

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          ToolIcon(icon: info.icon, color: info.color),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(info.title, style: textTheme.titleLarge),
                const SizedBox(height: 2),
                Text(
                  info.description,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
