import 'package:flutter/material.dart';

/// Like an `IndexedStack`, but pages cross-fade and are built lazily.
///
/// - A page is built the first time it is selected, then kept alive, so tabs
///   keep their scroll position and state.
/// - Pages that are not selected are invisible, ignore touches, are hidden
///   from screen readers and have their animations paused (`TickerMode`).
class FadeIndexedStack extends StatefulWidget {
  const FadeIndexedStack({
    super.key,
    required this.index,
    required this.itemCount,
    required this.itemBuilder,
    this.duration = const Duration(milliseconds: 280),
  });

  final int index;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final Duration duration;

  @override
  State<FadeIndexedStack> createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<FadeIndexedStack> {
  final Set<int> _visited = {};

  @override
  Widget build(BuildContext context) {
    _visited.add(widget.index);
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : widget.duration;

    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < widget.itemCount; i++)
          if (_visited.contains(i))
            _FadePage(
              key: ValueKey(i),
              active: i == widget.index,
              duration: duration,
              child: widget.itemBuilder(context, i),
            ),
      ],
    );
  }
}

class _FadePage extends StatelessWidget {
  const _FadePage({
    super.key,
    required this.active,
    required this.duration,
    required this.child,
  });

  final bool active;
  final Duration duration;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !active,
      child: ExcludeSemantics(
        excluding: !active,
        child: AnimatedOpacity(
          opacity: active ? 1 : 0,
          duration: duration,
          curve: Curves.easeOut,
          child: AnimatedScale(
            scale: active ? 1 : 0.985,
            duration: duration,
            curve: Curves.easeOut,
            // Pause only the page's own animations. The fade above must keep
            // running, or a page that was just left would freeze half-faded.
            child: TickerMode(enabled: active, child: child),
          ),
        ),
      ),
    );
  }
}
