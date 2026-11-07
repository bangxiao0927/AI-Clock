import 'package:flutter/material.dart';

import '../../core/widgets/app_card.dart';
import '../tool_scaffold.dart';
import 'notes_tool.dart';
import 'widgets/notes_empty_state.dart';

/// Notes: an empty state for now. The editor comes in a later iteration.
class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      info: notesInfo,
      children: [
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          child: NotesEmptyState(accent: notesInfo.color),
        ),
      ],
    );
  }
}
