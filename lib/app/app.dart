import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/theme/app_theme.dart';
import 'app_router.dart';
import 'app_services.dart';
import 'ring_overlay.dart';
import 'routes.dart';

/// Root widget. Makes [services] available to every screen, shows the ring
/// banner above all routes, and starts on the animated splash screen.
class AiClockApp extends StatefulWidget {
  const AiClockApp({super.key, required this.services});

  final AppServices services;

  @override
  State<AiClockApp> createState() => _AiClockAppState();
}

class _AiClockAppState extends State<AiClockApp> {
  @override
  void initState() {
    super.initState();
    widget.services.start();
  }

  @override
  void dispose() {
    widget.services.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppProviders(
      services: widget.services,
      child: MaterialApp(
        title: AppInfo.name,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRouter.onGenerateRoute,
        builder: (context, child) => RingOverlay(child: child!),
      ),
    );
  }
}
