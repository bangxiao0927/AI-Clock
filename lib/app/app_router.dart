import 'package:flutter/material.dart';

import '../core/transitions/fade_route.dart';
import '../features/splash/splash_screen.dart';
import 'app_shell.dart';
import 'routes.dart';

/// Builds the route for each top-level route name.
///
/// Tools live inside [AppShell] as tabs, so they are not routes here. A tool's
/// own detail screens (for example a note editor) can be pushed on top of the
/// shell with `Navigator.push`.
abstract final class AppRouter {
  static Route<void> onGenerateRoute(RouteSettings settings) {
    return switch (settings.name) {
      AppRoutes.shell => _shell(settings),
      _ => MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const SplashScreen(),
      ),
    };
  }

  static Route<void> _shell(RouteSettings settings) {
    final args = settings.arguments;
    final instant = args is ShellRouteArgs && args.instant;
    return FadeRoute<void>(
      settings: settings,
      duration: instant ? Duration.zero : const Duration(milliseconds: 700),
      builder: (_) => const AppShell(),
    );
  }
}
