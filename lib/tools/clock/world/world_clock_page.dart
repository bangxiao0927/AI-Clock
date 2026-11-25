import 'package:flutter/material.dart';

import '../../../core/di/provide.dart';
import '../../../core/services/feedback_context.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/ticking_builder.dart';
import '../clock_tool.dart';
import '../widgets/clock_card.dart';
import 'city.dart';
import 'widgets/city_picker_sheet.dart';
import 'widgets/world_clock_tile.dart';
import 'world_clock_controller.dart';

/// World section: the local time, then the user's cities. Swipe a city away to
/// remove it (with undo); the button adds more.
class WorldClockPage extends StatelessWidget {
  const WorldClockPage({super.key});

  void _remove(BuildContext context, WorldClockController world, City city) {
    context.tapFeedback();
    world.remove(city);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Removed ${city.name}'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => world.add(city),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final world = context.read<WorldClockController>();
    final settings = context.read<AppSettings>();
    final textTheme = Theme.of(context).textTheme;

    return ListenableBuilder(
      listenable: Listenable.merge([world, settings]),
      builder: (context, _) {
        final use24Hour = settings.use24Hour(context);
        return TickingBuilder(
          builder: (context, now) => Column(
            children: [
              AppCard(
                child: ClockCard(
                  time: now,
                  accent: clockInfo.color,
                  use24Hour: use24Hour,
                ),
              ),
              const SizedBox(height: 16),
              if (world.cities.isEmpty)
                AppCard(
                  child: SizedBox(
                    width: double.infinity,
                    child: Text(
                      'No cities yet. Add one to see its time here.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              for (final city in world.cities)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Dismissible(
                    key: ValueKey(city.id),
                    direction: DismissDirection.endToStart,
                    background: const _DeleteBackground(),
                    onDismissed: (_) => _remove(context, world, city),
                    child: WorldClockTile(
                      city: city,
                      now: now,
                      use24Hour: use24Hour,
                    ),
                  ),
                ),
              const SizedBox(height: 4),
              OutlinedButton.icon(
                onPressed: context.tapped(
                  () => showAppSheet<void>(
                    context,
                    builder: (_) => const CityPickerSheet(),
                  ),
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add city'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 24),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
    );
  }
}
