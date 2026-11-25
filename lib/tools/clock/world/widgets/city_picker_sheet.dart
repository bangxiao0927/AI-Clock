import 'package:flutter/material.dart';

import '../../../../core/di/provide.dart';
import '../../../../core/services/feedback_context.dart';
import '../../../../core/theme/app_theme.dart';
import '../city.dart';
import '../world_clock_controller.dart';

/// Bottom sheet for adding a city: a search box over the cities not yet on the
/// world clock. Tapping one adds it and closes the sheet.
class CityPickerSheet extends StatefulWidget {
  const CityPickerSheet({super.key});

  @override
  State<CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends State<CityPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final world = context.read<WorldClockController>();
    final textTheme = Theme.of(context).textTheme;
    final needle = _query.trim().toLowerCase();
    final cities = [
      for (final city in allCities)
        if (!world.contains(city) &&
            (city.name.toLowerCase().contains(needle) ||
                city.country.toLowerCase().contains(needle)))
          city,
    ];

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.7,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: TextField(
              autofocus: false,
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                hintText: 'Search cities',
                prefixIcon: Icon(Icons.search_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
            ),
          ),
          Expanded(
            child: cities.isEmpty
                ? Center(
                    child: Text(
                      needle.isEmpty
                          ? 'Every city is already added.'
                          : 'No cities match "$_query".',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: cities.length,
                    itemBuilder: (context, index) {
                      final city = cities[index];
                      return ListTile(
                        title: Text(city.name),
                        subtitle: Text(city.country),
                        trailing: const Icon(Icons.add_rounded),
                        onTap: () {
                          context.confirmFeedback();
                          world.add(city);
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
