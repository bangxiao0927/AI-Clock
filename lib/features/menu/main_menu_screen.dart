import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/feature_icon.dart';
import '../app_feature.dart';
import '../clock/clock_screen.dart';
import '../day/day_screen.dart';
import '../notes/notes_screen.dart';

/// Main menu: one card per feature area. Cards fade in one after another and
/// open their screen with the theme's page transition.
class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  static Widget _screenFor(AppFeature feature) => switch (feature) {
    AppFeature.clock => const ClockScreen(),
    AppFeature.day => const DayScreen(),
    AppFeature.notes => const NotesScreen(),
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
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
                            Text(AppInfo.name, style: textTheme.headlineMedium),
                            const SizedBox(height: 2),
                            Text(
                              AppInfo.tagline,
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 36),
                for (final (index, feature) in AppFeature.values.indexed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: FadeSlideIn(
                      delay: Duration(milliseconds: 180 + 90 * index),
                      child: _FeatureCard(feature: feature),
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

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.feature});

  final AppFeature feature;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => MainMenuScreen._screenFor(feature),
        ),
      ),
      child: Row(
        children: [
          Hero(
            tag: feature.heroTag,
            child: FeatureIcon(icon: feature.icon, color: feature.color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(feature.title, style: textTheme.titleLarge),
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
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
