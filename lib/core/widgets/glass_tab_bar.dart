import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'glass_container.dart';

/// One destination in a [GlassTabBar].
@immutable
class GlassTabItem {
  const GlassTabItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;

  /// Tint of the selected state (icon, label and the sliding highlight).
  final Color color;
}

/// A floating, pill-shaped tab bar made of frosted glass.
///
/// Meant for `Scaffold(extendBody: true, bottomNavigationBar: ...)` so page
/// content scrolls underneath and shows through the blur. A tinted capsule
/// slides to the selected item.
class GlassTabBar extends StatelessWidget {
  const GlassTabBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<GlassTabItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _itemHeight = 64.0;
  static const _inset = 6.0;
  static const _radius = 36.0;
  static const _slide = Duration(milliseconds: 320);

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final count = items.length;
    // Maps item i of n to -1..1 for an Align that spans the whole row.
    final alignmentX = count < 2 ? 0.0 : -1 + 2 * currentIndex / (count - 1);

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, math.max(bottomInset - 10, 12)),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          // Keep labels inside the bar even with very large system text.
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.2,
            child: GlassContainer(
              borderRadius: BorderRadius.circular(_radius),
              blur: 28,
              padding: const EdgeInsets.all(_inset),
              child: SizedBox(
                height: _itemHeight,
                child: Stack(
                  children: [
                    AnimatedAlign(
                      duration: _slide,
                      curve: Curves.easeOutCubic,
                      alignment: Alignment(alignmentX, 0),
                      child: FractionallySizedBox(
                        widthFactor: 1 / count,
                        heightFactor: 1,
                        child: AnimatedContainer(
                          duration: _slide,
                          curve: Curves.easeOutCubic,
                          decoration: BoxDecoration(
                            color: items[currentIndex].color.withValues(
                              alpha: 0.18,
                            ),
                            borderRadius: BorderRadius.circular(
                              _radius - _inset,
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.14),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        for (final (index, item) in items.indexed)
                          Expanded(
                            child: _TabButton(
                              item: item,
                              selected: index == currentIndex,
                              onTap: () => onTap(index),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final GlassTabItem item;
  final bool selected;
  final VoidCallback onTap;

  static const _fade = Duration(milliseconds: 220);

  @override
  Widget build(BuildContext context) {
    final color = selected ? item.color : AppColors.textMuted;
    final labelStyle =
        Theme.of(context).textTheme.labelSmall ?? const TextStyle();

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<Color?>(
              tween: ColorTween(end: color),
              duration: _fade,
              builder: (context, value, _) =>
                  Icon(item.icon, size: 24, color: value),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: _fade,
              style: labelStyle.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
              child: Text(item.label, maxLines: 1),
            ),
          ],
        ),
      ),
    );
  }
}
