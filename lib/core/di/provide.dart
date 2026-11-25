import 'package:flutter/widgets.dart';

/// Makes one object of type [T] available to every widget below it.
///
/// A tiny stand-in for the `provider` package: `Provide<AppSettings>` above
/// the app, then `context.read<AppSettings>()` anywhere below. It never
/// rebuilds listeners by itself; widgets that need updates wrap the object in
/// a `ListenableBuilder` (every controller here is a `ChangeNotifier`).
class Provide<T extends Object> extends InheritedWidget {
  const Provide({super.key, required this.value, required super.child});

  final T value;

  /// The provided [T], or null when nothing above provides one.
  static T? maybeOf<T extends Object>(BuildContext context) =>
      context.getInheritedWidgetOfExactType<Provide<T>>()?.value;

  static T of<T extends Object>(BuildContext context) {
    final value = maybeOf<T>(context);
    assert(value != null, 'No Provide<$T> found above this widget.');
    return value!;
  }

  @override
  bool updateShouldNotify(Provide<T> oldWidget) => oldWidget.value != value;
}

extension ProvideContext on BuildContext {
  /// The object of type [T] provided above this widget.
  T read<T extends Object>() => Provide.of<T>(this);

  /// Like [read], but null instead of an error when nothing is provided.
  /// Lets shared widgets (cards, buttons) work in isolation, e.g. in tests.
  T? maybeRead<T extends Object>() => Provide.maybeOf<T>(this);
}
