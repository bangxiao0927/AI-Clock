import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// The three main feature areas. Metadata only: each area's screen lives in
/// its own folder under `lib/features/`.
enum AppFeature {
  clock(
    title: 'Clock',
    description: 'Live time on a calm analog face',
    icon: Icons.schedule_rounded,
    color: AppColors.clockAccent,
  ),
  day(
    title: 'Day',
    description: "Today's date and how far along it is",
    icon: Icons.today_rounded,
    color: AppColors.dayAccent,
  ),
  notes(
    title: 'Notes',
    description: 'A quiet place for quick thoughts',
    icon: Icons.edit_note_rounded,
    color: AppColors.notesAccent,
  );

  const AppFeature({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;

  /// Shared [Hero] tag: the menu card's icon flies into the screen header.
  String get heroTag => 'feature-icon-$name';
}
