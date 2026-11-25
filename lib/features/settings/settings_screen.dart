import 'package:flutter/material.dart';

import '../../core/di/provide.dart';
import '../../core/services/feedback_context.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/pill_segments.dart';
import '../../tools/app_tool.dart';
import '../../tools/tool_scaffold.dart';
import 'widgets/background_picker.dart';
import 'widgets/notifications_card.dart';
import 'widgets/setting_switch_row.dart';

const settingsInfo = ToolInfo(
  id: 'options',
  title: 'Options',
  description: 'Sounds, background and more',
  icon: Icons.tune_rounded,
  color: AppColors.optionsAccent,
);

/// Options tab. Every change is saved straight away by [AppSettings], so the
/// choices are still there after the app has been closed completely.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.read<AppSettings>();
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodyMedium?.copyWith(color: AppColors.textMuted);

    return ToolScaffold(
      info: settingsInfo,
      children: [
        ListenableBuilder(
          listenable: settings,
          builder: (context, _) => AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              children: [
                SettingSwitchRow(
                  icon: Icons.touch_app_rounded,
                  title: 'Sound effects',
                  subtitle: 'Clicks and taps',
                  value: settings.soundEffects,
                  onChanged: settings.setSoundEffects,
                ),
                SettingSwitchRow(
                  icon: Icons.alarm_rounded,
                  title: 'Alarm & timer sounds',
                  subtitle: 'Ringing while the app is open',
                  value: settings.alarmSounds,
                  onChanged: settings.setAlarmSounds,
                ),
                SettingSwitchRow(
                  icon: Icons.vibration_rounded,
                  title: 'Haptics',
                  subtitle: 'A small vibration on taps',
                  value: settings.haptics,
                  onChanged: settings.setHaptics,
                ),
              ],
            ),
          ),
        ),
        ListenableBuilder(
          listenable: settings,
          builder: (context, _) => AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Background', style: textTheme.titleMedium),
                const SizedBox(height: 4),
                Text('The glow behind everything', style: muted),
                const SizedBox(height: 16),
                BackgroundPicker(
                  selected: settings.background,
                  onChanged: settings.setBackground,
                ),
                const SizedBox(height: 24),
                Text('Time format', style: textTheme.titleMedium),
                const SizedBox(height: 12),
                PillSegments<TimeFormat>(
                  accent: settingsInfo.color,
                  selected: settings.timeFormat,
                  onChanged: settings.setTimeFormat,
                  segments: [
                    for (final format in TimeFormat.values)
                      PillSegment(value: format, label: format.label),
                  ],
                ),
              ],
            ),
          ),
        ),
        const NotificationsCard(),
        Center(
          child: TextButton.icon(
            onPressed: () {
              context.confirmFeedback();
              settings.resetToDefaults();
            },
            icon: const Icon(Icons.restart_alt_rounded),
            label: const Text('Reset to defaults'),
          ),
        ),
      ],
    );
  }
}
