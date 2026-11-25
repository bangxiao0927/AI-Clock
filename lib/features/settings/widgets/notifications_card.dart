import 'package:flutter/material.dart';

import '../../../core/di/provide.dart';
import '../../../core/services/feedback_context.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';

/// Shows whether system notifications are allowed and lets the user allow
/// them. Alarms, timers and reminders need them to alert when the app is
/// closed.
class NotificationsCard extends StatefulWidget {
  const NotificationsCard({super.key});

  @override
  State<NotificationsCard> createState() => _NotificationsCardState();
}

class _NotificationsCardState extends State<NotificationsCard> {
  bool? _permitted;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final permitted = await context.read<NotificationService>().isPermitted();
    if (mounted) setState(() => _permitted = permitted);
  }

  Future<void> _allow() async {
    context.tapFeedback();
    final granted = await context
        .read<NotificationService>()
        .requestPermission();
    if (mounted) setState(() => _permitted = granted);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final permitted = _permitted;
    final muted = textTheme.bodyMedium?.copyWith(color: AppColors.textMuted);

    return AppCard(
      child: Row(
        children: [
          Icon(
            permitted == true
                ? Icons.notifications_active_rounded
                : Icons.notifications_off_outlined,
            color: permitted == true
                ? AppColors.notesAccent
                : AppColors.textMuted,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Alerts when closed', style: textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  permitted == null
                      ? 'Checking…'
                      : permitted
                      ? 'Alarms, timers and reminders will alert you even when the app is closed.'
                      : 'Allow notifications so alarms, timers and reminders can alert you when the app is closed.',
                  style: muted,
                ),
              ],
            ),
          ),
          if (permitted == false) ...[
            const SizedBox(width: 12),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.optionsAccent,
                foregroundColor: AppColors.background,
              ),
              onPressed: _allow,
              child: const Text('Allow'),
            ),
          ],
        ],
      ),
    );
  }
}
