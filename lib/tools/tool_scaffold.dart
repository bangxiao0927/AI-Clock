import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/widgets/fade_slide_in.dart';
import '../core/widgets/tool_icon.dart';
import 'app_tool.dart';

/// Shared layout for every tool screen: an icon + title header, then the
/// screen's cards fading in one after another.
///
/// The background is transparent (the app shell paints it) and the list leaves
/// room at the bottom, so content scrolls underneath the glass tab bar.
class ToolScaffold extends StatelessWidget {
  const ToolScaffold({super.key, required this.info, required this.children});

  final ToolInfo info;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
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
                    ToolIcon(icon: info.icon, color: info.color),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Semantics(
                            header: true,
                            child: Text(
                              info.title,
                              style: textTheme.headlineMedium,
                            ),
                          ),
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
                  ],
                ),
                const SizedBox(height: 28),
                for (final (index, child) in children.indexed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: FadeSlideIn(
                      delay: Duration(milliseconds: 120 + 90 * index),
                      child: child,
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
