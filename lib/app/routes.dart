/// Names of the app's top-level routes. Constants only, so any screen can
/// navigate by name without importing other screens.
abstract final class AppRoutes {
  static const splash = '/';
  static const shell = '/home';
}

/// Arguments for [AppRoutes.shell].
class ShellRouteArgs {
  const ShellRouteArgs({this.instant = false});

  /// Skip the cross-fade (used when the system asks for reduced motion).
  final bool instant;
}
