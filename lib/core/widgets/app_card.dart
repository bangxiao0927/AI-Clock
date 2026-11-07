import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The one card style used across the app. Tappable when [onTap] is set, with
/// a subtle press-down scale.
class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final onTap = widget.onTap;
    return AnimatedScale(
      scale: _pressed ? 0.98 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Material(
        // Translucent so the ambient background shows through, like glass.
        color: AppColors.glassFill,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.glassBorder),
        ),
        child: InkWell(
          onTap: onTap,
          onHighlightChanged: onTap == null
              ? null
              : (value) => setState(() => _pressed = value),
          child: Padding(padding: widget.padding, child: widget.child),
        ),
      ),
    );
  }
}
