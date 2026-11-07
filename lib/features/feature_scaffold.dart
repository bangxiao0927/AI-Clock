import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/widgets/fade_slide_in.dart';
import '../core/widgets/feature_icon.dart';
import 'app_feature.dart';

/// Shared layout for the three feature screens: back button, icon + title
/// header, then the screen's content cards fading in one after another.
class FeatureScaffold extends StatelessWidget {
  const FeatureScaffold({
    super.key,
    required this.feature,
    required this.children,
  });

  final AppFeature feature;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              children: [
                Row(
                  children: [
                    Hero(
                      tag: feature.heroTag,
                      child: FeatureIcon(
                        icon: feature.icon,
                        color: feature.color,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(feature.title, style: textTheme.headlineMedium),
                          const SizedBox(height: 2),
                          Text(
                            feature.description,
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
