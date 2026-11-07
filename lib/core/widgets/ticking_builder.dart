import 'dart:async';

import 'package:flutter/widgets.dart';

/// Rebuilds [builder] with the current time every [interval].
///
/// Updates pause while the widget is not visible (its `TickerMode` is off,
/// which is the case for background tabs) and the time is refreshed the
/// moment it becomes visible again.
class TickingBuilder extends StatefulWidget {
  const TickingBuilder({
    super.key,
    required this.builder,
    this.interval = const Duration(seconds: 1),
  });

  final Widget Function(BuildContext context, DateTime now) builder;

  /// Fixed for the lifetime of the widget.
  final Duration interval;

  @override
  State<TickingBuilder> createState() => _TickingBuilderState();
}

class _TickingBuilderState extends State<TickingBuilder> {
  late final Timer _timer;
  DateTime _now = DateTime.now();
  bool _active = true;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.interval, (_) {
      if (_active) setState(() => _now = DateTime.now());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final active = TickerMode.valuesOf(context).enabled;
    if (active && !_active) _now = DateTime.now();
    _active = active;
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _now);
}
